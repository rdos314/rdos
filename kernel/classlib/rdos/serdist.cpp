/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# serdist.cpp
# Serial port distributed device class
#
########################################################################*/

#include <mem.h>

#include "rdos.h"
#include "serdist.h"
#include "sigdev.h"

#define	STACK_SIZE 0x1800

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TSerialDistDevice::TSerialDistDevice
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSerialDistDevice::TSerialDistDevice(TSerialDevice *Serial)
{
    FThreadStarted = FALSE;
    FSerial = Serial;
    FSerial->Open();
    
	Start("Serial Dist Rec", STACK_SIZE);
}

/*##########################################################################
#
#   Name       : TSerialDistDevice::~TSerialDistDevice
#
#   Purpose....: Destructor for file storage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSerialDistDevice::~TSerialDistDevice()
{
}

/*##########################################################################
#
#   Name       : TSerialDistDevice::SendMsg
#
#   Purpose....: Send a message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDistDevice::SendMsg(const char *Data, int Size)
{
	const char *ptr;
	int i;

    ptr = Data;
    for (i = 0; i < Size; i++)
    {
        while (FSerial->GetSendBufferSpace() < 16)
			RdosWaitMilli(100);

        FSerial->Write(*ptr);
        ptr++;
    }
}

/*##########################################################################
#
#   Name       : TSerialDistDevice::GetTimeout
#
#   Purpose....: Get answer timeout (in milliseconds)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSerialDistDevice::GetTimeout()
{
    return 500;
}

/*##################  TSerialDistDevice::CheckForMsg ############
*   Purpose....: Check for messages                		                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDistDevice::CheckForMsg()
{
    unsigned char uch;
    char ch;
    char Buf[6];
    short int size;
	int i;
	char *data;

	FSerial->WaitForChar(10000);

    for (i = 0; i < 6; i++)
    {
        if (!FSerial->WaitForChar(200))
            return;

		ch = FSerial->Read();
        uch = (unsigned char)ch;
        switch (i)
        {
            case 0:
                if (uch != 0xDE)
                    return;
                break;
                
            case 1:
                if (uch != 0x01)
                    return;
                break;

            case 2:
                if (uch != 0xCE)
                    return;
                break;

            case 3:
                if (uch != 0x01)
                    return;
        }
		Buf[i] = ch;
    }

    memcpy(&size, &Buf[4], 2);

    if (size <= 0)
        return;

    data = new char[8 + size];
	memcpy(data, Buf, 6);

	for (i = 0; i < size + 2; i++)
	{
		if (!FSerial->WaitForChar(200))
		{
			delete data;
			return;
		}
		*(data + i + 6) = FSerial->Read();
	}

	NotifyMsg(data, size);
}

/*##########################################################################
#
#   Name       : TSerialDistDevice::ReceiveThread
#
#   Purpose....: Receive thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDistDevice::ReceiveThread()
{
    while (FInstalled)
        CheckForMsg();
}

/*##########################################################################
#
#   Name       : TSerialDistDevice::SendThread
#
#   Purpose....: Send thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDistDevice::SendThread()
{
    while (FInstalled)
    {
        FSignal->WaitForever();
        UpdateMsg();
    }
}

/*##########################################################################
#
#   Name       : TSerialDistDevice::Execute
#
#   Purpose....: Execute rec & send threads
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDistDevice::Execute()
{
    if (FThreadStarted)
        SendThread();
    else
    {
        FThreadStarted = TRUE;
    	Start("Serial Dist Send", STACK_SIZE);
        ReceiveThread();
    }
}
