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
# usbpipe.cpp
# Usbpipe class
#
########################################################################*/

#include <string.h>
#include "usbpipe.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TUsbPipe::TUsbPipe
#
#   Purpose....: Constructor
#
#   In params..: Handle     USB pipe handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUsbPipe::TUsbPipe(int Handle)
{
        FHandle = Handle;
}

/*##########################################################################
#
#   Name       : TUsbPipe::TUsbPipe
#
#   Purpose....: Constructor
#
#   In params..: Controller Controller ID
#                                Device     Device ID
#                Pipe       Pipe #
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUsbPipe::TUsbPipe(int Controller, int Device, int Pipe)
{
        FHandle = RdosOpenUsbPipe(Controller, Device, Pipe);
}

/*##########################################################################
#
#   Name       : TUsbPipe::~TUsbPipe
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUsbPipe::~TUsbPipe()
{
    if (FHandle)
        RdosCloseUsbPipe(FHandle);
}

/*##########################################################################
#
#   Name       : TUsbPipe::DeviceName
#
#   Purpose....: Returns device-name
#
#   In params..: MaxLen max size of name
#   Out params.: Name   device name
#   Returns....: *
#
##########################################################################*/
void TUsbPipe::DeviceName(char *Name, int MaxLen) const
{
        strncpy(Name,"Usb pipe",MaxLen);
}

/*##########################################################################
#
#   Name       : TUsbPipe::Add
#
#   Purpose....: Add object to wait
#
#   In params..: Wait       Wait device
#                Handle     Socket handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbPipe::Add(TWait *Wait)
{
        if (FHandle)
                RdosAddWaitForUsbPipe(Wait->GetHandle(), FHandle, this);
}

/*##########################################################################
#
#   Name       : TUsbPipe::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbPipe::SignalNewData()
{
}

/*##########################################################################
#
#   Name       : TUsbPipe::Lock
#
#   Purpose....: Lock pipe for commands
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbPipe::Lock()
{
        RdosLockUsbPipe(FHandle);
}

/*##########################################################################
#
#   Name       : TUsbPipe::Unlock
#
#   Purpose....: Unlock pipe for commands
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbPipe::Unlock()
{
        RdosUnlockUsbPipe(FHandle);
}

/*##########################################################################
#
#   Name       : TUsbPipe::WriteControl
#
#   Purpose....: Queue control message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbPipe::WriteControl(const char *buf, int size)
{
    RdosWriteUsbControl(FHandle, buf, size);
}

/*##########################################################################
#
#   Name       : TUsbPipe::ReqData
#
#   Purpose....: Queue request for input data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbPipe::ReqData(char *buf, int maxsize)
{
        RdosReqUsbData(FHandle, buf, maxsize);
}

/*##########################################################################
#
#   Name       : TUsbPipe::WriteData
#
#   Purpose....: Queue data message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbPipe::WriteData(const char *buf, int size)
{
    RdosWriteUsbData(FHandle, buf, size);
}

/*##########################################################################
#
#   Name       : TUsbPipe::GetDataSize
#
#   Purpose....: Get received data size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUsbPipe::GetDataSize()
{
        return RdosGetUsbDataSize(FHandle);
}

/*##########################################################################
#
#   Name       : TUsbPipe::ReqStatus
#
#   Purpose....: Queue status input req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbPipe::ReqStatus()
{
    RdosReqUsbStatus(FHandle);
}

/*##########################################################################
#
#   Name       : TUsbPipe::WriteStatus
#
#   Purpose....: Queue status output req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbPipe::WriteStatus()
{
    RdosWriteUsbStatus(FHandle);
}

/*##########################################################################
#
#   Name       : TUsbPipe::IsTransDone
#
#   Purpose....: Check if transaction is done
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUsbPipe::IsTransDone()
{
    return RdosIsUsbTransactionDone(FHandle);
}

/*##########################################################################
#
#   Name       : TUsbPipe::WasTransOk
#
#   Purpose....: Check if transaction was ok
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUsbPipe::WasTransOk()
{
    return RdosWasUsbTransactionOk(FHandle);
}

