/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# discserv.cpp
# Disc server class
#
########################################################################*/

#include <stdio.h>
#include <rdos.h>
#include <serv.h>
#include "discserv.h"
#include "fs.h"

static int handle = 0;
static TFs *Server = 0;

extern "C" {

extern void WaitForMsg(int handle);
#pragma aux WaitForMsg parm routine [ebx]

long long GetFreeSectors()
{
    return Server->GetFreeSectors();
}

struct TShareHeader *GetDir(int rel, char *path, int *count)
{
    return Server->GetDir(rel, path, count);
}

int GetDirHeaderSize()
{
    return sizeof(struct DirEntry);
}

int GetDirEntryAttrib(int rel, char *path)
{
    return Server->GetDirEntryAttrib(rel, path);
}

int LockRelDir(int rel, char *path)
{
    return Server->LockRelDir(rel, path);
}

void CloneRelDir(int rel)
{
    Server->CloneRelDir(rel);
}

void UnlockRelDir(int rel)
{
    Server->UnlockRelDir(rel);
}

int GetRelDir(int rel, char *path)
{
    return Server->GetRelDir(rel, path);
}

void ReadDirLink(void *d, int index)
{
    TDir *dir = (TDir *)d;

    return Server->ReadDirLink(dir, index);
}

int OpenFile(int rel, char *path)
{
    return Server->OpenFile(rel, path);
}

int GetFileAttrib(int handle)
{
    return Server->GetFileAttrib(handle);
}

int GetFileHandle(int handle)
{
    return Server->GetFileHandle(handle);
}
}

