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
# partint.cpp
# Partition interface class
#
########################################################################*/

#include <stdio.h>
#include <rdos.h>
#include <serv.h>
#include "partint.h"
#include "fs.h"

static int handle = 0;
static TPartServer *Server = 0;
static TFs *Fs = 0;

extern "C" {

extern int WaitForMsg(int handle);
#pragma aux WaitForMsg parm routine [ebx] value [eax]

void Start()
{
    if (Server)
        Server->Start();
}

void Stop()
{
    if (Server)
        Server->Stop();
}

int Format()
{
    if (Server)
        return Server->Format();
    else
        return 0;
}

long long GetFreeSectors()
{
    if (Fs)
        return Fs->GetFreeSectors();
    else
        return 0;
}

struct TShareHeader *GetDir(int rel, char *path, int *count)
{
    if (Fs)
        return Fs->GetDir(rel, path, count);
    else
        return 0;
}

int GetDirHeaderSize()
{
    return sizeof(struct RdosDirEntry);
}

int GetDirEntryAttrib(int rel, char *path)
{
    if (Fs)
        return Fs->GetDirEntryAttrib(rel, path);
    else
        return -1;
}

int LockRelDir(int rel, char *path)
{
    if (Fs)
        return Fs->LockRelDir(rel, path);
    else
        return 0;
}

void CloneRelDir(int rel)
{
    if (Fs)
        Fs->CloneRelDir(rel);
}

void UnlockRelDir(int rel)
{
    if (Fs)
        Fs->UnlockRelDir(rel);
}

int GetRelDir(int rel, char *path)
{
    if (Fs)
        return Fs->GetRelDir(rel, path);
    else
        return 0;
}

void LockDirLink(void *d, int index)
{
    TDir *dir = (TDir *)d;

    if (Fs)
        Fs->LockDirLink(dir, index);
}

void UnlockDirLink(void *d, int index)
{
    TDir *dir = (TDir *)d;

    if (Fs)
        Fs->UnlockDirLink(dir, index);
}

int OpenFile(int rel, char *path)
{
    if (Fs)
        return Fs->OpenFile(rel, path);
    else
        return 0;
}

int CreateFile(int rel, char *path, int attrib)
{
    if (Fs)
        return Fs->CreateFile(rel, path, attrib);
    else
        return 0;
}

int GetFileAttrib(int handle)
{
    if (Fs)
        return Fs->GetFileAttrib(handle);
    else
        return -1;
}

int GetFileHandle(int handle)
{
    if (Fs)
        return Fs->GetFileHandle(handle);
    return 0;
}

void DerefFile(int handle)
{
    if (Fs)
        Fs->DerefFile(handle);
}

void CloseFile(int handle)
{
    if (Fs)
        Fs->CloseFile(handle);
}

int CreateDir(int rel, char *path)
{
    if (Fs)
        return Fs->CreateDir(rel, path);
    else
        return 0;
}

}

