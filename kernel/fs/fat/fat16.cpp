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
unsigned int TFat16::Adjust(TPartServer *Server)
{
    long long Start = Server->GetPartStartSector();
    long long Count = Server->GetPartSectors();
    long long pos = Start;
    unsigned int size;
    long long diff;

    pos = pos / 8;
    pos = 8 * pos + 7;

    if (Count < 0xFFFFFFFF)
        size = (unsigned int)Count;
    else
        size = 0xFFFFFFFF;

    diff = pos - Start;
    size -= (int)diff;

    if (Server->MovePartUp(diff))
        return size;
    else
        return 0;
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
            Clusters = Used / ClusterSize + 2;
            FatSectors = 2 * Clusters / 512;
            FatSectors--;
            FatSectors = FatSectors / 8;
            FatSectors = 8 * FatSectors;
            Used = size - ROOT_DIR_SECTORS - 1 - 2 * FatSectors;
        } 

        if (Clusters < 65525)
            break;

        ClusterSize = 2 * ClusterSize;
    }    

    return ClusterSize;
}

/*##########################################################################
#
#   Name       : TFat16::CalcClusterCount
#
#   Purpose....: Calculate cluster count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned short int TFat16::CalcClusterCount(unsigned int TotalSectors, unsigned int ClusterSize)
{
    unsigned int Clusters;
    unsigned int FatSectors;
    unsigned int Used;
    int tries;

    Used = TotalSectors - ROOT_DIR_SECTORS - 1;
    for (tries = 0; tries < 3; tries++)
    { 
        Clusters = Used / ClusterSize + 2;
        FatSectors = 2 * Clusters / 512;
        FatSectors--;
        FatSectors = FatSectors / 8;
        FatSectors = 8 * FatSectors;
        Used = TotalSectors - ROOT_DIR_SECTORS - 1 - 2 * FatSectors;
    } 

    Used = Clusters * ClusterSize + 2 * FatSectors + ROOT_DIR_SECTORS + 1;

    while (Used > TotalSectors)
    {
        Clusters--;
        Used -= ClusterSize;
    }

    while (Clusters < 65524 && Used + ClusterSize < TotalSectors)
    {
        Clusters++;
        Used += ClusterSize;
    }

    return (unsigned short int)Clusters;
}

/*##########################################################################
#
#   Name       : TFat16::CalcFatSectors
#
#   Purpose....: Calculate FAT sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned short int TFat16::CalcFatSectors(unsigned int Clusters)
{
    unsigned short int FatSectors;

    FatSectors = (unsigned short int)(2 * Clusters / 512);
    FatSectors--;
    FatSectors = FatSectors / 8;
    FatSectors = 8 * FatSectors;

    return FatSectors;
}

/*##########################################################################
#
#   Name       : TFat16::InitFs
#
#   Purpose....: Validate before format
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat16::InitFs(TPartServer *Server, struct TBootSector12_16 *boot)
{
    long long Diff;
    unsigned int Size;
    unsigned int ClusterSize;
    unsigned short int Clusters;
    unsigned short int FatSectors;
    unsigned long lsb, msb;
    int handle = Server->GetHandle();

    RdosGetSysTime(&msb, &lsb);

    Size = Adjust(Server);

    ClusterSize = CalcClusterSize(Size);
    Clusters = CalcClusterCount(Size, ClusterSize);
    FatSectors = CalcFatSectors(Clusters);

    Clusters = FatSectors * 512 / 2;
    Size = (Clusters - 2) * ClusterSize + 2 * FatSectors + ROOT_DIR_SECTORS + 1;

    if (Size > 0xFFFF)
    {
        boot->base.Sectors = Size;
        boot->base.SectorCount16 = 0;
    }
    else
    {
        boot->base.Sectors = 0;
        boot->base.SectorCount16 = (unsigned short int)Size;
    }

    boot->base.SectorsPerCluster = (char)ClusterSize;
    boot->base.ResvSectors = 1;
    boot->base.FatCount = 2;
    boot->base.RootDirEntries = 512 * ROOT_DIR_SECTORS / 32;
    boot->base.Media = 0xF8;
    boot->base.FatSectors16 = FatSectors;
    boot->base.SectorsPerCyl = -1;
    boot->base.Heads = -1;
    boot->base.HiddenSectors = 0;

    boot->ext.DriveNr = 0x80;
    boot->ext.Resv1 = 0;
    boot->ext.Sign = 0x29;

    boot->ext.VolumeId = lsb;
    strcpy(boot->ext.VolumeLabel, "NO NAME    ");
    strcpy(boot->ext.FsName, "FAT16   ");

    Diff = Server->GetPartSectors() - (long long)Size;
    Server->ShrinkPart(Diff);

    if (Clusters < 4085)
        return false;
    else
        return true;
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
TFat16::TFat16(TPartServer *server, struct TBootSector12_16 *boot, bool format)
  : TFat(server, (struct TBaseBootSector *)boot),
    Tab1(server),
    Tab2(server)
{
    int Free1;
    int Free2;

    FServer = server;

    if (format)
        WriteBootSector(boot);

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

        Clusters = (unsigned int)((PartSectors - StartSector) / SectorsPerCluster + 2);

        if (Clusters > 0xFFF0)
            Clusters = 0xFFF0;

        Tab1.Setup(SectorsPerCluster, Fat1Sector, FatSectors, Clusters);
        Tab2.Setup(SectorsPerCluster, Fat2Sector, FatSectors, Clusters);

        if (format)
        {
            Free1 = Tab1.FormatClusters();
            Free2 = Tab2.FormatClusters();

            if (Free1 > Free2)
                FreeClusters = Free2;
            else
                FreeClusters = Free1;

            FormatFixedDir(RootSector, RootDirEntries);
        }
        else
        {
            Free1 = Tab1.GetFreeClusters();
            Free2 = Tab2.GetFreeClusters();

            if (Free1 > Free2)
                FreeClusters = Free2;
            else
                FreeClusters = Free1;
        }
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
#   Name       : TFat16::WriteBootSector
#
#   Purpose....: Write boot sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFat16::WriteBootSector(struct TBootSector12_16 *BootSector)
{
    TPartReq req(FServer);
    TPartReqEntry e1(&req, 0, 1, false);
    char *Data;

    req.WaitForever();

    Data = (char *)e1.Map();
    memcpy(Data, BootSector, 512);

    e1.Write();
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
