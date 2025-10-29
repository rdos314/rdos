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
# gptpart.h
# GPT partion handling classes
#
########################################################################*/

#ifndef _GPTPART_H
#define _GPTPART_H

#include "str.h"
#include "disc.h"
#include "drive.h"

#define MAX_GPT_PART_COUNT  128

class TGptPartition
{
public:
        TGptPartition(TDisc *Disc, const char *Guid, long long StartSector, long long EndSector, const short int *Name);

    long double GetTotalSpace();

        int Usable;
        long long Start;
        long long Size;
        TDisc *FDisc;
        char GuidStr[40];
        char Name[40];

protected:
    void GetMsFsName();

};

class TGptDiscPartition
{
public:
    TGptDiscPartition(TDisc *Disc);
    ~TGptDiscPartition();

    void Read();
    void Write();
    void Write(int Resv);

    int Add(const char *FsName, long Size, const char *BootCode, int BootSize);
    int Remove(long long Lba);

    TDisc *GetDisc();
    long long GetStart();
    long long GetEnd();

    TGptPartition *PartArr[MAX_GPT_PART_COUNT];
    int PartCount;

protected:
    struct TPartEntry *ReadGpt(long long StartLba, char *HeaderBuf);
    void InitGpt(long long HeaderLba, char *HeaderBuf, int Resv);
    void WriteGpt(char *HeaderBuf);
    void WriteBootSector(long long Sector, int Count, const char *BootCode, int BootSize);
    void ReadOtherGpt();
    void RecreatePrimaryGpt();
    void Sort();
    const char *GetGuid(const char *FsName);
    long long GetFreeLba(long long Size);
    struct TPartEntry *InsertEntry(long long Lba);

    TDisc *FDisc;

    char FPrimaryHeader[512];
    char FSecondaryHeader[512];

    struct TPartHeader *FPartHeader;
    struct TPartEntry *FPartEntry;
};

#endif

