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

#include "str.h"
#include "disc.h"
#include "drive.h"

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
	short int Resv6;
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
class TDiscPartition;
class TFsPartition;

class TPartition
{
friend class TPartitionTable;
friend class TDiscPartition;
public:
	TPartition(TDisc *Disc, unsigned char Type, TPartitionTable *Parent, int Entry, long Start, long Size);
	virtual ~TPartition();

	TDisc *GetDisc();
	TDrive *GetDrive();
	unsigned char GetType();
	int GetBytesPerSector();
	double GetTotalSpace();
	double GetFreeSpace();

	virtual const char *GetPartName();
	virtual int IsTable();
	virtual int IsFs();
	virtual int IsFree();

	long Start;
	long Size;
	long DriveSectors;
	long FreeSectors;

protected:
	void WriteToTable(TPartitionTable *Owner, char Active);
	void DeleteFromTable(TPartitionTable *Owner);

	TDisc *FDisc;
	TDrive *FDrive;
	unsigned char FType;
	TPartitionTable *FParent;
	int FControlEntry;
};

class TFreePartition : public TPartition
{
public:
	TFreePartition(TDisc *Disc);

	virtual const char *GetPartName();
	virtual int IsFree();

protected:
};

class TPartitionTable : public TPartition
{
friend class TDiscPartition;
friend class TPartition;
public:
	TPartitionTable(TDisc *Disc, unsigned char Type, TPartitionTable *Parent, int Entry, long Start, long Size);
	virtual ~TPartitionTable();

	TPartitionTable *Create(int Entry, TFreePartition *FreePart);

	virtual const char *GetPartName();
	virtual int IsTable();

	TPartition *PartArr[4];

protected:
	long ChsToLba(const char *Data);
	void LbaToChs(long Sector, char *Data);
	void Process();
	void ProcessOne(int Entry, const char *Data);
	TFsPartition *InsertFs(const char *FsName, TFreePartition *FreePart, long Size, char Active);
	void FreeEntry(int Entry);

	int FSectorsPerCyl;
	int FHeads;
	long FTotalSectors;

};

class TFsPartition : public TPartition
{
friend class TPartitionTable;
friend class TFsPartitionFactory;
public:
	TFsPartition(TDisc *Disc, unsigned char Type, TPartitionTable *Parent, int Entry, long Start, long Size);

	virtual const char *GetPartName();
	virtual int IsFs();
	virtual int Format();

	int Read(long Sector, char *Buf, int Size);
	int Write(long Sector, const char *Buf, int Size);

	TString FsName;

protected:
};

class TFsPartitionFactory
{
public:
	TFsPartitionFactory(unsigned char Type, const char *FsName);
	virtual ~TFsPartitionFactory();

	static TFsPartition *Parse(TDisc *Disc, unsigned char Type, TPartitionTable *Parent, int Entry, long Start, long Size);
	static TFsPartition *Format(TDisc *Disc, const char *FsName, TPartitionTable *Parent, int Entry, long Start, long Size);

protected:
	virtual TFsPartition *Open(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size) = 0;
	virtual TFsPartition *Create(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size) = 0;

    static TString GetFs(TDisc *Disc, long Start);

	void Insert();
	void Remove();

	static TFsPartitionFactory *FPartList;
	TFsPartitionFactory *FList;

	unsigned char FType;
	TString FFsName;
};

class TDiscPartition
{
public:
	TDiscPartition(TDisc *Disc);

	void Update();
	TDisc *GetDisc();

	void Delete(int Entry);
	TFsPartition *Add(const char *FsName, long Size);

	TPartitionTable *PartRoot;
	TPartition *PartArr[MAX_PART_COUNT];
	int PartCount;

protected:
	void Free();
	int GetParams();
	void InsertTable(TPartitionTable *PartTable);
	void InsertEntry(TPartition *Part);
	void CreateArr();
	void Sort();
	void AddFree();

	TDisc *FDisc;
	char FBootSector[512];
	TBootParam *FBootParam;
};

#endif

