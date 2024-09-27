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

