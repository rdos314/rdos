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

#include "idepart.h"

class TIdeFatPartition : public TIdeFsPartition
{
public:
        TIdeFatPartition(TDisc *Disc, unsigned char Type, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual ~TIdeFatPartition();        

protected:
    void WriteBootSector(const char *BootCode, int BootSize);
};

class TIdeFat12Partition : public TIdeFatPartition
{
public:
        TIdeFat12Partition(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual ~TIdeFat12Partition();        
        virtual const char *GetPartName();
        virtual int Format(const char *BootCode, int BootSize);
};

class TIdeFat16Partition : public TIdeFatPartition
{
public:
        TIdeFat16Partition(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual ~TIdeFat16Partition();        
        virtual const char *GetPartName();
        virtual int Format(const char *BootCode, int BootSize);
};

class TIdeFat32Partition : public TIdeFatPartition
{
public:
        TIdeFat32Partition(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual ~TIdeFat32Partition();        
        virtual const char *GetPartName();
        virtual int Format(const char *BootCode, int BootSize);
};

class TIdeFat12PartitionFactory : public TIdeFsPartitionFactory
{
public:
        TIdeFat12PartitionFactory();
        virtual ~TIdeFat12PartitionFactory();

protected:
        virtual TIdeFsPartition *Open(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual TIdeFsPartition *Create(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size, const char *BootCode, int BootSize);
};

class TIdeFat16PartitionFactory : public TIdeFsPartitionFactory
{
public:
        TIdeFat16PartitionFactory();
        virtual ~TIdeFat16PartitionFactory();

protected:
        virtual TIdeFsPartition *Open(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual TIdeFsPartition *Create(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size, const char *BootCode, int BootSize);
};

class TIdeFat32PartitionFactory : public TIdeFsPartitionFactory
{
public:
        TIdeFat32PartitionFactory();
        virtual ~TIdeFat32PartitionFactory();

protected:
        virtual TIdeFsPartition *Open(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual TIdeFsPartition *Create(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size, const char *BootCode, int BootSize);
};

#endif

