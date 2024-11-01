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
# file.cpp
# File class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <rdos.h>
#include <serv.h>
#include "file.h"
#include "serv.h"
#include "fs.h"
#include "datetime.h"

#define DEBUG   1

static int FileHandle = 0;

/*##########################################################################
#
#   Name       : TFileReq::TFileReq
#
#   Purpose....: File req contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileReq::TFileReq(int handle, int index, int req)
{
    MaxSectors = 0;
    SectorCount = 0;
    SectorArr = 0;

    File = handle;
    Index = index;
    Req = req;

    BytePos = 0;
    SectPos = 0;

    Enabled = true;

    Link = 0;
}

/*##########################################################################
#
#   Name       : TFileReq::~TFileReq
#
#   Purpose....: File req destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileReq::~TFileReq()
{
    if (SectorArr)
        delete SectorArr;
}

/*##########################################################################
#
#   Name       : TFileReq::InitArray
#
#   Purpose....: Init array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileReq::InitArray(int sectors)
{
    if (SectorArr)
        delete SectorArr;

    MaxSectors = sectors;
    SectorCount = 0;
    SectorArr = new long long[sectors];
}

/*##########################################################################
#
#   Name       : TFileReq::FreeArray
#
#   Purpose....: Free array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileReq::FreeArray()
{
    if (SectorArr)
        delete SectorArr;

    SectorArr = 0;
}

/*##########################################################################
#
#   Name       : TFileReq::AddSector
#
#   Purpose....: Add sector to buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileReq::AddSector(long long sector)
{
    if (SectorCount < MaxSectors)
    {
        SectorArr[SectorCount] = sector;
        SectorCount++;
    }
}

/*##########################################################################
#
#   Name       : TFileReq::SetPos
#
#   Purpose....: Set pos
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileReq::SetPos(int BytesPerSector, long long spos)
{
    BytePos = spos * BytesPerSector;
    SectPos = spos;
}

/*##########################################################################
#
#   Name       : TFileReq::Disable
#
#   Purpose....: Disable request
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileReq::Disable()
{
    if (Enabled)
    {
        ServDisableVfsFileReq(File, Req + 1);
        Enabled = false;
        FreeArray();
    }
}

/*##########################################################################
#
#   Name       : TFileReq::IsEnabled
#
#   Purpose....: Is request enabled?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFileReq::IsEnabled()
{
    return Enabled;
}

/*##########################################################################
#
#   Name       : TFileReq::StartRead
#
#   Purpose....: Start read
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileReq::StartRead()
{
    char str[80];
    int ReqCount = SectorCount;

    if (Enabled)
    {
        SectorCount = ServVfsFileReadReq(File, Req + 1, BytePos, SectorArr, SectorCount);

        if (ReqCount == SectorCount)
            sprintf(str, "Read %d.%d start %lld size %d\r\n", Index, Req, SectPos, SectorCount);
        else
            sprintf(str, "Read %d.%d start %lld size %d (%d)\r\n", Index, Req, SectPos, SectorCount, ReqCount);

        RdosWriteFile(FileHandle, str, strlen(str));
        printf(str);

        FreeArray();
    }
}

/*##########################################################################
#
#   Name       : TFileReq::StartWrite
#
#   Purpose....: Start write
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileReq::StartWrite()
{
    char str[80];
    int ReqCount = SectorCount;

    if (Enabled)
    {
        SectorCount = ServVfsFileWriteReq(File, Req + 1, BytePos, SectorArr, SectorCount);

        if (ReqCount == SectorCount)
            sprintf(str, "Write %d.%d start %lld size %d\r\n", Index, Req, SectPos, SectorCount);
        else
            sprintf(str, "Write %d.%d start %lld size %d (%d)\r\n", Index, Req, SectPos, SectorCount, ReqCount);

        RdosWriteFile(FileHandle, str, strlen(str));
        printf(str);

        FreeArray();
    }
}

/*##########################################################################
#
#   Name       : TFile::TFile
#
#   Purpose....: File constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::TFile(TDir *pd, int pi, int bps, int os)
  : FSection("file")
{
    int i;
    struct RdosDirEntry *entry;

#ifdef DEBUG
    if (!FileHandle)
        FileHandle = RdosCreateFile("z:/log.txt", 0);
#endif

    FClosing = false;

    FBytesPerSector = bps;
    FSectorsPerPage = 0x1000 / bps;
    FOffsetSector = os;

    FParent = pd;
    FParentIndex = pi;

    entry = FParent->LockEntry(FParentIndex);
    Info = (struct RdosFileInfo *)RdosAllocateMem(0x1000);

    if (entry->Size)
        Info->SectorCount = (entry->Size - 1) / FBytesPerSector + 1;
    else
        Info->SectorCount = 0;

    Info->BytesPerSector = FBytesPerSector;
    Info->DiscSize = Info->SectorCount * FBytesPerSector;
    Info->CurrSize = entry->Size;
    Info->CreateTime = entry->CreateTime;
    Info->AccessTime = entry->AccessTime;
    Info->ModifyTime = entry->ModifyTime;
    Info->Attrib = entry->Attrib;
    Info->Flags = entry->Flags;
    Info->Uid = entry->Uid;
    Info->Gid = entry->Gid;
    Info->ServHandle = 0;
    strcpy(Info->Name, entry->PathName);

    Handle = 0;
    Index = -1;

    FCurrAllocatedCount = 0;
    FMaxAllocatedCount = 4;
    FAllocatedArr = new TFileReq*[FMaxAllocatedCount];

    for (i = 0; i < FMaxAllocatedCount; i++)
        FAllocatedArr[i] = 0;

    FCurrActiveCount = 0;
    FMaxActiveCount = 4;
    FActiveArr = new TFileReq*[FMaxActiveCount];

    for (i = 0; i < FMaxActiveCount; i++)
        FActiveArr[i] = 0;

    FFreeList = 0;

    FParent->UnlockEntry(entry);

    SetAccessTime(RdosGetLongTime());
}

/*##########################################################################
#
#   Name       : TFile::~TFile
#
#   Purpose....: File destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::~TFile()
{
    int i;

    for (i = 0; i < FCurrAllocatedCount; i++)
        delete FAllocatedArr[i];

    delete FActiveArr;
    delete FAllocatedArr;

    if (Handle)
        ServCloseVfsFile(Handle);

    RdosFreeMem(Info);

    if (FParent)
        FParent->ClearFileLink(FParentIndex);
}

/*##########################################################################
#
#   Name       : TFile::GrowAllocated
#
#   Purpose....: Grow allocated array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::GrowAllocated()
{
    int i;
    int Size = 2 * FMaxAllocatedCount;
    TFileReq **NewArr;

    NewArr = new TFileReq*[Size];

    for (i = 0; i < FMaxAllocatedCount; i++)
        NewArr[i] = FAllocatedArr[i];

    for (i = FMaxAllocatedCount; i < Size; i++)
        NewArr[i] = 0;

    delete FAllocatedArr;
    FAllocatedArr = NewArr;
    FMaxAllocatedCount = Size;
}

/*##########################################################################
#
#   Name       : TFile::GrowActive
#
#   Purpose....: Grow active array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::GrowActive()
{
    int i;
    int Size = 2 * FMaxActiveCount;
    TFileReq **NewArr;

    NewArr = new TFileReq*[Size];

    for (i = 0; i < FMaxActiveCount; i++)
        NewArr[i] = FActiveArr[i];

    for (i = FMaxActiveCount; i < Size; i++)
        NewArr[i] = 0;

    delete FActiveArr;
    FActiveArr = NewArr;
    FMaxActiveCount = Size;
}

/*##########################################################################
#
#   Name       : TFile::Setup
#
#   Purpose....: Setup handles
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFile::Setup(int VfsHandle)
{
    Handle = ServOpenVfsFile(VfsHandle, Info);
    Index = Handle & 0xFFFF;
    if (Index > 0)
        Index--;
    else
    {
        Handle = 0;
        Index = -1;
    }

    Info->ServHandle = Handle;
    return Handle;
}

/*##########################################################################
#
#   Name       : TFile::Deref
#
#   Purpose....: Req to derefence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::Deref()
{
    if (FParent)
        FParent->UnlockDirLink(FParentIndex);
}

/*##########################################################################
#
#   Name       : TFile::Close
#
#   Purpose....: Req to close
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::Close()
{
    FClosing = true;
    FCloseSignal.Signal();
}

/*##########################################################################
#
#   Name       : TFile::WaitForClosing
#
#   Purpose....: Check if ready to close
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::WaitForClosing()
{
    while (!FClosing)
        FCloseSignal.WaitForever();
}

/*##########################################################################
#
#   Name       : TFile::LockFile
#
#   Purpose....: Lock
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::LockFile()
{
}

/*##########################################################################
#
#   Name       : TFile::UnlockFile
#
#   Purpose....: Unlock file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::UnlockFile()
{
}

/*##########################################################################
#
#   Name       : TFile::GetAttrib
#
#   Purpose....: Get attrib
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFile::GetAttrib()
{
    return Info->Attrib;
}

/*##########################################################################
#
#   Name       : TFile::GetDiscSize
#
#   Purpose....: Get size on disc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TFile::GetDiscSize()
{
    return Info->DiscSize;
}

/*##########################################################################
#
#   Name       : TFile::AllocateReq
#
#   Purpose....: Allocate new req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileReq *TFile::AllocateReq()
{
    TFileReq *req = 0;

    if (FFreeList)
    {
        req = FFreeList;
        FFreeList = req->Link;
    }
    else
    {
        if (FCurrAllocatedCount < 256)
        {
            if (FCurrAllocatedCount == FMaxAllocatedCount)
                GrowAllocated();

            req = new TFileReq(Handle, Index, FCurrAllocatedCount);
            FAllocatedArr[FCurrAllocatedCount] = req;
            FCurrAllocatedCount++;
        }
    }
    return req;
}

/*##########################################################################
#
#   Name       : TFile::FreeReq
#
#   Purpose....: Free req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::FreeReq(TFileReq *req)
{
    req->Link = FFreeList;
    FFreeList = req;

    if (req->IsEnabled() && req->BytePos >= Info->CurrSize)
        SetSize(Info->CurrSize);
}

/*##########################################################################
#
#   Name       : TFile::AddActive
#
#   Purpose....: Add request as active
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::AddActive(TFileReq *req)
{
    int i;
    int j;
    TFileReq *temp;
    TFileReq *curr = req;

    if (FCurrActiveCount == FMaxActiveCount)
        GrowActive();

    for (i = 0; i < FCurrActiveCount; i++)
    {
        if (FActiveArr[i]->SectPos > req->SectPos)
        {
            curr = req;

            for (j = i; j < FCurrActiveCount; j++)
            {
                temp = FActiveArr[j];
                FActiveArr[j] = curr;
                curr = temp;
            }
            break;
        }
    }

    FActiveArr[FCurrActiveCount] = curr;
    FCurrActiveCount++;
}

/*##########################################################################
#
#   Name       : TFile::FindReq
#
#   Purpose....: Find active req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileReq *TFile::FindReq(long long start)
{
    int i;

    for (i = 0; i < FCurrActiveCount; i++)
        if (FActiveArr[i]->SectPos <= start)
            if (FActiveArr[i]->SectPos + FActiveArr[i]->SectorCount > start)
                return FActiveArr[i];

    return 0;
}

/*##########################################################################
#
#   Name       : TFile::GetSector
#
#   Purpose....: Default get sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TFile::GetSector(long long pos)
{
    return 0;
}

/*##########################################################################
#
#   Name       : TFile::SetRead
#
#   Purpose....: Set read params
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::SetRead(long long StartSector, int Sectors)
{
    long long count;
    long long start;
    long long end;
    long long temp;
    long long sect;
    long long exp;
    int i;
    TFileReq *FileReq;

    if (StartSector < 0)
        StartSector = 0;

    if (StartSector >= Info->SectorCount)
        StartSector = Info->SectorCount - 1;

    if (Sectors < FSectorsPerPage)
        Sectors = FSectorsPerPage;

    start = StartSector;

    sect = FOffsetSector + GetSector(start);
    exp = sect - 1;
    while (sect % FSectorsPerPage)
    {
        if (start)
        {
            sect = FOffsetSector + GetSector(start - 1);

            if (sect == exp)
            {
                exp = sect - 1;
                start--;
                Sectors++;
            }
            else
                break;
        }
        else
            break;
    }

    end = StartSector + Sectors - 1;

    if (end < start)
        end = start;

    if (end > Info->SectorCount)
        end = Info->SectorCount - 1;

    sect = FOffsetSector + GetSector(end + 1);
    exp = sect + 1;
    while (sect % FSectorsPerPage)
    {
        if (end < Info->SectorCount - 1)
        {
            sect = FOffsetSector + GetSector(end + 2);

            if (sect == exp)
            {
                exp = sect + 1;
                end++;
            }
            else
                break;
        }
        else
            break;
    }

    count = end - start + 1;

    for (i = 0; i < FCurrActiveCount && count > 0; i++)
    {
        FileReq = FActiveArr[i];

        if (FileReq->IsEnabled())
        {
            temp = FileReq->SectPos - start;
            if (temp > 0)
            {
                if (temp < count)
                    count = (int)temp;
                break;
            }
            else
            {
                temp = FileReq->SectPos + FileReq->SectorCount;
                if (temp > start)
                {
                    count = (int)(start + count - temp);
                    start = temp;
                }
            }
        }
    }

    if (count < 0)
        count = 0;

    FCurrStart = start;
    FCurrSectors = (int)count;
}

/*##########################################################################
#
#   Name       : TFile::SetWrite
#
#   Purpose....: Set write params
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::SetWrite(long long StartSector, int Sectors)
{
    long long count;
    long long start;
    long long end;
    long long temp;
    int i;
    TFileReq *FileReq;

    if (StartSector < 0)
        StartSector = 0;

    if (StartSector >= Info->SectorCount)
        StartSector = Info->SectorCount - 1;

    start = StartSector;
    end = StartSector + Sectors - 1;

    if (end < start)
        end = start;

    count = end - start + 1;

    for (i = 0; i < FCurrActiveCount && count > 0; i++)
    {
        FileReq = FActiveArr[i];

        if (FileReq->IsEnabled())
        {
            temp = FileReq->SectPos - start;
            if (temp > 0)
            {
                if (temp < count)
                    count = (int)temp;
                break;
            }
            else
            {
                temp = FileReq->SectPos + FileReq->SectorCount;
                if (temp > start)
                {
                    count = (int)(start + count - temp);
                    start = temp;
                }
            }
        }
    }

    if (count < 0)
        count = 0;

    FCurrStart = start;
    FCurrSectors = (int)count;
}

/*##########################################################################
#
#   Name       : TFile::HandleRead
#
#   Purpose....: Handle read file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileReq *TFile::HandleRead(long long pos, int size)
{
    int sector;
    long long prev;
    long long curr;
    int offset;
    bool HasPos = false;
    TFileReq *FileReq = 0;
    char str[80];

    if (!FParent)
        return 0;

    FCurrPos = pos / FBytesPerSector;

    SetRead(FCurrPos, size / FBytesPerSector);

    if (FCurrSectors > 0)
        FileReq = AllocateReq();
    else
        FileReq = 0;

    if (FileReq)
    {
        sprintf(str, "Read allocated %d.%d pos %lld size %d \r\n", Index, FileReq->Req, pos, size);
        RdosWriteFile(FileHandle, str, strlen(str));
        printf(str);

        FileReq->InitArray(FCurrSectors);

        for (sector = 0; sector < FCurrSectors; sector++)
        {
            if (FCurrStart + sector == FCurrPos)
                HasPos = true;

            curr = GetSector(FCurrStart + sector);

            if (sector)
            {
                prev++;
                offset = (int)((curr + FOffsetSector) % FSectorsPerPage);

                if (offset)
                {
                    if (prev != curr)
                    {
                        if (HasPos)
                            break;
                        else
                        {
                            FCurrStart += sector;
                            FCurrSectors -= sector;
                            sector = 0;
                            FileReq->SectorCount = 0;
                        }
                    }
                }
            }
            prev = curr;
            FileReq->AddSector(curr);
        }

        FCurrSectors = FileReq->SectorCount;

        if (FileReq->SectorCount)
            FileReq->SetPos(FBytesPerSector, FCurrStart);
        else
        {
            sprintf(str, "Read %d No size, pos %lld size %d\r\n", Index, pos, size);
            RdosWriteFile(FileHandle, str, strlen(str));
            printf(str);
            ServNotifyVfsFileReq(Handle, pos, size);
        }
    }
    else
    {
        sprintf(str,"Read %d No req available, pos %lld size %d\r\n", Index, pos, size);
        RdosWriteFile(FileHandle, str, strlen(str));
        printf(str);
        ServNotifyVfsFileReq(Handle, pos, size);
    }

    if (FileReq)
    {
        if (FileReq->SectorCount)
            AddActive(FileReq);
        else
        {
            FreeReq(FileReq);
            FileReq = 0;
        }
    }

    return FileReq;
}

/*##########################################################################
#
#   Name       : TFile::HandleUpdateReq
#
#   Purpose....: Handle update
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::HandleUpdateReq(long long pos, int size)
{
    char str[80];
    TFileReq *FileReq;
    long long start;
    long long end;
    int count;
    int offset;
    int curr;
    bool update = false;

    if (!FParent)
        return;

    if (pos + size > Info->CurrSize)
        size = (int)(Info->CurrSize - pos);

    if (size > 0)
    {
        start = pos / FBytesPerSector;
        end = (pos + size - 1) / FBytesPerSector;
        count = (int)(end - start + 1);

        while (count)
        {
            FileReq = FindReq(start);
            if (FileReq && FileReq->IsEnabled())
            {
                offset = (int)(FileReq->SectPos - start);

                if (FileReq->SectorCount >= count)
                    curr = count;
                else
                    curr = FileReq->SectorCount;

                if (offset || count != FileReq->SectorCount)
                    sprintf(str, "Update %d.%d offset %ld size %d \r\n", Index, FileReq->Req, offset, curr);
                else
                    sprintf(str, "Update %d.%d\r\n", Index, FileReq->Req);

                RdosWriteFile(FileHandle, str, strlen(str));
                printf(str);

                ServUpdateVfsFileReq(Handle, FileReq->Req + 1, offset, curr);

                update = true;

                start += curr;
                count -= curr;
            }
            else
            {
                sprintf(str, "Update with no req %d pos %lld\r\n", Index, pos);
                RdosWriteFile(FileHandle, str, strlen(str));
                printf(str);
                break;
            }
        }
    }
    else
    {
        sprintf(str, "Update with no size %d pos %lld\r\n", Index, pos);
        RdosWriteFile(FileHandle, str, strlen(str));
        printf(str);
    }

    if (update)
        SetModifyTime(RdosGetLongTime());
}

/*##########################################################################
#
#   Name       : TFile::HandleFreeReq
#
#   Purpose....: Handle free req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::HandleFreeReq(int req)
{
    int i;
    int j;
    bool found = false;
    TFileReq *FileReq;
    char str[40];

    for (i = 0; i < FCurrActiveCount; i++)
    {
        FileReq = FActiveArr[i];
        if (FileReq && FileReq->Req == req)
        {
            found = true;

            FActiveArr[i] = 0;
            FCurrActiveCount--;

            for (j = i; j < FCurrActiveCount; j++)
                FActiveArr[j] = FActiveArr[j+1];

            FActiveArr[FCurrActiveCount] = 0;

            FreeReq(FileReq);

            sprintf(str, "Free %d.%d\r\n", Index, req);
            RdosWriteFile(FileHandle, str, strlen(str));
            printf(str);

            ServFreeVfsFileReq(Handle, req + 1);
            break;
        }
    }

    if (!found)
        printf("Cannot free %d.%d\r\n", Index, req);
}

/*##########################################################################
#
#   Name       : TFile::HandleCompletedReq
#
#   Purpose....: Handle completed req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::HandleCompletedReq(int req)
{
    int i;
    char str[80];

    sprintf(str, "Completed %d.%d\r\n", Index, req);
    RdosWriteFile(FileHandle, str, strlen(str));
    printf(str);
}

/*##########################################################################
#
#   Name       : TFile::HandleMapReq
#
#   Purpose....: Handle map req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::HandleMapReq(int req)
{
    char str[80];

    sprintf(str, "Map %d.%d\r\n", Index, req);
    RdosWriteFile(FileHandle, str, strlen(str));
    printf(str);
}

/*##########################################################################
#
#   Name       : TFile::HandleGrowReq
#
#   Purpose....: Handle grow req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileReq *TFile::HandleGrowReq(long long req)
{
    int sector;
    long long prev;
    long long curr;
    int offset;
    bool HasPos = false;
    TFileReq *FileReq = 0;
    char str[80];
    long long pos;
    int size;
    long long pages;

    if (!FParent)
        return 0;

    pos = Info->DiscSize;

    pages = req >> 12;

    if (req & 0xFFF)
        pages++;

    req = pages << 12;

    sprintf(str, "Grow %d.%lld\r\n", Index, req);
    RdosWriteFile(FileHandle, str, strlen(str));
    printf(str);

    GrowDisc(req);

    size = (int)(Info->DiscSize - pos);

    FCurrPos = pos / FBytesPerSector;

    SetWrite(FCurrPos, size / FBytesPerSector);

    if (FCurrSectors > 0)
        FileReq = AllocateReq();
    else
        FileReq = 0;

    if (FileReq)
    {
        sprintf(str, "Grow %d.%d pos %lld size %d \r\n", Index, FileReq->Req, pos, size);
        RdosWriteFile(FileHandle, str, strlen(str));
        printf(str);

        FileReq->InitArray(FCurrSectors);

        for (sector = 0; sector < FCurrSectors; sector++)
        {
            if (FCurrStart + sector == FCurrPos)
                HasPos = true;

            curr = GetSector(FCurrStart + sector);

            if (sector)
            {
                prev++;
                offset = (int)((curr + FOffsetSector) % FSectorsPerPage);

                if (offset)
                {
                    if (prev != curr)
                    {
                        if (HasPos)
                            break;
                        else
                        {
                            FCurrStart += sector;
                            FCurrSectors -= sector;
                            sector = 0;
                            FileReq->SectorCount = 0;
                        }
                    }
                }
            }
            prev = curr;
            FileReq->AddSector(curr);
        }

        FCurrSectors = FileReq->SectorCount;

        if (FileReq->SectorCount)
            FileReq->SetPos(FBytesPerSector, FCurrStart);
        else
        {
            sprintf(str, "Grow %d No size, pos %lld size %d\r\n", Index, pos, size);
            RdosWriteFile(FileHandle, str, strlen(str));
            printf(str);
            ServNotifyVfsFileReq(Handle, pos, size);
        }
    }
    else
    {
        sprintf(str,"Grow %d No req available, pos %lld size %d\r\n", Index, pos, size);
        RdosWriteFile(FileHandle, str, strlen(str));
        printf(str);
        ServNotifyVfsFileReq(Handle, pos, size);
    }

    if (FileReq)
    {
        if (FileReq->SectorCount)
            AddActive(FileReq);
        else
        {
            FreeReq(FileReq);
            FileReq = 0;
        }
    }

    return FileReq;
}

/*##########################################################################
#
#   Name       : TFile::HandleSizeReq
#
#   Purpose....: Handle size req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::HandleSizeReq(long long size)
{
    char str[80];

    sprintf(str, "Size %d.%lld\r\n", Index, size);
    RdosWriteFile(FileHandle, str, strlen(str));
    printf(str);

    SetSize(size);
}

/*##########################################################################
#
#   Name       : TFile::HandleDeleteReq
#
#   Purpose....: Handle delete req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::HandleDeleteReq()
{
    char str[80];

    sprintf(str, "Delete %d\r\n", Index);
    RdosWriteFile(FileHandle, str, strlen(str));
    printf(str);

    SetSize(0);
    DeleteDirEntry();
}

/*##########################################################################
#
#   Name       : TFile::SetSize
#
#   Purpose....: Set file size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFile::SetSize(long long size)
{
    bool ok;
    bool update = false;
    int i;
    TFileReq *FileReq;
    long long pos;

    if (!FParent)
        return false;

    pos = Info->DiscSize;

    ok = SetDiscSize(size);

    if (ok)
    {
        Info->CurrSize = size;

        if (Info->DiscSize < pos)
        {
            for (i = 0; i < FCurrActiveCount; i++)
            {
                FileReq = FActiveArr[i];
                pos = (FileReq->SectPos + FileReq->SectorCount) * FBytesPerSector;
                if (pos > Info->DiscSize)
                {
                    FileReq->Disable();
                    update = true;
                }
            }
        }

        if (update)
            ServUpdateVfsFile(Handle);

        SyncDirEntry();
    }

    return ok;
}

/*##########################################################################
#
#   Name       : TFile::SyncDirEntry
#
#   Purpose....: Sync dir entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::SyncDirEntry()
{
    struct RdosDirEntry *entry;

    if (FParent)
    {
        entry = FParent->LockEntry(FParentIndex);
        if (entry)
        {
            FParent->UpdateEntry(entry, Info);
            FParent->UnlockEntry(entry);
        }
    }
}

/*##########################################################################
#
#   Name       : TFile::IsDirEntryUnlinked
#
#   Purpose....: Check if dir entry is unlinked
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFile::IsDirEntryUnlinked()
{
    if (FParent)
        return false;
    else
        return true;
}

/*##########################################################################
#
#   Name       : TFile::UnlinkDirEntry
#
#   Purpose....: Unlink dir entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::UnlinkDirEntry()
{
    FParent = 0;
    FParentIndex = -1;
}

/*##########################################################################
#
#   Name       : TFile::DeleteDirEntry
#
#   Purpose....: Delete dir entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFile::DeleteDirEntry()
{
    bool ok;

    if (FParent)
    {
        FParent->ClearFileLink(FParentIndex);
        ok = FParent->DeleteEntry(FParentIndex);
        UnlinkDirEntry();
    }
    else
        ok = false;

    return ok;
}

/*##########################################################################
#
#   Name       : TFile::SetAccessTime
#
#   Purpose....: Set access time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::SetAccessTime(long long time)
{
    Info->AccessTime = time;
    SyncDirEntry();
}

/*##########################################################################
#
#   Name       : TFile::SetModifyTime
#
#   Purpose....: Set modify time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::SetModifyTime(long long time)
{
    Info->ModifyTime = time;
    SyncDirEntry();
}
