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
#include "sig.h"

class TFileReq
{
public:
    TFileReq(int handle, int index, int req);
    ~TFileReq();

    void InitArray(int sectors);
    void AddSector(long long sector);

    void SetPos(int BytesPerSector, long long pos);
    void StartRead();
    void StartWrite();

    int File;
    int Index;
    int Req;
    long long BytePos;
    long long SectPos;

    int MaxSectors;
    int ReqCount;
    int SectorCount;
    long long *SectorArr;

    TFileReq *Link;
};

class TFile
{
    friend class TFs;
public:
    TFile(TDir *ParentDir, int ParentIndex, int BytesPerSector, int OffsetSector);
    virtual ~TFile();

    int Setup(int VfsHandle);
    void Close();
    void WaitForClosing();

    void LockFile();
    void UnlockFile();

    int GetAttrib();

    virtual bool GrowDisc(long long Size) = 0;
    virtual bool SetSize(long long Size) = 0;

    int Handle;
    int Index;

protected:
    virtual TFileReq *HandleRead(long long pos, int size);
    virtual void HandleUpdateReq(long long pos, int size);
    virtual void HandleCompletedReq(int index);
    virtual void HandleMapReq(int index);
    virtual void HandleFreeReq(int index);
    virtual TFileReq *HandleGrowReq(long long size);
    virtual void HandleSizeReq(long long size);

    virtual void SetRead(long long RelSector, int Sectors);
    virtual void SetWrite(long long RelSector, int Sectors);
    virtual long long GetSector(long long pos);

    TFileReq *AllocateReq();
    void FreeReq(TFileReq *req);
    void UpdateReq();

    void GrowAllocated();
    void GrowActive();

    void AddActive(TFileReq *req);

    struct RdosFileInfo *Info;

    bool FClosing;
    TSignal FCloseSignal;

    TFileReq **FAllocatedArr;
    int FCurrAllocatedCount;
    int FMaxAllocatedCount;

    TFileReq **FActiveArr;
    int FCurrActiveCount;
    int FMaxActiveCount;

    TFileReq *FFreeList;

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

