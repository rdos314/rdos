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

    double GetTotalSpace();

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

        int Add(const char *FsName, long Size, const char *BootCode, int BootSize);

    TDisc *GetDisc();

    TGptPartition *PartArr[MAX_GPT_PART_COUNT];
    int PartCount;

protected:
    struct TPartEntry *ReadGpt(long long StartLba, char *HeaderBuf);
    void InitGpt(long long HeaderLba, char *HeaderBuf);
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

