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
# discint.cpp
# Disc interface class
#
########################################################################*/

#include <stdio.h>
#include <rdos.h>
#include <serv.h>
#include "discint.h"
#include "discpart.h"
#include "cmdfact.h"

static int handle = -1;
static TDisc *Disc = 0;
static TDiscServer *Server = 0;

extern "C" {

extern int WaitForMsg(int handle);
#pragma aux WaitForMsg parm routine [ebx] value [eax]

void RunCmd(int handle, char *cmd)
{
    Server->RunCmd(handle, cmd);
}

int ReadSector(long long sector, char *buf, int size)
{
    return Disc->ReadSector(sector, buf, size);
}

int WriteSector(long long sector, char *buf, int size)
{
    return Disc->WriteSector(sector, buf, size);
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
#   Name       : TDiscReqEntry::TDisReqEntry
#
#   Purpose....: Disc req entry contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscReqEntry::TDiscReqEntry(TDiscReq *Req, long long StartSector, int SectorCount, bool Zero)
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
#   Name       : TDiscReqEntry::Write
#
#   Purpose....: Write sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDiscReqEntry::Write()
{
    ServWriteVfsSectors(FReq->FServer->GetHandle(), FStartSector, FSectorCount);
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
void TDiscReq::WaitForever()
{
    while (!ServIsVfsReqDone(FReq))
        RdosWaitForever(FWaitHandle);
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
    int i;

    FActive = true;
    FReloadDisc = false;
    Server = this;
    OnInit = 0;

    if (handle == -1)
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
#   Name       : TDiscServer::GetDisc
#
#   Purpose....: Get disc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDisc *TDiscServer::GetDisc()
{
    return Disc;
}

/*##########################################################################
#
#   Name       : TDiscServer::GetDiscNr
#
#   Purpose....: Get disc #
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDiscServer::GetDiscNr()
{
    int h = handle;

    h = (h >> 8) & 0xFF;
    return h - 1;    
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
#   Name       : TDiscServer::IsBusy
#
#   Purpose....: Check if busy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TDiscServer::IsBusy()
{
    if (FActive)
        return ServIsVfsBusy(handle);
    else
        return false;
}

/*##########################################################################
#
#   Name       : TDiscServer::GetDiscSectors
#
#   Purpose....: Get partition sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TDiscServer::GetDiscSectors()
{
    return ServGetVfsSectors(handle);
}

/*##########################################################################
#
#   Name       : TDiscServer::GetBytesPerSector
#
#   Purpose....: Get bytes per sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDiscServer::GetBytesPerSector()
{
    return ServGetVfsBytesPerSector(handle);
}

/*##########################################################################
#
#   Name       : TDiscServer::InitDisc
#
#   Purpose....: Init disc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TDiscServer::InitDisc(const char *parttype)
{
    FReloadDisc = true;

    if (Disc)
    {
        Disc->Stop();
        delete Disc;
        Disc = 0;
    }

    if (OnInit)
        return (*OnInit)(this, parttype);    
    else
        return false;
}

/*##########################################################################
#
#   Name       : TDiscServer::AddPartition
#
#   Purpose....: Add partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TDiscServer::AddPartition(const char *FsName, long long Sectors)
{
    if (Disc)
        return Disc->AddPart(FsName, Sectors);
    else
        return false;
}

/*##########################################################################
#
#   Name       : TDiscServer::RunCmd
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDiscServer::RunCmd(int handle, char *msg)
{
    TCommandOutput out(handle);
    TCommandFactory::Run(&out, msg);
}

/*##########################################################################
#
#   Name       : TDiscServer::Run
#
#   Purpose....: Run message loop
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDiscServer::Run(TDisc *disc)
{
    Disc = disc;

    while (!FReloadDisc)
        if (!::WaitForMsg(handle))
            break;

    FReloadDisc = false;
}
