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
# file.h
# File class
#
########################################################################*/

#ifndef _FILE_H
#define _FILE_H

#include "section.h"
#include "rdos.h"
#include "block.h"
#include "dir.h"

struct TFileBufEntry
{
    long long Pos;
    int Size;
    int Handle;
};

struct TFileBuf
{
    unsigned char SortedArr[241];
    char Resv[3];
    int Count;
    long long LastActive;
    struct TFileBufEntry BufArr[240];
};

class TFileReq
{
public:
    TFileReq(int sectors);
    ~TFileReq();

    void AddSector(long long sector);
    void Start(int handle, int req);

    int File;
    int Req;

    int MaxSectors;
    int SectorCount;
    long long *SectorArr;
};

class TFile
{
    friend class TFs;
public:
    TFile(TDir *ParentDir, int ParentIndex, int BytesPerSector, int OffsetSector);
    virtual ~TFile();

    int Setup(int VfsHandle);

    void LockFile();
    void UnlockFile();

    int GetAttrib();

    int Handle;
    int Index;

    TFileReq *FileReq;

protected:
    virtual void HandleRead(long long pos, int size);
    virtual void HandleCompletedReq(int index);
    virtual void HandleMapReq(int index);
    virtual void HandleFreeReq(int index);

    virtual void SetReq(long long RelSector, int Sectors);
    virtual long long GetSector(long long pos);

    int AllocateReq();
    void UpdateReq();

    struct RdosFileInfo *Info;
    struct TFileBuf *Buf;

    long long FCurrPos;
    long long FCurrStart;
    int FCurrSectors;

    int FBytesPerSector;
    int FSectorsPerPage;
    int FOffsetSector;

    TDir *FParent;
    int FParentIndex;
    TSection FSection;
};

#endif

