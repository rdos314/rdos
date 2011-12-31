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
#include "ctlpipe.h"

#define FALSE 0
#define TRUE !FALSE

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
    
    for (contr = 0; contr < 256; contr++)
    {
        for (device = 1; device < 128; device++)
        {
            size = RdosGetUsbDevice(contr, device, &UsbDevice, sizeof(TUsbDevice));
            if (size >= sizeof(TUsbDevice))
            {
                if (UsbDevice.vendor == 0x1941 && (unsigned short int)UsbDevice.prod == 0x8021)
                {
                    printf("Found weather station, controller: %d, device: %d\r\n", contr, device);
                }
            }
        }
    }
}

void main()
{
    GetDevice();
}
