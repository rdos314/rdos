/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# part.cpp
# Harddrive partition handling classes
#
########################################################################*/

#ifdef __GNUC__
#include <string.h>
#else
#include <mem.h>
#endif
#include <stdio.h>

#include "part.h"

#define FALSE   0
#define TRUE    !FALSE

TFsPartitionFactory *TFsPartitionFactory::FPartList = 0;

/*##################  TPartition::TPartition  #############
*   Purpose....: Partition constructor                                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TPartition::TPartition(TDisc *Disc, unsigned char Type, TPartitionTable *Parent, int Entry, long PStart, long PSize)
{
        FDisc = Disc;
        FDrive = 0;
        FParent = Parent;
        FControlEntry = Entry;
        FType = Type;
        Start = PStart;
        Size = PSize;
    DriveSectors = Size;
    FreeSectors = 0;
    FDrive = 0;
}

/*##################  TPartition::~TPartition  #############
*   Purpose....: Partition destructor                                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TPartition::~TPartition()
{
    if (FDrive)
        delete FDrive;
}

/*##################  TPartition::GetPartName  #############
*   Purpose....: Get partition name                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TPartition::GetPartName()
{
        return "Free    ";
}

/*##################  TPartition::GetDisc  #############
*   Purpose....: Get disc nr                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDisc *TPartition::GetDisc()
{
        return FDisc;
}

/*##################  TPartition::GetDrive  #############
*   Purpose....: Get drive nr                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDrive *TPartition::GetDrive()
{
        return FDrive;
}

/*##################  TPartition::GetType  #############
*   Purpose....: Get partition type                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
unsigned char TPartition::GetType()
{
        return FType;
}

/*##################  TPartition::GetBytesPerSector  #############
*   Purpose....: Get bytes per sector                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartition::GetBytesPerSector()
{
    if (FDisc)
                return FDisc->GetBytesPerSector();
        else
                return 0;
}

/*##################  TPartition::GetTotalSpace  #############
*   Purpose....: Get total space in MB                                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
double TPartition::GetTotalSpace()
{
        return (double)Size * (double)GetBytesPerSector() / (double)0x100000;
}

/*##################  TPartition::GetFreeSpace  #############
*   Purpose....: Get free space in MB                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
double TPartition::GetFreeSpace()
{
        return (double)FreeSectors * (double)GetBytesPerSector() / (double)0x100000;
}

/*##################  TPartition::IsTable  #############
*   Purpose....: Check if entry is table                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartition::IsTable()
{
        return FALSE;
}

/*##################  TPartition::IsFs  #############
*   Purpose....: Check if entry is a filesystem                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartition::IsFs()
{
        return FALSE;
}

/*##################  TPartition::IsFree  #############
*   Purpose....: Check if entry is free                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartition::IsFree()
{
        return FALSE;
}

/*##################  TPartition::WriteToTable  #############
*   Purpose....: Write partition entry to disc
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartition::WriteToTable(TPartitionTable *Owner, char Active)
{
        char Buf[512];
        char *PartPtr;

        if (!FParent)
                return;

        FDisc->Read(FParent->Start, Buf, 512);
        switch (FControlEntry)
        {
                case 0:
                        PartPtr = Buf + 0x1BE;
                        break;

                case 1:
                        PartPtr = Buf + 0x1CE;
                        break;

                case 2:
                        PartPtr = Buf + 0x1DE;
                        break;

                case 3:
                        PartPtr = Buf + 0x1EE;
                        break;
        }

        *PartPtr = Active;
        FDisc->LbaToChs(Start, PartPtr + 1);
        *(PartPtr + 4) = FType;
        FDisc->LbaToChs(Start + Size - 1, PartPtr + 5);
        *(long *)(PartPtr + 8) = Start - Owner->Start;
        *(long *)(PartPtr + 0xC) = Size;

        FDisc->Write(FParent->Start, Buf, 512);
}

/*##################  TPartition::DeleteFromTable  #############
*   Purpose....: Delete partition entry on disc
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartition::DeleteFromTable(TPartitionTable *Owner)
{
        char Buf[512];
        char *PartPtr;

        if (!FParent)
                return;

        FDisc->Read(FParent->Start, Buf, 512);
        switch (FControlEntry)
        {
                case 0:
                        PartPtr = Buf + 0x1BE;
                        break;

                case 1:
                        PartPtr = Buf + 0x1CE;
                        break;

                case 2:
                        PartPtr = Buf + 0x1DE;
                        break;

                case 3:
                        PartPtr = Buf + 0x1EE;
                        break;
        }

        memset(PartPtr, 0, 16);

        FDisc->Write(FParent->Start, Buf, 512);
}

/*##################  TFsPartition::TFsPartition  #############
*   Purpose....: Partition filesystem constructor                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition::TFsPartition(TDisc *Disc, unsigned char Type, TPartitionTable *Parent, int Entry, long PStart, long PSize)
 : TPartition(Disc, Type, Parent, Entry, PStart, PSize)
{
        int DriveNr;

        DriveNr = FDisc->GetDrive(PStart, PSize);

        if (DriveNr)
                FDrive = new TDrive(DriveNr);

        if (FDrive)
        {
            DriveSectors = FDrive->GetTotalSectors();
            FreeSectors = FDrive->GetFreeSectors();
        }
}

/*##################  TFsPartitionEntry::GetPartName  #############
*   Purpose....: Get partition name                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TFsPartition::GetPartName()
{
        if (FsName.GetSize())
                return FsName.GetData();
        else
        {
                switch (FType)
                {
                        case 1:
                                return "FAT12";

                        case 4:
                        case 6:
                                return "FAT16";

                        case 7:
                                return "Custom";

                        case 0xB:
                        case 0xC:
                                return "FAT32";

                        case 0x81:
                                return "Linux";

                        case 0x82:
                                return "Swap";

                        case 0x83:
                                return "EXT2FS";

                        default:
                                return "???";
                }
        }
}

/*##################  TFsPartition::IsFs  #############
*   Purpose....: Check for filesystem                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TFsPartition::IsFs()
{
        return TRUE;
}

/*##################  TFsPartition::Read  #############
*   Purpose....: Read data from partition                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TFsPartition::Read(long Sector, char *Buf, int Count)
{
        if (Sector < 0 || Sector >= Size)
                return 0;

        return FDisc->Read(Start + Sector, Buf, Count);
}

/*##################  TFsPartition::Write  #############
*   Purpose....: Write data to partition                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TFsPartition::Write(long Sector, const char *Buf, int Count)
{
        if (Sector < 0 || Sector >= Size)
                return 0;

        return FDisc->Write(Start + Sector, Buf, Count);
}

/*##################  TFsPartition::Format  #############
*   Purpose....: Format partition                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TFsPartition::Format()
{
    return FALSE;
}

/*##################  TFreePartition::TFreePartition  #############
*   Purpose....: Partition free constructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFreePartition::TFreePartition(TDisc *Disc)
 : TPartition(Disc, 0, 0, 0, 0, 0)
{
}

/*##################  TFreePartition::GetPartName  #############
*   Purpose....: Get partition name                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TFreePartition::GetPartName()
{
        return "Free";
}

/*##################  TFreePartition::IsFree  #############
*   Purpose....: Check if entry is free                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TFreePartition::IsFree()
{
        return TRUE;
}

/*##################  TPartitionTable::TPartitionTable  #############
*   Purpose....: Partition table constructor                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TPartitionTable::TPartitionTable(TDisc *Disc, unsigned char Type, TPartitionTable *Parent, int Entry, long PStart, long PSize)
 : TPartition(Disc, Type, Parent, Entry, PStart, PSize)
{
        int i;

        for (i = 0; i < 4; i++)
                PartArr[i] = 0;
}

/*##################  TPartitionTable::~TPartitionTable  #############
*   Purpose....: Partition table destructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TPartitionTable::~TPartitionTable()
{
        int i;

        for (i = 0; i < 4; i++)
                if (PartArr[i])
                {
                        delete PartArr[i];
                        PartArr[i] = 0;
                }
}

/*##################  TPartitionTable::IsTable  #############
*   Purpose....: Check if entry is table                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartitionTable::IsTable()
{
        return TRUE;
}

/*##################  TPartitionTable::GetPartName  #############
*   Purpose....: Get partition name                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TPartitionTable::GetPartName()
{
        return "Table";
}

/*##################  TPartitionTable::ChsToLba  #############
*   Purpose....: Convert CHS to LBA                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long TPartitionTable::ChsToLba(const char *Data)
{
        int chs[3];
        int BiosHead;
        int BiosSector;
        int BiosCyl;

        chs[0] = *(unsigned char *)Data;
        chs[1] = *(unsigned char *)(Data + 1);
        chs[2] = *(unsigned char *)(Data + 2);

        BiosCyl = chs[2];
        BiosCyl += (chs[1] & 0xC0) << 2;
        BiosSector = chs[1] & 0x3F;
        BiosHead = chs[0];

        if (BiosCyl == 1023)
                return 0;

        if (BiosSector == 0)
                return 0;

        return BiosSector + FSectorsPerCyl * (BiosHead + FHeads * BiosCyl) - 1;
}

/*##################  TPartitionTable::LbaToChs  #############
*   Purpose....: Convert LBA to CHS                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartitionTable::LbaToChs(long Sector, char *Data)
{
        int BiosHead;
        int BiosSector;
        int BiosCyl;

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

        *Data = (char)BiosHead;
        *(Data + 1) = (char)BiosSector;
        *(Data + 2) = (char)BiosCyl;
        *(Data + 1) |= (char)((BiosCyl >> 2) & 0xC0);
}

/*##################  TPartitionTable::ProcessOne  #############
*   Purpose....: Process one entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartitionTable::ProcessOne(int Entry, const char *Data)
{
        unsigned char Type;
        TPartition *Part;
        TFsPartition *FsPart = 0;
        TPartitionTable *TablePart = 0;
        long PStart;
        long PSize;

        PStart = ChsToLba(Data + 1);
        if (PStart)
        {
                PSize = ChsToLba(Data + 5);
                if (PSize)
                        PSize = PSize - PStart + 1;
                else
                        PSize = *(long *)(Data + 0xC);
        }
        else
        {
                PStart = Start + *(long *)(Data + 8);
                PSize = *(long *)(Data + 0xC);
        }

        Type = *(Data + 4);
        switch (Type)
        {
                case 0:
                        Part = new TPartition(FDisc, Type, 0, Entry, PStart, PSize);
                        break;

                case 5:
                case 0xF:
                        TablePart = new TPartitionTable(FDisc, Type, this, Entry, PStart, PSize);
                        Part = TablePart;
                        break;

                default:
                        FsPart = TFsPartitionFactory::Parse(FDisc, Type, this, Entry, PStart, PSize);
                        Part = FsPart;
                        break;
        }

        if (TablePart)
        {
                TablePart->FTotalSectors = FTotalSectors;
                TablePart->FHeads = FHeads;
                TablePart->FSectorsPerCyl = FSectorsPerCyl;
                TablePart->Process();
        }

        PartArr[Entry] = Part;
}

/*##################  TPartitionTable::Process  #############
*   Purpose....: Process partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartitionTable::Process()
{
        char Buf[512];

        if (Start < FTotalSectors)
        {
                FDisc->Read(Start, Buf, 512);
                ProcessOne(0, &Buf[0x1BE]);
                ProcessOne(1, &Buf[0x1CE]);
                ProcessOne(2, &Buf[0x1DE]);
                ProcessOne(3, &Buf[0x1EE]);
        }
}

/*##################  TPartitionTable::Create  #############
*   Purpose....: Create an empty partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TPartitionTable *TPartitionTable::Create(int Entry, TFreePartition *FreePart)
{
        TPartitionTable *PartTable;
        int i;
        char Buf[512];

        PartTable = new TPartitionTable(FDisc, 0xF, this, Entry, FreePart->Start, FreePart->Size);
        PartTable->FTotalSectors = FTotalSectors;
        PartTable->FHeads = FHeads;
        PartTable->FSectorsPerCyl = FSectorsPerCyl;
        FreePart->Start++;
        FreePart->Size--;
        for (i = 0; i < 4; i++)
                PartTable->PartArr[i] = new TPartition(FDisc, 0, 0, i, 0, 0);

        memset(Buf, 0, 512);
        Buf[510] = 0x55;
        Buf[511] = 0xAA;
        FDisc->Write(PartTable->Start, Buf, 512);
        PartArr[Entry] = PartTable;
        PartTable->WriteToTable(this, 0);

        return PartTable;
}

/*##################  TPartitionTable::InsertFs  #############
*   Purpose....: Allocate partition entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition *TPartitionTable::InsertFs(const char *FsName, TFreePartition *FreePart, long NewSize, char Active)
{
        int i;
        TFsPartition *FsPart;
        TPartitionTable *PartTable;
        int FreeEntries;

        if (Start > FreePart->Start)
                return 0;

        if (Start + Size < FreePart->Start)
                return 0;

        for (i = 0; i < 4; i++)
                if (PartArr[i])
                {
                        if (PartArr[i]->IsTable())
                        {
                                if (PartArr[i]->Start <= FreePart->Start && PartArr[i]->Start + PartArr[i]->Size >= FreePart->Start)
                                {
                                    PartTable = (TPartitionTable *)PartArr[i];
                                        FsPart = PartTable->InsertFs(FsName, FreePart, NewSize, 0);
                                        while (PartTable->FParent && FsPart->Start + FsPart->Size > PartTable->Start + PartTable->Size)
                    {
                                        PartTable->Size = FsPart->Start + FsPart->Size - PartTable->Start;
                                PartTable->WriteToTable(PartTable->FParent, 0);
                                PartTable = PartTable->FParent;
                                        }
                                        return FsPart;
                }
                        }
                }

        FreeEntries = 0;
        for (i = 0; i < 4; i++)
                if (PartArr[i])
                        if (!PartArr[i]->IsFs() && !PartArr[i]->IsTable())
                                FreeEntries++;

        if (FreeEntries <= 2)
        {
                for (i = 0; i < 4; i++)
                        if (PartArr[i])
                                if (!PartArr[i]->IsFs() && !PartArr[i]->IsTable())
                                {
                                        delete PartArr[i];
                                        PartTable = Create(i, FreePart);
                                        PartArr[i] = PartTable;
                                        return PartTable->InsertFs(FsName, FreePart, NewSize, 0);
                                }
        }

        for (i = 0; i < 4; i++)
                if (PartArr[i])
                {
                        if (!PartArr[i]->IsFs() && !PartArr[i]->IsTable())
                        {
                                delete PartArr[i];
                                FsPart = TFsPartitionFactory::Format(FDisc, FsName, this, i, FreePart->Start, NewSize);
                                PartArr[i] = FsPart;
                                if (i == 0)
                                FsPart->WriteToTable(this, Active);
                        else
                                        FsPart->WriteToTable(this, 0);
                                
                                return FsPart;
                        }
                }
        return 0;
}

/*##################  TPartitionTable::FreeEntry  #############
*   Purpose....: Free partition entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartitionTable::FreeEntry(int Entry)
{
        TPartition *Part;
        TPartitionTable *PartTable;
        int i;
        int Count;

        Part = PartArr[Entry];
        if (Part->IsFs() || Part->IsTable())
        {
                PartArr[Entry] = new TPartition(FDisc, 0, 0, Entry, 0, 0);

        PartTable = this;
                while (PartTable->FParent && Part->Start + Part->Size == PartTable->Start + PartTable->Size)
                {
                    PartTable->Size -= Part->Size;
            PartTable->WriteToTable(PartTable->FParent, 0);
            PartTable = PartTable->FParent;
        }
        
                Part->DeleteFromTable(this);
                delete Part;
        }

        Count = 0;
        for (i = 0; i < 4; i++)
                if (PartArr[i]->IsFs() || PartArr[i]->IsTable())
                        Count++;

        if (Count == 0)
                if (FParent)
                {
                        FParent->FreeEntry(FControlEntry);
                        delete this;
                }
}

/*##################  TFsPartitionFactory::TFsPartitionFactory  #############
*   Purpose....: Filesystem partition factory constructor                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartitionFactory::TFsPartitionFactory(unsigned char Type, const char *FsName)
  : FFsName(FsName)
{
         FType = Type;
         Insert();
}

/*##################  TFsPartitionFactory::~TFsPartitionFactory  #############
*   Purpose....: Filesystem partition factory destructor                                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartitionFactory::~TFsPartitionFactory()
{
        Remove();
}

/*##################  TFsPartitionFactory::GetFs  #############
*   Purpose....: Get partition FS name                                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TString TFsPartitionFactory::GetFs(TDisc *Disc, long Start)
{
        TString str;
        char Buf[512];
        char Name[9];
        int i;

        if (Disc->IsValid())
        {
                if (Start < Disc->GetTotalSectors())
                {
                        Disc->Read(Start, Buf, 512);
                        memcpy(Name, &Buf[0x36], 8);
                        Name[8] = 0;

                        for (i = 7; i; i--)
                                if (Name[i] == ' ')
                                        Name[i] = 0;
                                else
                                        break;
                        str = Name;
                }
        }

        return str;
}

/*##################  TFsPartitionFactory::Parse  #############
*   Purpose....: Parse entry for filesystem                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition *TFsPartitionFactory::Parse(TDisc *Disc, unsigned char Type, TPartitionTable *Parent, int Entry, long Start, long Size)
{
        TFsPartition *part;
        TFsPartitionFactory *factory = 0;
        TString FsName;

        FsName = GetFs(Disc, Start);

        factory = FPartList;
    while (factory)
        {
            if (factory->FType == Type)
            {
                if (Type == 7)
                {
                    if (FsName == factory->FFsName)
                        break;
                }
                else
                        break;
        }                       
                factory = factory->FList;
        }

    if (factory)
        part = factory->Open(Disc, Parent, Entry, Start, Size);
    else
        part = new TFsPartition(Disc, Type, Parent, Entry, Start, Size);

        if (part)
            part->FsName = FsName;

        return part;
}

/*##################  TFsPartitionFactory::Format  #############
*   Purpose....: Format a filesystem                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition *TFsPartitionFactory::Format(TDisc *Disc, const char *FsName, TPartitionTable *Parent, int Entry, long Start, long Size)
{
        TFsPartitionFactory *factory = 0;
        TString Name(FsName);

        factory = FPartList;
    while (factory)
        {
            if (Name == factory->FFsName)
                break;
                factory = factory->FList;
        }

    if (factory)
        return factory->Create(Disc, Parent, Entry, Start, Size);
    else
        return 0;
}

/*##################  TFsPartitionFactory::Insert  ##########################
*   Purpose....: Insert partition factory into list                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TFsPartitionFactory::Insert()
{
        FList = FPartList;
        FPartList = this;
}

/*##################  TFsPartitionFactory::Remove  ##########################
*   Purpose....: Remove partition factory from list                                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TFsPartitionFactory::Remove()
{
        TFsPartitionFactory *ptr;
        TFsPartitionFactory *prev;
        prev = 0;

        ptr = FPartList;
        while ((ptr != 0) && (ptr != this))
        {
                prev = ptr;
                ptr = ptr->FList;
        }
        
        if (prev == 0)
                FPartList = FPartList->FList;
        else
                prev->FList = ptr->FList;
}

/*##################  TDiscPartition::TDiscPartition  #############
*   Purpose....: Disc partition constructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDiscPartition::TDiscPartition(TDisc *Disc)
{
        int i;

        FBootParam = 0;
        FDisc = Disc;
        PartRoot = 0;
        PartCount = 0;
        for (i = 0; i < MAX_PART_COUNT; i++)
                PartArr[i] = 0; 

        Update();
}

/*##################  TDiscPartition::Free  #############
*   Purpose....: Free partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDiscPartition::Free()
{
        int i;

        for (i = 0; i < MAX_PART_COUNT; i++)
                if (PartArr[i])
                {
                        if (PartArr[i]->IsFree())
                                delete PartArr[i];
                        PartArr[i] = 0;
                }

        if (PartRoot)
        {
                delete PartRoot;
                PartRoot = 0;
        }
}

/*##################  TDiscPartition::GetParams  #############
*   Purpose....: Get partition params                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDiscPartition::GetParams()
{
        return FDisc->IsValid();
}

/*##################  TDiscPartition::InsertEntry  #############
*   Purpose....: Insert partition entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDiscPartition::InsertEntry(TPartition *Part)
{
        if (Part->IsFs())
        {
                PartArr[PartCount] = Part;
                PartCount++;
        }
}

/*##################  TDiscPartition::InsertTable  #############
*   Purpose....: Insert partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDiscPartition::InsertTable(TPartitionTable *PartTable)
{
        int i;

        for (i = 0; i < 4; i++)
                if (PartTable->PartArr[i])
                {
                        if (PartTable->PartArr[i]->IsTable())
                                InsertTable((TPartitionTable *)PartTable->PartArr[i]);
                        else
                                InsertEntry(PartTable->PartArr[i]);
                }
}

/*##################  TDiscPartition::CreateArr  #############
*   Purpose....: Create partition array
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDiscPartition::CreateArr()
{
        InsertTable(PartRoot);
}

/*##################  TDiscPartition::Sort  #############
*   Purpose....: Sort partition array
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDiscPartition::Sort()
{
        int i;
        int Changed;
        TPartition *Temp;

        Changed = TRUE;

        while (Changed)
        {
                Changed = FALSE;
                for (i = 1; i < PartCount; i++)
                {
                        if (PartArr[i-1]->Start > PartArr[i]->Start)
                        {
                                Temp = PartArr[i-1];
                                PartArr[i-1] = PartArr[i];
                                PartArr[i] = Temp;
                                Changed = TRUE;
                        }
                }
        }
}

/*##################  TDiscPartition::AddFree  #############
*   Purpose....: Add free entries partition array
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDiscPartition::AddFree()
{
        int i;
        int j;
        long Start;

        Start = 0;

        for (i = 0; i < PartCount; i++)
        {
                if (Start + 1024 < PartArr[i]->Start)
                {
                        for (j = PartCount; j > i; j--)
                                PartArr[j] = PartArr[j-1];
                        PartArr[i] = new TFreePartition(FDisc);
                        PartArr[i]->Start = Start;
                        PartArr[i]->Size = PartArr[i+1]->Start - Start - 1;
                        PartCount++;
                }
                Start = PartArr[i]->Start + PartArr[i]->Size;
        }

        if (Start + 1024 < FDisc->GetTotalSectors())
        {
                PartArr[i] = new TFreePartition(FDisc);
                PartArr[i]->Start = Start;
                PartArr[i]->Size = FDisc->GetTotalSectors() - Start;
                PartCount++;
        }
}

/*##################  TDiscPartition::GetDisc  #############
*   Purpose....: Get disc
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDisc *TDiscPartition::GetDisc()
{
        return FDisc;
}

/*##################  TDiscPartition::Update  #############
*   Purpose....: Update partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDiscPartition::Update()
{
        char Buf[512];
        const char *Name;

        Free();

        PartRoot = new TPartitionTable(FDisc, 0, 0, 0, 0, 0);
        PartRoot->Start = 0;
        if (GetParams())
        {
            Name = PartRoot->GetPartName();
                PartRoot->FTotalSectors = FDisc->GetTotalSectors();
                PartRoot->FHeads = FDisc->GetHeads();
                PartRoot->FSectorsPerCyl = FDisc->GetSectorsPerCyl();
                PartRoot->Size = PartRoot->FTotalSectors;
                FDisc->Read(0, Buf, 512);
            Name = PartRoot->GetPartName();
                PartRoot->ProcessOne(0, &Buf[0x1BE]);
                PartRoot->ProcessOne(1, &Buf[0x1CE]);
                PartRoot->ProcessOne(2, &Buf[0x1DE]);
                PartRoot->ProcessOne(3, &Buf[0x1EE]);
            Name = PartRoot->GetPartName();

                CreateArr();
            Name = PartRoot->GetPartName();
                Sort();
            Name = PartRoot->GetPartName();
                AddFree();
            Name = PartRoot->GetPartName();
        }
        else
        {
                delete PartRoot;
                PartRoot = 0;
        }
}

/*##################  TDiscPartition::Add  #############
*   Purpose....: Add partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition *TDiscPartition::Add(const char *FsName, long Sectors)
{
        int i;
        TFsPartition *FsPart;
        long Size;
        long Start;
        long SectorsPerCyl = FDisc->GetSectorsPerCyl();

        for (i = 0; i < PartCount; i++)
                if (PartArr[i]->IsFree())
                {
                    Start = PartArr[i]->Start;
                    Size = PartArr[i]->Size;

                    if (Start < SectorsPerCyl)
                    {
                        Start += SectorsPerCyl;
                        Size -= SectorsPerCyl;
                    }
                    
                        if (Size >= Sectors)
                        {
                            PartArr[i]->Start = Start;
                            PartArr[i]->Size = Size;
                            if (i == 0)
                                FsPart = PartRoot->InsertFs(FsName, (TFreePartition *)PartArr[i], Sectors, 0x80);
                        else
                                FsPart = PartRoot->InsertFs(FsName, (TFreePartition *)PartArr[i], Sectors, 0);

                                if (FsPart)
                                {
                                        PartArr[i]->Size -= Sectors;
                                        PartArr[i]->Start += Sectors;
                                        PartArr[PartCount] = FsPart;
                                        PartCount++;
                                        Sort();
                                        return FsPart;
                                }
                        }
                }
        return 0;
}

/*##################  TDiscPartition::Delete  #############
*   Purpose....: Delete partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDiscPartition::Delete(int Entry)
{
    TPartition *Part;
    int i;

    Part = PartArr[Entry];
    if (Part->FParent)
        Part->FParent->FreeEntry(Part->FControlEntry);
}
