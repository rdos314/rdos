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
# hid.c
# HID device
#
########################################################################*/

#include "rdos.h"
#include "rdosdev.h"
#include "string.h"

#include <stdio.h>

#define MAX_HID_DEVICES 32

extern void InitHid();

struct THidDevice
{
    int Controller;
    int Device;
};

struct THidDevice *HidArr[MAX_HID_DEVICES];

/*##########################################################################
#
#   Name       : UsbAttach
#
#   Purpose....: USB attach notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux UsbAttach "*" rdosdev parm routine [ebx] [eax]
void UsbAttach(int controller, int device)
{
    int i;
    struct THidDevice *dev;

    for (i = 0; i < MAX_HID_DEVICES; i++)
    {
        if (HidArr[i] == 0)
        {
            dev = (struct THidDevice *)RdosAllocateSmallGlobalMem(sizeof(struct THidDevice));
            dev->Controller = controller;
            dev->Device = device;
            HidArr[i] = dev;        
            break;
        }
    }
}

/*##########################################################################
#
#   Name       : UsbDetach
#
#   Purpose....: USB detach notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux UsbDetach "*" rdosdev parm routine [ebx] [eax]
void UsbDetach(int controller, int device)
{
    int i;
    struct THidDevice *dev;

    for (i = 0; i < MAX_HID_DEVICES; i++)
    {
        dev = HidArr[i];
        if (dev)
        {
            if (dev->Controller == controller && dev->Device == device)
            {
                RdosFreeMem(RdosPointerToSelector(dev));
                HidArr[i] = 0;
                break;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Initialization
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main()
{
    int i;

    for (i = 0; i < MAX_HID_DEVICES; i++)
        HidArr[i] = 0;

    InitHid();
}
