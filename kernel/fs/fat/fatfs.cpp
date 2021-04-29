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
#include "dir.h"
#include "cluster.h"

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
TFat::TFat(TDiscServer *server, struct TBootSector *boot)
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

    TotalSectors = Server->GetPartSectors();

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
#   Name       : TFat::ProcessDir
#
#   Purpose....: Process dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFat::ProcessDir(struct TFatDirEntry *entry)
{
}

/*##########################################################################
#
#   Name       : TFat::GetDir
#
#   Purpose....: Get dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFat::GetDir(unsigned int Cluster)
{
    TDiscReq Req(Server);
    TCluster Chain;
    unsigned int NextCluster1;
    unsigned int NextCluster2;
    unsigned int *ClusterArr;
    TDiscReqEntry **ReqArr;
    int size;
    int i, j, k;
    long long Sector;
    struct TFatDirEntry *DirEntry;

    while (Cluster && Cluster < Clusters)
    {
        Chain.Add(Cluster);

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

    size = Chain.GetSize();
    ClusterArr = Chain.GetChain();

    if (size)
    {
        ReqArr = new TDiscReqEntry *[size];

        for (i = 0; i < size; i++)
        {
            Sector = StartSector + (ClusterArr[i] - 2) * SectorsPerCluster; 
            ReqArr[i] = new TDiscReqEntry(&Req, Sector, SectorsPerCluster);
        } 

        Req.WaitForever();

        if (Req.IsDone())
        {
            for (i = 0; i < size; i++)
            {
                DirEntry = (struct TFatDirEntry *)ReqArr[i]->Map();

                for (j = 0; j < SectorsPerCluster; j++)
                {
                    for (k = 0; k < 16; k++)
                    {
                        ProcessDir(DirEntry);
                        DirEntry++;
                    }
                }
            }
        }
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
void TFat::GetSectors(TDiscReq *Req, long long Sector, int Count)
{
    int i;
    TDiscReqEntry e1(Req, Sector, Count);
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
    TDiscReq Req(Server);
    int count;
    long long sector;
    int delay;

    while (Server->IsActive())
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
void TFat::Run()
{
    bool ok;
    struct TDirEntry *e;

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

    GetDir(2);

    Server->WaitForMsg(this);

}
