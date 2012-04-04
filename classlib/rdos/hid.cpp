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
# hid.cpp
# HID device class
#
########################################################################*/

#include <string.h>

#include "hid.h"
#include "usbpipe.h"
#include "rdos.h"

#define     FALSE	0
#define     TRUE	!FALSE

/*##########################################################################
#
#   Name       : THidDevice::THidDevice
#
#   Purpose....: Constructor for THidDevice
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THidDevice::THidDevice(unsigned short int vendor, unsigned short int prod)
{
    int contr;
    int device;
    int size;
    TUsbDevice UsbDevice;
    int pipe;

    FHidHandle = 0;
    
    for (contr = 0; contr < 256; contr++)
    {
        for (device = 1; device < 128; device++)
        {
            size = RdosGetUsbDevice(contr, device, &UsbDevice, sizeof(TUsbDevice));
            if (size >= sizeof(TUsbDevice))
            {
                if (UsbDevice.vendor == vendor && (unsigned short int)UsbDevice.prod == prod)
                {
                    FHidHandle = RdosOpenHid(contr, device);
                    return;
                }
            }
        }
    }
}

/*##########################################################################
#
#   Name       : THidDevice::~THidDevice
#
#   Purpose....: Destructor for THidDevice
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THidDevice::~THidDevice()
{
    if (FHidHandle)
        RdosCloseHid(FHidHandle);
}

/*##########################################################################
#
#   Name       : THidDevice::IsOnline
#
#   Purpose....: Check if device is online
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THidDevice::IsOnline() const
{
    if (FHidHandle)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : THidDevice::DeviceName
#
#   Purpose....: Return device-name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THidDevice::DeviceName(char *Name, int MaxLen) const
{
    strncpy(Name, "HID", MaxLen);
}

/*##########################################################################
#
#   Name       : THidDevice::Read
#
#   Purpose....: Read HID report descriptor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THidDevice::Read(char *buf, int size, int timeout)
{
    if (FHidHandle)
        return RdosReadHid(FHidHandle, buf, size, timeout);
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : THidDevice::Write
#
#   Purpose....: Write HID report descriptor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THidDevice::Write(const char *buf, int size)
{
    if (FHidHandle)
        return RdosWriteHid(FHidHandle, buf, size);
    else
        return FALSE;
}
