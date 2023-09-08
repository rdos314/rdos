/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-20019, Leif Ekblad
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
# fs.h
# Fat class
#
########################################################################*/

#ifndef _MBR_DISC_H
#define _MBR_DISC_H

#include "discpart.h"

struct TMbrChs
{
    unsigned char Head;
    unsigned short int CylSector;
};

struct TMbrPartitionEntry
{
    char Status;
    struct TMbrChs ChsStart;
    char Type;
    struct TMbrChs ChsEnd;
    unsigned int LbaStart;
    unsigned int LbaCount;
};

struct TBootParamBlock
{
    short int BytesPerSector;
    char Resv1;
    short int MappingSectors;
    char Resv3;
    short int Resv4;
    short int SmallSectors;
    char Media;
    short int Resv6;
    unsigned short int SectorsPerCyl;
    unsigned short int Heads;
    int HiddenSectors;
    int Sectors;
    char Drive;
    char Resv7;
    char Signature;
    int Serial;
    char Volume[11];
    char Fs[8];
};

class TMbrDisc;
class TMbrPartitionTable;

class TMbrPartition : public TPartition
{
public:
    TMbrPartition(struct TMbrPartitionTable *Parent, int Index, struct TMbrPartitionEntry *Entry, unsigned int StartSector, unsigned int SectorCount);
    virtual ~TMbrPartition();

    virtual bool IsTable();

    struct TMbrPartitionTable *FParent;
    int FIndex;

    struct TMbrPartitionEntry FPartEntry;
};

class TMbrPartitionTable : public TMbrPartition
{
public:
    TMbrPartitionTable(struct TMbrPartitionTable *Parent, int Index, struct TMbrPartitionEntry *Entry, unsigned int Start, unsigned int Size);
    virtual ~TMbrPartitionTable();

    virtual bool IsTable();

    void Process(TMbrDisc *disc, char *data);
    struct TMbrPartition *AddEntry(TMbrDisc *Disc, char Type, unsigned int Start, unsigned int Size);
    void DeletePart(TMbrPartition *part);

    TMbrPartition *PartArr[4];

protected:
    void ProcessOne(TMbrDisc *disc, int index, struct TMbrPartitionEntry *entry);
    bool ProcessTable(TMbrDisc *Disc, TMbrPartitionTable *TablePart);
    bool WriteEntry(TMbrDisc *Disc, int Index, struct TMbrPartitionEntry *entry);
};

class TMbrDisc : public TDisc
{
public:
    TMbrDisc(TDiscServer *server);
    ~TMbrDisc();

    unsigned int ChsToLba(struct TMbrChs *entry);
    void LbaToChs(unsigned int Sector, struct TMbrChs *Entry);

    char PartToType(int Type, long long Sectors);
    int TypeToPart(char Type);

    virtual bool IsGpt();
    virtual bool LoadPart();    
    virtual bool InitPart();    
    virtual bool AddPart(const char *FsName, long long Sectors);

    TMbrPartitionTable PartRoot;

protected:
    virtual bool CreatePart(int Handle, int Type, long long Start, long long Sectors);
    virtual void DeletePart(TPartition *part);

    void LoadBootLoader();
    bool WriteBootSector();
    bool WriteBootLoader();

    void AddPossibleFs(struct TMbrPartition *part);
    void AddFsParts(struct TMbrPartitionTable *table);

    int FSectorsPerCyl;
    int FHeads;

    int FLoaderSectors;
    char *FBootLoader;
    int FLoaderSize;
};

#endif

