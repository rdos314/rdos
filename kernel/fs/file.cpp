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
TFileReq::TFileReq(int sectors)
{
    MaxSectors = sectors;
    SectorCount = 0;
    SectorArr = new long long[sectors];
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
    delete SectorArr;
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
#   Name       : TFileReq::Start
#
#   Purpose....: Start
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileReq::Start(int file, int req)
{
    File = file;
    Req = req;

    if (ServAddVfsFileReq(File, Req + 1, SectorArr, SectorCount))
        printf(" done\r\n");
    else
        printf(" pending\r\n");
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
    struct RdosDirEntry *entry;

    FBytesPerSector = bps;
    FSectorsPerPage = 0x1000 / bps;
    FOffsetSector = os;

    FParent = pd;
    FParentIndex = pi;

    entry = FParent->LockEntry(FParentIndex);
    Info = (struct RdosFileInfo *)RdosAllocateMem(0x1000);

    Info->DiscSize = entry->Size;
    Info->CurrSize = entry->Size;
    Info->AccessTime = entry->AccessTime;
    Info->ModifyTime = entry->ModifyTime;
    Info->Attrib = entry->Attrib;
    Info->Flags = entry->Flags;
    Info->Uid = entry->Uid;
    Info->Gid = entry->Gid;
    Info->ServHandle = 0;
    strcpy(Info->Name, entry->PathName);

    Buf = 0;

    Handle = 0;
    Index = -1;

    FParent->UnlockEntry(entry);
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
    printf("Close %d\r\n", Index);

    ServCloseVfsFile(Handle);

    RdosFreeMem(Info);
    if (Buf)
        RdosFreeMem(Buf);

    FParent->ClearFileLink(FParentIndex);
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
    int i;

    Buf = (struct TFileBuf *)RdosAllocateMem(0x1000);

    Buf->Count = 0;
    Buf->LastActive = 0;

    for (i = 0; i < 240; i++)
    {
        Buf->BufArr[i].Pos = 0;
        Buf->BufArr[i].Size = 0;
        Buf->BufArr[i].Handle = 0;
    }

    for (i = 0; i < 241; i++)
        Buf->SortedArr[i] = 0xFF;

    Handle = ServOpenVfsFile(VfsHandle, Info, Buf);
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
#   Name       : TFile::AllocateEntry
#
#   Purpose....: Allocate new entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFile::AllocateReq()
{
    int i;

    for (i = 0; i < 240; i++)
        if (Buf->BufArr[i].Handle == 0)
            return i;

    return -1;
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
#   Name       : TFile::SetReq
#
#   Purpose....: Set req params
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::SetReq(long long StartSector, int Sectors)
{
    long long count;
    long long start;
    long long end;
    long long temp;
    int i;
    int link;

    if (StartSector < 0)
        StartSector = 0;

    if (StartSector >= Info->DiscSize / FBytesPerSector)
        StartSector = Info->DiscSize / FBytesPerSector - 1;

    if (Sectors < FSectorsPerPage)
        Sectors = FSectorsPerPage;

    start = StartSector;
    end = StartSector + Sectors - 1;

    if (end < start)
        end = start;

    if (end > Info->DiscSize / FBytesPerSector)
        end = Info->DiscSize / FBytesPerSector - 1;

    count = end - start + 1;

    for (i = 0; i < Buf->Count; i++)
    {
        link = Buf->SortedArr[i];

        temp = Buf->BufArr[link].Pos / FBytesPerSector - start;
        if (temp >= 0)
        {
            if (temp < Sectors)
                count = (int)temp;
            break;
        }
        else
        {
            temp = (Buf->BufArr[link].Pos + Buf->BufArr[link].Size) / FBytesPerSector;
            if (temp > start)
            {
                count -= (int)(temp - start);
                start = temp;
            }
        }
    }

    FCurrStart = start;
    FCurrSectors = count;
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
void TFile::HandleRead(long long pos, int size)
{
    int req;
    int sector;
    long long prev;
    long long curr;
    int offset;
    bool HasPos = false;

    FCurrPos = pos / FBytesPerSector;


    SetReq(FCurrPos, size / FBytesPerSector);

    if (FCurrSectors > 0)
        req = AllocateReq();
    else
        req = -1;

    if (req >= 0)
    {
        FileReq = new TFileReq(FCurrSectors);
        for (sector = 0; sector < FCurrSectors; sector++)
        {
            if (FCurrStart + sector == FCurrPos)
                HasPos = true;

            curr = GetSector(FCurrStart + sector);

            if (sector)
            {
                prev++;
                offset = curr % FSectorsPerPage;

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
        {
            Buf->BufArr[req].Pos = FCurrStart * FBytesPerSector;
            Buf->BufArr[req].Size = FileReq->SectorCount * FBytesPerSector;
            Buf->BufArr[req].Handle = -1;
            printf("Read %d.%d start %lld size %d", Index, req, FCurrStart, FileReq->SectorCount);
            FileReq->Start(Handle, req);
        }
        else
        {
            printf("Read %d No size\r\n", Index);
            ServAddVfsFileReq(Handle, 0, 0, 0);
        }

        delete FileReq;
    }
    else
    {
        printf("Read %d No req available\r\n", Index);
        ServAddVfsFileReq(Handle, 0, 0, 0);
    }
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
    if (Buf->BufArr[req].Handle > 0)
    {
        printf("Free %d.%d\r\n", Index, req);
        ServFreeVfsFileReq(Handle, req + 1);
        Buf->BufArr[req].Handle = 0;
    }
    else
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
    printf("Completed %d.%d\r\n", Index, req);
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
    printf("Map %d.%d\r\n", Index, req);
}
