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
