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
    void FreeArray();
    void AddSector(long long sector);

    void SetPos(int BytesPerSector, long long pos);
    void StartRead();
    void StartWrite();

    void Disable();
    bool IsEnabled();

    int File;
    int Index;
    int Req;
    long long BytePos;
    long long SectPos;

    TFileReq *Link;

    int SectorCount;

protected:
    bool Enabled;
    int MaxSectors;
    long long *SectorArr;
};

class TFile
{
    friend class TFs;
public:
    TFile(TDir *ParentDir, int ParentIndex, int BytesPerSector, int OffsetSector);
    virtual ~TFile();

    int Setup(int VfsHandle);
    void Deref();
    void Close();
    void WaitForClosing();

    void LockFile();
    void UnlockFile();

    int GetAttrib();

    void SetAccessTime(long long time);
    void SetModifyTime(long long time);
    bool SetSize(long long Size);
    long long GetDiscSize();

    virtual bool GrowDisc(long long Size) = 0;

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
    virtual void HandleDeleteReq();
    virtual bool SetDiscSize(long long Size) = 0;

    virtual void SetRead(long long RelSector, int Sectors);
    virtual void SetWrite(long long RelSector, int Sectors);
    virtual long long GetSector(long long pos);

    bool IsDirEntryUnlinked();
    void UnlinkDirEntry();

    void SyncDirEntry();
    bool DeleteDirEntry();

    TFileReq *AllocateReq();
    void FreeReq(TFileReq *req);
    void UpdateReq();
    TFileReq *FindReq(long long pos);

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

