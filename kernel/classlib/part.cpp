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

#include <mem.h>
#include <stdio.h>

#include "rdos.h"
#include "part.h"

#define FALSE	0
#define TRUE	!FALSE

/*##################  TPartition::TPartition  #############
*   Purpose....: Partition constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TPartition::TPartition(int Disc, unsigned char Type, TPartitionTable *Parent, int Entry)
{
	FDisc = Disc;
	FParent = Parent;
	FControlEntry = Entry;
	FType = Type;
	Start = 0;
	Size = 0;
}

/*##################  TPartition::GetPartName  #############
*   Purpose....: Get partition name						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
char *TPartition::GetPartName()
{
	return "Free    ";
}

/*##################  TPartition::GetDisc  #############
*   Purpose....: Get disc nr						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartition::GetDisc()
{
	return FDisc;
}

/*##################  TPartition::GetType  #############
*   Purpose....: Get partition type						                    #
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
*   Purpose....: Get bytes per sector						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartition::GetBytesPerSector()
{
	int BytesPerSector;
	long Sectors;
	int SectorsPerCyl;
    int Heads;

	if (RdosGetDiscInfo(FDisc, &BytesPerSector, &Sectors, &SectorsPerCyl, &Heads))
		return BytesPerSector;
	else
		return 0;
}

/*##################  TPartition::GetSpace  #############
*   Purpose....: Get space in MB						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
double TPartition::GetSpace()
{
	return (double)Size * (double)GetBytesPerSector() / (double)0x100000;
}

/*##################  TPartition::IsTable  #############
*   Purpose....: Check if entry is table				                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartition::IsTable()
{
	return FALSE;
}

/*##################  TPartition::IsEntry  #############
*   Purpose....: Check if entry is entry				                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartition::IsEntry()
{
	return FALSE;
}

/*##################  TPartition::IsFree  #############
*   Purpose....: Check if entry is free				                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartition::IsFree()
{
	return FALSE;
}

/*##################  TPartition::Write  #############
*   Purpose....: Write partition entry to disc
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartition::Write(TPartitionTable *Owner)
{
	char Buf[512];
	char *PartPtr;

	if (!FParent)
		return;

	RdosReadDisc(FDisc, FParent->Start, Buf, 512);
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

	*PartPtr = 0;
	Owner->LbaToChs(Start, PartPtr + 1);
	*(PartPtr + 4) = FType;
	Owner->LbaToChs(Start + Size - 1, PartPtr + 5);
	*(long *)(PartPtr + 8) = Start - Owner->Start;
	*(long *)(PartPtr + 0xC) = Size;

	RdosWriteDisc(FDisc, FParent->Start, Buf, 512);
}

/*##################  TPartition::Delete  #############
*   Purpose....: Delete partition entry on disc
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartition::Delete(TPartitionTable *Owner)
{
	char Buf[512];
	char *PartPtr;

	if (!FParent)
		return;

	RdosReadDisc(FDisc, FParent->Start, Buf, 512);
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

	RdosWriteDisc(FDisc, FParent->Start, Buf, 512);
}

/*##################  TPartitionEntry::TPartitionEntry  #############
*   Purpose....: Partition entry constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TPartitionEntry::TPartitionEntry(int Disc, unsigned char Type, TPartitionTable *Parent, int Entry)
 : TPartition(Disc, Type, Parent, Entry)
{
	FsName[0] = 0;
}

/*##################  TPartitionEntry::GetPartName  #############
*   Purpose....: Get partition name						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
char *TPartitionEntry::GetPartName()
{
	if (FsName[0])
		return FsName;
	else
	{
		switch (FType)
		{
			case 1:
				return "FAT12   ";

			case 4:
			case 6:
				return "FAT16   ";

			case 7:
				return "Custom  ";

			case 0xB:
			case 0xC:
				return "FAT32   ";

			case 0x81:
				return "Linux   ";

			case 0x82:
				return "Swap    ";

			case 0x83:
				return "EXT2FS  ";

			default:
				return "???     ";
		}
	}
}

/*##################  TPartitionEntry::IsEntry  #############
*   Purpose....: Check if entry is entry				                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartitionEntry::IsEntry()
{
	return TRUE;
}

/*##################  TPartitionEntry::GetFs  #############
*   Purpose....: Get partition FS name						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartitionEntry::GetFs()
{
	char Buf[512];
	int BytesPerSector;
	long Sectors;
	int SectorsPerCyl;
	int Heads;

	if (RdosGetDiscInfo(FDisc, &BytesPerSector, &Sectors, &SectorsPerCyl, &Heads))
	{
		if (Start < Sectors)
		{
			RdosReadDisc(FDisc, Start, Buf, 512);
			memcpy(FsName, &Buf[0x36], 8);
			FsName[8] = 0;
		}
	}
}

/*##################  TPartitionFree::TPartitionFree  #############
*   Purpose....: Partition free constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TPartitionFree::TPartitionFree(int Disc)
 : TPartition(Disc, 0, 0, 0)
{
}

/*##################  TPartitionFree::GetPartName  #############
*   Purpose....: Get partition name						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
char *TPartitionFree::GetPartName()
{
	return "Free    ";
}

/*##################  TPartitionFree::IsFree  #############
*   Purpose....: Check if entry is free				                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartitionFree::IsFree()
{
	return TRUE;
}

/*##################  TPartitionTable::TPartitionTable  #############
*   Purpose....: Partition table constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TPartitionTable::TPartitionTable(int Disc, unsigned char Type, TPartitionTable *Parent, int Entry)
 : TPartition(Disc, Type, Parent, Entry)
{
	int i;

	for (i = 0; i < 4; i++)
		PartArr[i] = 0;
}

/*##################  TPartitionTable::~TPartitionTable  #############
*   Purpose....: Partition table destructor							                    #
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
*   Purpose....: Check if entry is table				                    #
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
*   Purpose....: Get partition name						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
char *TPartitionTable::GetPartName()
{
	return "Table   ";
}

/*##################  TPartitionTable::ChsToLba  #############
*   Purpose....: Convert CHS to LBA						                    #
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
*   Purpose....: Convert LBA to CHS						                    #
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
	TPartitionEntry *EntryPart = 0;
	TPartitionTable *TablePart = 0;

	Type = *(Data + 4);
	switch (Type)
	{
		case 0:
			Part = new TPartition(FDisc, Type, 0, Entry);
			break;

		case 5:
		case 0xF:
			TablePart = new TPartitionTable(FDisc, Type, this, Entry);
			Part = TablePart;
			break;

		default:
			EntryPart = new TPartitionEntry(FDisc, Type, this, Entry);
			Part = EntryPart;
			break;
	}

	Part->Start = ChsToLba(Data + 1);
	if (Part->Start)
	{
		Part->Size = ChsToLba(Data + 5);
		if (Part->Size)
			Part->Size = Part->Size - Part->Start + 1;
		else
			Part->Size = *(long *)(Data + 0xC);
	}
	else
	{
		Part->Start = Start + *(long *)(Data + 8);
		Part->Size = *(long *)(Data + 0xC);
	}

	if (EntryPart)
		EntryPart->GetFs();

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
		RdosReadDisc(FDisc, Start, Buf, 512);
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
TPartitionTable *TPartitionTable::Create(int Entry, TPartitionFree *PartFree)
{
	TPartitionTable *PartTable;
	int i;
	char Buf[512];

	PartTable = new TPartitionTable(FDisc, 0xF, this, Entry);
	PartTable->FTotalSectors = FTotalSectors;
	PartTable->FHeads = FHeads;
	PartTable->FSectorsPerCyl = FSectorsPerCyl;
	PartTable->Start = PartFree->Start;
	PartTable->Size = PartFree->Size;
	PartFree->Start++;
	PartFree->Size--;
	for (i = 0; i < 4; i++)
		PartTable->PartArr[i] = new TPartition(FDisc, 0, 0, i);

	memset(Buf, 0, 512);
	Buf[510] = 0x55;
	Buf[511] = 0xAA;
	RdosWriteDisc(FDisc, PartTable->Start, Buf, 512);
	PartArr[Entry] = PartTable;
	PartTable->Write(this);

	return PartTable;
}

/*##################  TPartitionTable::AllocateEntry  #############
*   Purpose....: Allocate partition entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TPartitionEntry *TPartitionTable::AllocateEntry(unsigned char NewType, TPartitionFree *PartFree, long NewSize)
{
	int i;
	TPartitionEntry *PartEntry;
	TPartitionTable *PartTable;
	int FreeEntries;

	if (Start > PartFree->Start)
		return 0;

	if (Start + Size < PartFree->Start)
		return 0;

	for (i = 0; i < 4; i++)
		if (PartArr[i])
		{
			if (PartArr[i]->IsTable())
			{
				if (PartArr[i]->Start <= PartFree->Start && PartArr[i]->Start + PartArr[i]->Size >= PartFree->Start)
					return ((TPartitionTable *)PartArr[i])->AllocateEntry(NewType, PartFree, NewSize);
			}
		}

	FreeEntries = 0;
	for (i = 0; i < 4; i++)
		if (PartArr[i])
			if (!PartArr[i]->IsEntry() && !PartArr[i]->IsTable())
				FreeEntries++;

	if (FreeEntries <= 2)
	{
		for (i = 0; i < 4; i++)
			if (PartArr[i])
				if (!PartArr[i]->IsEntry() && !PartArr[i]->IsTable())
				{
					delete PartArr[i];
					PartTable = Create(i, PartFree);
					PartArr[i] = PartTable;
					return PartTable->AllocateEntry(NewType, PartFree, NewSize);
				}
	}

	for (i = 0; i < 4; i++)
		if (PartArr[i])
		{
			if (!PartArr[i]->IsEntry() && !PartArr[i]->IsTable())
			{
				delete PartArr[i];
				PartEntry = new TPartitionEntry(FDisc, NewType, this, i);
				PartEntry->Start = PartFree->Start;
				PartEntry->Size = NewSize;
				PartArr[i] = PartEntry;
				PartEntry->Write(this);
				return PartEntry;
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
	int i;
	int Count;

	Part = PartArr[Entry];
	if (Part->IsEntry() || Part->IsTable())
	{
		PartArr[Entry] = new TPartition(FDisc, 0, 0, Entry);
		Part->Delete(this);
		delete Part;
	}

	Count = 0;
	for (i = 0; i < 4; i++)
		if (PartArr[i]->IsEntry() || PartArr[i]->IsTable())
			Count++;

	if (Count == 0)
		if (FParent)
		{
			FParent->FreeEntry(FControlEntry);
			delete this;
		}
}

/*##################  TPartitionData::TPartitionData  #############
*   Purpose....: Partition data constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TPartitionData::TPartitionData(int Disc)
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

/*##################  TPartitionData::Free  #############
*   Purpose....: Free partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartitionData::Free()
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

/*##################  TPartitionData::GetParams  #############
*   Purpose....: Get partition params					                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartitionData::GetParams()
{
	return RdosGetDiscInfo(FDisc, &BytesPerSector, &TotalSectors, &SectorsPerCyl, &Heads);
}

/*##################  TPartitionData::InsertEntry  #############
*   Purpose....: Insert partition entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartitionData::InsertEntry(TPartition *Part)
{
	if (Part->IsEntry())
	{
		PartArr[PartCount] = Part;
		PartCount++;
	}
}

/*##################  TPartitionData::InsertTable  #############
*   Purpose....: Insert partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartitionData::InsertTable(TPartitionTable *PartTable)
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

/*##################  TPartitionData::CreateArr  #############
*   Purpose....: Create partition array
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartitionData::CreateArr()
{
	InsertTable(PartRoot);
}

/*##################  TPartitionData::Sort  #############
*   Purpose....: Sort partition array
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartitionData::Sort()
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

/*##################  TPartitionData::AddFree  #############
*   Purpose....: Add free entries partition array
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartitionData::AddFree()
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
			PartArr[i] = new TPartitionFree(FDisc);
			PartArr[i]->Start = Start;
			PartArr[i]->Size = PartArr[i+1]->Start - Start - 1;
			PartCount++;
		}
		Start = PartArr[i]->Start + PartArr[i]->Size;
	}

	if (Start + 1024 < TotalSectors)
	{
		PartArr[i] = new TPartitionFree(FDisc);
		PartArr[i]->Start = Start;
		PartArr[i]->Size = TotalSectors - Start;
		PartCount++;
	}
}

/*##################  TPartitionData::GetDisc  #############
*   Purpose....: Get disc
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartitionData::GetDisc()
{
	return FDisc;
}

/*##################  TPartitionData::Update  #############
*   Purpose....: Update partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartitionData::Update()
{
	char Buf[512];

	Free();

	PartRoot = new TPartitionTable(FDisc, 0, 0, 0);
	PartRoot->Start = 0;
	if (GetParams() && BytesPerSector)
	{
		PartRoot->FTotalSectors = TotalSectors;
		PartRoot->FHeads = Heads;
		PartRoot->FSectorsPerCyl = SectorsPerCyl;
		PartRoot->Size = PartRoot->FTotalSectors;
		RdosReadDisc(FDisc, 0, Buf, 512);
		PartRoot->ProcessOne(0, &Buf[0x1BE]);
		PartRoot->ProcessOne(1, &Buf[0x1CE]);
		PartRoot->ProcessOne(2, &Buf[0x1DE]);
		PartRoot->ProcessOne(3, &Buf[0x1EE]);

		CreateArr();
		Sort();
		AddFree();
	}
	else
	{
		delete PartRoot;
		PartRoot = 0;
	}
}

/*##################  TPartitionData::Add  #############
*   Purpose....: Add partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TPartitionEntry *TPartitionData::Add(unsigned char Type, long Sectors)
{
	int i;
	TPartitionEntry *PartEntry;

	for (i = 0; i < PartCount; i++)
		if (PartArr[i]->IsFree())
		{
			if (PartArr[i]->Size >= Sectors)
			{
				PartEntry = PartRoot->AllocateEntry(Type, (TPartitionFree *)PartArr[i], Sectors);
				if (PartEntry)
				{
					PartArr[i]->Size -= Sectors;
					PartArr[i]->Start += Sectors;
					PartArr[PartCount] = PartEntry;
					PartCount++;
					Sort();
					return PartEntry;
				}
			}
		}
	return 0;
}

/*##################  TPartitionData::Delete  #############
*   Purpose....: Delete partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TPartitionData::Delete(int Entry)
{
	TPartition *Part;
	int i;

	Part = PartArr[Entry];
	if (Part->FParent)
	{
		Part->FParent->FreeEntry(Part->FControlEntry);
		delete Part;
	}

	PartCount--;
	for (i = Entry; i < PartCount; i++)
		PartArr[i] = PartArr[i+1];
}
