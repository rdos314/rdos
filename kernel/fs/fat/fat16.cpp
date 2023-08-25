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
# fat16.cpp
# Fat16 class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <rdos.h>
#include <serv.h>
#include "fat16.h"

#define ROOT_DIR_SECTORS	32

/*##########################################################################
#
#   Name       : TFat16::Adjust
#
#   Purpose....: Adjust size & pos to achieve 4k alignment
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFat16::Adjust(long long *Start, long long *Count)
{
    long long pos = *Start;
    unsigned int size;
    long long diff;

    pos = pos / 8;
    pos = 8 * pos + 7;

    if (*Count < 0xFFFFFFFF)
        size = (unsigned int)*Count;
    else
        size = 0xFFFFFFFF;

    diff = pos - *Start;
    size -= diff;

    *Start = pos;
    *Count = size;

    return size;
}

/*##########################################################################
#
#   Name       : TFat16::CalcClusterSize
#
#   Purpose....: Calculate cluster size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFat16::CalcClusterSize(unsigned int size)
{
    unsigned int ClusterSize;
    unsigned int Clusters;
    unsigned int FatSectors;
    unsigned int Used;
    int tries;

    ClusterSize = 8;
    while (ClusterSize != 64)
    {
        Used = size - ROOT_DIR_SECTORS - 1;
        for (tries = 0; tries < 3; tries++)
        { 
            Clusters = Used / ClusterSize;
            FatSectors = Clusters / 256;
            FatSectors--;
            FatSectors = FatSectors / 4;
            FatSectors = 4 * (FatSectors + 1);
            Used = size - ROOT_DIR_SECTORS - 1 - 2 * FatSectors;
        } 

        if (Clusters <= 0XFFFF)
            break;

        ClusterSize = 2 * ClusterSize;
    }    

    return ClusterSize;
}

/*##########################################################################
#
#   Name       : TFat16::ValidateFs
#
#   Purpose....: Validate before format
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat16::ValidateFs(struct TBootSector12_16 *boot, long long *Start, long long *Count)
{
    unsigned int Size;
    unsigned int ClusterSize;
    int tries;

    Size = Adjust(Start, Count);
    ClusterSize = CalcClusterSize(Size);

    return false;
}

/*##########################################################################
#
#   Name       : TFat16::TFat16
#
#   Purpose....: Fat16 constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat16::TFat16(TPartServer *server, struct TBootSector12_16 *boot)
  : TFat(server, (struct TBaseBootSector *)boot),
    Tab1(server),
    Tab2(server)
{
    int Free1;
    int Free2;

    FatSize = 16;
    PartSectors = boot->base.SectorCount16;
    if (!PartSectors)
        PartSectors = boot->base.Sectors;

    FatSectors = boot->base.FatSectors16;

    RootDirEntries = boot->base.RootDirEntries;

    if (Validate())
    {
        FatTable1 = &Tab1;
        FatTable2 = &Tab2;

        Fat1Sector = ReservedSectors;
        Fat2Sector = Fat1Sector + FatSectors;
        RootSector = Fat2Sector + FatSectors;
        StartSector = RootSector + RootDirEntries / 16;

        Clusters = PartSectors / SectorsPerCluster + 2;

        if (Clusters > 0xFFF0)
            Clusters = 0xFFF0;

        Tab1.Setup(SectorsPerCluster, Fat1Sector, FatSectors, Clusters);
        Tab2.Setup(SectorsPerCluster, Fat2Sector, FatSectors, Clusters);

        Free1 = Tab1.GetFreeClusters();
        Free2 = Tab2.GetFreeClusters();

        if (Free1 > Free2)
            FreeClusters = Free2;
        else
            FreeClusters = Free1;
    }
}

/*##########################################################################
#
#   Name       : TFat16::~TFat16
#
#   Purpose....: Fat16 destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat16::~TFat16()
{
}

/*##########################################################################
#
#   Name       : TFat16::CacheRootDir
#
#   Purpose....: CacheRootDir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir *TFat16::CacheRootDir()
{
    return CacheFixedDir(RootSector, RootDirEntries);
}
