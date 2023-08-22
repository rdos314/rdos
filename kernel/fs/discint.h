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

    int WaitForever();
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

    long long GetDiscSectors();
    int GetBytesPerSector();
    void RunCmd(int handle, char *msg);
    void Run(TDisc *disc);
    bool IsActive();

    void InitDisc(const char *parttype);

    void (*OnInit)(TDiscServer *Server, const char *PartType);

protected:
    void Add(int id, TDiscReq *req);
    void Remove(int id);

    bool FActive;
    bool FReloadDisc;
    TDiscReq *FReqArr[MAX_DISC_REQ_COUNT];
};

#endif

