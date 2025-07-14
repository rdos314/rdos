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

    FFreeClusters = 0;
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
    unsigned int fc = 0;
    TPartReqEntry e1(&FReq, Sector, 8);
    short int *tab;

    FReq.WaitForever();

    tab = (short int *)e1.Map();

    for (i = 0; i < Clusters; i++)
        if (tab[i] == 0)
            fc++;

    return fc;
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
    int i;
    long long Sector = FStartSector;
    unsigned int Cluster = 0;
    int Count;
    int Blocks = FClusters / 512 * 2 / 8;

    FFreeClusters = 0;

    for (i = 0; i <= Blocks; i++)
    {
        Count = FClusters - Cluster;
        if (Count > 512 * 8 / 2)
            Count = 512 * 8 / 2;

        FFreeClusters += GetFreeInBlock(Sector, Count);
        Sector += 8;
        Cluster += Count;
    }

    return FFreeClusters;
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
    unsigned int fc;
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

        fc = Clusters - 2;
    }
    else
        fc = Clusters;

    e1.Write();

    return fc;
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
    int i;
    long long Sector = FStartSector;
    unsigned int Cluster = 0;
    int Count;
    int Blocks = FClusters / 512 * 2 / 8;

    FFreeClusters = 0;

    for (i = 0; i <= Blocks; i++)
    {
        Count = FClusters - Cluster;
        if (Count > 512 * 8 / 2)
            Count = 512 * 8 / 2;

        FFreeClusters += FormatBlock(Sector, Count);
        Sector += 8;
        Cluster += Count;
    }

    return FFreeClusters;
}

/*##########################################################################
#
#   Name       : TFatTable16::ClearMod
#
#   Purpose....: Clear modify
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable16::ClearMod()
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
#   Name       : TFatTable16::ClearCache
#
#   Purpose....: Clear cache
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable16::ClearCache()
{
    if (FReqEntry)
    {
        delete FReqEntry;
        FReqEntry = 0;
    }
}

/*##########################################################################
#
#   Name       : TFatTable16::SetupCache
#
#   Purpose....: Setup cache
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable16::SetupCache(unsigned int Cluster)
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

    if (FModReq)
        ClearMod();

    if (!FReqEntry)
    {
        RelSector = Cluster / 512 * 2;
        FStartCluster = RelSector * 512 / 2;
        Sector = FStartSector + RelSector;
        FReqEntry = new TPartReqEntry(&FReq, Sector, FCachedSectors);
        FReq.WaitForever();
        FTab = (unsigned short int *)FReqEntry->Map();
    }
}

/*##########################################################################
#
#   Name       : TFatTable16::SetupMod
#
#   Purpose....: Setup modification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable16::SetupMod(unsigned int Cluster)
{
    int RelSector;
    long long Sector;

    if (FReqEntry)
        ClearCache();

    if (!FModReq || Cluster < FModCluster || Cluster >= FModCluster + 512 / 2)
    {
        if (FModReq)
            ClearMod();

        RelSector = Cluster / (512 / 2);
        FModCluster = RelSector * 512 / 2;
        Sector = FStartSector + RelSector;

        FModReq = new TPartReqEntry(&FReq, Sector, 1, false);
        FReq.WaitForever();
        FModTab = (unsigned short int *)FModReq->Map();
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
    SetupCache(Cluster);
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

        offset = FAllocateCluster % (512 / 2);
        size = (256 / 2) - offset;

        for (i = 0; i < size; i++)
        {
            if (FModTab[i + offset] == 0)
            {
                Cluster = FModCluster + i + offset;
                break;
            }
        }

        if (Cluster)
        {
            FModTab[Cluster - FModCluster] = 0xFFFF;
            FWrite = true;
            FAllocateCluster = Cluster + 1;
            FFreeClusters--;
            return Cluster;
        }

        FAllocateCluster = FModCluster + (512 / 2);
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
    SetupMod(Cluster);

    if (FModTab[Cluster - FModCluster] == 0)
    {
        FModTab[Cluster - FModCluster] = 0xFFFF;
        FWrite = true;
        FFreeClusters--;
        return true;
    }
    else
        return false;
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
    SetupMod(Cluster);
    FModTab[Cluster - FModCluster] = (unsigned short int)Link;
    FWrite = true;
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
void TFatTable16::LinkCluster(unsigned int Cluster)
{
    SetupMod(Cluster);
    FModTab[Cluster - FModCluster] = 0xFFFF;
    FWrite = true;
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
    SetupMod(Cluster);
    FModTab[Cluster - FModCluster] = 0;
    FFreeClusters++;
    FWrite = true;
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
    if (FModReq)
        ClearMod();
}
