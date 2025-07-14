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
    const char *GetEntryName();

    void Advance();
    void Process();

protected:

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

    TPartServer *GetServer();

    virtual void Stop();
    virtual void Run();

    virtual int Format(long long *Start, long long *Count);

    virtual long long GetFreeSectors() = 0;
    virtual TDir *CacheRootDir() = 0;
    virtual TDir *CacheDir(TDir *ParentDir, int ParentIndex, long long Inode) = 0;
    virtual TFile *OpenFile(TDir *ParentDir, int ParentIndex, long long Inode) = 0;
    virtual bool CreateDir(TDir *ParentDir, const char *Name) = 0;
    virtual bool CreateFile(TDir *ParentDir, const char *Name, int Attrib) = 0;

    struct TShareHeader *GetDir(int rel, char *path, int *count);
    int GetDirEntryAttrib(int rel, char *path);
    int LockRelDir(int rel, char *path);
    void CloneRelDir(int rel);
    void UnlockRelDir(int rel);
    int GetRelDir(int rel, char *path);

    int OpenFile(int rel, char *path);
    int CreateFile(int rel, char *path, int attrib);
    int GetFileHandle(int handle);
    int GetFileAttrib(int handle);
    bool SetFileSize(int handle, long long size);
    void DerefFile(int handle);
    void CloseFile(int handle);

    int CreateDir(int rel, char *path);

    void LockDirLink(TDir *dir, int index);
    void UnlockDirLink(TDir *dir, int index);

    void Execute();

protected:
    virtual void HandleRead(TFile *file, long long pos, int size);
    virtual void HandleCompletedReq(TFile *file, int index);
    virtual void HandleMapReq(TFile *file, int index);
    virtual void HandleFreeReq(TFile *file, int index);
    virtual void HandleGrowReq(TFile *file, long long size);
    virtual void HandleUpdateReq(TFile *file, long long pos, int size);
    virtual void HandleSizeReq(TFile *file, long long size, int thread);
    virtual void HandleDeleteReq(TFile *file, int thread);
    void HandleQueue(TFile *file, struct TFsQueueEntry *entry);
    void StartServer();

    int FileHandleToIndex(int handle);

    void GrowDir();
    void Add(TDir *dir);
    void Remove(TDir *dir);

    void GrowFile();
    void Add(TFile *file);
    void Remove(TFile *file);

    void GrowPend();

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

    bool FStopped;
    TPartServer *FServer;
};

#endif

