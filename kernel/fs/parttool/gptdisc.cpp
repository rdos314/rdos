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

    PartCount = 0;
    MaxPartCount = 4;
    PartArr = new TGptPartEntry*[MaxPartCount];

    HeaderOk = false;

    for (i = 0; i < MaxPartCount; i++)
        PartArr[i] = 0;
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

    for (i = 0; i < PartCount; i++)
        if (PartArr[i])
            delete PartArr[i];

    delete PartArr;
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
    int Size = 2 * MaxPartCount;
    TGptPartEntry **NewArr;

    NewArr = new TGptPartEntry*[Size];

    for (i = 0; i < MaxPartCount; i++)
        NewArr[i] = PartArr[i];

    for (i = MaxPartCount; i < Size; i++)
        NewArr[i] = 0;

    delete PartArr;
    PartArr = NewArr;
    MaxPartCount = Size;
}

/*##################  TGptTable::Add  #############
*   Purpose....: Add entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
bool TGptTable::Add(struct TGptPartEntry *entry)
{
    int pos;
    int i;
    struct TGptPartEntry *e;  

    if (entry->FirstLba == 0)
        return false;

    for (pos = 0; pos < PartCount; pos++)
        if (entry->FirstLba < PartArr[pos]->FirstLba)
            break;

    if (pos)
        if (entry->FirstLba <= PartArr[pos-1]->LastLba)
            return false;

    if (PartCount > pos)
        if (entry->LastLba >= PartArr[pos]->FirstLba)
            return false;

    if (PartCount == MaxPartCount)
        GrowPart();

    e = new TGptPartEntry;
    *e = *entry;

    for (i = PartCount - 1; i > pos; i--)
        PartArr[i] = PartArr[i - 1];

    PartArr[pos] = e;    

    PartCount++;

    return true;
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
    struct TGptPartEntry *PartEntryArr;
    int SectorCount = Header.EntryCount * sizeof(struct TGptPartEntry) / Disc->FBytesPerSector;
    TDiscServer *Server = Disc->GetServer();
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, Header.EntryLba, SectorCount);
    int size = SectorCount * Disc->FBytesPerSector;
    unsigned int ThisCrc32;
    int i;

    req.WaitForever();

    if (req.IsDone())
    {
        Buf = (char *)e1.Map();

        ThisCrc32 = RdosCalcCrc32(0xFFFFFFFF, Buf, size);

        if (ThisCrc32 == Header.EntryCrc32)
        {
            PartEntryArr = (struct TGptPartEntry *)Buf;

            for (i = 0; i < Header.EntryCount; i++)
                Add(PartEntryArr + i);
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

/*##################  TGptTable::InitHeader  #############
*   Purpose....: Init header
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TGptTable::InitHeader(long long MyLba, long long OtherLba)
{
    Header.EntryCount = 128;

    strcpy(Header.Sign, "EFI PART");
    Header.Revision[0] = 0;
    Header.Revision[1] = 0;
    Header.Revision[2] = 1;
    Header.Revision[3] = 0;

    Header.HeaderSize = sizeof(struct TGptPartHeader);
    Header.Crc32 = 0;    
    Header.Resv = 0;

    Header.CurrLba = MyLba;
    Header.OtherLba = OtherLba;

    Header.FirstLba = 34;

    if (MyLba == 1)
        Header.LastLba = OtherLba - 1;
    else
        Header.LastLba = MyLba - 1;

    RdosCreateUuid(Header.Guid);

    Header.EntryLba = MyLba + 1;    
    Header.EntrySize = 128;
};

/*##########################################################################
#
#   Name       : TGptTable::Recreate
#
#   Purpose....: Recreate table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGptTable::Recreate(TDisc *Disc, struct TGptPartHeader *OtherHeader, struct TGptPartEntry *OtherPart)
{
    if (!HeaderOk)
        InitHeader(OtherHeader->OtherLba, OtherHeader->CurrLba);
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
#   Name       : TGptDisc::MergeTables
#
#   Purpose....: Merge tables
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGptDisc::MergeTables()
{
/*
    int i;
    int size;
    bool primary = false;

    size = PrimaryTable.Header.EntryCount;
    if (SecondaryTable.Header.EntryCount < size);
        size = SecondaryTable.Header.EntryCount;

    for (i = 0; i < size && !primary; i++)
    {
        if (PrimaryTable->PartEntryArr[i].FirstLba != SecondaryTable->PartEntryArr[i].FirstLba)
        {
            if (PrimaryTable->PartEntryArr[i].FirstLba > SecondaryTable->PartEntryArr[i].FirstLba)
                primary = !SecondaryTable->Insert(PrimaryTable->PartEntryArr[i]);
            else
                primary = !PrimaryTable->Insert(SecondaryTable->PartEntryArr[i]);
        }
    }
*/
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

/*

    if (PrimaryTable.PartCount && SecondaryTable.PartCount)
        MergeTables();
    else
    {
        if (PrimaryTable.PartCount)
            SecondaryTable.Recreate(this, &PrimaryTable.Header, PrimaryTable.PartEntryArr);
        else
        {
            if (SecondaryTable.PartCount)
                PrimaryTable.Recreate(this, &SecondaryTable.Header, SecondaryTable.PartEntryArr);
        }
    }
*/

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
