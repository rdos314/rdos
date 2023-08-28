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
# tab16.cpp
# 16-bit Fat table class
#
########################################################################*/

#include "tab16.h"

/*##########################################################################
#
#   Name       : TFatTable16::TFatTable6
#
#   Purpose....: Fat table16 constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatTable16::TFatTable16(TPartServer *Server)
 :  TFatTable(Server)
{
    FClusters = 0;
    FReqEntry = 0;
    FTab = 0;

    SetCacheSize(4);
}

/*##########################################################################
#
#   Name       : TFatTable16::~TFatTable16
#
#   Purpose....: Fat table16 destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatTable16::~TFatTable16()
{
}

/*##########################################################################
#
#   Name       : TFatTable16::Setup
#
#   Purpose....: Setup parameters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable16::Setup(int SectorsPerCluster, long long StartSector, int FatSectors, unsigned int Clusters)
{
    FSectorsPerCluster = SectorsPerCluster;
    FStartSector = StartSector;

    if (FatSectors * 512 / 2 < Clusters)
        FClusters = FatSectors * 512 / 2;
    else
        FClusters = Clusters;
}

/*##########################################################################
#
#   Name       : TFatTable16::SetCacheSize
#
#   Purpose....: Set cache size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable16::SetCacheSize(int size)
{
    FCachedSectors = size;
    FCachedClusters = size * 512 / 2;
}

/*##########################################################################
#
#   Name       : TFatTable16::GetFreeInBlock
#
#   Purpose....: Get free clusters in block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable16::GetFreeInBlock(long long Sector, unsigned int Clusters)
{
    unsigned int i;
    unsigned int FreeClusters = 0;
    TPartReqEntry e1(&FReq, Sector, 8);
    short int *tab;

    FReq.WaitForever();

    tab = (short int *)e1.Map();

    for (i = 0; i < Clusters; i++)
        if (tab[i] == 0)
            FreeClusters++;

    return FreeClusters;
}

/*##########################################################################
#
#   Name       : TFatTable16::GetFreeClusters
#
#   Purpose....: Get free clusters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable16::GetFreeClusters()
{
    unsigned int FreeClusters = 0;
    int i;
    long long Sector = FStartSector;
    unsigned int Cluster = 0;
    int Count;
    int Blocks = FClusters / 512 * 2 / 8;

    for (i = 0; i <= Blocks; i++)
    {
        Count = FClusters - Cluster;
        if (Count > 512 * 8 / 2)
            Count = 512 * 8 / 2;

        FreeClusters += GetFreeInBlock(Sector, Count);
        Sector += 8;
        Cluster += Count;
    }

    return FreeClusters;
}

/*##########################################################################
#
#   Name       : TFatTable16::FormatClusters
#
#   Purpose....: Format clusters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable16::FormatClusters()
{
    return 0;
}

/*##########################################################################
#
#   Name       : TFatTable16::GetClusterLink
#
#   Purpose....: Get cluster link
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable16::GetClusterLink(unsigned int Cluster)
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
        RelSector = Cluster / 512 * 2;
        FStartCluster = RelSector * 512 / 2;
        Sector = FStartSector + RelSector;
        FReqEntry = new TPartReqEntry(&FReq, Sector, FCachedSectors);
        FReq.WaitForever();
        FTab = (unsigned short int *)FReqEntry->Map();
    }

    return FTab[Cluster - FStartCluster];
}
