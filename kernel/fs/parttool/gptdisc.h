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
# gptdisc.h
# GPT disc class
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
    TGptPartition(struct TGptPartEntry *entry, const char *guid);
    ~TGptPartition();

    struct TGptPartEntry Entry;
    char Guid[40];
};

class TGptTable
{
public:
    TGptTable();
    ~TGptTable();

    void ReadTable(TDisc *Disc, long long StartSector);
    void InitHeader(TDisc *disc, bool primary);
    void Recreate(TDisc *Disc, TGptTable *Src);
    bool Add(struct TGptPartEntry *PartEntry);

    bool HeaderOk;

    struct TGptPartHeader Header;

    TGptPartEntry **PartArr;
    int PartCount;
    int MaxPartCount;

protected:
    void ReadEntryArr(TDisc *Disc);
    void WriteHeader(TDisc *Disc);

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
    void AddPossibleFs(struct TGptPartEntry *entry);
    const char *GetGuid(const char *FsName);
    void WriteGptBoot();

    virtual bool CreatePart(int Handle, int Type, long long Start, long long Sectors);

    int FLoaderSectors;
    char *FBootLoader;
    int FLoaderSize;
};

#endif

