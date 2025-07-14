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
# tab32.cpp
# 32-bit Fat table class
#
########################################################################*/

#include <memory.h>
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
    FReqEntry = 0;
    FTab = 0;
    FAllocateCluster = 2;
    FModReq = 0;
    FModTab = 0;

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

    FFreeClusters = 0;
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
    unsigned int fc = 0;
    TPartReqEntry e1(&FReq, Sector, 64);
    int *tab;

    FReq.WaitForever();

    tab = (int *)e1.Map();

    for (i = 0; i < Clusters; i++)
        if ((tab[i] & 0xFFFFFFF) == 0)
            fc++;

    return fc;
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
    int i;
    long long Sector = FStartSector;
    unsigned int Cluster = 0;
    int Count;
    int Blocks = FClusters / 512 * 4 / 64;

    FFreeClusters = 0;

    for (i = 0; i <= Blocks; i++)
    {
        Count = FClusters - Cluster;
        if (Count > 512 * 64 / 4)
            Count = 512 * 64 / 4;

        FFreeClusters += GetFreeInBlock(Sector, Count);
        Sector += 64;
        Cluster += Count;
    }

    return FFreeClusters;
}

/*##########################################################################
#
#   Name       : TFatTable32::FormatBlock
#
#   Purpose....: Format block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable32::FormatBlock(long long Sector, unsigned int Clusters)
{
    unsigned int fc;
    TPartReqEntry e1(&FReq, Sector, 8, true);
    char *tab;

    FReq.WaitForever();

    tab = (char *)e1.Map();

    memset(tab, 0, 4 * Clusters);

    if (Sector == FStartSector)
    {
        tab[0] = 0xF8;
        tab[1] = 0xFF;
        tab[2] = 0xFF;
        tab[3] = 0x0F;
        tab[4] = 0xFF;
        tab[5] = 0xFF;
        tab[6] = 0xFF;
        tab[7] = 0x0F;
        tab[8] = 0xFF;
        tab[9] = 0xFF;
        tab[10] = 0xFF;
        tab[11] = 0x0F;

        fc = Clusters - 3;
    }
    else
        fc = Clusters;

    e1.Write();

    return fc;
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
    int i;
    long long Sector = FStartSector;
    unsigned int Cluster = 0;
    int Count;
    int Blocks = FClusters / 512 * 4 / 8;

    FFreeClusters = 0;

    for (i = 0; i <= Blocks; i++)
    {
        Count = FClusters - Cluster;
        if (Count > 512 * 8 / 4)
            Count = 512 * 8 / 4;

        FFreeClusters += FormatBlock(Sector, Count);
        Sector += 8;
        Cluster += Count;
    }

    return FFreeClusters;
}

/*##########################################################################
#
#   Name       : TFatTable32::ClearMod
#
#   Purpose....: Clear modify
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable32::ClearMod()
{
    if (FModReq)
    {
        if (FWrite)
            FModReq->Write();

        FWrite = false;
        delete FModReq;
        FModReq = 0;
    }
}

/*##########################################################################
#
#   Name       : TFatTable32::ClearCache
#
#   Purpose....: Clear cache
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable32::ClearCache()
{
    if (FReqEntry)
    {
        delete FReqEntry;
        FReqEntry = 0;
    }
}

/*##########################################################################
#
#   Name       : TFatTable32::SetupCache
#
#   Purpose....: Setup cache
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable32::SetupCache(unsigned int Cluster)
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
}

/*##########################################################################
#
#   Name       : TFatTable32::SetupMod
#
#   Purpose....: Setup modification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable32::SetupMod(unsigned int Cluster)
{
    int RelSector;
    long long Sector;

    if (FReqEntry)
        ClearCache();

    if (!FModReq || Cluster < FModCluster || Cluster >= FModCluster + 512 / 4)
    {
        if (FModReq)
            ClearMod();

        RelSector = Cluster / (512 / 4);
        FModCluster = RelSector * 512 / 4;
        Sector = FStartSector + RelSector;

        FModReq = new TPartReqEntry(&FReq, Sector, 1, false);
        FReq.WaitForever();
        FModTab = (unsigned int *)FModReq->Map();
    }
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
    SetupCache(Cluster);
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
    unsigned int Cluster = 0;
    int offset;
    int size;
    int i;
    bool Restarted = false;

    if (FFreeClusters == 0)
        return 0;

    for (;;)
    {
        SetupMod(FAllocateCluster);

        offset = FAllocateCluster % (512 / 4);
        size = (512 / 4) - offset;

        for (i = 0; i < size; i++)
        {
            if ((FModTab[i + offset] & 0x0FFFFFFF) == 0)
            {
                Cluster = FModCluster + i + offset;
                break;
            }
        }

        if (Cluster)
        {
            FModTab[Cluster - FModCluster] |= 0x0FFFFFFF;
            FWrite = true;
            FAllocateCluster = Cluster + 1;
            FFreeClusters--;
            return Cluster;
        }

        FAllocateCluster = FModCluster + 512 / 4;
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
    SetupMod(Cluster);

    if ((FModTab[Cluster - FModCluster] & 0x0FFFFFFF) == 0)
    {
        FModTab[Cluster - FModCluster] |= 0x0FFFFFFF;
        FWrite = true;
        FFreeClusters--;
        return true;
    }
    else
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
    unsigned int val;

    SetupMod(Cluster);

    val = FModTab[Cluster - FModCluster];
    val &= 0xF0000000;
    val |= Link & 0x0FFFFFFF;
    FModTab[Cluster - FModCluster] = val;
    FWrite = true;
}

/*##########################################################################
#
#   Name       : TFatTable32::LinkCluster
#
#   Purpose....: Unlink cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable32::LinkCluster(unsigned int Cluster)
{
    SetupMod(Cluster);
    FModTab[Cluster - FModCluster] |= 0x0FFFFFFF;
    FWrite = true;
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
    FAllocateCluster = Cluster;

    SetupMod(Cluster);
    FModTab[Cluster - FModCluster] &= 0xF0000000;
    FFreeClusters++;
    FWrite = true;
}

/*##########################################################################
#
#   Name       : TFatTable32::Complete
#
#   Purpose....: Complete cluster updates
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable32::Complete()
{
    if (FModReq)
        ClearMod();
}
