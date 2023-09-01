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

#include <memory.h>
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
    FAllocateCluster = 2;
    FModReq = 0;
    FModTab = 0;

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

    FFreeClusters = FreeClusters;

    return FreeClusters;
}

/*##########################################################################
#
#   Name       : TFatTable16::FormatBlock
#
#   Purpose....: Format block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable16::FormatBlock(long long Sector, unsigned int Clusters)
{
    unsigned int i;
    unsigned int FreeClusters = 0;
    TPartReqEntry e1(&FReq, Sector, 8, true);
    char *tab;

    FReq.WaitForever();

    tab = (char *)e1.Map();

    memset(tab, 0, 2 * Clusters);

    if (Sector == FStartSector)
    {
        tab[0] = 0xF8;
        tab[1] = 0xFF;
        tab[2] = 0xFF;
        tab[3] = 0xFF;
    }

    tab += 2 * Clusters;
    memset(tab, 0xFF, 0x1000 - 2 * Clusters);

    e1.Write();

    return Clusters;
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

        FreeClusters += FormatBlock(Sector, Count);
        Sector += 8;
        Cluster += Count;
    }

    return FreeClusters;
}

/*##########################################################################
#
#   Name       : TFatTable16::UpdateMod
#
#   Purpose....: Update modify
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable16::UpdateMod()
{
    if (FModReq)
    {
        FModReq->Write();
        delete FModReq;
        FModReq = 0;
    }
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

    UpdateMod();

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

/*##########################################################################
#
#   Name       : TFatTable16::AllocateCluster
#
#   Purpose....: Allocate cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable16::AllocateCluster()
{
    int RelSector;
    long long Sector;
    unsigned int Cluster = 0;
    int offset;
    int size;
    int i;
    bool Restarted = false;

    if (FFreeClusters == 0)
        return 0;

    if (FReqEntry)
    {
        delete FReqEntry;
        FReqEntry = 0;
    }

    UpdateMod();

    for (;;)
    {
        RelSector = FAllocateCluster / 512 * 2;
        FModCluster = RelSector * 512 / 2;
        Sector = FStartSector + RelSector;

        FModReq = new TPartReqEntry(&FReq, Sector, 1, false);
        FReq.WaitForever();
        FModTab = (unsigned short int *)FModReq->Map();

        offset = FAllocateCluster % 256;
        size = 256 - offset;

        for (i = offset; i < size; i++)
        {
            if (FModTab[i] == 0)
            {
                Cluster = FModCluster + i;
                break;
            }
        }

        if (Cluster)
        {
            FModTab[Cluster - FModCluster] = 0xFFFF;
            FAllocateCluster = Cluster + 1;
            return Cluster;
        }

        delete FModReq;
        FModReq = 0;
        FModCluster = 0;
        FModTab = 0;

        FAllocateCluster = FModCluster + 256;
        if (FAllocateCluster > FClusters)
        {
            FAllocateCluster = 2;

            if (Restarted)
            {
                FFreeClusters = 0;
                return 0;
            }
            else
                Restarted = true;
        }
    }

    return 0;
}

/*##########################################################################
#
#   Name       : TFatTable16::ReserveCluster
#
#   Purpose....: Reserve cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatTable16::ReserveCluster(unsigned int Cluster)
{
    int RelSector;
    long long Sector;

    if (FReqEntry)
    {
        delete FReqEntry;
        FReqEntry = 0;
    }

    UpdateMod();

    RelSector = Cluster / 512 * 2;
    FModCluster = RelSector * 512 / 2;
    Sector = FStartSector + RelSector;

    FModReq = new TPartReqEntry(&FReq, Sector, 1, false);
    FReq.WaitForever();
    FModTab = (unsigned short int *)FModReq->Map();

    if (FModTab[Cluster - FModCluster] == 0)
    {
        FModTab[Cluster - FModCluster] = 0xFFFF;
        return true;
    }
    else
    {
        delete FModReq;
        FModReq = 0;
        FModCluster = 0;
        FModTab = 0;
        return false;
    }
}

/*##########################################################################
#
#   Name       : TFatTable16::LinkCluster
#
#   Purpose....: Link cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable16::LinkCluster(unsigned int Cluster, unsigned int Link)
{
}

/*##########################################################################
#
#   Name       : TFatTable16::UnlinkCluster
#
#   Purpose....: Unlink cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable16::UnlinkCluster(unsigned int Cluster)
{
}

/*##########################################################################
#
#   Name       : TFatTable16::FreeCluster
#
#   Purpose....: Free cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable16::FreeCluster(unsigned int Cluster)
{
}

/*##########################################################################
#
#   Name       : TFatTable16::Complete
#
#   Purpose....: Complete cluster updates
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable16::Complete()
{
}
