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

#ifdef __GNUC__
#include <string.h>
#else
#include <mem.h>
#endif
#include <string.h>

#include "rdos.h"
#include "serdist.h"
#include "sigdev.h"
#include "datetime.h"

#define STACK_SIZE          0x1800
#define POLL_INTERVAL       15

#define FALSE
#define TRUE    !FALSE

/*##################  SendStartup  ##############################################
*   Purpose....: Startup procedure for send thread                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
static void SendStartup(void *ptr)
{
        ((TSerialDistDevice *)ptr)->SendThread();
}

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
        FSerial = Serial;
    FSerial->Open();
        FPollCount = 0;
    
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

/*##################  TSerialDistDevice::DeviceName  ################
*   Purpose....: Get device name                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TSerialDistDevice::DeviceName(char *Name, int MaxLen) const
{
        strncpy(Name,"Serial Dist",MaxLen);
}

/*##########################################################################
#
#   Name       : TSerialDistDevice::NotifyOpen
#
#   Purpose....: Notify device open
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDistDevice::NotifyOpen()
{
    FSerial->Open();
    TDevice::NotifyOpen();
}

/*##########################################################################
#
#   Name       : TSerialDistDevice::NotifyClose
#
#   Purpose....: Notify device close
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDistDevice::NotifyClose()
{
    TDevice::NotifyClose();
    FSerial->Close();
}

/*##########################################################################
#
#   Name       : TSerialDistDevice::Reset
#
#   Purpose....: Reset device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDistDevice::Reset()
{
    FSerial->Clear();
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
        return 1000;
}

/*##########################################################################
#
#   Name       : TSerialDistDevice::GetPort
#
#   Purpose....: Get serial port
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSerialDistDevice::GetPort()
{
        return FSerial->GetPort();
}

/*##################  TSerialDistDevice::CheckForMsg ############
*   Purpose....: Check for messages                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDistDevice::CheckForMsg()
{
        char Buf[6];
        short int size;
        int i;
        char *data;
        long sign;

        FSerial->WaitForChar(10000);

        for (i = 0; i < 4; i++)
        {
        if (!FSerial->WaitForChar(200))
            return;

                Buf[i] = FSerial->Read();
    }

        memcpy(&sign, Buf, 4);

        while (!CheckSignature(sign))
        {
                if (!FSerial->WaitForChar(200))
                        return;

                Buf[0] = Buf[1];
                Buf[1] = Buf[2];
                Buf[2] = Buf[3];
                Buf[3] = FSerial->Read();

                memcpy(&sign, Buf, 4);
        }

    for (i = 4; i < 6; i++)
    {
        if (!FSerial->WaitForChar(200))
            return;

                Buf[i] = FSerial->Read();
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

    FPollTime = TDateTime();
    FPollTime.AddSec(POLL_INTERVAL);
    
    FPollCount = 0;
    Online();
        NotifyMsg(sign, data, size);
        delete data;
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
        if (IsActive())
            CheckForMsg();
        else
            RdosWaitMilli(1000);
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
        if (IsActive())
        {
            FSignal->WaitTimeout(500);
            UpdateMsg();

            if (FPollTime < TDateTime())
            {
                if (FPollCount > 10)
                    Offline();
                else
                    FPollCount++;
            
                SendPollReq();       
            }
        }
        else
            RdosWaitMilli(1000);
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
        RdosCreateThread(SendStartup, "Serial Dist Send", this, STACK_SIZE);
    ReceiveThread();
}
