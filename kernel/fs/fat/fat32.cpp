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
# fat32.cpp
# Fat32 class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <rdos.h>
#include <serv.h>
#include "fat32.h"

struct TFatInfo
{
    int ExtSign;
    char Resv1[480];
    int InfoSign;
    int FreeClusters;
    int NextCluster;
    char Resv2[12];
    int TrailSign;
};

#define RESERVED_SECTORS        8

/*##########################################################################
#
#   Name       : TFat32::Adjust
#
#   Purpose....: Adjust size & pos to achieve 4k alignment
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFat32::Adjust(TPartServer *Server)
{
    long long Start = Server->GetPartStartSector();
    long long Count = Server->GetPartSectors();
    long long pos = Start;
    unsigned int size;
    long long diff;

    pos--;
    pos = pos / 8;
    pos = 8 * (pos + 1);

    if (Count < 0xFFFFFFFF)
        size = (unsigned int)Count;
    else
        size = 0xFFFFFFFF;

    diff = pos - Start;
    size -= (unsigned int)diff;

    if (Server->MovePartUp(diff))
        return size;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFat32::CalcClusterSize
#
#   Purpose....: Calculate cluster size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFat32::CalcClusterSize(unsigned int size)
{
    unsigned int ClusterSize;
    unsigned int Clusters;
    unsigned int FatSectors;
    unsigned int Used;
    int tries;

    ClusterSize = 8;
    while (ClusterSize != 64)
    {
        Used = size - RESERVED_SECTORS;
        for (tries = 0; tries < 3; tries++)
        {
            Clusters = Used / ClusterSize + 2;
            FatSectors = 4 * Clusters / 512;
            FatSectors--;
            FatSectors = FatSectors / 8;
            FatSectors = 8 * FatSectors;
            Used = size - RESERVED_SECTORS - 4 * FatSectors;
        }

        if (Clusters < 0x200000)
            break;

        ClusterSize = 2 * ClusterSize;
    }

    return ClusterSize;
}

/*##########################################################################
#
#   Name       : TFat32::CalcClusterCount
#
#   Purpose....: Calculate cluster count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFat32::CalcClusterCount(unsigned int TotalSectors, unsigned int ClusterSize)
{
    unsigned int Clusters;
    unsigned int FatSectors;
    unsigned int Used;
    int tries;

    Used = TotalSectors - RESERVED_SECTORS;
    for (tries = 0; tries < 3; tries++)
    {
        Clusters = Used / ClusterSize + 2;
        FatSectors = 4 * Clusters / 512;
        FatSectors--;
        FatSectors = FatSectors / 8;
        FatSectors = 8 * FatSectors;
        Used = TotalSectors - RESERVED_SECTORS - 4 * FatSectors;
    }

    Used = Clusters * ClusterSize + 4 * FatSectors + RESERVED_SECTORS;

    while (Used > TotalSectors)
    {
        Clusters--;
        Used -= ClusterSize;
    }

    return Clusters;
}

/*##########################################################################
#
#   Name       : TFat32::CalcFatSectors
#
#   Purpose....: Calculate FAT sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFat32::CalcFatSectors(unsigned int Clusters)
{
    unsigned int FatSectors;

    FatSectors = 4 * Clusters / 512;
    FatSectors--;
    FatSectors = FatSectors / 8;
    FatSectors = 8 * FatSectors;

    return FatSectors;
}

/*##########################################################################
#
#   Name       : TFat32::InitFs
#
#   Purpose....: Init before format
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat32::InitFs(TPartServer *server, struct TBootSector32 *boot)
{
    long long Diff;
    unsigned int Size;
    unsigned int ClusterSize;
    unsigned int Clusters;
    unsigned int FatSectors;
    unsigned long lsb, msb;
    int handle = server->GetHandle();

    RdosGetSysTime(&msb, &lsb);

    Size = Adjust(server);

    ClusterSize = CalcClusterSize(Size);
    Clusters = CalcClusterCount(Size, ClusterSize);
    FatSectors = CalcFatSectors(Clusters);

    Clusters = FatSectors * 512 / 4;
    Size = (Clusters - 2) * ClusterSize + 2 * FatSectors + RESERVED_SECTORS;

    boot->base.Sectors = Size;
    boot->base.SectorCount16 = 0;

    boot->base.SectorsPerCluster = (char)ClusterSize;
    boot->base.ResvSectors = RESERVED_SECTORS;
    boot->base.FatCount = 2;
    boot->base.RootDirEntries = 0;
    boot->base.Media = 0xF8;
    boot->base.SectorsPerCyl = -1;
    boot->base.Heads = -1;
    boot->base.HiddenSectors = 0;

    boot->base.FatSectors16 = 0;
    boot->FatSectors = FatSectors;

    boot->ExtFlags = 0;
    boot->FsVersion = 0;
    boot->RootCluster = 2;
    boot->InfoSector = 1;
    boot->BackupSector = 6;
    memset(boot->Resv1, 0, 12);

    boot->ext.DriveNr = 0x80;
    boot->ext.Resv1 = 0;
    boot->ext.Sign = 0x29;

    boot->ext.VolumeId = lsb;
    strcpy(boot->ext.VolumeLabel, "NO NAME    ");
    strcpy(boot->ext.FsName, "FAT32   ");

    Diff = server->GetPartSectors() - (long long)Size;
    server->ShrinkPart(Diff);

    if (Clusters < 65525)
        return false;
    else
        return true;
}

/*##########################################################################
#
#   Name       : TFa32::TFat32
#
#   Purpose....: Fat32 constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat32::TFat32(TPartServer *server, struct TBootSector32 *boot, bool format)
  : TFat(server, (struct TBaseBootSector *)boot),
    Tab1(server),
    Tab2(server)
{
    int Free1;
    int Free2;

    FatSize = 32;
    PartSectors = boot->base.Sectors;
    if (!PartSectors)
        PartSectors = boot->base.SectorCount16;

    FatSectors = boot->FatSectors;
    if (!FatSectors)
        FatSectors = boot->base.FatSectors16;

    RootCluster = boot->RootCluster;
    InfoSector = boot->InfoSector;

    if (Validate())
    {
        FatTable1 = &Tab1;
        FatTable2 = &Tab2;

        Fat1Sector = ReservedSectors;
        Fat2Sector = Fat1Sector + FatSectors;
        StartSector = Fat2Sector + FatSectors;

        Clusters = (unsigned int)((PartSectors - StartSector) / SectorsPerCluster + 2);
        FreeClusters = 0;

        if (Clusters > 0xFFFFFFF0)
            Clusters = 0xFFFFFFF0;

        if (!format)
            if (Clusters > 0x200000)
                if (InfoSector)
                    ProcessInfoSector();

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

            TFatDir::InitDir(this, RootCluster);
            WriteBootSector(boot);
        }
        else
        {
            if (!FreeClusters)
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
}

/*##########################################################################
#
#   Name       : TFat32::~TFat32
#
#   Purpose....: Fat32 destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat32::~TFat32()
{
}

/*##########################################################################
#
#   Name       : TFat32::WriteBootSector
#
#   Purpose....: Write boot sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFat32::WriteBootSector(struct TBootSector32 *boot)
{
    TPartReq req(FServer);
    TPartReqEntry e1(&req, 0, RESERVED_SECTORS, true);
    char *Data;
    struct TFatInfo *info;

    req.WaitForever();

    Data = (char *)e1.Map();
    memset(Data, 0, 512 * RESERVED_SECTORS);

    memcpy(Data, boot, 512);
    memcpy(Data + boot->BackupSector * 512, boot, 512);

    info = (struct TFatInfo *)(Data + boot->InfoSector * 512);

    info->ExtSign = 0x41615252;
    info->InfoSign = 0x61417272;
    info->FreeClusters = FreeClusters;
    info->NextCluster = 3;

    memset(info->Resv1, 0, 480);
    memset(info->Resv2, 0, 12);

    info->TrailSign = 0xAA550000;

    info = (struct TFatInfo *)(Data + (boot->BackupSector + boot->InfoSector) * 512);

    info->ExtSign = 0x41615252;
    info->InfoSign = 0x61417272;
    info->FreeClusters = FreeClusters;
    info->NextCluster = 3;

    memset(info->Resv1, 0, 480);
    memset(info->Resv2, 0, 12);

    info->TrailSign = 0xAA550000;

    e1.Write();
}

/*##########################################################################
#
#   Name       : TFat32::ProcessInfoSector
#
#   Purpose....: Process info sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat32::ProcessInfoSector()
{
    TPartReq req(FServer);
    TPartReqEntry e1(&req, InfoSector, 1);
    struct TFatInfo *info;

    req.WaitForever();

    info = (struct TFatInfo *)e1.Map();

    if (!info)
        return false;

    if (info->ExtSign != 0x41615252)
        return false;

    if (info->InfoSign != 0x61417272)
        return false;

    FreeClusters = info->FreeClusters;
    return true;
}

/*##########################################################################
#
#   Name       : TFat32::CacheRootDir
#
#   Purpose....: CacheRootDir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir *TFat32::CacheRootDir()
{
    return CacheDir(0, 0, RootCluster);
}
