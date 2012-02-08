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

class TWh1080 : public TThread
{
public:
    TWh1080Pipe(int Controller, int Device, int Pipe);
    ~TWh1080Pipe();

protected:
    virtual void Execute();

    TUsbPipe FControlPipe;
    TUsbPipe FInputPipe;    
};

/*##########################################################################
#
#   Name       : NotifyData
#
#   Purpose....: New data from pipe
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void NotifyData(const char *buf)
{
}

/*##########################################################################
#
#   Name       : TWh1080::TWh1080
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWh1080::TWh1080(int Controller, int Device, int Pipe)
  : FControlPipe(Controller, Device, 0,
    FInputPipe(Controller, Device, Pipe)
{
    Start("WH1080", 0x4000);
}

/*##########################################################################
#
#   Name       : TWh1080::~TWh1080
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWh1080::~TWh1080()
{
}

/*##########################################################################
#
#   Name       : TWh1080::Execute
#
#   Purpose....: Execute method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWh1080::Execute()
{
    char buf[8];

    for (;;)
    {
        ReqData(buf, 8);
        WaitForever();

        if (GetDataSize() == 8)
            NotifyData(buf);
    }
}

/*##########################################################################
#
#   Name       : Execute
#
#   Purpose....: Execute 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void Execute(int Hid, int Controller, int Device, int Pipe)
{
    TWh1080 Station(Controller, Device, Pipe);

    printf("Found weather station started\r\n");

    for (;;)
        RdosWaitMilli(1000);
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
    int handle;
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
                    handle = RdosOpenHid(contr, device);
                    pipe = RdosGetHidPipe(handle);
                    Execute(handle, contr, device, pipe);
                }
            }
        }
    }
}

void main()
{
    GetDevice();
}
