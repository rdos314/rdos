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
# rdfspart.h
# RDFS partition class
#
########################################################################*/

#ifndef _RDFSPART_H
#define _RDFSPART_H

#include "part.h"

#define INFO_STATE_NONE		0
#define INFO_STATE_ALLOC	1
#define INFO_STATE_FREE 	2

struct TInfoSector
{
	int FirstId;
	int FreeArr;
	int FreeArrSize;
	int StartSector;
	int TotalSectors;
	int RootDir;
	int DataSectors;
	int FreeSectors;
	int HoleStart;
	int HoleSize;
	int TargetSector;
	short int TargetOffset;
	short int State;
	int Sector;
};

#define CONTROL_FLAG_DIR 1
#define CONTROL_FLAG_BACKUP 2

struct TControlSector
{
	char Version;
	char Flags;
	short int KeyOffset;
	int Size;
	int SectorArr[126];
};

struct TRdfsDirSectorHeader
{
	char Version;
	char Checksum;
};

struct TRdfsDirBlock
{
	short int FPrev;
	short int FNext;
	short int SPrev;
	short int SNext;
};

struct TRdfsDirPtr
{
	short int RelSector;
	short int Offset;
};

struct TRdfsDirSector
{
	short int FreeList;
};

struct TRdfsDirHeader
{
	TRdfsDirPtr DirList;
	TRdfsDirPtr FileList;
};

struct TRdfsDirEntry
{
	long Time[2];
	short int Attrib;
	short int NameSize;
	TRdfsDirPtr Name;
	long StartSector;
};

struct TKey
{
	short int start;
	short int inc0;
	short int inc1;
	short int max;
};

class TRdfsPartition : public TFsPartition
{
public:
	TRdfsPartition(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size);
	virtual const char *GetPartName();
	virtual int Format();

protected:
};

class TRdfsPartitionFactory : public TFsPartitionFactory
{
public:
	TRdfsPartitionFactory(int BootSectorID);
	TRdfsPartitionFactory();
	virtual ~TRdfsPartitionFactory();

	char CryptTab[4096];
	TKey KeyTab[2048];
	long ExtentSizeTab[128];
	char BootSector[512];

protected:
	virtual TFsPartition *Open(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size);
	virtual TFsPartition *Create(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size);

	int FBootSectorID;

private:
	void Init();
};

#endif

