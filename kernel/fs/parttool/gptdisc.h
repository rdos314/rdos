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

#ifndef _GPT_DISC_H
#define _GPT_DISC_H

#include "discpart.h"

#define MAX_GPT_PART_COUNT  64

struct TGptPartHeader
{
    char Sign[8];
    char Revision[4];
    int HeaderSize;
    unsigned int Crc32;
    int Resv;
    long long CurrLba;
    long long OtherLba;
    long long FirstLba;
    long long LastLba;
    char Guid[16];
    long long EntryLba;
    int EntryCount;
    int EntrySize;
    int EntryCrc32;
};

struct TGptPartEntry
{
    char PartGuid[16];
    char UniqueGuid[16];
    long long FirstLba;
    long long LastLba;
    long long Attrib;
    short int Name[36];
};

class TGptPartition : public TPartition
{
public:
    TGptPartition(int Index, struct TGptPartEntry *Entry);
    ~TGptPartition();

    int FIndex;
    struct TGptPartEntry FEntry;
};

class TGptTable
{
public:
    TGptTable();
    ~TGptTable();

    void ReadTable(TDisc *Disc, long long StartSector);
    void Recreate(TDisc *Disc, TGptTable *Src);
    bool Add(struct TGptPartEntry *PartEntry);

    bool HeaderOk;

    struct TGptPartHeader Header;

    TGptPartEntry **PartArr;
    int PartCount;
    int MaxPartCount;

protected:
    void ReadEntryArr(TDisc *Disc);
    void InitHeader(long long MyLba, long long OtherLba);

    void GrowPart();
};

class TGptDisc : public TDisc
{
public:
    TGptDisc(TDiscServer *server);
    ~TGptDisc();

    virtual bool IsGpt();
    virtual bool InitPart();
    virtual bool LoadPart();
    virtual bool AddPart(const char *FsName, long long Sectors);

    TGptTable PrimaryTable;
    TGptTable SecondaryTable;

protected:
    virtual bool CreatePart(int Handle, int Type, long long Start, long long Sectors);

    void MergeTables();
};

#endif

