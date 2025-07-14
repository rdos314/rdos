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
# part.h
# Partition server class
#
########################################################################*/

#ifndef _DISCINT_H
#define _DISCINT_H

#include "str.h"
#include "thread.h"
#include "datetime.h"

#define MAX_DISC_REQ_COUNT 15
#define MAX_DISC_REQ_ENTRIES 255

class TDiscServer;
class TDiscReq;
class TDisc;

class TDiscReqEntry
{
public:
    TDiscReqEntry(TDiscReq *Req, long long StartSector, int SectorCount);
    TDiscReqEntry(TDiscReq *Req, long long StartSector, int SectorCount, bool Zero);
    ~TDiscReqEntry();

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

    TDiscReq *FReq;
    int FId;
};

class TDiscReq
{
friend class TDiscReqEntry;
public:
    TDiscReq(TDiscServer *server);
    ~TDiscReq();

    int Add(long long StartSector, int SectorCount);
    void Start();

    void WaitForever();
    int WaitTimeout(int MilliSec);
    int WaitUntil(TDateTime &time);
    bool IsDone();

protected:
    void Add(TDiscReqEntry *entry);
    void Remove(TDiscReqEntry *entry);

    TDiscServer *FServer;
    TDiscReqEntry *FEntryArr[MAX_DISC_REQ_ENTRIES];
    int FReq;
    int FWaitHandle;
};

class TDiscServer
{
friend class TDiscReq;
public:
    TDiscServer();
    ~TDiscServer();

    int GetHandle();
    TDisc *GetDisc();
    int GetDiscNr();

    long long GetDiscSectors();
    int GetBytesPerSector();
    void RunCmd(int handle, char *msg);
    void Run(TDisc *disc);
    bool IsActive();
    bool IsBusy();

    bool InitDisc(const char *parttype);
    bool AddPartition(const char *FsName, long long Sectors);

    bool (*OnInit)(TDiscServer *Server, const char *PartType);

protected:
    void Add(int id, TDiscReq *req);
    void Remove(int id);

    bool FActive;
    bool FReloadDisc;
    TDiscReq *FReqArr[MAX_DISC_REQ_COUNT];
};

#endif

