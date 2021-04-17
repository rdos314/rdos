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
# fs.cpp
# Fat FS class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <rdos.h>
#include <serv.h>
#include "fatfs.h"
#include "tab12.h"
#include "tab16.h"
#include "tab32.h"
#include "md5.h"

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

struct TFatInfo
{
    int ExtSign;
    char Resv[480];
    int InfoSign;
    int FreeClusters;
    int NextCluster;
};

/*##########################################################################
#
#   Name       : ThreadStartup
#
#   Purpose....: Startup procedure for thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void ThreadStartup(void *ptr)
{
    ((TFat *)ptr)->Test();
}

/*##########################################################################
#
#   Name       : TFat::TFat
#
#   Purpose....: Fat constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat::TFat()
{
    Tab1 = 0;
    Tab2 = 0;
}

/*##########################################################################
#
#   Name       : TFat::~TFat
#
#   Purpose....: Fat destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat::~TFat()
{
    if (Tab1)
        delete Tab1;

    if (Tab2)
        delete Tab2;
}

/*##########################################################################
#
#   Name       : TFat::ProcessBootSector
#
#   Purpose....: Process boot sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat::ProcessBootSector(const char *FsName)
{
    char Name[6];
    long long TotalSectors;
    struct TBootSector *boot;
    TDiscReq req(&Server);
    TDiscReqEntry e1(&req, 0, 1);

    req.WaitForever();

    boot = (struct TBootSector *)e1.Map();

    if (!boot)
    {
        printf("Cannot read boot sector\r\n");
        return false;
    }

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
        printf("No FAT size specified\r\n");
        return false;
    }

    if (boot->BytesPerSector != 512)
    {
        printf("Unexpected bytes per sector: %d\r\n", boot->BytesPerSector);
        return false;
    }

    TotalSectors = Server.GetPartSectors();

    FatCount = boot->FatCount;
    SectorsPerCluster = boot->SectorsPerCluster;
    ReservedSectors = boot->ResvSectors;

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
        printf("Partition size mismatch: Part: %lld, Boot: %lld\r\n", TotalSectors, PartSectors);
        return false;
    }

    if (FatSectors == 0)
    {
        printf("No FAT sectors\r\n");
        return false;
    }

    if (FatCount != 2)
    {
        printf("Must have 2 FAT tables\r\n");
        return false;
    }

    if (SectorsPerCluster <= 0)
    {
        printf("Invalid sectors per cluster: %d\r\n", SectorsPerCluster);
        return false;
    }

    return true;
}

/*##########################################################################
#
#   Name       : TFat::ProcessInfoSector
#
#   Purpose....: Process info sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat::ProcessInfoSector()
{
    TDiscReq req(&Server);
    TDiscReqEntry e1(&req, InfoSector, 1);
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
#   Name       : TFat::CreateTables
#
#   Purpose....: Create tables
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFat::CreateTables()
{
    int Free1;
    int Free2;

    Fat1Sector = ReservedSectors;
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
    FreeClusters = 0;

    switch (FatSize)
    {
        case 12:
            if (Clusters > 0x1000)
                Clusters = 0x1000;

            Tab1 = new TFatTable12(&Server, SectorsPerCluster, Fat1Sector, FatSectors, Clusters);
            Tab2 = new TFatTable12(&Server, SectorsPerCluster, Fat2Sector, FatSectors, Clusters);
            break;

        case 16:
            if (Clusters > 0x10000)
                Clusters = 0x10000;

            Tab1 = new TFatTable16(&Server, SectorsPerCluster, Fat1Sector, FatSectors, Clusters);
            Tab2 = new TFatTable16(&Server, SectorsPerCluster, Fat2Sector, FatSectors, Clusters);
            break;

        case 32:
            if (Clusters > 0x100000)
                if (InfoSector)
                    ProcessInfoSector();

            Tab1 = new TFatTable32(&Server, SectorsPerCluster, Fat1Sector, FatSectors, Clusters);
            Tab2 = new TFatTable32(&Server, SectorsPerCluster, Fat2Sector, FatSectors, Clusters);
            break;
    }

    if (!FreeClusters)
    {
        Free1 = Tab1->GetFreeClusters();
        Free2 = Tab2->GetFreeClusters();

        if (Free1 > Free2)
            FreeClusters = Free2;
        else
            FreeClusters = Free1;
    }
}

/*##########################################################################
#
#   Name       : VerifySector
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFat::VerifySector(int id, char *buf)
{
    TMd5Hash hash;
    char hbuf[16];
    int cid;
    int year, month, day, hour;
    int min, sec, ms, us;
    unsigned long lsb, msb;

    hash.Add(buf + 16, 512 - 16);
    hash.GetHashData(hbuf);

    if (memcmp(hbuf, buf, 16))
        printf("Wrong hash\r\n");
    else
    {
        memcpy(&cid, buf + 16, 4);
        if (id != cid)
        {
            RdosGetTime(&msb, &lsb);
            RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
            RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);
            printf("%04d-%02d-%02 %02d.%02d.%02d,%03d.%03d Wrong sector, expected: %d, found: %d \r\n", year, month, day, hour, min, sec, ms, us, id, cid);
        }
    }
}

/*##########################################################################
#
#   Name       : TFat::GetSectors
#
#   Purpose....: Get sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFat::GetSectors(TDiscReq *Req, long long Sector, int Count)
{
    int i;
    TDiscReqEntry e1(Req, Sector, Count);
    char *ptr;
    int id = (int)(Sector + 0x10 - 100000);

    Req->WaitForever();

    if (Req->IsDone())
    {
        ptr = e1.Map();

        for (i = 0; i < Count; i++)
        {
            VerifySector(id + i, ptr);
            ptr += 512;
        }
    }
    else
        printf("Not done, sector: %lld\r\n");

}

/*##########################################################################
#
#   Name       : TFat::Test
#
#   Purpose....: Test read interface
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFat::Test()
{
    TDiscReq Req(&Server);
    int count;
    long long sector;
    int delay;

    for (;;)
    {
        count = 1 + RdosGetRandom(127);
        sector = 400000 - 0x10 + RdosGetRandom(600000 - count);
        delay = RdosGetRandom(30);

//        printf("Start: %lld, Count: %d\r\n", sector, count);

        GetSectors(&Req, sector, count);

        RdosWaitMilli(delay);
    }
}

/*##########################################################################
#
#   Name       : TFat::Run
#
#   Purpose....: Run
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFat::Run(const char *FsName)
{
    bool ok;

    ok = ProcessBootSector(FsName);
    if (ok)
        CreateTables();

    RdosCreateThread(ThreadStartup, "Disc Test 1", this, 0x4000);
    RdosCreateThread(ThreadStartup, "Disc Test 2", this, 0x4000);
    RdosCreateThread(ThreadStartup, "Disc Test 3", this, 0x4000);
    RdosCreateThread(ThreadStartup, "Disc Test 4", this, 0x4000);
    RdosCreateThread(ThreadStartup, "Disc Test 5", this, 0x4000);
    RdosCreateThread(ThreadStartup, "Disc Test 6", this, 0x4000);
    RdosCreateThread(ThreadStartup, "Disc Test 7", this, 0x4000);
    RdosCreateThread(ThreadStartup, "Disc Test 8", this, 0x4000);
    RdosCreateThread(ThreadStartup, "Disc Test 9", this, 0x4000);
    RdosCreateThread(ThreadStartup, "Disc Test 10", this, 0x4000);

    ServTest();

    while (ok)
        ok = ProcessMsg();
}
