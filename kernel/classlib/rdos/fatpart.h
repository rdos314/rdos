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
# fatpart.h
# FAT partition class
#
########################################################################*/

#ifndef _FATPART_H
#define _FATPART_H

#include "part.h"

class TFatPartition : public TFsPartition
{
public:
	TFatPartition(int Disc, unsigned char Type, TPartitionTable *Parent, int Entry, long Start, long Size);
};

class TFat12Partition : public TFatPartition
{
public:
	TFat12Partition(int Disc, TPartitionTable *Parent, int Entry, long Start, long Size);
	virtual const char *GetPartName();
	virtual int Format();
};

class TFat16Partition : public TFatPartition
{
public:
	TFat16Partition(int Disc, TPartitionTable *Parent, int Entry, long Start, long Size);
	virtual const char *GetPartName();
	virtual int Format();
};

class TFat32Partition : public TFatPartition
{
public:
	TFat32Partition(int Disc, TPartitionTable *Parent, int Entry, long Start, long Size);
	virtual const char *GetPartName();
	virtual int Format();
};

class TFat12PartitionFactory : public TFsPartitionFactory
{
public:
	TFat12PartitionFactory();
	virtual ~TFat12PartitionFactory();

protected:
	virtual TFsPartition *Open(int Disc, TPartitionTable *Parent, int Entry, long Start, long Size);
	virtual TFsPartition *Create(int Disc, TPartitionTable *Parent, int Entry, long Start, long Size);
};

class TFat16PartitionFactory : public TFsPartitionFactory
{
public:
	TFat16PartitionFactory();
	virtual ~TFat16PartitionFactory();

protected:
	virtual TFsPartition *Open(int Disc, TPartitionTable *Parent, int Entry, long Start, long Size);
	virtual TFsPartition *Create(int Disc, TPartitionTable *Parent, int Entry, long Start, long Size);
};

class TFat32PartitionFactory : public TFsPartitionFactory
{
public:
	TFat32PartitionFactory();
	virtual ~TFat32PartitionFactory();

protected:
	virtual TFsPartition *Open(int Disc, TPartitionTable *Parent, int Entry, long Start, long Size);
	virtual TFsPartition *Create(int Disc, TPartitionTable *Parent, int Entry, long Start, long Size);
};

#endif

