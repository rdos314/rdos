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
