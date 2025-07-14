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
# discserv.h
# Disc server class
#
########################################################################*/

#ifndef _DIR_H
#define _DIR_H

#include "block.h"
#include "section.h"
#include "rdos.h"

#define DIR_NOT_FOUND -1

struct TDirLink
{
    int Offset;
    void *Link;
    short int WaitHandle;
    signed char RefCount;
    signed char WaitCount;
};

class TFile;

class TDir : public TBlock
{
public:
    TDir(TDir *ParentDir, int ParentIndex);
    virtual ~TDir();

    void LockDir();
    void UnlockDir();

    struct TShareHeader *Share();
    int GetCount();
    int Find(long long inode);
    int Find(const char *path);
    struct RdosDirEntry *LockEntry(int index);
    struct RdosDirEntry *LockEntry(struct TDirLink *link);
    void UnlockEntry(struct RdosDirEntry *entry);
    bool DeleteEntry(int index);

    virtual bool UpdateEntry(struct RdosDirEntry *direntry, struct RdosFileInfo *fileinfo) = 0;
    virtual bool DeleteEntry(struct RdosDirEntry *direntry) = 0;

    long long GetInode();
    TDir *GetParentDir();

    TDir *LockDirLink(int index);
    TFile *LockFileLink(int index);
    void UnlockDirLink(int index);

    TDir *GetDirLink(int index);
    void SetDirLink(int index, TDir *dir);

    TFile *GetFileLink(int index);
    void SetFileLink(int index, TFile *file);
    void ClearFileLink(int index);

    struct RdosDirEntry *Add(const char *path, long long inode);

    int Entry;

protected:
    void Grow();
    int FindFree();

    struct TDirLink *EntryArr;
    TDir *Parent;
    int ParentIndex;
    long long Inode;

    int EntryCount;
    int MaxCount;
    TSection Section;
};

#endif

