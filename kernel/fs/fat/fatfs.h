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
# Fat class
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
    virtual bool DeleteFile(TFile *File);

    void Test();

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

    unsigned int AllocateCluster();
    void Complete();

    bool VerifySector(int id, char *buf);
    void GetSectors(TPartReq *Req, long long sector, int count);

    TCluster *GetClusterChain(unsigned int Cluster);

    TFatTable *FatTable1;
    TFatTable *FatTable2;
};

#endif

