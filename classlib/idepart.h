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
# idepart.h
# IDE partion handling classes
#
########################################################################*/

#ifndef _IDEPART_H
#define _IDEPART_H

#include "str.h"
#include "disc.h"
#include "drive.h"
#include "part.h"

class TIdePartitionTable;

class TIdePartition : public TPartition
{
        friend class TIdePartitionTable;
        friend class TIdeDiscPartition;
public:
        TIdePartition(TDisc *Disc, unsigned char Type, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual ~TIdePartition();

        unsigned char GetType();

        virtual const char *GetPartName();
        virtual int IsTable();

protected:
        void WriteToTable(TIdePartitionTable *Owner, char Active);
        void DeleteFromTable(TIdePartitionTable *Owner);

        unsigned char FType;
        int FControlEntry;
        TIdePartitionTable *FParent;
};

class TIdeFsPartition;

class TIdePartitionTable : public TIdePartition
{
        friend class TIdeDiscPartition;
public:
        TIdePartitionTable(TDisc *Disc, unsigned char Type, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual ~TIdePartitionTable();

        TIdePartitionTable *Create(int Entry, TPartition *FreePart);

        virtual const char *GetPartName();
        virtual int IsTable();

        TIdePartition *PartArr[4];

protected:
        long ChsToLba(const char *Data);
        void LbaToChs(long Sector, char *Data);
        void Process();
        void ProcessOne(int Entry, const char *Data);
        TIdeFsPartition *InsertFs(const char *FsName, TFreePartition *FreePart, long Size, char Active, const char *BootCode, int BootSize);
        void FreeEntry(int Entry);

        int FSectorsPerCyl;
        int FHeads;
        long FTotalSectors;
};

class TIdeFsPartition : public TIdePartition
{
public:
        TIdeFsPartition(TDisc *Disc, unsigned char Type, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual ~TIdeFsPartition();

        virtual const char *GetPartName();
        virtual int IsFs();
        virtual int Format();
    	virtual TDrive *GetDrive();
    	virtual double GetFreeSpace();

        TString FsName;

protected:
        TDrive *FDrive;
};

class TIdeFsPartitionFactory
{
public:
        TIdeFsPartitionFactory(unsigned char Type, const char *FsName);
        virtual ~TIdeFsPartitionFactory();

        static TIdeFsPartition *Parse(TDisc *Disc, unsigned char Type, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        static TIdeFsPartition *Format(TDisc *Disc, const char *FsName, TIdePartitionTable *Parent, int Entry, long Start, long Size, const char *BootCode, int BootSize);

protected:
        virtual TIdeFsPartition *Open(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size) = 0;
        virtual TIdeFsPartition *Create(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size, const char *BootCode, int BootSize) = 0;

    static TString GetFs(TDisc *Disc, long Start);

        void Insert();
        void Remove();

        static TIdeFsPartitionFactory *FPartList;
        TIdeFsPartitionFactory *FList;

        unsigned char FType;
        TString FFsName;
};

class TIdeDiscPartition : public TDiscPartition
{
public:
        TIdeDiscPartition(TDisc *Disc);
    ~TIdeDiscPartition();

        virtual void Delete(int Entry);
        virtual int Add(const char *FsName, long Size, const char *BootCode, int BootSize);

        TIdePartitionTable *PartRoot;

protected:
        void Load();
        void InsertTable(TIdePartitionTable *PartTable);
        void CreateArr();
};

#endif

