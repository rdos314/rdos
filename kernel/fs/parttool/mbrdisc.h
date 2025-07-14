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
# mbrdisc.h
# MBR disc class
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

