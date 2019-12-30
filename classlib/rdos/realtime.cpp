/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2019, Leif Ekblad
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
# Realtime.cpp
# Realtime class
#
########################################################################*/

#include "realtime.h"

#include <rdos.h>

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TRealtimeCore::TRealtimeCore
#
#   Purpose....: Constructor for TRealtimeCore
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRealtimeCore::TRealtimeCore(TRealtimeDevice *Dev, int Core, int ID)
{
    OnSignal = 0;
    FDevice = Dev;
    FCore = Core;
    FID = ID;
}

/*##########################################################################
#
#   Name       : TRealtimeCore::~TRealtimeCore
#
#   Purpose....: Destructor for TRealtimeCore
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRealtimeCore::~TRealtimeCore()
{
}

/*##########################################################################
#
#   Name       : TRealtimeCore::GetCore
#
#   Purpose....: Get core #
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRealtimeCore::GetCore()
{
    return FCore;
}

/*##########################################################################
#
#   Name       : TRealtimeCore::GetID
#
#   Purpose....: Get ID
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRealtimeCore::GetID()
{
    return FID;
}

/*##########################################################################
#
#   Name       : TRealtimeCore::NotifySignal
#
#   Purpose....: Notify signal
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRealtimeCore::NotifySignal(int Signal)
{
    if (OnSignal)
        (*OnSignal)(this, Signal);
}

/*##########################################################################
#
#   Name       : TRealtimeDevice::TRealtimeDevice
#
#   Purpose....: Constructor for TRealtimeDevice
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRealtimeDevice::TRealtimeDevice()
 : FSection("Realtime")
{
    int i;

    for (i = 0; i < 256; i++)
        FCoreArr[i] = 0;

    FHandle = RdosCreateRealtime();

    Start("Realtime", 0x8000);
}

/*##########################################################################
#
#   Name       : TRealtimeDevice::~TRealtimeDevice
#
#   Purpose....: Destructor for TRealtimeDevice
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRealtimeDevice::~TRealtimeDevice()
{
}

/*##########################################################################
#
#   Name       : TRealtimeDevice::Add
#
#   Purpose....: Add core
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRealtimeCore *TRealtimeDevice::AddCore(int ID, const char *ExeName)
{
    TRealtimeCore *CoreObj;
    int CoreNum;

    FSection.Enter();
    CoreNum = RdosAddRealtimeCore(FHandle, ExeName);
    CoreObj = new TRealtimeCore(this, CoreNum, ID);
    FCoreArr[CoreNum] = CoreObj;
    FSection.Leave();

    return CoreObj;
}

/*##########################################################################
#
#   Name       : TRealtimeDevice::AllocateGlobalBuffer
#
#   Purpose....: Allocate global buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRealtimeDevice::AllocateGlobalBuffer(long long size)
{
    return RdosAllocateRealtimeBuffer(FHandle, size);
}

/*##########################################################################
#
#   Name       : TRealtimeDevice::MapGlobalBuffer
#
#   Purpose....: Map global buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TRealtimeDevice::MapGlobalBuffer(int handle, long long offset, int size)
{
    return RdosMapRealtimeBuffer(handle, offset, size);
}

/*##########################################################################
#
#   Name       : TRealtimeDevice::UnmapGlobalBuffer
#
#   Purpose....: Unmap global buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRealtimeDevice::UnmapGlobalBuffer(int handle)
{
    RdosUnmapRealtimeBuffer(handle);
}

/*##########################################################################
#
#   Name       : TRealtimeDevice::Execute
#
#   Purpose....: Execute
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRealtimeDevice::Execute()
{
    int core;
    int sig;

    while (FInstalled)
    {
        RdosWaitForRealtimeSignal(FHandle);

        FSection.Enter();
        if (RdosGetRealtimeSignal(FHandle, &core, &sig))
        {
            if (FCoreArr[core])
            {
                if (OnSignal)
                    (OnSignal)(this, FCoreArr[core]->GetID(), sig);

                FCoreArr[core]->NotifySignal(sig);
            }
        }
        FSection.Leave();
    }
}
