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

#define FALSE 0
#define TRUE !FALSE

#define MAX_HID_DEVICES 32

extern void InitHid();

extern int GetReportDescr(struct THidDevice *dev, char *buf, int size, int interface);
#pragma aux GetReportDescr parm routine [fs esi] [es edi] [ecx] [edx] value [eax]

struct THidDescriptor
{
    unsigned char Len;
    char Type;
    char Ver[2];
    char CountryCode;
    char NumDescriptors;
    char DescriptorType;
    unsigned short int DescriptorLen;
};

struct THidDevice
{
    int Controller;
    int Device;
    int ControlPipe;
    int ControlWait;
    int ReportDescrSize;
    char ReportDescrData[1];
};

struct THidDevice *HidArr[MAX_HID_DEVICES];

/*##########################################################################
#
#   Name       : LoadReportDescr
#
#   Purpose....: Load report descriptor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int LoadReportDescr(struct THidDevice *dev)
{
    int size;
    
    dev->ControlPipe = RdosOpenUsbPipe(dev->Controller, dev->Device, 0);
    dev->ControlWait = RdosCreateWait();
    size = GetReportDescr(dev, dev->ReportDescrData, dev->ReportDescrSize, 0);

    if (size == dev->ReportDescrSize)
        return TRUE;
    else
    {
        RdosCloseUsbPipe(dev->ControlPipe);
        RdosCloseWait(dev->ControlWait);
        return FALSE;
    }
}

/*##########################################################################
#
#   Name       : Test gate
#
##########################################################################*/

#pragma aux ImplTestGate "*" rdosdev parm routine [es edi]
void __far ImplTestGate(const char *msg)
{
    int i;
    struct THidDevice *dev;
    int size;
    int ok;

    for (i = 0; i < MAX_HID_DEVICES; i++)
    {
        dev = HidArr[i];
        if (dev)
        {
            ok = LoadReportDescr(dev);
        }
    }
}

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
    int size;
    struct THidDescriptor *descr;
    char *buf = RdosAllocateSmallGlobalMem(0x1000);
    char *ptr;

    for (i = 0; i < MAX_HID_DEVICES; i++)
    {
        if (HidArr[i] == 0)
        {
            size = RdosGetUsbConfig(controller, device, 0, buf, 0x1000);
                   
            ptr = buf;
            while (size > 0)
            {
                descr = (struct THidDescriptor *)ptr;
                if (descr->Type == 0x21 && descr->DescriptorType == 0x22)
                {
                    dev = (struct THidDevice *)RdosAllocateSmallGlobalMem(sizeof(struct THidDevice) + descr->DescriptorLen);
                    dev->Controller = controller;
                    dev->Device = device;
                    dev->ReportDescrSize = descr->DescriptorLen;
                    HidArr[i] = dev;        
                    break;
                }
                ptr += descr->Len;
                size -= descr->Len;
            }
            break;
        }
    }
    RdosFreeMem(RdosPointerToSelector(buf));
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
    RdosRegisterBimodalUserGate(usergate_test_gate, (__rdos_gate_callback *)&ImplTestGate, "Test Gate"); 
}
