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
# part.h
# Partion handling classes
#
########################################################################*/

#ifndef _PART_H
#define _PART_H

#define MAX_PART_COUNT	100

struct TBootParam
{
	short int BytesPerSector;
	char Resv1;
	short int MappingSectors;
	char Resv3;
	short int Resv4;
	short int SmallSectors;
	char Media;
	char Resv6;
	short int SectorsPerCyl;
	short int Heads;
	int HiddenSectors;
	int Sectors;
	char Drive;
	char Resv7;
	char Signature;
	int Serial;
	char Volume[11];
	char Fs[8];
};

class TPartitionTable;
class TPartitionData;

class TPartition
{
friend class TPartitionTable;
friend class TPartitionData;
public:
	TPartition(int Disc, unsigned char Type, TPartitionTable *Parent, int Entry);
	int GetDisc();
	unsigned char GetType();
	int GetBytesPerSector();
	double GetSpace();

	virtual char *GetPartName();
	virtual int IsTable();
	virtual int IsEntry();
	virtual int IsFree();

	long Start;
	long Size;

protected:
	void Write(TPartitionTable *Owner);
	void Delete(TPartitionTable *Owner);

	int FDisc;
	unsigned char FType;
	TPartitionTable *FParent;
	int FControlEntry;
};

class TPartitionEntry : public TPartition
{
friend class TPartitionTable;
public:
	TPartitionEntry(int Disc, unsigned char Type, TPartitionTable *Parent, int Entry);

	virtual char *GetPartName();
	virtual int IsEntry();

	char FsName[9];

protected:
	virtual void GetFs();
};

class TPartitionFree : public TPartition
{
public:
	TPartitionFree(int Disc);

	virtual char *GetPartName();
	virtual int IsFree();

protected:
};

class TPartitionTable : public TPartition
{
friend class TPartitionData;
friend class TPartition;
public:
	TPartitionTable(int Disc, unsigned char Type, TPartitionTable *Parent, int Entry);
	virtual ~TPartitionTable();

	TPartitionTable *Create(int Entry, TPartitionFree *PartFree);

	virtual char *GetPartName();
	virtual int IsTable();

	TPartition *PartArr[4];

protected:
	long ChsToLba(const char *Data);
	void LbaToChs(long Sector, char *Data);
	void Process();
	void ProcessOne(int Entry, const char *Data);
	TPartitionEntry *AllocateEntry(unsigned char Type, TPartitionFree *PartFree, long Size);
	void FreeEntry(int Entry);

	int FSectorsPerCyl;
	int FHeads;
	long FTotalSectors;

};

class TPartitionData
{
public:
	TPartitionData(int Disc);

	void Update();
	int GetDisc();

	TPartitionTable *PartRoot;
	TPartition *PartArr[MAX_PART_COUNT];
	int PartCount;
	int BytesPerSector;
	int SectorsPerCyl;
	int Heads;
	long TotalSectors;

protected:
	void Free();
	int GetParams();
	void InsertTable(TPartitionTable *PartTable);
	void InsertEntry(TPartition *Part);
	void CreateArr();
	void Sort();
	void AddFree();
	void Delete(int Entry);
	TPartitionEntry *Add(unsigned char Type, long Size);

	int FDisc;
	char FBootSector[512];
	TBootParam *FBootParam;
};

#endif

