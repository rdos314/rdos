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
    FFat = Fat;
    FClusterChain = Fat->GetClusterChain(Cluster);

    FClusterCount = FClusterChain->GetSize();
    FClusterArr = FClusterChain->GetChain();

    FSectorsPerCluster = Fat->SectorsPerCluster;

    Info->DiscSize = (long long)FClusterCount * (long long)FSectorsPerCluster * (long long)BytesPerSector;
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
#   Name       : TFatFile::AdjustStart
#
#   Purpose....: Adjust start position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatFile::SetReq(long long StartSector, int Sectors)
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

    TFile::SetReq(start, count);
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

    return FFat->StartSector + (FClusterArr[c] - 2) * sc + diff;
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
            FParent->UpdateEntry(FParentIndex, entry, Info);
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
            FParent->UpdateEntry(FParentIndex, entry, Info);
            FParent->UnlockEntry(entry);
        }
    }

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
        ok = true;

        CurrClusters = FClusterChain->GetSize();

        if (Size)
        {
            NewClusters = (Size - 1) / FSectorsPerCluster / FBytesPerSector;
            NewClusters++;
        }
        else
            NewClusters = 0;
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
        Info->DiscSize = FClusterCount * FSectorsPerCluster * FBytesPerSector;
    }

    UnlockFile();

    return ok;
}
