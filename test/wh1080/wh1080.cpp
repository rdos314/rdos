/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2011, Leif Ekblad
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
# wh1080.cpp
# WH1080 weather station class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "usbpipe.h"

#define FALSE 0
#define TRUE !FALSE

int HidHandle = 0;

/*##########################################################################
#
#   Name       : ReadBlock
#
#   Purpose....: Read block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int ReadBlock(int Offset, char *Buffer)
{
    char req[8];

    req[0] = 0xA1;
    req[1] = (char)(Offset / 256);
    req[2] = (char)(Offset & 0xFF);
    req[3] = 0x20;
    req[4] = 0xA1;
    req[5] = (char)(Offset / 256);
    req[6] = (char)(Offset & 0xFF);
    req[7] = 0x20;

//    RdosReadHid(HidHandle, Buffer, 32, 500);

    if (RdosWriteHid(HidHandle, req, 8, 250))
        if (RdosReadHid(HidHandle, Buffer, 32, 1000))
            return TRUE;

    return FALSE;
}

/*##########################################################################
#
#   Name       : WriteBlock
#
#   Purpose....: Write block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int WriteBlock(int Offset, const char *Buffer)
{
    char req[8];

    req[0] = 0xA0;
    req[1] = (char)(Offset / 256);
    req[2] = (char)(Offset & 0xFF);
    req[3] = 0x20;
    req[4] = 0xA0;
    req[5] = (char)(Offset / 256);
    req[6] = (char)(Offset & 0xFF);
    req[7] = 0x20;

    if (RdosWriteHid(HidHandle, req, 8, 250))
        if (RdosWriteHid(HidHandle, Buffer, 32, 250))
            if (RdosReadHid(HidHandle, req, 8, 1000))
                return TRUE;
        
    return FALSE;
}

/*##########################################################################
#
#   Name       : WriteDataRefresh
#
#   Purpose....: Write data refresh
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int WriteDataRefresh()
{
    char req[8];

    req[0] = 0xA2;
    req[1] = 0;
    req[2] = 0x1A;
    req[3] = 0x20;
    req[4] = 0xA2;
    req[5] = 0xAA;
    req[6] = 0;
    req[7] = 0x20;

    if (RdosWriteHid(HidHandle, req, 8, 250))
        if (RdosReadHid(HidHandle, req, 8, 1000))
            return TRUE;
        
    return FALSE;
}

/*##########################################################################
#
#   Name       : ReadFixedBlock
#
#   Purpose....: Read fixed block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int ReadFixedBlock(char *Buffer)
{
    unsigned char ch0, ch1;

    if (ReadBlock(0, Buffer))
    {
        ch0 = (unsigned char)Buffer[0];
        ch1 = (unsigned char)Buffer[1];
    
        if (ch0 == 0x55 && ch1 == 0xAA)
            return TRUE;

        if (ch0 == 0xFF && ch1 == 0xFF)
            return TRUE;

        if (ch0 == 0x55 && ch1 == 0x55)
            return TRUE;
    }

    return FALSE;
}

/*##########################################################################
#
#   Name       : WriteFixedBlock
#
#   Purpose....: Write fixed block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int WriteFixedBlock(char *Buffer)
{
    Buffer[0] = 0x55;
    Buffer[1] = 0xAA;

    if (WriteBlock(0, Buffer))
        if (WriteDataRefresh())
            return TRUE;

    return FALSE;
}

/*##########################################################################
#
#   Name       : GetDevice
#
#   Purpose....: Find device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetDevice()
{
    int contr;
    int device;
    int size;
    TUsbDevice UsbDevice;
    int pipe;
    
    for (contr = 0; contr < 256; contr++)
    {
        for (device = 1; device < 128; device++)
        {
            size = RdosGetUsbDevice(contr, device, &UsbDevice, sizeof(TUsbDevice));
            if (size >= sizeof(TUsbDevice))
            {
                if (UsbDevice.vendor == 0x1941 && (unsigned short int)UsbDevice.prod == 0x8021)
                {
                    HidHandle = RdosOpenHid(contr, device);
                    printf("Found weather station\r\n");
                }
            }
        }
    }
}

void main()
{
    int ok;
    char Buffer[32];
    
    GetDevice();

    if (HidHandle)
    {
        ok = ReadFixedBlock(Buffer);
    
        for (;;)
            RdosWaitMilli(1000);
    }
}