/*##########################################################################
#
#   Name       : TDiscReqEntry::TDisReqEntry
#
#   Purpose....: Disc req entry contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscReqEntry::TDiscReqEntry(TDiscReq *Req, long long StartSector, int SectorCount)
{
    FStartSector = StartSector;
    FSectorCount = SectorCount;
    FData = 0;

    FReq = Req;

    FId = ServAddVfsSectors(Req->FReq, StartSector, SectorCount);

    Req->Add(this);
}

/*##########################################################################
#
#   Name       : TDiscReqEntry::~TDiscReqEntry
#
#   Purpose....: Disc req entry destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscReqEntry::~TDiscReqEntry()
{
    FReq->Remove(this);

    if (FData)
        ServUnmapVfsReq(FReq->FReq, FId);

    ServRemoveVfsSectors(FReq->FReq, FId);
}

/*##########################################################################
#
#   Name       : TDiscReqEntry::GetId
#
#   Purpose....: Get ID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDiscReqEntry::GetId()
{
    return FId;
}

/*##########################################################################
#
#   Name       : TDiscReqEntry::GetStartSector
#
#   Purpose....: Get start sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TDiscReqEntry::GetStartSector()
{
    return FStartSector;
}

/*##########################################################################
#
#   Name       : TDiscReqEntry::GetSectorCount
#
#   Purpose....: Get sector count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDiscReqEntry::GetSectorCount()
{
    return FSectorCount;
}

/*##########################################################################
#
#   Name       : TDiscReqEntry::GetData
#
#   Purpose....: Get data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TDiscReqEntry::GetData()
{
    return FData;
}

/*##########################################################################
#
#   Name       : TDiscReqEntry::Map
#
#   Purpose....: Map sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TDiscReqEntry::Map()
{
    FData = ServMapVfsReq(FReq->FReq, FId);
    return FData;
}

/*##########################################################################
#
#   Name       : TDiscReqEntry::Unmap
#
#   Purpose....: Unmap sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDiscReqEntry::Unmap()
{
    ServUnmapVfsReq(FReq->FReq, FId);
    FData = 0;
}

/*##########################################################################
#
#   Name       : TDiscReq::TDisReq
#
#   Purpose....: Disc req contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscReq::TDiscReq(TDiscServer *server)
{
    int i;

    FWaitHandle = RdosCreateWait();
    FServer = server;
    FReq = ServCreateVfsReq(handle);

    ServAddWaitForVfsReq(FWaitHandle, FReq, FReq & 0xFF);

    FServer->Add(FReq & 0xFF, this);

    for (i = 0; i < MAX_DISC_REQ_ENTRIES; i++)
        FEntryArr[i] = 0;
}

/*##########################################################################
#
#   Name       : TDiscReq::~TDiscReq
#
#   Purpose....: Disc req destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscReq::~TDiscReq()
{
    int i;

    FServer->Remove(FReq & 0xFF);

    for (i = 0; i < MAX_DISC_REQ_ENTRIES; i++)
        if (FEntryArr[i])
            delete FEntryArr[i];

    ServCloseVfsReq(FReq);

    RdosCloseWait(FWaitHandle);
}

/*##########################################################################
#
#   Name       : TDiscReq::WaitForever
#
#   Purpose....: Wait forever
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDiscReq::WaitForever()
{
    return RdosWaitForever(FWaitHandle);
}

/*##########################################################################
#
#   Name       : TDiscReq::WaitTimeout
#
#   Purpose....: Wait timeout
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDiscReq::WaitTimeout(int MilliSec)
{
    return RdosWaitTimeout(FWaitHandle, MilliSec);
}

/*##########################################################################
#
#   Name       : TDiscReq::WaitUntil
#
#   Purpose....: Wait until
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDiscReq::WaitUntil(TDateTime &time)
{
    return RdosWaitUntilTimeout(FWaitHandle, time.GetMsb(), time.GetLsb());
}

/*##########################################################################
#
#   Name       : TDiscReq::IsDone
#
#   Purpose....: Check if done
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TDiscReq::IsDone()
{
    return ServIsVfsReqDone(FReq);
}

/*##########################################################################
#
#   Name       : TDiscReq::Add
#
#   Purpose....: Add request
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDiscReq::Add(TDiscReqEntry *entry)
{
    int id = entry->GetId();

    if (id > 0 && id <= MAX_DISC_REQ_ENTRIES)
        FEntryArr[id - 1] = entry;
}

/*##########################################################################
#
#   Name       : TDiscReq::Remove
#
#   Purpose....: Remove request
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDiscReq::Remove(TDiscReqEntry *entry)
{
    int id = entry->GetId();

    if (id > 0 && id <= MAX_DISC_REQ_ENTRIES)
        FEntryArr[id - 1] = 0;
}

/*##########################################################################
#
#   Name       : TDiscReq::Add
#
#   Purpose....: Add request
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDiscReq::Add(long long StartSector, int SectorCount)
{
    TDiscReqEntry *entry = new TDiscReqEntry(this, StartSector, SectorCount);
    return entry->GetId();
}

/*##########################################################################
#
#   Name       : TDiscReq::Start
#
#   Purpose....: Start request
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDiscReq::Start()
{
    ServStartVfsReq(FReq);
}

/*##########################################################################
#
#   Name       : TDiscServer::TDiscServer
#
#   Purpose....: Disc server contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscServer::TDiscServer()
{
    char str[40];
    int i;

    FActive = true;

    if (!handle)
        handle = ServGetVfsHandle();

    for (i = 0; i < MAX_DISC_REQ_COUNT; i++)
        FReqArr[i] = 0;
}

/*##########################################################################
#
#   Name       : TDiscServer::~TDiscServer
#
#   Purpose....: Disc server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscServer::~TDiscServer()
{
}

/*##########################################################################
#
#   Name       : TDiscServer::GetHandle
#
#   Purpose....: Get VFS handle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDiscServer::GetHandle()
{
    return handle;
}

/*##########################################################################
#
#   Name       : TDiscServer::Add
#
#   Purpose....: Add disc req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDiscServer::Add(int id, TDiscReq *req)
{
    if (id > 0 && id <= MAX_DISC_REQ_COUNT)
        FReqArr[id - 1] = req;
}

/*##########################################################################
#
#   Name       : TDiscServer::Remove
#
#   Purpose....: Remove disc req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDiscServer::Remove(int id)
{
    if (id > 0 && id <= MAX_DISC_REQ_COUNT)
        FReqArr[id - 1] = 0;
}

/*##########################################################################
#
#   Name       : TDiscServer::IsActive
#
#   Purpose....: Check if active
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TDiscServer::IsActive()
{
    if (FActive)
        FActive = ServIsVfsActive(handle);

    return FActive;
}

/*##########################################################################
#
#   Name       : TDiscServer::GetPartSectors
#
#   Purpose....: Get partition sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TDiscServer::GetPartSectors()
{
    return ServGetVfsSectors(handle);
}

/*##########################################################################
#
#   Name       : TDiscServer::WaitForMsg
#
#   Purpose....: Wait for msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDiscServer::WaitForMsg(TFs *fs)
{
    Server = fs;
    return ::WaitForMsg(handle);
}
