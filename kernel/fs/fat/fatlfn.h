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
# fatlfn.h
# FAT LFN class
#
########################################################################*/

#ifndef _FATLFN_H
#define _FATLFN_H

#include "dir.h"

struct TFatLfnEntry
{
    char Ord;
    short int Name1[5];
    char Attr;
    char Type;
    char ChkSum;
    short int Name2[6];
    short int ClusterLow;
    short int Name3[2];
};

class TFatLfn
{
public:
    TFatLfn();
    TFatLfn(struct TFatLfnEntry *entry);
    virtual ~TFatLfn();

    bool Add(struct TFatLfnEntry *entry);
    bool Verify(struct TFatDirEntry *entry);
    int GetNameSize();
    int GetEntryCount();
    void GetName(char *buf);
    void SetChkSum(char sum);
    bool GetEntry(struct TFatDirEntry *entry);

    void SetName(const char *buf);

protected:
    void AddData(struct TFatLfnEntry *entry);
    int CalculateUtf8Len(unsigned int codepoint);
    unsigned int DecodeUtf8(const unsigned char *utf8, int *size);
    int EncodeUtf16(short int *utf16, short int codepoint);

    bool First;
    char ChkSum;
    char Count;
    int MaxSize;
    short int *Buf;
};

#endif

