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
# fatboot.cpp
# Fat boot class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <rdos.h>
#include "fatboot.h"

struct TBootSector
{
    char Jmp[3];
    char Name[8];
    short int BytesPerSector;
    char SectorsPerCluster;
    short int ResvSectors;
    char FatCount;
    short int RootDirEntries;
    unsigned short int SectorCount16;
    char Media;
    short int FatSectors16;
    short int SectorsPerCyl;
    short int Heads;
    int HiddenSectors;
    unsigned int Sectors;
    int FatSectors;
    short int ExtFlags;
    short int FsVersion;
    int RootCluster;
    short int InfoSector;
    short int BackupSector;
    short int Pad;
    char FsName[8];
};

/*##########################################################################
#
#   Name       : TFatBoot::TFatBoot
#
#   Purpose....: Fat boot constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatBoot::TFatBoot(TDiscServer *Server, const char *FsName)
{
    char Name[6];
    long long TotalSectors;
    struct TBootSector *boot;
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, 0, 1);

    req.WaitForever();

    boot = (struct TBootSector *)e1.Map();

    if (boot)
        FValid = true;
    else
    {
        printf("Cannot read boot sector");
        FValid = false;
    }

    if (FValid)
    {
        FatSize = 0;

        memcpy(Name, boot->FsName, 5);
        Name[5] = 0;

        if (!strcmp(Name, "FAT12"))
            FatSize = 12;

        if (!strcmp(Name, "FAT16"))
            FatSize = 16;

        if (!strcmp(Name, "FAT32"))
            FatSize = 32;

        if (!FatSize)
        {
            memcpy(Name, FsName, 5);
            Name[5] = 0;

            if (!strcmp(Name, "FAT12"))
                FatSize = 12;

            if (!strcmp(Name, "FAT16"))
                FatSize = 16;

            if (!strcmp(Name, "FAT32"))
                FatSize = 32;
        }

        if (!FatSize)
        {
            printf("No FAT size specified");
            FValid = false;
        }
    }

    if (FValid)
    {
        if (boot->BytesPerSector != 512)
        {
            printf("Unexpected bytes per sector: %d", boot->BytesPerSector);
            FValid = false;
        }
    }

    if (FValid)
    {
        TotalSectors = Server->GetPartSectors();

        FatCount = boot->FatCount;
        SectorsPerCluster = boot->SectorsPerCluster;

        if (FatSize == 32)
        {
            PartSectors = boot->Sectors;
            if (!PartSectors)
                PartSectors = boot->SectorCount16;

            FatSectors = boot->FatSectors;
            if (!FatSectors)
                FatSectors = boot->FatSectors16;

            RootDirEntries = 0;
            RootCluster = boot->RootCluster;
            InfoSector = boot->InfoSector;

            if (!RootCluster)
            {
                FatSize = 16;
                RootDirEntries = boot->RootDirEntries;
            }
        }
        else
        {
            PartSectors = boot->SectorCount16;
            if (!PartSectors)
                PartSectors = boot->Sectors;

            FatSectors = boot->FatSectors16;
            if (!FatSectors)
                FatSectors = boot->FatSectors;

            RootDirEntries = boot->RootDirEntries;
            RootCluster = 0;
            InfoSector = 0;

            if (!RootDirEntries)
            {
                FatSize = 32;
                RootCluster = boot->RootCluster;
                InfoSector = boot->InfoSector;
            }
        }

        if (TotalSectors < PartSectors)
        {
            printf("Partition size mismatch: Part: %lld, Boot: %lld", TotalSectors, PartSectors);
            FValid = false;
        }
    }

    if (FValid)
    {
        if (FatSectors == 0)
        {
            printf("No FAT sectors");
            FValid = false;
        }
    }

    if (FValid)
    {
        if (FatCount != 2)
        {
            printf("Must have 2 FAT tables");
            FValid = false;
        }
    }

    if (FValid)
    {
        if (SectorsPerCluster <= 0)
        {
            printf("Invalid sectors per cluster: %d", SectorsPerCluster);
            FValid = false;
        }
    }

    if (FValid)
    {
        Fat1Sector = boot->ResvSectors;
        Fat2Sector = Fat1Sector + FatSectors;

        if (FatSize == 32)
        {
            RootSector = 0;
            StartSector = Fat2Sector + FatSectors;
        }
        else
        {
            RootSector = Fat2Sector + FatSectors;
            StartSector = RootSector + RootDirEntries / 16;
        }

        Clusters = PartSectors / SectorsPerCluster + 2;
    }
    else
    {
        Fat1Sector = 0;
        Fat2Sector = 0;
        StartSector = 0;
        Clusters = 0;
    }
}

/*##########################################################################
#
#   Name       : TFatBoot::~TFatBoot
#
#   Purpose....: Fat boot destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatBoot::~TFatBoot()
{
}

/*##########################################################################
#
#   Name       : TFatBoot::IsValid
#
#   Purpose....: Check if valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatBoot::IsValid()
{
    return FValid;
}
