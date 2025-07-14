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
# partint.h
# Partition interface class
#
########################################################################*/

#ifndef _PARTINT_H
#define _PARTINT_H

#include "thread.h"
#include "datetime.h"

#define MAX_DISC_REQ_COUNT 15
#define MAX_DISC_REQ_ENTRIES 255

class TPartServer;
class TPartReq;
class TFs;

class TPartReqEntry
{
public:
    TPartReqEntry(TPartReq *Req, long long StartSector, int SectorCount);
    TPartReqEntry(TPartReq *Req, long long StartSector, int SectorCount, bool Zero);
    ~TPartReqEntry();

    int GetId();
    long long GetStartSector();
    int GetSectorCount();
    char *GetData();
    char *Map();
    void Unmap();
    void Write();

protected:
    long long FStartSector;
    int FSectorCount;
    char *FData;
    bool FMapped;

    TPartReq *FReq;
    int FId;
};

class TPartReq
{
friend class TPartReqEntry;
public:
    TPartReq(TPartServer *server);
    ~TPartReq();

    int Add(long long StartSector, int SectorCount);
    void Start();

    void WaitForever();
    int WaitTimeout(int MilliSec);
    int WaitUntil(TDateTime &time);
    bool IsDone();

protected:
    void Add(TPartReqEntry *entry);
    void Remove(TPartReqEntry *entry);

    TPartServer *FServer;
    TPartReqEntry *FEntryArr[MAX_DISC_REQ_ENTRIES];
    int FReq;
    int FWaitHandle;
};

class TPartServer
{
friend class TPartReq;
public:
    TPartServer();
    ~TPartServer();

    int GetHandle();

    void Start();
    void Stop();
    void Disable();
    int Format();

    long long GetPartStartSector();
    long long GetPartSectors();
    int GetBytesPerSector();
    int GetPartType();
    bool MovePartUp(long long Diff);
    bool ShrinkPart(long long Diff);

    bool WaitForMsg();
    bool WaitForMsg(TFs *fs);
    bool IsActive();

    void (*OnStart)(TPartServer *Server);
    int (*OnFormat)(TPartServer *Server);

protected:
    void Add(int id, TPartReq *req);
    void Remove(int id);

    bool FActive;
    TPartReq *FReqArr[MAX_DISC_REQ_COUNT];
};

#endif

