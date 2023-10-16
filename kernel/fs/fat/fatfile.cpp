/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# fatfile.cpp
# FAT file class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <rdos.h>
#include "fatfile.h"
#include "fatfs.h"

/*##########################################################################
#
#   Name       : TFatFile::TFatFile
#
#   Purpose....: Fat file constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatFile::TFatFile(TFat *Fat, TDir *ParentDir, int ParentIndex, unsigned int Cluster, int BytesPerSector, int OffsetSector)
  : TFile(ParentDir, ParentIndex, BytesPerSector, OffsetSector)
{
    unsigned int NeededClusters;
    FFat = Fat;
    struct RdosDirEntry *entry;
    FClusterChain = Fat->GetClusterChain(Cluster);

    FSectorsPerCluster = Fat->SectorsPerCluster;
    FClusterCount = FClusterChain->GetSize();
    FClusterArr = FClusterChain->GetChain();

    NeededClusters = SizeToClusters(Info->CurrSize);

    if (NeededClusters > FClusterCount)
    {
        Info->CurrSize = ClustersToSize(FClusterCount);

        entry = FParent->LockEntry(FParentIndex);
        if (entry)
        {
            entry->Inode = FClusterArr[0];
            FParent->UpdateEntry(entry, Info);
            FParent->UnlockEntry(entry);
        }
    }
    else
    {
        if (NeededClusters < FClusterCount)
            Shrink(FClusterCount - NeededClusters);
    }

    FClusterCount = FClusterChain->GetSize();
    FClusterArr = FClusterChain->GetChain();

    Info->SectorCount = (long long)(FClusterCount * FSectorsPerCluster);
    Info->DiscSize = ClustersToSize(FClusterCount);
}

/*##########################################################################
#
#   Name       : TFatFile::~TFatFile
#
#   Purpose....: Fat file destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatFile::~TFatFile()
{
    delete FClusterChain;
}

/*##########################################################################
#
#   Name       : TFatFile::SetRead
#
#   Purpose....: Set read req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatFile::SetRead(long long StartSector, int Sectors)
{
    long long start;
    long long end;
    int count;
    long long c;

    c = StartSector / FSectorsPerCluster;

    if (c >= FClusterCount)
        c = FClusterCount - 1;

    if (c < 0)
        c = 0;

    start =  c * FSectorsPerCluster;

    c = (StartSector + Sectors - 1) / FSectorsPerCluster;

    if (c >= FClusterCount)
        c = FClusterCount - 1;

    if (c < 0)
        c = 0;

    end = (c + 1) * FSectorsPerCluster - 1;
    count = end - start + 1;

    TFile::SetRead(start, count);
}

/*##########################################################################
#
#   Name       : TFatFile::SetWrite
#
#   Purpose....: Set write req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatFile::SetWrite(long long StartSector, int Sectors)
{
    long long start = StartSector;
    long long end;
    int count = Sectors;
    long long c;
    int i;

    if (FOffsetSector && Sectors)
    {
        c = (StartSector + Sectors - 1) / FSectorsPerCluster;

        if (c >= FClusterCount)
            c = FClusterCount - 1;

        if (c < 0)
            c = 0;

        end =  c * FSectorsPerCluster + FOffsetSector - 1;
        count = FSectorsPerPage / FSectorsPerCluster;
        if (!count)
            count = 1;

        if (c == FClusterCount - 1)
        {
            for (i = 1; i <= count; i++)
            {
                if (FFat->IsFree(FClusterArr[c] + i))
                    end =  (c + i) * FSectorsPerCluster + FOffsetSector - 1 - FSectorsPerPage;
                else
                    break;
            }
        }

        count = end - start + 1;
    }

    TFile::SetWrite(start, count);
}

/*##########################################################################
#
#   Name       : TFatFile::GetSector
#
#   Purpose....: Get sector base on position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TFatFile::GetSector(long long RelSector)
{
    unsigned int c = RelSector / FSectorsPerCluster;
    int sc = FFat->SectorsPerCluster;
    int diff = RelSector % FSectorsPerCluster;
    int i;
    int count;
    unsigned int cluster;
    long long sector;

    if (c < FClusterCount)
        return FFat->StartSector + (FClusterArr[c] - 2) * sc + diff;
    else
    {
        count = c - FClusterCount + 1;
        cluster = FClusterArr[FClusterCount - 1];
        sector = FFat->StartSector + (cluster - 2) * sc + diff;

        for (i = 0; i < count; i++)
        {
           if (FFat->IsFree(cluster + 1))
           {
               cluster++;
               sector += sc;
           }
           else
               return 0;
        }
        return sector;
    }
}

/*##########################################################################
#
#   Name       : TFatFile::SizeToClusters
#
#   Purpose....: Size to clusters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatFile::SizeToClusters(long long Size)
{
    unsigned clusters;

    if (Size)
    {
        clusters = (Size - 1) / FSectorsPerCluster / FBytesPerSector;
        clusters++;
    }
    else
        clusters = 0;

    return clusters;
}

/*##########################################################################
#
#   Name       : TFatFile::ClustersToSize
#
#   Purpose....: Clusters to size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TFatFile::ClustersToSize(unsigned int clusters)
{
    return (long long)clusters * (long long)FSectorsPerCluster * (long long)FBytesPerSector;
}

/*##########################################################################
#
#   Name       : TFatFile::Grow
#
#   Purpose....: Grow file with new clusters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatFile::Grow(unsigned int count)
{
    struct RdosDirEntry *entry;
    bool ok;
    bool update;
    unsigned int *Arr;

    if (FClusterChain->GetSize())
        update = false;
    else
        update = true;

    ok = FFat->GrowClusterChain(FClusterChain, count);

    if (update && FClusterChain->GetSize())
    {
        Arr = FClusterChain->GetChain();

        entry = FParent->LockEntry(FParentIndex);
        if (entry)
        {
            entry->Inode = Arr[0];
            FParent->UpdateEntry(entry, Info);
            FParent->UnlockEntry(entry);
        }
    }

    return ok;
}

/*##########################################################################
#
#   Name       : TFatFile::Shrink
#
#   Purpose....: Shrink file by removing clusters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatFile::Shrink(unsigned int count)
{
    struct RdosDirEntry *entry;
    bool ok;
    bool update;

    if (FClusterChain->GetSize())
        update = true;
    else
        update = false;

    ok = FFat->ShrinkClusterChain(FClusterChain, count);

    if (update && FClusterChain->GetSize() == 0)
    {
        entry = FParent->LockEntry(FParentIndex);
        if (entry)
        {
            entry->Inode = 0;
            FParent->UpdateEntry(entry, Info);
            FParent->UnlockEntry(entry);
        }
    }

    return ok;
}

/*##########################################################################
#
#   Name       : TFatFile::GrowDisc
#
#   Purpose....: Grow file and request sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatFile::GrowDisc(long long Size)
{
    unsigned int CurrClusters;
    unsigned int NewClusters;
    bool ok;

    if (Size > 0xFFFFFFFF)
        ok = false;
    else
    {
        CurrClusters = FClusterChain->GetSize();
        NewClusters = SizeToClusters(Size);
        ok = true;
    }

    LockFile();

    if (ok)
    {
        if (NewClusters > CurrClusters)
            ok = Grow(NewClusters - CurrClusters);        

        FClusterCount = FClusterChain->GetSize();
        FClusterArr = FClusterChain->GetChain();
        Info->SectorCount = (long long)(FClusterCount * FSectorsPerCluster);
        Info->DiscSize = ClustersToSize(FClusterCount);
    }

    UnlockFile();

    return ok;
}

/*##########################################################################
#
#   Name       : TFatFile::SetSize
#
#   Purpose....: Set file size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatFile::SetSize(long long Size)
{
    unsigned int CurrClusters;
    unsigned int NewClusters;
    bool ok;

    if (Size > 0xFFFFFFFF)
        ok = false;
    else
    {
        CurrClusters = FClusterChain->GetSize();
        NewClusters = SizeToClusters(Size);
        ok = true;
    }

    LockFile();

    if (ok)
    {
        if (NewClusters > CurrClusters)
            ok = Grow(NewClusters - CurrClusters);
        else
        {
            if (NewClusters < CurrClusters)
                ok = Shrink(CurrClusters - NewClusters);
        }

        if (ok)
            Info->CurrSize = Size;

        FClusterCount = FClusterChain->GetSize();
        FClusterArr = FClusterChain->GetChain();
        Info->SectorCount = (long long)(FClusterCount * FSectorsPerCluster);
        Info->DiscSize = ClustersToSize(FClusterCount);
    }

    UnlockFile();

    return ok;
}
