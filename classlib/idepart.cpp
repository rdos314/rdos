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
# idepart.cpp
# IDE partition handling classes
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "idepart.h"

#define FALSE   0
#define TRUE    !FALSE

TIdeFsPartitionFactory *TIdeFsPartitionFactory::FPartList = 0;

/*##################  TIdePartition::TIdePartition  #############
*   Purpose....: IDE partition constructor                                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdePartition::TIdePartition(TDisc *Disc, unsigned char Type, TIdePartitionTable *Parent, int Entry, long PStart, long PSize)
  : TPartition(Disc, PStart, PSize)
{
    FParent = Parent;
    FType = Type;
    FControlEntry = Entry;
}

/*##################  TIdePartition::~TIdePartition  #############
*   Purpose....: IDE partition destructor                                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdePartition::~TIdePartition()
{
}

/*##################  TPartition::GetPartName  #############
*   Purpose....: Get partition name                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TIdePartition::GetPartName()
{
    return "Free    ";
}

/*##################  TPartition::GetType  #############
*   Purpose....: Get partition type                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
unsigned char TIdePartition::GetType()
{
    return FType;
}

/*##################  TIdePartition::IsTable  #############
*   Purpose....: Check if entry is table                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TIdePartition::IsTable()
{
    return FALSE;
}

/*##################  TIdePartition::WriteToTable  #############
*   Purpose....: Write IDE partition entry to disc
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TIdePartition::WriteToTable(TIdePartitionTable *Owner, char Active)
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

/*##################  TIdePartition::DeleteFromTable  #############
*   Purpose....: Delete IDE partition entry on disc
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TIdePartition::DeleteFromTable(TIdePartitionTable *Owner)
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

/*##################  TIdePartitionTable::TIdePartitionTable  #############
*   Purpose....: Partition table constructor                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdePartitionTable::TIdePartitionTable(TDisc *Disc, unsigned char Type, TIdePartitionTable *Parent, int Entry, long PStart, long PSize)
 : TIdePartition(Disc, Type, Parent, Entry, PStart, PSize)
{
    int i;

    for (i = 0; i < 4; i++)
        PartArr[i] = 0;
}

/*##################  TIdePartitionTable::~TIdePartitionTable  #############
*   Purpose....: Partition table destructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdePartitionTable::~TIdePartitionTable()
{
}

/*##################  TIdePartitionTable::IsTable  #############
*   Purpose....: Check if entry is table                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TIdePartitionTable::IsTable()
{
    return TRUE;
}

/*##################  TIdePartitionTable::GetPartName  #############
*   Purpose....: Get partition name                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TIdePartitionTable::GetPartName()
{
    return "Table";
}

/*##################  TIdePartitionTable::ChsToLba  #############
*   Purpose....: Convert CHS to LBA                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long TIdePartitionTable::ChsToLba(const char *Data)
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

    if (FSectorsPerCyl == 0xFFFF)
        return 0;

    if (FHeads == 0xFFFF)
        return 0;

    return BiosSector + FSectorsPerCyl * (BiosHead + FHeads * BiosCyl) - 1;
}

/*##################  TIdePartitionTable::LbaToChs  #############
*   Purpose....: Convert LBA to CHS                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TIdePartitionTable::LbaToChs(long Sector, char *Data)
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

/*##################  TIdePartitionTable::ProcessOne  #############
*   Purpose....: Process one entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TIdePartitionTable::ProcessOne(int Entry, const char *Data)
{
    unsigned char Type;
    TIdePartition *Part = 0;
    TIdeFsPartition *FsPart = 0;
    TIdePartitionTable *TablePart = 0;
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

    if (PStart >= 0 && PSize >= 0)
    {

        Type = *(Data + 4);
        switch (Type)
        {
            case 0:
                Part = new TIdePartition(FDisc, Type, 0, Entry, PStart, PSize);
                break;

            case 5:
            case 0xF:
                TablePart = new TIdePartitionTable(FDisc, Type, this, Entry, PStart, PSize);
                Part = TablePart;
                break;

            default:
                FsPart = TIdeFsPartitionFactory::Parse(FDisc, Type, this, Entry, PStart, PSize);
                Part = FsPart;
                break;
        }
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

/*##################  TIdePartitionTable::Process  #############
*   Purpose....: Process partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TIdePartitionTable::Process()
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

/*##################  TIdePartitionTable::Create  #############
*   Purpose....: Create an empty partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdePartitionTable *TIdePartitionTable::Create(int Entry, TPartition *FreePart)
{
    TIdePartitionTable *PartTable;
    int i;
    char Buf[512];

    PartTable = new TIdePartitionTable(FDisc, 0xF, this, Entry, FreePart->Start, FreePart->Size);
    PartTable->FTotalSectors = FTotalSectors;
    PartTable->FHeads = FHeads;
    PartTable->FSectorsPerCyl = FSectorsPerCyl;
    FreePart->Start++;
    FreePart->Size--;
    for (i = 0; i < 4; i++)
        PartTable->PartArr[i] = new TIdePartition(FDisc, 0, 0, i, 0, 0);

    memset(Buf, 0, 512);
    Buf[510] = 0x55;
    Buf[511] = 0xAA;
    FDisc->Write(PartTable->Start, Buf, 512);
    PartArr[Entry] = PartTable;
    PartTable->WriteToTable(this, 0);

    return PartTable;
}

/*##################  TIdePartitionTable::InsertFs  #############
*   Purpose....: Allocate partition entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFsPartition *TIdePartitionTable::InsertFs(const char *FsName, TFreePartition *FreePart, long NewSize, char Active, const char *BootCode, int BootSize)
{
    int i;
    TIdeFsPartition *FsPart;
    TIdePartitionTable *PartTable;
    int FreeEntries;

    if (Start > FreePart->Start)
        return 0;

    if (Start + Size < FreePart->Start)
        return 0;

    for (i = 0; i < 4; i++)
    {
        if (PartArr[i])
        {
            if (PartArr[i]->IsTable())
            {
                if (PartArr[i]->Start <= FreePart->Start && PartArr[i]->Start + PartArr[i]->Size >= FreePart->Start)
                {
                    PartTable = (TIdePartitionTable *)PartArr[i];
                    FsPart = PartTable->InsertFs(FsName, FreePart, NewSize, 0, BootCode, BootSize);
                    if (FsPart)
                    {
                        while (PartTable->FParent && FsPart->Start + FsPart->Size > PartTable->Start + PartTable->Size)
                        {
                            PartTable->Size = FsPart->Start + FsPart->Size - PartTable->Start;
                            PartTable->WriteToTable(PartTable->FParent, 0);
                            PartTable = PartTable->FParent;
                        }
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
                        return PartTable->InsertFs(FsName, FreePart, NewSize, 0, BootCode, BootSize);
                    }
        }

        for (i = 0; i < 4; i++)
        {
            if (PartArr[i])
            {
                if (!PartArr[i]->IsFs() && !PartArr[i]->IsTable())
                {
                    delete PartArr[i];
                    FsPart = TIdeFsPartitionFactory::Format(FDisc, FsName, this, i, FreePart->Start, NewSize, BootCode, BootSize);
                    if (FsPart)
                    {
                        PartArr[i] = FsPart;
                        if (i == 0)
                            FsPart->WriteToTable(this, Active);
                        else
                            FsPart->WriteToTable(this, 0);
                    }            
                    return FsPart;
                }
            }
        }
    }
    return 0;
}

/*##################  TIdePartitionTable::FreeEntry  #############
*   Purpose....: Free partition entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TIdePartitionTable::FreeEntry(int Entry)
{
    TIdePartition *Part;
    TIdePartitionTable *PartTable;
    int i;
    int Count;

    Part = PartArr[Entry];
    if (Part->IsFs() || Part->IsTable())
    {
        PartArr[Entry] = new TIdePartition(FDisc, 0, 0, Entry, 0, 0);

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
    {
        if (FParent)
        {
            FParent->FreeEntry(FControlEntry);
            delete this;
        }
    }
}

/*##################  TIdeFsPartition::TIdeFsPartition  #############
*   Purpose....: Partition filesystem constructor                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFsPartition::TIdeFsPartition(TDisc *Disc, unsigned char Type, TIdePartitionTable *Parent, int Entry, long PStart, long PSize)
 : TIdePartition(Disc, Type, Parent, Entry, PStart, PSize)
{
    int DriveNr;

    DriveNr = FDisc->GetDrive(PStart, PSize);

    if (DriveNr)
        FDrive = new TDrive(DriveNr);
    else
        FDrive = 0;
}

/*##################  TIdeFsPartition::~TIdeFsPartition  #############
*   Purpose....: Partition filesystem destructor                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFsPartition::~TIdeFsPartition()
{
    if (FDrive)
        delete FDrive;
}

/*##################  TIdeFsPartition::GetDrive  #############
*   Purpose....: Get drive nr                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDrive *TIdeFsPartition::GetDrive()
{
    return FDrive;
}

/*##################  TIdeFsPartition::GetFreeSpace  #############
*   Purpose....: Get free space in MB                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
double TIdeFsPartition::GetFreeSpace()
{
    if (FDrive)
        return (double)FDrive->GetFreeSectors() * (double)GetBytesPerSector() / (double)0x100000;
    else
        return 0;
}

/*##################  TIdeFsPartitionEntry::GetPartName  #############
*   Purpose....: Get partition name                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TIdeFsPartition::GetPartName()
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

/*##################  TIdeFsPartition::IsFs  #############
*   Purpose....: Check for filesystem                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TIdeFsPartition::IsFs()
{
    return TRUE;
}

/*##################  TIdeFsPartition::Format  #############
*   Purpose....: Format partition                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TIdeFsPartition::Format()
{
    return FALSE;
}

/*##################  TIdeFsPartitionFactory::TIdeFsPartitionFactory  #############
*   Purpose....: Filesystem partition factory constructor                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFsPartitionFactory::TIdeFsPartitionFactory(unsigned char Type, const char *FsName)
  : FFsName(FsName)
{
     FType = Type;
     Insert();
}

/*##################  TIdeFsPartitionFactory::~TIdeFsPartitionFactory  #############
*   Purpose....: Filesystem partition factory destructor                                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFsPartitionFactory::~TIdeFsPartitionFactory()
{
    Remove();
}

/*##################  TIdeFsPartitionFactory::GetFs  #############
*   Purpose....: Get partition FS name                                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TString TIdeFsPartitionFactory::GetFs(TDisc *Disc, long Start)
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

/*##################  TIdeFsPartitionFactory::Parse  #############
*   Purpose....: Parse entry for filesystem                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFsPartition *TIdeFsPartitionFactory::Parse(TDisc *Disc, unsigned char Type, TIdePartitionTable *Parent, int Entry, long Start, long Size)
{
    TIdeFsPartition *part;
    TIdeFsPartitionFactory *factory = 0;
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
        part = new TIdeFsPartition(Disc, Type, Parent, Entry, Start, Size);

    if (part)
        part->FsName = FsName;

    return part;
}

/*##################  TIdeFsPartitionFactory::Format  #############
*   Purpose....: Format a filesystem                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFsPartition *TIdeFsPartitionFactory::Format(TDisc *Disc, const char *FsName, TIdePartitionTable *Parent, int Entry, long Start, long Size, const char *BootCode, int BootSize)
{
    TIdeFsPartitionFactory *factory = 0;
    TString Name(FsName);

    factory = FPartList;
    while (factory)
    {
        if (Name == factory->FFsName)
            break;
        factory = factory->FList;
    }

    if (factory)
        return factory->Create(Disc, Parent, Entry, Start, Size, BootCode, BootSize);
    else
        return 0;
}

/*##################  TIdeFsPartitionFactory::Insert  ##########################
*   Purpose....: Insert partition factory into list                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TIdeFsPartitionFactory::Insert()
{
    FList = FPartList;
    FPartList = this;
}

/*##################  TIdeFsPartitionFactory::Remove  ##########################
*   Purpose....: Remove partition factory from list                                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TIdeFsPartitionFactory::Remove()
{
    TIdeFsPartitionFactory *ptr;
    TIdeFsPartitionFactory *prev;
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

/*##################  TIdeDiscPartition::TIdeDiscPartition  #############
*   Purpose....: IDE Disc partition constructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeDiscPartition::TIdeDiscPartition(TDisc *Disc)
  : TDiscPartition(Disc)
{
    PartRoot = 0;
    Load();
}

/*##################  TIdeDiscPartition::~TIdeDiscPartition  #############
*   Purpose....: IDE Disc partition destructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeDiscPartition::~TIdeDiscPartition()
{
    if (PartRoot)
        delete PartRoot;
}

/*##################  TDiscPartition::InsertTable  #############
*   Purpose....: Insert partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TIdeDiscPartition::InsertTable(TIdePartitionTable *PartTable)
{
    int i;

    for (i = 0; i < 4; i++)
    {
        if (PartTable->PartArr[i])
        {
            if (PartTable->PartArr[i]->IsTable())
                InsertTable((TIdePartitionTable *)PartTable->PartArr[i]);
            else
                InsertEntry(PartTable->PartArr[i]);
        }
    }
}

/*##################  TDiscPartition::CreateArr  #############
*   Purpose....: Create partition array
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TIdeDiscPartition::CreateArr()
{
    InsertTable(PartRoot);
}

/*##################  TDiscPartition::Load  #############
*   Purpose....: Load partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TIdeDiscPartition::Load()
{
    char Buf[512];
    const char *Name;

    PartRoot = new TIdePartitionTable(FDisc, 0, 0, 0, 0, 0);
    PartRoot->Start = 0;
    if (FDisc->IsValid())
    {
        Name = PartRoot->GetPartName();
        PartRoot->FTotalSectors = (int)FDisc->GetTotalSectors();
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

/*##################  TIdeDiscPartition::Add  #############
*   Purpose....: Add IDE partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TIdeDiscPartition::Add(const char *FsName, long Sectors, const char *BootCode, int BootSize)
{
    int i;
    TIdeFsPartition *FsPart;
    long Size;
    long Start;
    long SectorsPerCyl = FDisc->GetSectorsPerCyl();

    for (i = 0; i < PartCount; i++)
    {
        if (PartArr[i]->IsFree())
        {
            Start = PartArr[i]->Start;
            Size = PartArr[i]->Size;

            if (Start < SectorsPerCyl)
            {
                if (SectorsPerCyl == 0xFFFF)
                {
                    Start += 16;
                    Size -= 16;
                }
                else
                {
                    Start += SectorsPerCyl;
                    Size -= SectorsPerCyl;
                }
            }
                    
            if (Size >= Sectors)
            {
                PartArr[i]->Start = Start;
                PartArr[i]->Size = Size;
                if (i == 0)
                    FsPart = PartRoot->InsertFs(FsName, (TFreePartition *)PartArr[i], Sectors, 0x80, BootCode, BootSize);
                else
                    FsPart = PartRoot->InsertFs(FsName, (TFreePartition *)PartArr[i], Sectors, 0, BootCode, BootSize);

                if (FsPart)
                {
                    PartArr[i]->Size -= Sectors;
                    PartArr[i]->Start += Sectors;
                    PartArr[PartCount] = FsPart;
                    PartCount++;
                    Sort();
                    return TRUE;
                }
            }
        }
    }
    return FALSE;
}

/*##################  TIdeDiscPartition::Add  #############
*   Purpose....: Add IDE partition with space
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TIdeDiscPartition::Add(const char *FsName, long Resv, long Sectors, const char *BootCode, int BootSize)
{
    int i;
    TIdeFsPartition *FsPart;
    long TotalSectors = Resv + Sectors;
    long Size;
    long Start;
    long SectorsPerCyl = FDisc->GetSectorsPerCyl();

    for (i = 0; i < PartCount; i++)
    {
        if (PartArr[i]->IsFree())
        {
            Start = PartArr[i]->Start;
            Size = PartArr[i]->Size;

            if (Start < SectorsPerCyl)
            {
                if (SectorsPerCyl == 0xFFFF)
                {
                    Start += 16;
                    Size -= 16;
                }
                else
                {
                    Start += SectorsPerCyl;
                    Size -= SectorsPerCyl;
                }
            }
                    
            if (Size >= TotalSectors)
            {
                PartArr[i]->Start = Start + Resv;
                PartArr[i]->Size = Size;
                if (i == 0)
                    FsPart = PartRoot->InsertFs(FsName, (TFreePartition *)PartArr[i], Sectors, 0x80, BootCode, BootSize);
                else
                    FsPart = PartRoot->InsertFs(FsName, (TFreePartition *)PartArr[i], Sectors, 0, BootCode, BootSize);

                if (FsPart)
                {
                    PartArr[i]->Size -= TotalSectors;
                    PartArr[i]->Start += TotalSectors;
                    PartArr[PartCount] = FsPart;
                    PartCount++;
                    Sort();
                    return TRUE;
                }
            }
        }
    }
    return FALSE;
}

/*##################  TIdeDiscPartition::Delete  #############
*   Purpose....: Delete IDE partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TIdeDiscPartition::Delete(int Entry)
{
    TIdePartition *Part;

    Part = (TIdePartition *)PartArr[Entry];
    if (Part->FParent)
        Part->FParent->FreeEntry(Part->FControlEntry);
}
