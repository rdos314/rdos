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
# realtime.h
# Realtime class
#
########################################################################*/

#ifndef _REALTIME_H
#define _REALTIME_H

#include "thread.h"

class TRealtimeDevice;

class TRealtimeCore
{
friend class TRealtimeDevice;
public:
    int GetCore();
    int GetID();

    void (*OnSignal)(TRealtimeCore *Core, int Signal);

protected:
    TRealtimeCore(TRealtimeDevice *Dev, int Core, int ID);
    virtual ~TRealtimeCore();

    void NotifySignal(int Signal);

    TRealtimeDevice *FDevice;
    int FCore;
    int FID;
};

class TRealtimeDevice : public TThread
{
friend class TRealtimeCore;
public:
    TRealtimeDevice();
    virtual ~TRealtimeDevice();

    TRealtimeCore *AddCore(int ID, const char *ExeName);

    int AllocateGlobalBuffer(long long size);
    char *MapGlobalBuffer(int handle, long long offset, int size);
    void UnmapGlobalBuffer(int handle);

    void (*OnSignal)(TRealtimeDevice *Dev, int ID, int Signal);

protected:
    virtual void Execute();

    TSection FSection;
    int FHandle;
    TRealtimeCore *FCoreArr[256];
};

#endif

