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
# gptdisc.cpp
# GPT disc class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <rdos.h>
#include <serv.h>
#include "gptdisc.h"

/*##########################################################################
#
#   Name       : UuidToStr
#
#   Purpose....: Convert UUID to string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void UuidToStr(const char *uuid, char *str)
{
    int ival;
    int *ip;
    short int sval;
    short int *sp;

    ip = (int *)uuid;
    ival = *ip;
    sprintf(str, "%08lX-", ival);

    sp = (short int *)(uuid + 4); 
    sval = *sp;
    sprintf(str+9, "%04hX-", sval);
    
    sp = (short int *)(uuid + 6); 
    sval = *sp;
    sprintf(str+14, "%04hX-", sval);

    sp = (short int *)(uuid + 8); 
    sval = RdosSwapShort(*sp);
    sprintf(str+19, "%04hX-", sval);

    sp = (short int *)(uuid + 10); 
    sval = RdosSwapShort(*sp);
    sprintf(str+24, "%04hX", sval);

    sp = (short int *)(uuid + 12); 
    sval = RdosSwapShort(*sp);
    sprintf(str+28, "%04hX", sval);

    sp = (short int *)(uuid + 14); 
    sval = RdosSwapShort(*sp);
    sprintf(str+32, "%04hX", sval);
}

/*##########################################################################
#
#   Name       : TGptTable::TGptTable
#
#   Purpose....: Constructor for GPT table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGptTable::TGptTable()
{
}

/*##########################################################################
#
#   Name       : TGptTable::~TGptTable
#
#   Purpose....: Destructor for GPT table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGptTable::~TGptTable()
{
}

/*##########################################################################
#
#   Name       : TGptTable::ReadEntryArr
#
#   Purpose....: Read entry array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TGptTable::ReadEntryArr(TDisc *Disc)
{
    char *Buf;
    int SectorCount = Header.EntryCount * sizeof(struct TGptPartEntry) / Disc->FBytesPerSector;
    TDiscServer *Server = Disc->GetServer();
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, Header.EntryLba, SectorCount);
    struct TPartEntry *EntryData;
    int size = SectorCount * Disc->FBytesPerSector;
    unsigned int ThisCrc32;

    req.WaitForever();

    Buf = (char *)e1.Map();

    EntryData = (struct TPartEntry *)Buf;

    ThisCrc32 = RdosCalcCrc32(0xFFFFFFFF, Buf, size);

    if (ThisCrc32 == Header.EntryCrc32)
        return true;
    else
        return false;
}

/*##########################################################################
#
#   Name       : TGptTable::ReadTable
#
#   Purpose....: Read table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TGptTable::ReadTable(TDisc *Disc, long long StartSector)
{
    char *Buf;
    TDiscServer *Server = Disc->GetServer();
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, StartSector, 1);
    unsigned int Crc32;
    unsigned int ThisCrc32;
    int TableSectors;
    bool ok = false;

    req.WaitForever();

    Buf = (char *)e1.Map();
    memcpy(&Header, Buf, sizeof(struct TGptPartHeader));

    if (!strcmp(Header.Sign, "EFI PART"))
    {
        Crc32 = Header.Crc32;
        Header.Crc32 = 0;
        ThisCrc32 = RdosCalcCrc32(0xFFFFFFFF, (const char *)&Header, Header.HeaderSize);
        Header.Crc32 = Crc32;

        if (Crc32 == ThisCrc32)
        {
            if (Header.EntrySize == sizeof(struct TGptPartEntry))
            {
                ok = ReadEntryArr(Disc);
            }
        }        
    }

    return ok;
}

/*##########################################################################
#
#   Name       : TGptDisc::TGptDisc
#
#   Purpose....: Gpt disc constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGptDisc::TGptDisc(TDiscServer *server)
  : TDisc(server)
{
}

/*##########################################################################
#
#   Name       : TGptDisc::~TGptDisc
#
#   Purpose....: Gpt disc destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGptDisc::~TGptDisc()
{
}

/*##########################################################################
#
#   Name       : TGptDisc::LoadPart
#
#   Purpose....: Load partitions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGptDisc::LoadPart()
{
    PrimaryTable.ReadTable(this, 1);
}

/*##########################################################################
#
#   Name       : TGptDisc::Run
#
#   Purpose....: Run
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGptDisc::Run()
{
    FServer->WaitForMsg(this);

}
