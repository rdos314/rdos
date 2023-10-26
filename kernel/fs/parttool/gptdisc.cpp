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
/* static void UuidToStr(const char *uuid, char *str)
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
*/

/*##########################################################################
#
#   Name       : TGptPartition::TGptPartition
#
#   Purpose....: Constructor for GPT partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGptPartition::TGptPartition(int Index, struct TGptPartEntry *Entry)
  : TPartition(Entry->FirstLba, Entry->LastLba - Entry->FirstLba + 1)
{
    FIndex = Index;
    memcpy(&FEntry, Entry, sizeof(struct TGptPartEntry));
}

/*##########################################################################
#
#   Name       : TGptPartition::~TGptPartition
#
#   Purpose....: Destructor for GPT partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGptPartition::~TGptPartition()
{
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
    int i;

    FCurrPartCount = 0;
    FMaxPartCount = 4;
    FPartArr = new TGptPartition*[FMaxPartCount];

    PartEntryArr = 0;

    HeaderOk = false;

    for (i = 0; i < FMaxPartCount; i++)
        FPartArr[i] = 0;
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
    int i;

    for (i = 0; i < FCurrPartCount; i++)
        if (FPartArr[i])
            delete FPartArr[i];

    delete FPartArr;

    if (PartEntryArr)
        delete PartEntryArr;
}

/*##########################################################################
#
#   Name       : TGptTable::GrowPart
#
#   Purpose....: Grow part array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGptTable::GrowPart()
{
    int i;
    int Size = 2 * FMaxPartCount;
    TGptPartition **NewArr;

    NewArr = new TGptPartition*[Size];

    for (i = 0; i < FMaxPartCount; i++)
        NewArr[i] = FPartArr[i];

    for (i = FMaxPartCount; i < Size; i++)
        NewArr[i] = 0;

    delete FPartArr;
    FPartArr = NewArr;
    FMaxPartCount = Size;
}

/*##################  TGptTable::Sort  #############
*   Purpose....: Sort partition array
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TGptTable::Sort()
{
    int i;
    bool Exchange;
    bool Changed;
    struct TGptPartEntry *PrevEntry;
    struct TGptPartEntry *CurrEntry;
    struct TGptPartEntry Temp;

    Changed = true;

    while (Changed)
    {
        Changed = false;

        PrevEntry = PartEntryArr;

        if (PrevEntry)
        {            
            CurrEntry = PrevEntry;
            CurrEntry++;
        
            for (i = 1; i < Header.EntryCount; i++)
            {
                Exchange = false;
                
                if (CurrEntry->FirstLba)
                {
                    if (PrevEntry->FirstLba == 0)
                        Exchange = true;
                    else
                    {
                        if (CurrEntry->FirstLba < PrevEntry->FirstLba)
                            Exchange = true;
                    }
                }

                if (Exchange)
                {
                    Temp = *CurrEntry;
                    *CurrEntry = *PrevEntry;
                    *PrevEntry = Temp;
                    Changed = true;
                }

                CurrEntry++;
                PrevEntry++;
            }
        }
    }
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
void TGptTable::ReadEntryArr(TDisc *Disc)
{
    char *Buf;
    int SectorCount = Header.EntryCount * sizeof(struct TGptPartEntry) / Disc->FBytesPerSector;
    TDiscServer *Server = Disc->GetServer();
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, Header.EntryLba, SectorCount);
    int size = SectorCount * Disc->FBytesPerSector;
    unsigned int ThisCrc32;

    req.WaitForever();

    if (req.IsDone())
    {
        Buf = (char *)e1.Map();

        ThisCrc32 = RdosCalcCrc32(0xFFFFFFFF, Buf, size);

        if (ThisCrc32 == Header.EntryCrc32)
        {
            PartEntryArr = new struct TGptPartEntry[Header.EntryCount];
            memcpy(PartEntryArr, Buf, Header.EntryCount * sizeof(struct TGptPartEntry));
            Sort();
        }
    }
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
void TGptTable::ReadTable(TDisc *Disc, long long StartSector)
{
    char *Buf;
    TDiscServer *Server = Disc->GetServer();
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, StartSector, 1);
    unsigned int Crc32;
    unsigned int ThisCrc32;

    HeaderOk = false;

    if (PartEntryArr)
    {
        delete PartEntryArr;
        PartEntryArr = 0;
    }

    req.WaitForever();

    if (req.IsDone())
    {
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
                    HeaderOk = true;
                    ReadEntryArr(Disc);
                }
            }
        }
    }
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
#   Name       : TGptDisc::IsGpt
#
#   Purpose....: Is GPT partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TGptDisc::IsGpt()
{
    return true;
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
bool TGptDisc::LoadPart()
{
    PrimaryTable.ReadTable(this, 1);

    if (PrimaryTable.HeaderOk)
        SecondaryTable.ReadTable(this, PrimaryTable.Header.OtherLba);

    return true;
}

/*##########################################################################
#
#   Name       : TGptDisc::InitPart
#
#   Purpose....: Init partitions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TGptDisc::InitPart()
{
    return false;
}

/*##########################################################################
#
#   Name       : TGptDisc::AddPart
#
#   Purpose....: Add partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TGptDisc::AddPart(const char *FsName, long long Sectors)
{
    return false;
}

/*##########################################################################
#
#   Name       : TGptDisc::CreatePart
#
#   Purpose....: Create partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TGptDisc::CreatePart(int Handle, int Type, long long Start, long long Sectors)
{
    return false;
}
