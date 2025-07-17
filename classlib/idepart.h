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
        virtual int Add(const char *FsName, long Resv, long Size, const char *BootCode, int BootSize);

        TIdePartitionTable *PartRoot;

protected:
        void Load();
        void InsertTable(TIdePartitionTable *PartTable);
        void CreateArr();
};

#endif

