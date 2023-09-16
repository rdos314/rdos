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
#include <ctype.h>
#include <rdos.h>
#include <serv.h>
#include "fat.h"
#include "fatfs.h"
#include "tab12.h"
#include "tab16.h"
#include "tab32.h"
#include "md5.h"
#include "dir.h"
#include "cluster.h"
#include "fatfile.h"

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
TFat::TFat(TPartServer *server, struct TBaseBootSector *boot)
  : TFs(server)
{
    FatCount = boot->FatCount;
    SectorsPerCluster = boot->SectorsPerCluster;
    ReservedSectors = boot->ResvSectors;

    FatTable1 = 0;
    FatTable2 = 0;
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
}

/*##########################################################################
#
#   Name       : TFat::Validate
#
#   Purpose....: Validate important parameters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat::Validate()
{
    long long TotalSectors;

    TotalSectors = FServer->GetPartSectors();

    if (TotalSectors < PartSectors)
        return false;

    if (FatSectors == 0)
        return false;

    if (FatCount != 2)
        return false;

    if (SectorsPerCluster <= 0)
        return false;

    return true;
}

/*##########################################################################
#
#   Name       : TFat::Format
#
#   Purpose....: Format partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFat::Format(long long *Start, long long *Count)
{
    return 1;
}

/*##########################################################################
#
#   Name       : TFat::GetFreeSectors
#
#   Purpose....: Get free sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TFat::GetFreeSectors()
{
    return (long long)FreeClusters * (long long)SectorsPerCluster;
}

/*##########################################################################
#
#   Name       : TFat::FormatFixedDir
#
#   Purpose....: FormatFixedDir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFat::FormatFixedDir(long long RootSector, int RootDirEntries)
{
    int Sectors = RootDirEntries / 16;
    TPartReq Req(FServer);
    TPartReqEntry ReqEntry(&Req, RootSector, Sectors, true);
    char *data;

    Req.WaitForever();

    data = (char *)ReqEntry.Map();

    memset(data, 0, 512 * Sectors);

    ReqEntry.Write();
}

/*##########################################################################
#
#   Name       : TFat::CacheFixedDir
#
#   Purpose....: CacheFixedDir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir *TFat::CacheFixedDir(long long RootSector, int RootDirEntries)
{
    return new TFatDir(this, RootSector, RootDirEntries / 16);
}

/*##########################################################################
#
#   Name       : TFat::CacheDir
#
#   Purpose....: Cache dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir *TFat::CacheDir(TDir *ParentDir, int ParentIndex, long long Inode)
{
    return new TFatDir(this, ParentDir, ParentIndex, Inode);
}

/*##########################################################################
#
#   Name       : TFat::GetClusterChain
#
#   Purpose....: Get cluster chain
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCluster *TFat::GetClusterChain(unsigned int Cluster)
{
    TPartReq Req(FServer);
    TCluster *Chain;
    unsigned int NextCluster1;
    unsigned int NextCluster2;

    Chain = new TCluster;

    while (Cluster && Cluster < Clusters)
    {
        Chain->Add(Cluster);

        NextCluster1 = FatTable1->GetClusterLink(Cluster);
        NextCluster2 = FatTable2->GetClusterLink(Cluster);

        if (NextCluster1 == NextCluster2)
            Cluster = NextCluster1;
        else
        {
            if (NextCluster1 >= Clusters && NextCluster2 >= Clusters)
                break;

            if (NextCluster1 < Clusters && NextCluster2 < Clusters)
                break;

            if (NextCluster1 > NextCluster2)
                Cluster = NextCluster2;
            else
                Cluster = NextCluster1;
        }
    }

    return Chain;
}

/*##########################################################################
#
#   Name       : TFat::OpenFile
#
#   Purpose....: Open file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TFat::OpenFile(TDir *ParentDir, int ParentIndex, long long Inode)
{
    unsigned int Cluster = Inode;
    TFile *File = new TFatFile(this, ParentDir, ParentIndex, Cluster, FBytesPerSector, FOffsetSector);
    return File;
}

/*##########################################################################
#
#   Name       : TFat::AllocateCluster
#
#   Purpose....: Allocate cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFat::AllocateCluster()
{
    unsigned int Cluster;
    unsigned int Link;

    while (!FStopped)
    {
        Cluster = FatTable1->AllocateCluster();

        if (!Cluster)
            return 0;

        if (FatTable2->ReserveCluster(Cluster))
            return Cluster;
        else
        {
            Link = FatTable2->GetClusterLink(Cluster);
            FatTable1->LinkCluster(Cluster, Link);
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TFat::Complete
#
#   Purpose....: Complete FAT table modification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFat::Complete()
{
    FatTable1->Complete();
    FatTable2->Complete();
}

/*##########################################################################
#
#   Name       : TFat::CreateDir
#
#   Purpose....: Create dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat::CreateDir(TDir *ParentDir, const char *Name)
{
    TFatDir *dir = (TFatDir *)ParentDir;
    bool ok;

    ok = dir->CreateDirEntry(Name);
    Complete();

    return ok;
}

/*##########################################################################
#
#   Name       : TFat::CreateFile
#
#   Purpose....: Create file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat::CreateFile(TDir *ParentDir, const char *Name, int Attrib)
{
    TFatDir *dir = (TFatDir *)ParentDir;
    char fattr = EncodeAttrib(Attrib);
    bool ok;

    if (fattr & 0x10)
        ok = false;
    else
        ok = dir->CreateFileEntry(Name, 0, fattr);

    Complete();

    return ok;
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
bool TFat::VerifySector(int id, char *buf)
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
            printf("%04d-%02d-%02d %02d.%02d.%02d,%03d.%03d Wrong sector, expected: %d, found: %d", year, month, day, hour, min, sec, ms, us, id, cid);
            return false;
        }
    }
    return true;
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
void TFat::GetSectors(TPartReq *Req, long long Sector, int Count)
{
    int i;
    TPartReqEntry e1(Req, Sector, Count);
    char *ptr;
    bool ok;
    int id = (int)(Sector + 0x10 - 100000);

    Req->WaitForever();

    if (Req->IsDone())
    {
        ptr = e1.Map();

        for (i = 0; i < Count; i++)
        {
            ok = VerifySector(id + i, ptr);
            if (!ok)
                printf(" Start: %lld, %d (%d)\r\n", Sector, i, Count);
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
    TPartReq Req(FServer);
    int count;
    long long sector;
    int delay;

    while (FServer->IsActive())
    {
        count = 1 + RdosGetRandom(127);
        sector = 400000 - 0x10 + RdosGetRandom(600000 - count);
        delay = RdosGetRandom(30);

//        printf("Start: %lld, Count: %d\r\n", sector, count);

        GetSectors(&Req, sector, count);

        RdosWaitMilli(delay);
    }
}
