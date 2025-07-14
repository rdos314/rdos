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
    int EncodeUtf16(short int *utf16, unsigned int codepoint);

    bool First;
    char ChkSum;
    char Count;
    int Entries;
    int MaxSize;
    short int *Buf;
};

#endif

