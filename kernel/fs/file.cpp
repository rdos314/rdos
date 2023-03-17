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
#   Name       : TFile::TFile
#
#   Purpose....: Dir constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::TFile(TDir *pd, int pi, int bps, int os)
  : FSection("file")
{
    struct DirEntry *entry;

    FBytesPerSector = bps;
    FSectorsPerPage = 0x1000 / bps;
    FOffsetSector = os;

    FParent = pd;
    FParentIndex = pi;

    entry = FParent->LockEntry(FParentIndex);
    Info = (struct TFileInfo *)RdosAllocateMem(0x1000);

    Info->FsSize = entry->Size;
    Info->ReqSize = entry->Size;
    Info->AccessTime = entry->AccessTime;
    Info->ModifyTime = entry->ModifyTime;
    Info->Attrib = entry->Attrib;
    Info->Flags = entry->Flags;
    Info->Uid = entry->Uid;
    Info->Gid = entry->Gid;
    Info->KernelHandle = 0;
    Info->ServHandle = 0;
    strcpy(Info->Name, entry->PathName);

    Req = 0;

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
    UpdateReq();
    printf("Close %d\r\n", GetServHandle());

    ServCloseVfsFile(GetKernelHandle());

    RdosFreeMem(Info);
    if (Req)
        RdosFreeMem(Req);

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
void TFile::Setup(int VfsHandle, int ServFileHandle)
{
    int i;

    Req = (struct TFileReq *)RdosAllocateMem(0x1000);
    Req->Count = 0;
    Req->Update = 0;
    for (i = 0; i < 240; i++)
    {
        Req->ReqArr[i].Pos = 0;
        Req->ReqArr[i].Size = 0;
        Req->ReqArr[i].Handle = 0;
    }

    for (i = 0; i < 241; i++)
        Req->SortedArr[i] = 0xFF;

    Info->ServHandle = ServFileHandle;
    Info->KernelHandle = ServOpenVfsFile(VfsHandle, Info, Req);
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
#   Name       : TFile::GetServHandle
#
#   Purpose....: Get server handle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFile::GetServHandle()
{
    return Info->ServHandle;
}

/*##########################################################################
#
#   Name       : TFile::GetKernelHandle
#
#   Purpose....: Get kernel handle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFile::GetKernelHandle()
{
    return Info->KernelHandle;
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
        if (Req->ReqArr[i].Handle == 0)
            return i;

    return -1;
}

/*##########################################################################
#
#   Name       : TFile::AddReq
#
#   Purpose....: Add req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFile::AddReq()
{
    int index;

    if (FCurrSize > 0)
    {
        index = AllocateReq();

        if (index >= 0)
        {
            Req->ReqArr[index].Pos = FCurrStart;
            Req->ReqArr[index].Size = FCurrSize;
            Req->ReqArr[index].Handle = -1;
            printf("Read %d.%d start %lld size %d\r\n", GetServHandle(), index, FCurrStart, FCurrSize);

            return index + 1;
        }
        else
            printf("No entry\r\n");
    }
    else
        printf("No size\r\n");

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
#   Name       : TFile::SetReq
#
#   Purpose....: Set req params
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::SetReq(long long pos, int size)
{
    long long start;
    long long end;
    long long temp;
    int i;
    int link;

    if (pos < 0)
        pos = 0;

    if (pos >= Info->ReqSize)
        pos = Info->ReqSize - 1;

    if (size < 0x1000)
        size = 0x1000;

    start = pos;
    end = start + size - 1;

    if (end < start)
        end = start;

    if (end > Info->ReqSize)
        end = Info->ReqSize - 1;

    size = end - start + 1;

    for (i = 0; i < Req->Count; i++)
    {
        link = Req->SortedArr[i];

        temp = Req->ReqArr[link].Pos - start;
        if (temp >= 0)
        {
            if (temp < size)
                size = (int)temp;
            break;
        }
        else
        {
            temp = Req->ReqArr[link].Pos + Req->ReqArr[link].Size;
            if (temp > start)
            {
                size -= (int)(temp - start);
                start = temp;
            }
        }
    }

    FCurrPos = pos;
    FCurrStart = start;
    FCurrSize = size;
}

/*##########################################################################
#
#   Name       : TFile::ReqFile
#
#   Purpose....: Req file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFile::ReqFile(long long pos, int size, int src)
{
    int SectorCount;
    long long *SectorArr;
    int res = 0;
    int index;
    int sector;
    long long start;

    UpdateReq();

    SetReq(pos, size);
    index = AddReq();

    if (index)
    {
        SectorCount = FCurrSize / FBytesPerSector;
        SectorArr = new long long[SectorCount];

        start = FCurrStart / FBytesPerSector;

        for (sector = 0; sector < SectorCount; sector++)
            SectorArr[sector] = GetSector((long long)FBytesPerSector * (start + sector));

        res = ServAddVfsFileReq(GetKernelHandle(), index, SectorArr, SectorCount, src);

        delete SectorArr;
        UpdateReq();
    }

    return res;
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
void TFile::FreeReq(int index)
{
    printf(" Free %d.%d ", GetServHandle(), index);
    ServFreeVfsFileReq(GetKernelHandle(), index + 1);
    Req->ReqArr[index].Handle = 0;
}

/*##########################################################################
#
#   Name       : TFile::UpdateReq
#
#   Purpose....: Update req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::UpdateReq()
{
    int i;
    int handle;

    while (Req->Update)
    {
        Req->Update = 0;

        for (i = 0; i < 240; i++)
        {
            handle = Req->ReqArr[i].Handle;
            if (handle & 0x80000000)
                if (handle != -1)
                    FreeReq(i);
        }
    }
}
