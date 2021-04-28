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
TFat::TFat(TDiscServer *server)
  : TFs(server)
{
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
void TFat::Run(const char *FsName)
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


    TDir d(567);

    e = d.Add("test", 123);
    e = d.Add("tre", 0xAA9876);
    e = d.Add("more.dat", 456);
    e = d.Add("fyra", 0xAA);
    e = d.Add("sista", 0xCCEE);

    Server->WaitForMsg(this);

}
