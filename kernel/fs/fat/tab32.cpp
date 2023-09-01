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
# tab32.cpp
# 32-bit Fat table class
#
########################################################################*/

#include "tab32.h"

/*##########################################################################
#
#   Name       : TFatTable32::TFatTable32
#
#   Purpose....: Fat table32 constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatTable32::TFatTable32(TPartServer *Server)
 :  TFatTable(Server)
{
    FClusters = 0;
    FReqEntry = 0;
    FTab = 0;

    SetCacheSize(8);
}

/*##########################################################################
#
#   Name       : TFatTable32::~TFatTable32
#
#   Purpose....: Fat table32 destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatTable32::~TFatTable32()
{
}

/*##########################################################################
#
#   Name       : TFatTable32::Setup
#
#   Purpose....: Setup parameters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable32::Setup(int SectorsPerCluster, long long StartSector, int FatSectors, unsigned int Clusters)
{
    FSectorsPerCluster = SectorsPerCluster;
    FStartSector = StartSector;

    if (FatSectors * 512 / 4 < Clusters)
        FClusters = FatSectors * 512 / 4;
    else
        FClusters = Clusters;
}

/*##########################################################################
#
#   Name       : TFatTable32::SetCacheSize
#
#   Purpose....: Set cache size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable32::SetCacheSize(int size)
{
    FCachedSectors = size;
    FCachedClusters = size * 512 / 4;
}

/*##########################################################################
#
#   Name       : TFatTable32::GetFreeInBlock
#
#   Purpose....: Get free clusters in block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable32::GetFreeInBlock(long long Sector, unsigned int Clusters)
{
    unsigned int i;
    unsigned int FreeClusters = 0;
    TPartReqEntry e1(&FReq, Sector, 8);
    int *tab;

    FReq.WaitForever();

    tab = (int *)e1.Map();

    for (i = 0; i < Clusters; i++)
        if ((tab[i] & 0xFFFFFFF) == 0)
            FreeClusters++;

    return FreeClusters;
}

/*##########################################################################
#
#   Name       : TFatTable32::GetFreeClusters
#
#   Purpose....: Get free clusters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable32::GetFreeClusters()
{
    unsigned int FreeClusters = 0;
    int i;
    long long Sector = FStartSector;
    unsigned int Cluster = 0;
    int Count;
    int Blocks = FClusters / 512 * 4 / 8;

    for (i = 0; i <= Blocks; i++)
    {
        Count = FClusters - Cluster;
        if (Count > 512 * 8 / 4)
            Count = 512 * 8 / 4;

        FreeClusters += GetFreeInBlock(Sector, Count);
        Sector += 8;
        Cluster += Count;
    }

    return FreeClusters;
}

/*##########################################################################
#
#   Name       : TFatTable32::FormatClusters
#
#   Purpose....: Format clusters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable32::FormatClusters()
{
    return 0;
}

/*##########################################################################
#
#   Name       : TFatTable32::GetClusterLink
#
#   Purpose....: Get cluster link
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable32::GetClusterLink(unsigned int Cluster)
{
    int RelSector;
    long long Sector;

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
        RelSector = Cluster / 512 * 4;
        FStartCluster = RelSector * 512 / 4;
        Sector = FStartSector + RelSector;
        FReqEntry = new TPartReqEntry(&FReq, Sector, FCachedSectors);
        FReq.WaitForever();
        FTab = (unsigned int *)FReqEntry->Map();
    }

    return FTab[Cluster - FStartCluster] & 0xFFFFFFF;
}

/*##########################################################################
#
#   Name       : TFatTable32::AllocateCluster
#
#   Purpose....: Allocate cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable32::AllocateCluster()
{
    return 0;
}

/*##########################################################################
#
#   Name       : TFatTable32::ReserveCluster
#
#   Purpose....: Reserve cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatTable32::ReserveCluster(unsigned int Cluster)
{
    return false;
}

/*##########################################################################
#
#   Name       : TFatTable32::LinkCluster
#
#   Purpose....: Link cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable32::LinkCluster(unsigned int Cluster, unsigned int Link)
{
}

/*##########################################################################
#
#   Name       : TFatTable32::UnlinkCluster
#
#   Purpose....: Unlink cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable32::UnlinkCluster(unsigned int Cluster)
{
}

/*##########################################################################
#
#   Name       : TFatTable32::FreeCluster
#
#   Purpose....: Free cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable32::FreeCluster(unsigned int Cluster)
{
}
