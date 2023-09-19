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
# tab12.cpp
# 12-bit Fat table class
#
########################################################################*/

#include <memory.h>
#include "tab12.h"

/*##########################################################################
#
#   Name       : TFatTable12::TFatTable12
#
#   Purpose....: Fat table12 constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatTable12::TFatTable12(TPartServer *Server)
 :  TFatTable(Server)
{
    FClusters = 0;
    FReqEntry = 0;
    FTab = 0;

    SetCacheSize(3);
}

/*##########################################################################
#
#   Name       : TFatTable12::~TFatTable12
#
#   Purpose....: Fat table12 destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatTable12::~TFatTable12()
{
}

/*##########################################################################
#
#   Name       : TFatTable12::Setup
#
#   Purpose....: Setup parameters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable12::Setup(int SectorsPerCluster, long long StartSector, int FatSectors, unsigned int Clusters)
{
    FSectorsPerCluster = SectorsPerCluster;
    FStartSector = StartSector;

    if (FatSectors * 512 * 2 / 3 < Clusters)
        FClusters = FatSectors * 512 * 2 / 3;
    else
        FClusters = Clusters;

    FFreeClusters = 0;
}

/*##########################################################################
#
#   Name       : TFatTable12::SetCacheSize
#
#   Purpose....: Set cache size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable12::SetCacheSize(int size)
{
    FCachedSectors = size;
    FCachedClusters = size * 512 * 2 / 3;
}

/*##########################################################################
#
#   Name       : TFatTable12::GetFreeInBlock
#
#   Purpose....: Get free clusters in block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable12::GetFreeInBlock(long long Sector, unsigned int Clusters)
{
    unsigned int i;
    unsigned int fc = 0;
    TPartReqEntry e1(&FReq, Sector, 3);
    char *tab;
    unsigned int val;

    FReq.WaitForever();

    tab = (char *)e1.Map();

    i = 0;

    while (i < Clusters)
    {
        val = 0;
        memcpy(&val, tab, 3);
        tab += 3;
        i += 2;

        if (val == 0)
            fc += 2;
        else
        {
            if ((val & 0xFFF) == 0)
                fc++;

            val = val >> 12;

            if ((val & 0xFFF) == 0)
                fc++;
        }
    }

    return fc;
}

/*##########################################################################
#
#   Name       : TFatTable12::GetFreeClusters
#
#   Purpose....: Get free clusters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable12::GetFreeClusters()
{
    int i;
    long long Sector = FStartSector;
    unsigned int Cluster = 0;
    int Count;
    int Blocks = FClusters / 512 / 2;

    FFreeClusters = 0;

    for (i = 0; i <= Blocks; i++)
    {
        Count = FClusters - Cluster;
        if (Count > 512 * 2)
            Count = 512 * 2;

        FFreeClusters += GetFreeInBlock(Sector, Count);
        Sector += 3;
        Cluster += Count;
    }

    return FFreeClusters;
}

/*##########################################################################
#
#   Name       : TFatTable12::FormatClusters
#
#   Purpose....: Format clusters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable12::FormatClusters()
{
    return 0;
}

/*##########################################################################
#
#   Name       : TFatTable12::GetClusterLink
#
#   Purpose....: Get cluster link
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable12::GetClusterLink(unsigned int Cluster)
{
    int RelSector;
    long long Sector;
    int pos;
    unsigned short int *shp;
    unsigned short int val;

    if (FReqEntry)
    {
        if (Cluster < FStartCluster || Cluster >= FStartCluster + FCachedClusters)
        {
            delete FReqEntry;
            FReqEntry = 0;
        }
    }

    if (!FReqEntry)
    {
        RelSector = Cluster / 512 * 3 / 2;
        while ((RelSector % 3) != 0)
            RelSector--;

        FStartCluster = RelSector * 512 / 3 * 2;
        Sector = FStartSector + RelSector;
        FReqEntry = new TPartReqEntry(&FReq, Sector, FCachedSectors);
        FReq.WaitForever();
        FTab = (char *)FReqEntry->Map();
    }

    pos = 3 * (Cluster - FStartCluster);
    if ((pos % 2) == 0)
    {
        shp = (unsigned short int *)(FTab + pos / 2);
        val = *shp;
        return val & 0xFFF;
    }
    else
    {
        shp = (unsigned short int *)(FTab + pos / 2);
        val = *shp;
        val = val >> 4;
        return val & 0xFFF;
    }
}

/*##########################################################################
#
#   Name       : TFatTable12::AllocateCluster
#
#   Purpose....: Allocate cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable12::AllocateCluster()
{
    return 0;
}

/*##########################################################################
#
#   Name       : TFatTable12::ReserveCluster
#
#   Purpose....: Reserve cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatTable12::ReserveCluster(unsigned int Cluster)
{
    return false;
}

/*##########################################################################
#
#   Name       : TFatTable12::LinkCluster
#
#   Purpose....: Link cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable12::LinkCluster(unsigned int Cluster, unsigned int Link)
{
}

/*##########################################################################
#
#   Name       : TFatTable12::LinkCluster
#
#   Purpose....: Unlink cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable12::LinkCluster(unsigned int Cluster)
{
}

/*##########################################################################
#
#   Name       : TFatTable12::FreeCluster
#
#   Purpose....: Free cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable12::FreeCluster(unsigned int Cluster)
{
}

/*##########################################################################
#
#   Name       : TFatTable12::Complete
#
#   Purpose....: Complete cluster updates
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable12::Complete()
{
}
