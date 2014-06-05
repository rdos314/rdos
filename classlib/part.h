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

class TPartition
{
public:
	TPartition(TDisc *Disc, long Start, long Size);
	virtual ~TPartition();

	TDisc *GetDisc();
	int GetBytesPerSector();
	double GetTotalSpace();

	int Read(long Sector, char *Buf, int Size);
	int Write(long Sector, const char *Buf, int Size);

	virtual TDrive *GetDrive();
	virtual double GetFreeSpace();
	virtual const char *GetPartName() = 0;
	virtual int IsFree();
    virtual int IsFs();

	TDisc *FDisc;
	long Start;
	long Size;
};

class TFreePartition : public TPartition
{
public:
	TFreePartition(TDisc *Disc);
	virtual ~TFreePartition();

	virtual const char *GetPartName();
	virtual int IsFree();
};

class TDiscPartition
{
public:
	TDiscPartition(TDisc *Disc);
	virtual ~TDiscPartition();

	TDisc *GetDisc();

	virtual void Delete(int Entry) = 0;
	virtual int Add(const char *FsName, long Size, const char *BootCode, int BootSize) = 0;

	int PartCount;
	TPartition *PartArr[MAX_PART_COUNT];

protected:
	void InsertEntry(TPartition *Part);
	void Sort();
	void AddFree();

	TDisc *FDisc;
};

#endif
