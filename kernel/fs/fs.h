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
# fs.h
# FS base class
#
########################################################################*/

#ifndef _FS_H
#define _FS_H

#include "partint.h"
#include "dir.h"
#include "file.h"

struct TFsQueueEntry
{
    long long Par64;
    int Par32;
    short int File;
    short int Op;
};

class TParser
{
public:
    TParser(TDir *Dir, char *PathName);
    ~TParser();

    bool IsDone();
    bool IsLast();
    bool IsValid();
    bool IsDir();
    bool IsCurrDir();
    bool IsParentDir();

    TDir *GetDir();
    TFile *GetFile();
    struct RdosDirEntry *GetEntry();

    void Advance();

protected:
    void Process();

    int CurrIndex;
    struct RdosDirEntry *CurrEntry;
    bool IsCurr;
    bool IsParent;
    char *Head;
    char *Next;
    TDir *Dir;
};

class TFs
{
    friend class TFile;
public:
    TFs(TPartServer *server);
    virtual ~TFs();

    virtual void Start();
    virtual void Stop();

    virtual long long GetFreeSectors() = 0;
    virtual TDir *CacheRootDir() = 0;
    virtual TDir *CacheDir(TDir *ParentDir, int ParentIndex, long long Inode) = 0;
    virtual TFile *OpenFile(TDir *ParentDir, int ParentIndex, long long Inode) = 0;

    struct TShareHeader *GetDir(int rel, char *path, int *count);
    int GetDirEntryAttrib(int rel, char *path);
    int LockRelDir(int rel, char *path);
    void CloneRelDir(int rel);
    void UnlockRelDir(int rel);
    int GetRelDir(int rel, char *path);

    int OpenFile(int rel, char *path);
    int GetFileHandle(int handle);
    int GetFileAttrib(int handle);
    void CloseFile(int handle);

    void ReadDirLink(TDir *dir, int index);

    void Execute();

protected:
    virtual void HandleRead(TFile *file, long long pos, int size);
    virtual void HandleCompletedReq(TFile *file, int index);
    virtual void HandleMapReq(TFile *file, int index);
    virtual void HandleFreeReq(TFile *file, int index);
    bool HandleQueue(struct TFsQueueEntry *entry);
    void StartServer();

    int FileHandleToIndex(int handle);

    void GrowDir();
    void Add(TDir *dir);
    void Remove(TDir *dir);

    void GrowFile();
    void Add(TFile *file);
    void Remove(TFile *file);

    void GrowPend();

    bool FStarted;

    TDir *GetStartDir(int rel);
    TFile *GetFile(int handle);

    int FBytesPerSector;
    long long FStartSector;
    long long FSectorCount;

    int FSectorsPerPage;
    int FOffsetSector;

    TDir **FDirArr;
    int FCurrDirCount;
    int FMaxDirCount;

    TFile **FFileArr;
    int FCurrFileCount;
    int FMaxFileCount;

    bool FServerActive;
    struct TFsQueueEntry *FQueueArr;

    TFileReq **FPendArr;
    int FCurrPendCount;
    int FMaxPendCount;

    TPartServer *FServer;
};

#endif

