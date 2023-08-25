/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-20019, Leif Ekblad
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
# part.h
# Partition server class
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
    int Format(int PartType, long long *Start, long long *Size);

    long long GetPartStartSector();
    long long GetPartSectors();
    int GetBytesPerSector();

    bool WaitForMsg();
    bool WaitForMsg(TFs *fs);
    bool IsActive();

    void (*OnStart)(TPartServer *Server);
    int (*OnFormat)(TPartServer *Server, int PartType, long long *Start, long long *Size);

protected:
    void Add(int id, TPartReq *req);
    void Remove(int id);

    bool FActive;
    TPartReq *FReqArr[MAX_DISC_REQ_COUNT];
};

#endif

