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
# ctlpipe.cpp
# USB control pipe class
#
########################################################################*/

#include <string.h>
#include "ctlpipe.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TUsbControlPipe::TUsbControlPipe
#
#   Purpose....: Constructor
#
#   In params..: Handle     USB pipe handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUsbControlPipe::TUsbControlPipe(int Handle)
 : TUsbPipe(Handle)
{
}

/*##########################################################################
#
#   Name       : TUsbControlPipe::TUsbControlPipe
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
TUsbControlPipe::TUsbControlPipe(int Controller, int Device, int Pipe)
 : TUsbPipe(Controller, Device, Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbControlPipe::~TUsbControlPipe
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUsbControlPipe::~TUsbControlPipe()
{
}

/*##########################################################################
#
#   Name       : TUsbControlPipe::Send
#
#   Purpose....: Send control-message with no data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUsbControlPipe::Send(TUsbControlMsg *msg, int MilliSec)
{
    int ok;

    msg->len = 0;

    Lock();
    WriteControl((char *)msg, sizeof(TUsbControlMsg));
    ReqStatus();

    WaitTimeout(MilliSec);
    ok = WasTransOk();

    Unlock();
    return ok;
}

/*##########################################################################
#
#   Name       : TUsbControlPipe::Write
#
#   Purpose....: Send control-message with output data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUsbControlPipe::Write(TUsbControlMsg *msg, const char *buf, int size, int MilliSec)
{
    int ok;
    
    msg->type &= 0x7F;
    msg->len = (short int)size;

    Lock();
    WriteControl((char *)msg, sizeof(TUsbControlMsg));
    WriteData(buf, size);
    ReqStatus();

    WaitTimeout(MilliSec);
    ok = WasTransOk();
    Unlock();

    if (ok)
        return size;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TUsbControlPipe::Read
#
#   Purpose....: Send control-message with input data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUsbControlPipe::Read(TUsbControlMsg *msg, char *buf, int size, int MilliSec)
{
    int ok;
    int len;
    
    msg->type |= 0x80;
    msg->len = (short int)size;
    
    Lock();    
    WriteControl((char *)msg, sizeof(TUsbControlMsg));
        ReqData(buf, size);
        ReqStatus();

        WaitTimeout(MilliSec);
        ok = WasTransOk();

        if (ok)
                len = GetDataSize();
    
    Unlock();

    if (ok)
        return len;
    else
        return 0;
}

