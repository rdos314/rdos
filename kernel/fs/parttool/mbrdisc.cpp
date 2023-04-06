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
# mbrdisc.cpp
# MBR disc class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <rdos.h>
#include <serv.h>
#include "mbrdisc.h"

/*##########################################################################
#
#   Name       : TMbrPartition::TMbrPartition
#
#   Purpose....: Mbr partition constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMbrPartition::TMbrPartition(struct TMbrPartitionTable *Parent, int Index, struct TMbrPartitionEntry *Entry, unsigned int StartSector, unsigned int SectorCount)
  : TPartition((long long)StartSector, (long long)SectorCount)
{
    FParent = Parent;
    FIndex = Index;

    if (Entry)
        memcpy(&FPartEntry, Entry, sizeof(TMbrPartitionEntry));
    else
        memset(&FPartEntry, 0, sizeof(TMbrPartitionEntry));
}

/*##########################################################################
#
#   Name       : TMbrPartition::~TMbrPartition
#
#   Purpose....: Mbr partition destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMbrPartition::~TMbrPartition()
{
}

/*##########################################################################
#
#   Name       : TMbrPartition::IsTable
#
#   Purpose....: Check for table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TMbrPartition::IsTable()
{
    return false;
}

/*##################  TMbrPartitionTable::TMbrPartitionTable  #############
*   Purpose....: Partition table constructor                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TMbrPartitionTable::TMbrPartitionTable(struct TMbrPartitionTable *Parent, int Index, struct TMbrPartitionEntry *Entry, unsigned int Start, unsigned int Size)
 : TMbrPartition(Parent, Index, Entry, Start, Size)
{
    int i;

    for (i = 0; i < 4; i++)
        PartArr[i] = 0;
}

/*##################  TMbrPartitionTable::~TMbrPartitionTable  #############
*   Purpose....: Partition table destructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TMbrPartitionTable::~TMbrPartitionTable()
{
    int i;

    for (i = 0; i < 4; i++)
        if (PartArr[i])
            delete PartArr[i];
}

/*##################  TMbrPartitionTable::IsTable  #############
*   Purpose....: Check if entry is table                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
bool TMbrPartitionTable::IsTable()
{
    return true;
}

/*##################  TMbrPartitionTable::ProcessTable  #############
*   Purpose....: Process table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TMbrPartitionTable::ProcessTable(TMbrDisc *Disc, TMbrPartitionTable *TablePart)
{
    char *Data;
    TDiscServer *server = Disc->GetServer();
    TDiscReq req(server);
    TDiscReqEntry e1(&req, TablePart->FStartSector, 1);

    req.WaitForever();

    Data = (char *)e1.Map();

    if (Data[0x1FE] == 0x55 && Data[0x1FF] == 0xAA)
        TablePart->Process(Disc, Data);
}

/*##################  TMbrPartitionTable::ProcessOne  #############
*   Purpose....: Process one entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TMbrPartitionTable::ProcessOne(TMbrDisc *Disc, int Index, struct TMbrPartitionEntry *Entry)
{
    TMbrPartition *Part = 0;
    TMbrPartitionTable *TablePart = 0;
    unsigned int LbaStart;
    unsigned int LbaSize;
    unsigned int Start;
    unsigned int ChsEnd;
    unsigned int Size;
    long long LastSector;
    char Type = Entry->Type;

    if (Type)
    {
        LbaStart = Entry->LbaStart;
        LbaSize = Entry->LbaCount;    

        if (LbaSize == 0)
        {
            Start = Disc->ChsToLba(&Entry->ChsStart);
            ChsEnd = Disc->ChsToLba(&Entry->ChsEnd);
            Size = ChsEnd - Start + 1;
        }        
        else
        {
            Start = (unsigned int)FStartSector + LbaStart;
            Size = LbaSize;
        }

        LastSector = (long long)Start + (long long)Size - 1;

        if (LastSector > Disc->FSectorCount)
            Type = 0;
    }

    switch (Type)
    {
        case 0:
            break;

        case 5:
        case 0xF:
            TablePart = new TMbrPartitionTable(this, Index, Entry, Start, Size);
            Part = TablePart;
            break;

        default:
            Part = new TMbrPartition(this, Index, Entry, Start, Size);
            break;
    }

    if (TablePart)
        ProcessTable(Disc, TablePart);

    PartArr[Index] = Part;
}

/*##################  TMbrPartitionTable::Process  #############
*   Purpose....: Process partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TMbrPartitionTable::Process(TMbrDisc *Disc, char *Data)
{
    ProcessOne(Disc, 0, (struct TMbrPartitionEntry *)(Data + 0x1BE));
    ProcessOne(Disc, 1, (struct TMbrPartitionEntry *)(Data + 0x1CE));
    ProcessOne(Disc, 2, (struct TMbrPartitionEntry *)(Data + 0x1DE));
    ProcessOne(Disc, 3, (struct TMbrPartitionEntry *)(Data + 0x1EE));
}

/*##########################################################################
#
#   Name       : TMbrDisc::TMbrDisc
#
#   Purpose....: Mbr disc constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMbrDisc::TMbrDisc(TDiscServer *server)
  : TDisc(server),
    PartRoot(0, 0, 0, 0, 0)
{
    FSectorsPerCyl = 0;
    FHeads = 0;
}

/*##########################################################################
#
#   Name       : TMbrDisc::~TMbrDisc
#
#   Purpose....: Mbr disc destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMbrDisc::~TMbrDisc()
{
}

/*##################  TMbrDisc::ChsToLba  #############
*   Purpose....: Convert CHS to LBA                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
unsigned int TMbrDisc::ChsToLba(struct TMbrChs *Entry)
{
    unsigned char cs[2];
    int BiosHead;
    int BiosSector;
    int BiosCyl;

    memcpy(cs, &Entry->CylSector, 2);

    BiosCyl = cs[1];
    BiosCyl += (cs[0] & 0xC0) << 2;
    BiosSector = cs[0] & 0x3F;
    BiosHead = Entry->Head;

    if (BiosCyl == 1023)
        return 0;

    if (BiosSector == 0)
        return 0;

    return BiosSector + FSectorsPerCyl * (BiosHead + FHeads * BiosCyl) - 1;
}

/*##################  TMbrDisc::LbaToChs  #############
*   Purpose....: Convert LBA to CHS                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TMbrDisc::LbaToChs(unsigned int Sector, struct TMbrChs *Entry)
{
    int BiosHead;
    int BiosSector;
    int BiosCyl;
    unsigned char cs[2];

    BiosCyl = Sector / FSectorsPerCyl / FHeads;
    if (BiosCyl >= 1024)
    {
        BiosCyl = 1023;
        BiosHead = FHeads - 1;
        BiosSector = FSectorsPerCyl;
    }
    else
    {
        Sector = Sector - BiosCyl * FSectorsPerCyl * FHeads;
        BiosHead = Sector / FSectorsPerCyl;
        BiosSector = Sector - BiosHead * FSectorsPerCyl + 1;
    }

    Entry->Head = BiosHead;

    cs[0] = (unsigned char)BiosSector;
    cs[1] = (unsigned char)BiosCyl;
    cs[0] |= (unsigned char)((BiosCyl >> 2) & 0xC0);

    memcpy(&Entry->CylSector, cs, 2);
}

/*##########################################################################
#
#   Name       : TMbrDisc::AddPossibleFs
#
#   Purpose....: Add possible FS part
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMbrDisc::AddPossibleFs(struct TMbrPartition *part)
{
    bool AddIt = false;

    switch (part->FPartEntry.Type)
    {
        case 1:
            part->SetType(PART_TYPE_FAT12);
            AddIt = true;
            break;

        case 4:
        case 6:
            part->SetType(PART_TYPE_FAT16);
            AddIt = true;
            break;

        case 0xB:
        case 0xC:
            part->SetType(PART_TYPE_FAT32);
            AddIt = true;
            break;

    }

    if (AddIt)
        Add(part);
}

/*##########################################################################
#
#   Name       : TMbrDisc::AddFsParts
#
#   Purpose....: Add usable FS parts
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMbrDisc::AddFsParts(struct TMbrPartitionTable *table)
{
    int i;
    struct TMbrPartition *part;

    for (i = 0; i < 4; i++)
    {
        part = table->PartArr[i];
        if (part)
        {
            if (part->IsTable())
                AddFsParts((struct TMbrPartitionTable *)part);
            else
                AddPossibleFs(part);
        }
    }
}

/*##########################################################################
#
#   Name       : TMbrDisc::LoadPart
#
#   Purpose....: Load partitions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMbrDisc::LoadPart()
{
    struct TBootParamBlock *bpb;
    char *Buf;
    TDiscReq req(FServer);
    TDiscReqEntry e1(&req, 0, 1);

    req.WaitForever();

    Buf = (char *)e1.Map();

    if (Buf[0x1FE] == 0x55 && Buf[0x1FF] == 0xAA)
    {
        bpb = (struct TBootParamBlock *)(Buf + 11);
        FSectorsPerCyl = bpb->SectorsPerCyl;
        FHeads = bpb->Heads;
        PartRoot.Process(this, Buf);

        AddFsParts(&PartRoot);
    }
}

/*##########################################################################
#
#   Name       : TMbrDisc::Run
#
#   Purpose....: Run
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMbrDisc::Run()
{
    FServer->WaitForMsg(this);

}
