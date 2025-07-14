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
# fatfs.h
# Fat FS class
#
########################################################################*/

#ifndef _FAT_FS_H
#define _FAT_FS_H

#include "fs.h"
#include "tab.h"
#include "cluster.h"
#include "fatdir.h"


struct TBaseBootSector
{
    char Jmp[3];
    char Name[8];
    short int BytesPerSector;
    char SectorsPerCluster;
    short int ResvSectors;
    char FatCount;
    short int RootDirEntries;
    unsigned short int SectorCount16;
    char Media;
    unsigned short int FatSectors16;
    short int SectorsPerCyl;
    short int Heads;
    int HiddenSectors;
    unsigned int Sectors;
};

struct TExtBootSector
{
    char DriveNr;
    char Resv1;
    char Sign;
    int VolumeId;
    char VolumeLabel[11];
    char FsName[8];
};

struct TBootSector12_16
{
    struct TBaseBootSector base;
    struct TExtBootSector ext;
};

struct TBootSector32
{
    struct TBaseBootSector base;
    int FatSectors;
    short int ExtFlags;
    short int FsVersion;
    int RootCluster;
    short int InfoSector;
    short int BackupSector;
    char Resv1[12];
    struct TExtBootSector ext;
};

class TFat : public TFs
{
friend class TFatFile;
friend class TFatDir;
public:
    TFat(TPartServer *server, struct TBaseBootSector *boot);
    ~TFat();

    bool Validate();
    virtual int Format(long long *Start, long long *Count);
    virtual long long GetFreeSectors();
    virtual TDir *CacheDir(TDir *ParentDir, int ParentIndex, long long Inode);
    virtual TFile *OpenFile(TDir *ParentDir, int ParentIndex, long long Inode);
    virtual bool CreateDir(TDir *ParentDir, const char *Name);
    virtual bool CreateFile(TDir *ParentDir, const char *Name, int Attrib);

    int FatSize;
    unsigned int PartSectors;
    int SectorsPerCluster;
    int ReservedSectors;

    long long StartSector;
    long long Fat1Sector;
    long long Fat2Sector;

    int FatCount;
    int FatSectors;

    unsigned int Clusters;
    unsigned int FreeClusters;

protected:
    TDir *CacheFixedDir(long long RootSector, int RootDirEntries);
    void FormatFixedDir(long long RootSector, int RootDirEntries);

    bool IsFree(unsigned int Cluster);
    unsigned int AllocateCluster();
    void Complete();

    bool GrowClusterChain(TCluster *Chain, unsigned int Count);
    bool ShrinkClusterChain(TCluster *Chain, unsigned int Count);

    TCluster *GetClusterChain(unsigned int Cluster);
    bool SetClusterCount(TCluster *Chain, unsigned int Clusters);

    TFatTable *FatTable1;
    TFatTable *FatTable2;
};

#endif

