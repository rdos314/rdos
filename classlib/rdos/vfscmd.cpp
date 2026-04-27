/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# vfscmd.cpp
# VFS command class
#
########################################################################*/

#include "vfscmd.h"

#include <rdos.h>

/*##########################################################################
#
#   Name       : TVfsCmd::TVfsCmd
#
#   Purpose....: VFS cmd constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVfsCmd::TVfsCmd()
 : TWaitDevice("VFS Cmd")
{
    FHandle = 0;
    OnDone = 0;
    OnMsg = 0;
}

/*##########################################################################
#
#   Name       : TVfsCmd::~TVfsCmd
#
#   Purpose....: VFS cmd destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVfsCmd::~TVfsCmd()
{
    if (FHandle)
        RdosCloseVfsCmd(FHandle);
}

/*##########################################################################
#
#   Name       : TVfsCmd::IsDone
#
#   Purpose....: Is done?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TVfsCmd::IsDone()
{
    return RdosIsVfsCmdDone(FHandle);
}

/*##########################################################################
#
#   Name       : TVfsCmd::NotifyDone
#
#   Purpose....: Notify done
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVfsCmd::NotifyDone()
{
    if (OnDone)
        (*OnDone)(this);
}

/*##########################################################################
#
#   Name       : TVfsCmd::NotifyMsg
#
#   Purpose....: Notify msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVfsCmd::NotifyMsg(const char *msg)
{
    if (OnMsg)
        (*OnMsg)(this, msg);
}

/*##########################################################################
#
#   Name       : TVfsCmd::SignalNewData
#
#   Purpose....: Signal new data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVfsCmd::SignalNewData()
{
    int size;
    char *msg;

    if (IsDone())
        NotifyDone();
    else
    {
        size = RdosGetVfsResponseSize(FHandle);
        if (size)
        {
            msg = new char[size + 1];
            RdosGetVfsResponseData(FHandle, msg, size);
            msg[size] = 0;
            NotifyMsg(msg);
            delete msg;
        }
    }
}

/*##########################################################################
#
#   Name       : TVfsCmd::Add
#
#   Purpose....: Add wait
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVfsCmd::Add(TWait *Wait)
{
    RdosAddWaitForVfsCmd(Wait->GetHandle(), FHandle, (int)this);
}
