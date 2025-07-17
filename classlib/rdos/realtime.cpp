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
