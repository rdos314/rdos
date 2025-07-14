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

#define BOOT_LOADER_SECTORS     16

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
bool TMbrPartitionTable::ProcessTable(TMbrDisc *Disc, TMbrPartitionTable *TablePart)
{
    char *Data;
    TDiscServer *server = Disc->GetServer();
    TDiscReq req(server);
    TDiscReqEntry e1(&req, TablePart->FStartSector, 1);

    req.WaitForever();

    if (req.IsDone())
    {
        Data = (char *)e1.Map();
    
        if (Data[0x1FE] == 0x55 && Data[0x1FF] == 0xAA)
        {
            TablePart->Process(Disc, Data);
            return true;
        }
    }
    return false;
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

/*##################  TMbrPartitionTable::WriteEntry  #############
*   Purpose....: Write entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
bool TMbrPartitionTable::WriteEntry(TMbrDisc *Disc, int Index, struct TMbrPartitionEntry *Entry)
{
    char *Data;
    TDiscServer *server = Disc->GetServer();
    TDiscReq req(server);
    TDiscReqEntry e1(&req, FStartSector, 1, false);

    req.WaitForever();

    if (req.IsDone())
    {
        Data = (char *)e1.Map();

        switch (Index)
        {
            case 0:
                memcpy(Data + 0x1BE, Entry, 0x10);
                break;

            case 1:
                memcpy(Data + 0x1CE, Entry, 0x10);
                break;

            case 2:
                memcpy(Data + 0x1DE, Entry, 0x10);
                break;

            case 3:
                memcpy(Data + 0x1EE, Entry, 0x10);
                break;
        }
  
        e1.Write();

        return true;
    }
    return false;
}

/*##################  TMbrPartitionTable::AddEntry  #############
*   Purpose....: Add entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
struct TMbrPartition *TMbrPartitionTable::AddEntry(TMbrDisc *Disc, char Type, unsigned int Start, unsigned int Size)
{
    int i;
    struct TMbrPartitionEntry entry;
    TMbrPartition *part = 0;

    for (i = 0; i < 4; i++)
        if (PartArr[i] == 0)
            break;

    if (i < 4)
    {
        if (i == 0 && !FParent)
            entry.Status = 0x80;
        else
            entry.Status = 0;

        Disc->LbaToChs(Start, &entry.ChsStart);
        entry.Type = Type;
        Disc->LbaToChs(Start + Size - 1, &entry.ChsEnd);
        entry.LbaStart = Start - (unsigned int)FStartSector;
        entry.LbaCount = Size;

        if (WriteEntry(Disc, i, &entry))
        {
            part = new TMbrPartition(this, i, &entry, Start, Size);
            PartArr[i] = part;
        }
    }
    return part;
}

/*##################  TMbrPartitionTable::DeletePart  #############
*   Purpose....: Delete part
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TMbrPartitionTable::DeletePart(TMbrPartition *part)
{
    int i;
    TMbrPartitionTable *table;

    for (i = 0; i < 4; i++)
    {
        if (PartArr[i])
        {
            if (PartArr[i]->IsTable())
            {
                table = (TMbrPartitionTable *)PartArr[i];
                table->DeletePart(part);
            }
            else
                if (PartArr[i] == part)
                    PartArr[i] = 0;
        }
    }
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

    if (FHeads == 0 || FSectorsPerCyl == 0)
    {
        BiosCyl = 1023;
        BiosHead = FHeads - 1;
        BiosSector = FSectorsPerCyl;
    }
    else
    {
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
    }

    Entry->Head = BiosHead;

    cs[0] = (unsigned char)BiosSector;
    cs[1] = (unsigned char)BiosCyl;
    cs[0] |= (unsigned char)((BiosCyl >> 2) & 0xC0);

    memcpy(&Entry->CylSector, cs, 2);
}

/*##########################################################################
#
#   Name       : TMbrDisc::PartToType
#
#   Purpose....: Convert partition type to MBR type
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TMbrDisc::PartToType(int Type, long long Sectors)
{
    switch (Type)
    {
        case PART_TYPE_FAT12:
            return 1;

        case PART_TYPE_FAT16:
            if (Sectors > 0xFFFF)
                return 6;
            else
                return 4;

        case PART_TYPE_FAT32:
            return 0xC;
    }

    return 0;
}

/*##########################################################################
#
#   Name       : TMbrDisc::TypeToPart
#
#   Purpose....: Convert MBR type to partition type
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMbrDisc::TypeToPart(char Type)
{
    switch (Type)
    {
        case 1:
            return PART_TYPE_FAT12;

        case 4:
        case 6:
            return PART_TYPE_FAT16;

        case 0xB:
        case 0xC:
            return PART_TYPE_FAT32;
    }
    return 0;
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
    int Type = TypeToPart(part->FPartEntry.Type);

    if (Type)
    {
        part->SetType(Type);
        Add(part);
    }
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
#   Name       : TMbrDisc::IsGpt
#
#   Purpose....: Is GPT partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TMbrDisc::IsGpt()
{
    return false;
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
bool TMbrDisc::LoadPart()
{
    struct TBootParamBlock *bpb;
    char *Buf;
    TDiscReq req(FServer);
    TDiscReqEntry e1(&req, 0, 1);

    req.WaitForever();

    if (req.IsDone())
    {
        Buf = (char *)e1.Map();

        if (Buf[0x1FE] == 0x55 && Buf[0x1FF] == 0xAA)
        {
            bpb = (struct TBootParamBlock *)(Buf + 11);
            FSectorsPerCyl = bpb->SectorsPerCyl;
            FHeads = bpb->Heads;
            FLoaderSectors = bpb->HiddenSectors;
 
            PartRoot.Process(this, Buf);
            AddFsParts(&PartRoot);
        }

        return TDisc::LoadPart();
    }
    return false;
}

/*##########################################################################
#
#   Name       : TMbrDisc::InitPart
#
#   Purpose....: Init partitions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TMbrDisc::InitPart()
{
    bool ok;

    LoadBootLoader();
    ok = WriteBootLoader();
    if (ok)
        ok = WriteBootSector();
   
    delete FBootLoader;
    FBootLoader = 0;

    return ok;
}

/*##########################################################################
#
#   Name       : TMbrDisc::LoadBootLoader
#
#   Purpose....: Load boot loader into memory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMbrDisc::LoadBootLoader()
{
    FBootLoader = new char[512 * BOOT_LOADER_SECTORS];

    memset(FBootLoader, 0, 512 * BOOT_LOADER_SECTORS);
    FLoaderSize = RdosReadBinaryResource(0, 101, FBootLoader, 512 * BOOT_LOADER_SECTORS);

    FLoaderSectors = 1 + (FLoaderSize - 1) / 512;
}

/*##########################################################################
#
#   Name       : TMbrDisc::WriteBootSector
#
#   Purpose....: Write boot sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TMbrDisc::WriteBootSector()
{
    TDiscReq req(FServer);
    TDiscReqEntry e1(&req, 0, 1, false);
    char *Data;
    char *BootSector;
    TBootParamBlock *bootp;

    req.WaitForever();

    if (req.IsDone())
    {
        Data = (char *)e1.Map();

        BootSector = new char[512];
        RdosReadBinaryResource(0, 100, BootSector, 0x1BE);
        memcpy(BootSector + 11, Data + 11, sizeof(TBootParamBlock));
    
        bootp = (TBootParamBlock *)(BootSector + 11);

        FSectorsPerCyl = bootp->SectorsPerCyl;
        FHeads = bootp->Heads;

        bootp->BytesPerSector = FServer->GetBytesPerSector();
        bootp->Resv1 = 1;
        bootp->MappingSectors = FLoaderSectors;
        bootp->Resv3 = 0;
        bootp->Resv4 = 0;
        bootp->SmallSectors = 0;
        bootp->Media = 0xF1;
        bootp->Resv6 = 0;
        bootp->HiddenSectors = FLoaderSectors;
        bootp->Sectors = (int)FServer->GetDiscSectors();
        bootp->Resv7 = 0;
        bootp->Signature = 0;
        bootp->Serial = 0;
        memset(bootp->Volume, 0, 11);
        memcpy(bootp->Fs, "RDOS    ", 8);

        BootSector[0x1FE] = 0x55;
        BootSector[0x1FF] = 0xAA;

        memcpy(Data, BootSector, 512);
        e1.Write();

        delete BootSector;
        return true;
    }
    return false;
}

/*##########################################################################
#
#   Name       : TMbrDisc::WriteBootLoader
#
#   Purpose....: Write boot loader
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TMbrDisc::WriteBootLoader()
{
    TDiscReq req(FServer);
    TDiscReqEntry e1(&req, 1, FLoaderSectors, true);
    char *Data;

    req.WaitForever();

    if (req.IsDone())
    {
        Data = (char *)e1.Map();
  
        memcpy(Data, FBootLoader, FLoaderSize);

        e1.Write();

        return true;
    }
    return false;
}


/*##########################################################################
#
#   Name       : TMbrDisc::DeletePart
#
#   Purpose....: Delete partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMbrDisc::DeletePart(TPartition *part)
{
    PartRoot.DeletePart((TMbrPartition *)part);
    TDisc::DeletePart(part);
}

/*##########################################################################
#
#   Name       : TMbrDisc::CreatePart
#
#   Purpose....: Create partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TMbrDisc::CreatePart(int Handle, int Type, long long Start, long long Sectors)
{
    TMbrPartition *part = 0;
    char PartType = PartToType(Type, Sectors);

    if (PartType)
        part = PartRoot.AddEntry(this, PartType, (int)Start, (int)Sectors);

    if (part)
    {
        part->Handle = Handle;
        part->SetType(Type);
        Add(part);
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TMbrDisc::::AddPart
#
#   Purpose....: Add partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TMbrDisc::AddPart(const char *FsName, long long Sectors)
{
    long long Start;
    long long Count = Sectors;
    int Type;
    int Handle;

    if (Count > 0xFFFFFFFF)
        Count = 0xFFFFFFFF;

    Start = AllocateSectors(FLoaderSectors + 1, Count);

    if (Start)
    {
        Handle = FormatPart(FsName, &Start, &Count, &Type);

        if (Handle)
            if (CreatePart(Handle, Type, (unsigned int)Start, (unsigned int)Count))
                return true;
    }
    return false;
}
