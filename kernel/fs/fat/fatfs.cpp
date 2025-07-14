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
# fs.cpp
# Fat FS class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <rdos.h>
#include <serv.h>
#include "fat.h"
#include "fatfs.h"
#include "tab12.h"
#include "tab16.h"
#include "tab32.h"
#include "dir.h"
#include "cluster.h"
#include "fatfile.h"

/*##########################################################################
#
#   Name       : TFat::TFat
#
#   Purpose....: Fat constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat::TFat(TPartServer *server, struct TBaseBootSector *boot)
  : TFs(server)
{
    FatCount = boot->FatCount;
    SectorsPerCluster = boot->SectorsPerCluster;
    ReservedSectors = boot->ResvSectors;

    FatTable1 = 0;
    FatTable2 = 0;
}

/*##########################################################################
#
#   Name       : TFat::~TFat
#
#   Purpose....: Fat destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat::~TFat()
{
}

/*##########################################################################
#
#   Name       : TFat::Validate
#
#   Purpose....: Validate important parameters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat::Validate()
{
    long long TotalSectors;

    TotalSectors = FServer->GetPartSectors();

    if (TotalSectors < PartSectors)
        return false;

    if (FatSectors == 0)
        return false;

    if (FatCount != 2)
        return false;

    if (SectorsPerCluster <= 0)
        return false;

    return true;
}

/*##########################################################################
#
#   Name       : TFat::Format
#
#   Purpose....: Format partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFat::Format(long long *Start, long long *Count)
{
    return 1;
}

/*##########################################################################
#
#   Name       : TFat::GetFreeSectors
#
#   Purpose....: Get free sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TFat::GetFreeSectors()
{
    return (long long)FreeClusters * (long long)SectorsPerCluster;
}

/*##########################################################################
#
#   Name       : TFat::FormatFixedDir
#
#   Purpose....: FormatFixedDir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFat::FormatFixedDir(long long RootSector, int RootDirEntries)
{
    int Sectors = RootDirEntries / 16;
    TPartReq Req(FServer);
    TPartReqEntry ReqEntry(&Req, RootSector, Sectors, true);
    char *data;

    Req.WaitForever();

    data = (char *)ReqEntry.Map();

    memset(data, 0, 512 * Sectors);

    ReqEntry.Write();
}

/*##########################################################################
#
#   Name       : TFat::CacheFixedDir
#
#   Purpose....: CacheFixedDir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir *TFat::CacheFixedDir(long long RootSector, int RootDirEntries)
{
    return new TFatDir(this, RootSector, RootDirEntries / 16);
}

/*##########################################################################
#
#   Name       : TFat::CacheDir
#
#   Purpose....: Cache dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir *TFat::CacheDir(TDir *ParentDir, int ParentIndex, long long Inode)
{
    return new TFatDir(this, ParentDir, ParentIndex, (unsigned int)Inode);
}

/*##########################################################################
#
#   Name       : TFat::GetClusterChain
#
#   Purpose....: Get cluster chain
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCluster *TFat::GetClusterChain(unsigned int Cluster)
{
    TPartReq Req(FServer);
    TCluster *Chain;
    unsigned int NextCluster1;
    unsigned int NextCluster2;

    Chain = new TCluster;

    while (Cluster && Cluster < Clusters)
    {
        Chain->Add(Cluster);

        NextCluster1 = FatTable1->GetClusterLink(Cluster);
        NextCluster2 = FatTable2->GetClusterLink(Cluster);

        if (NextCluster1 == NextCluster2)
            Cluster = NextCluster1;
        else
        {
            if (NextCluster1 >= Clusters && NextCluster2 >= Clusters)
                break;

            if (NextCluster1 < Clusters && NextCluster2 < Clusters)
                break;

            if (NextCluster1 > NextCluster2)
                Cluster = NextCluster2;
            else
                Cluster = NextCluster1;
        }
    }

    return Chain;
}

/*##########################################################################
#
#   Name       : TFat::GrowClusterChain
#
#   Purpose....: Grow cluster chain
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat::GrowClusterChain(TCluster *Chain, unsigned int Count)
{
    int i;
    bool ok = true;
    unsigned int cluster;
    unsigned int link;
    int size;
    unsigned int *arr;

    size = Chain->GetSize();
    if (size)
    {
        arr = Chain->GetChain();
        cluster = arr[size - 1];
        FatTable1->SetAllocateCluster(cluster);
        FatTable2->SetAllocateCluster(cluster);
    }

    for (i = 0; i < Count && ok; i++)
    {
        cluster = AllocateCluster();
        if (cluster)
        {
            size = Chain->GetSize();
            if (size)
            {
                arr = Chain->GetChain();
                link = arr[size - 1];
                FatTable1->LinkCluster(link, cluster);
                FatTable2->LinkCluster(link, cluster);
            }

            Chain->Add(cluster);
        }
        else
            ok = false;
    }

    FatTable1->Complete();
    FatTable2->Complete();

    return ok;
}

/*##########################################################################
#
#   Name       : TFat::ShrinkClusterChain
#
#   Purpose....: Shrink cluster chain
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat::ShrinkClusterChain(TCluster *Chain, unsigned int Count)
{
    int i;
    bool ok = true;
    unsigned int cluster;
    int pos;
    unsigned int *arr;

    for (i = 0; i < Count && ok; i++)
    {
        pos = Chain->GetSize();
        if (pos)
        {
            arr = Chain->GetChain();
            cluster = arr[pos - 1];
            FatTable1->FreeCluster(cluster);
            FatTable2->FreeCluster(cluster);

            Chain->Sub();
        }
        else
            ok = false;
    }

    pos = Chain->GetSize();
    if (pos)
    {
        arr = Chain->GetChain();
        cluster = arr[pos - 1];
        FatTable1->LinkCluster(cluster);
        FatTable2->LinkCluster(cluster);
    }

    FatTable1->Complete();
    FatTable2->Complete();

    return ok;
}

/*##########################################################################
#
#   Name       : TFat::SetClusterCount
#
#   Purpose....: Set cluster count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat::SetClusterCount(TCluster *Chain, unsigned int Clusters)
{
    int size = Chain->GetSize();

    if (Clusters > size)
        return GrowClusterChain(Chain, Clusters - size);
    else
        if (Clusters < size)
            return ShrinkClusterChain(Chain, size - Clusters);

    return true;
}

/*##########################################################################
#
#   Name       : TFat::OpenFile
#
#   Purpose....: Open file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TFat::OpenFile(TDir *ParentDir, int ParentIndex, long long Inode)
{
    unsigned int Cluster = (unsigned int)Inode;
    TFile *File = new TFatFile(this, ParentDir, ParentIndex, Cluster, FBytesPerSector, FOffsetSector);
    return File;
}

/*##########################################################################
#
#   Name       : TFat::IsFree
#
#   Purpose....: Check if cluster is free
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat::IsFree(unsigned int Cluster)
{
    if (!FatTable1->IsFree(Cluster))
        return false;

    if (!FatTable2->IsFree(Cluster))
        return false;

    return true;
}

/*##########################################################################
#
#   Name       : TFat::AllocateCluster
#
#   Purpose....: Allocate cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFat::AllocateCluster()
{
    unsigned int Cluster;
    unsigned int Link;

    while (!FStopped)
    {
        Cluster = FatTable1->AllocateCluster();

        if (!Cluster)
            return 0;

        if (FatTable2->ReserveCluster(Cluster))
            return Cluster;
        else
        {
            Link = FatTable2->GetClusterLink(Cluster);
            FatTable1->LinkCluster(Cluster, Link);
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TFat::Complete
#
#   Purpose....: Complete FAT table modification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFat::Complete()
{
    FatTable1->Complete();
    FatTable2->Complete();
}

/*##########################################################################
#
#   Name       : TFat::CreateDir
#
#   Purpose....: Create dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat::CreateDir(TDir *ParentDir, const char *Name)
{
    TFatDir *dir = (TFatDir *)ParentDir;
    bool ok;

    ok = dir->CreateDirEntry(Name);
    Complete();

    return ok;
}

/*##########################################################################
#
#   Name       : TFat::CreateFile
#
#   Purpose....: Create file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat::CreateFile(TDir *ParentDir, const char *Name, int Attrib)
{
    TFatDir *dir = (TFatDir *)ParentDir;
    bool ok;

    ok = dir->CreateFileEntry(Name, Attrib);
    Complete();

    return ok;
}
