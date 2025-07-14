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
# fatdir.h
# FAT directory class
#
########################################################################*/

#ifndef _FATDIR_H
#define _FATDIR_H

#include "cluster.h"
#include "dir.h"
#include "fatlfn.h"
#include "fat.h"

struct TLfnEntry
{
    char Name[14];
    int Pos;
    int Count;
};

class TFat;

class TFatDir : public TDir
{
public:
    TFatDir(TFat *Fat, long long RootSector, int Sectors);
    TFatDir(TFat *Fat, TDir *ParentDir, int ParentIndex, unsigned int Cluster);
    virtual ~TFatDir();

    bool IsFixedDir();
    long long GetSector(int pos);
    int GetIndex(int pos);

    void Add(int pos, struct TFatDirEntry *entry);
    void AddStd(int pos, struct TFatDirEntry *entry);
    void AddLfn(int pos, const char *name, struct TFatDirEntry *fat, int count);
    bool FindLfn(const char *path);

    virtual bool UpdateEntry(struct RdosDirEntry *direntry, struct RdosFileInfo *fileinfo);
    virtual bool DeleteEntry(struct RdosDirEntry *direntry);

    int GetClusterCount();
    unsigned int GetCluster(int index);

    void AddCluster(unsigned int cluster);
    void AddFree(int pos);
    void RemoveFree(int pos);

    bool CreateDirEntry(const char *name);
    bool CreateFileEntry(const char *name, int attr);

    static void InitDir(TFat *Fat, unsigned int Cluster);

protected:
    void GrowLfn();
    void GrowFree(int count);

    void Add(int pos, const char *name, struct TFatDirEntry *fat);
    void AddLfn(int pos, struct TFatDirEntry *entry);
    int DeleteLfn(int pos);

    void ProcessFixed();
    void ProcessCluster(unsigned int Cluster, int *pos);
    void ProcessClusters();

    int AllocateEntry(int count);
    void SetupStdEntry(struct TFatDirEntry *entry, int pos);
    bool SetupLfnEntry(struct TFatDirEntry *entry, TFatLfn *lfn, const char *name);
    bool CreateEntry(const char *name, unsigned int cluster, char attr);
    void InitDir(unsigned int cluster);

    int FreeEntries;
    int FreeCount;
    unsigned short int *FreeArr;

    int FSectorsPerCluster;
    int FClusterCount;
    unsigned int *FClusterArr;

    TFat *FFat;
    TCluster *FClusterChain;

    long long FStartSector;
    int FSectorCount;

    struct TFatLfn *FCurrLfn;

    int LfnCount;
    int LfnMax;
    struct TLfnEntry *LfnArr;

private:
    void Init();

};

#endif