/*##########################################################################
#
#   Name       : TPartReqEntry::TDisReqEntry
#
#   Purpose....: Disc req entry contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartReqEntry::TPartReqEntry(TPartReq *Req, long long StartSector, int SectorCount)
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
#   Name       : TPartReqEntry::TDisReqEntry
#
#   Purpose....: Disc req entry contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartReqEntry::TPartReqEntry(TPartReq *Req, long long StartSector, int SectorCount, bool Zero)
{
    FStartSector = StartSector;
    FSectorCount = SectorCount;
    FData = 0;

    FReq = Req;

    if (Zero)
        FId = ServZeroVfsSectors(Req->FReq, StartSector, SectorCount);
    else
        FId = ServLockVfsSectors(Req->FReq, StartSector, SectorCount);

    Req->Add(this);
}

/*##########################################################################
#
#   Name       : TPartReqEntry::~TPartReqEntry
#
#   Purpose....: Disc req entry destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartReqEntry::~TPartReqEntry()
{
    FReq->Remove(this);

    if (FData)
        ServUnmapVfsReq(FReq->FReq, FId);

    ServRemoveVfsSectors(FReq->FReq, FId);
}

/*##########################################################################
#
#   Name       : TPartReqEntry::GetId
#
#   Purpose....: Get ID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPartReqEntry::GetId()
{
    return FId;
}

/*##########################################################################
#
#   Name       : TPartReqEntry::GetStartSector
#
#   Purpose....: Get start sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TPartReqEntry::GetStartSector()
{
    return FStartSector;
}

/*##########################################################################
#
#   Name       : TPartReqEntry::GetSectorCount
#
#   Purpose....: Get sector count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPartReqEntry::GetSectorCount()
{
    return FSectorCount;
}

/*##########################################################################
#
#   Name       : TPartReqEntry::GetData
#
#   Purpose....: Get data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TPartReqEntry::GetData()
{
    return FData;
}

/*##########################################################################
#
#   Name       : TPartReqEntry::Map
#
#   Purpose....: Map sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TPartReqEntry::Map()
{
    FData = ServMapVfsReq(FReq->FReq, FId);
    return FData;
}

/*##########################################################################
#
#   Name       : TPartReqEntry::Unmap
#
#   Purpose....: Unmap sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartReqEntry::Unmap()
{
    ServUnmapVfsReq(FReq->FReq, FId);
    FData = 0;
}

/*##########################################################################
#
#   Name       : TPartReqEntry::Write
#
#   Purpose....: Write sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartReqEntry::Write()
{
    ServWriteVfsSectors(FReq->FServer->GetHandle(), FStartSector, FSectorCount);
}

/*##########################################################################
#
#   Name       : TPartReq::TDisReq
#
#   Purpose....: Disc req contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartReq::TPartReq(TPartServer *server)
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
#   Name       : TPartReq::~TPartReq
#
#   Purpose....: Disc req destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartReq::~TPartReq()
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
#   Name       : TPartReq::WaitForever
#
#   Purpose....: Wait forever
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartReq::WaitForever()
{
    while (!ServIsVfsReqDone(FReq))
        RdosWaitForever(FWaitHandle);
}

/*##########################################################################
#
#   Name       : TPartReq::WaitTimeout
#
#   Purpose....: Wait timeout
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPartReq::WaitTimeout(int MilliSec)
{
    return RdosWaitTimeout(FWaitHandle, MilliSec);
}

/*##########################################################################
#
#   Name       : TPartReq::WaitUntil
#
#   Purpose....: Wait until
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPartReq::WaitUntil(TDateTime &time)
{
    return RdosWaitUntilTimeout(FWaitHandle, time.GetMsb(), time.GetLsb());
}

/*##########################################################################
#
#   Name       : TPartReq::IsDone
#
#   Purpose....: Check if done
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPartReq::IsDone()
{
    return ServIsVfsReqDone(FReq);
}

/*##########################################################################
#
#   Name       : TPartReq::Add
#
#   Purpose....: Add request
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartReq::Add(TPartReqEntry *entry)
{
    int id = entry->GetId();

    if (id > 0 && id <= MAX_DISC_REQ_ENTRIES)
        FEntryArr[id - 1] = entry;
}

/*##########################################################################
#
#   Name       : TPartReq::Remove
#
#   Purpose....: Remove request
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartReq::Remove(TPartReqEntry *entry)
{
    int id = entry->GetId();

    if (id > 0 && id <= MAX_DISC_REQ_ENTRIES)
        FEntryArr[id - 1] = 0;
}

/*##########################################################################
#
#   Name       : TPartReq::Add
#
#   Purpose....: Add request
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPartReq::Add(long long StartSector, int SectorCount)
{
    TPartReqEntry *entry = new TPartReqEntry(this, StartSector, SectorCount);
    return entry->GetId();
}

/*##########################################################################
#
#   Name       : TPartReq::Start
#
#   Purpose....: Start request
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartReq::Start()
{
    ServStartVfsReq(FReq);
}

/*##########################################################################
#
#   Name       : TPartServer::TPartServer
#
#   Purpose....: Disc server contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartServer::TPartServer()
{
    int i;

    Server = this;

    FActive = true;

    OnStart = 0;
    OnFormat = 0;

    if (!handle)
        handle = ServGetVfsHandle();

    for (i = 0; i < MAX_DISC_REQ_COUNT; i++)
        FReqArr[i] = 0;
}

/*##########################################################################
#
#   Name       : TPartServer::~TPartServer
#
#   Purpose....: Disc server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartServer::~TPartServer()
{
    RdosWaitMilli(25);
    ServCloseVfsPartition(handle);
}

/*##########################################################################
#
#   Name       : TPartServer::GetHandle
#
#   Purpose....: Get VFS handle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPartServer::GetHandle()
{
    return handle;
}

/*##########################################################################
#
#   Name       : TPartServer::Start
#
#   Purpose....: Start filesystem
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartServer::Start()
{
    (*OnStart)(this);
}

/*##########################################################################
#
#   Name       : TPartServer::Stop
#
#   Purpose....: Stop filesystem
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartServer::Stop()
{
    if (Fs)
        Fs->Stop();
}

/*##########################################################################
#
#   Name       : TPartServer::Format
#
#   Purpose....: Format filesystem
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPartServer::Format()
{
    int Type = GetPartType();
    long long Size = GetPartSectors();

    if (Size > 0 && Type)
    {
        if ((*OnFormat)(this))
        {
            Size = GetPartSectors();
            if (Size > 0)
                return handle;
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TPartServer::Disable
#
#   Purpose....: Disable filesystem
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartServer::Disable()
{
    ServDisableVfsPartition(handle);
}

/*##########################################################################
#
#   Name       : TPartServer::Add
#
#   Purpose....: Add disc req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartServer::Add(int id, TPartReq *req)
{
    if (id > 0 && id <= MAX_DISC_REQ_COUNT)
        FReqArr[id - 1] = req;
}

/*##########################################################################
#
#   Name       : TPartServer::Remove
#
#   Purpose....: Remove disc req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartServer::Remove(int id)
{
    if (id > 0 && id <= MAX_DISC_REQ_COUNT)
        FReqArr[id - 1] = 0;
}

/*##########################################################################
#
#   Name       : TPartServer::IsActive
#
#   Purpose....: Check if active
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPartServer::IsActive()
{
    if (FActive)
        FActive = ServIsVfsActive(handle);

    return FActive;
}

/*##########################################################################
#
#   Name       : TPartServer::GetPartStartSector
#
#   Purpose....: Get partition start sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TPartServer::GetPartStartSector()
{
    return ServGetVfsStartSector(handle);
}

/*##########################################################################
#
#   Name       : TPartServer::GetPartSectors
#
#   Purpose....: Get partition sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TPartServer::GetPartSectors()
{
    return ServGetVfsSectors(handle);
}

/*##########################################################################
#
#   Name       : TPartServer::GetBytesPerSector
#
#   Purpose....: Get bytes per sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPartServer::GetBytesPerSector()
{
    return ServGetVfsBytesPerSector(handle);
}

/*##########################################################################
#
#   Name       : TPartServer::GetPartType
#
#   Purpose....: Get partition type
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPartServer::GetPartType()
{
    return ServGetVfsPartType(handle);
}

/*##########################################################################
#
#   Name       : TPartServer::MovePartUp
#
#   Purpose....: Move start porition of partition up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPartServer::MovePartUp(long long diff)
{
    long long Start = GetPartStartSector();
    long long Size = GetPartSectors();

    if (diff == 0)
        return true;

    if (diff > 0 && diff < Size)
    {
        Start += diff;
        Size -= diff;

        ServSetVfsStartSector(handle, Start);
        ServSetVfsSectors(handle, Size);
        return true;
    }

    ServSetVfsSectors(handle, 0);
    return false;
}

/*##########################################################################
#
#   Name       : TPartServer::ShrinkPart
#
#   Purpose....: Shrink partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPartServer::ShrinkPart(long long diff)
{
    long long Size = GetPartSectors();

    if (diff == 0)
        return true;

    if (diff > 0 && diff < Size)
    {
        Size -= diff;
        ServSetVfsSectors(handle, Size);
        return true;
    }

    ServSetVfsSectors(handle, 0);
    return false;
}

/*##########################################################################
#
#   Name       : TPartServer::WaitForMsg
#
#   Purpose....: Wait for msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPartServer::WaitForMsg()
{
    return ::WaitForMsg(handle);
}

/*##########################################################################
#
#   Name       : TPartServer::WaitForMsg
#
#   Purpose....: Wait for msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPartServer::WaitForMsg(TFs *fs)
{
    Fs = fs;
    return ::WaitForMsg(handle);
}
