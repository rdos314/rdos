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
# fatlfn.cpp
# FAT LFN class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <rdos.h>
#include "fatlfn.h"
#include "fatdir.h"
#include "fat.h"

typedef struct
{
    unsigned char mask;
    unsigned char value;
} utf8_pattern;

static const utf8_pattern utf8_leading_bytes[] =
{
    { 0x80, 0x00 }, // 0xxxxxxx
    { 0xE0, 0xC0 }, // 110xxxxx
    { 0xF0, 0xE0 }, // 1110xxxx
    { 0xF8, 0xF0 }  // 11110xxx
};

/*##########################################################################
#
#   Name       : TFatLfn::TFatLfn
#
#   Purpose....: Fat lfn constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatLfn::TFatLfn()
{
    MaxSize = 0;
    Buf = 0;
}

/*##########################################################################
#
#   Name       : TFatLfn::TFatLfn
#
#   Purpose....: Fat lfn constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatLfn::TFatLfn(struct TFatLfnEntry *entry)
{
    ChkSum = entry->ChkSum;
    Count = entry->Ord & 0x3F;
    Entries = Count;
    MaxSize = 13 * (int)Count;
    Buf = new short int[MaxSize];

    AddData(entry);
}

/*##########################################################################
#
#   Name       : TFatLfn::~TFatLfn
#
#   Purpose....: Fat lfn destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatLfn::~TFatLfn()
{
    if (Buf)
        delete Buf;
}

/*##########################################################################
#
#   Name       : TFatLfn::AddData
#
#   Purpose....: Add data from LFN entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatLfn::AddData(struct TFatLfnEntry *entry)
{
    short int *ptr;
    int i;

    Count--;
    ptr = Buf + 13 * Count;

    for (i = 0; i < 5; i++)
        ptr[i] = entry->Name1[i];

    ptr += 5;

    for (i = 0; i < 6; i++)
        ptr[i] = entry->Name2[i];

    ptr += 6;

    for (i = 0; i < 2; i++)
        ptr[i] = entry->Name3[i];

}

/*##########################################################################
#
#   Name       : TFatLfn::Add
#
#   Purpose....: Add LFN part
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatLfn::Add(struct TFatLfnEntry *entry)
{
    if (Count > 0)
    {
        if (entry->ChkSum == ChkSum)
        {
            if (entry->Ord == Count)
            {
                AddData(entry);
                return true;
            }
        }
    }
    return false;
}

/*##########################################################################
#
#   Name       : TFatLfn::Verify
#
#   Purpose....: Verify again short entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatLfn::Verify(struct TFatDirEntry *entry)
{
    if (Count == 0)
        if (ChkSum == GetChkSum(entry))
            return true;

    return false;
}

/*##########################################################################
#
#   Name       : TFatLfn::GetNameSize
#
#   Purpose....: Get max size of name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFatLfn::GetNameSize()
{
    return 2 * MaxSize + 1;
}

/*##########################################################################
#
#   Name       : TFatLfn::GetEntryCount
#
#   Purpose....: Get dir entry count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFatLfn::GetEntryCount()
{
    return Entries + 1;
}

/*##########################################################################
#
#   Name       : TFatLfn::SetChkSum
#
#   Purpose....: Set checksum
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatLfn::SetChkSum(char sum)
{
    ChkSum = sum;
    First = true;
}

/*##########################################################################
#
#   Name       : TFatLfn::GetEntry
#
#   Purpose....: Get FAT entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatLfn::GetEntry(struct TFatDirEntry *e)
{
    bool done = false;
    struct TFatLfnEntry *entry = (struct TFatLfnEntry *)e;
    short int *ptr;
    int i;

    if (Count)
    {
        if (First)
            entry->Ord = Count | 0x40;
        else
            entry->Ord = Count;
           
        entry->Attr = 0xF;
        entry->Type = 0;
        entry->ClusterLow = 0;
        entry->ChkSum = ChkSum;

        First = false;
        Count--;
        ptr = Buf + 13 * Count;

        for (i = 0; i < 5; i++)
        {
            if (done)
                entry->Name1[i] = 0xFFFF;
            else
            {
                entry->Name1[i] = ptr[i];
                if (ptr[i] == 0)
                    done = true;
            }
        }

        ptr += 5;
 
        for (i = 0; i < 6; i++)
        {
            if (done)
                entry->Name2[i] = 0xFFFF;
            else
            {
                entry->Name2[i] = ptr[i];
                if (ptr[i] == 0)
                    done = true;
            }
        }

        ptr += 6;

        for (i = 0; i < 2; i++)
        {
            if (done)
                entry->Name3[i] = 0xFFFF;
            else
            {
                entry->Name3[i] = ptr[i];
                if (ptr[i] == 0)
                    done = true;
            }
        }

        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TFatLfn::GetName
#
#   Purpose....: Get name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatLfn::GetName(char *name)
{
    unsigned short int *inptr = (unsigned short int *)Buf;
    char *outptr = name;
    int pos = 0;
    int bits;
    unsigned int c;
    unsigned int d;

    while (pos < MaxSize)
    {
        c = *inptr;
        inptr++;
        pos++;
        if (c == 0xFFFF)
            break;

        if ((c & 0xFC00) == 0xD800)
        {
            d = *inptr;
            inptr++;
            pos++;

            if ((d & 0xFC00) == 0xDC00)
            {
                c &= 0x03FF;
                c <<= 10;
                c |= d & 0x03FF;
                c += 0x10000;
            }
        }

        if (c < 0x80)
        {
            *outptr = (char)c;
            bits = -6;
        }
        else if (c < 0x800)
        {
            *outptr = (char)(((c >> 6) & 0x1F) | 0xC0);
            bits = 0;
        }
        else if (c < 0x10000)
        {
           *outptr = (char)(((c >> 12) & 0xF) | 0xE0);
           bits = 6;
        }
        else
        {
           *outptr = (char)(((c >> 18) & 0x7) | 0xF0);
           bits = 12;
        }
        outptr++;

        for ( ; bits >= 0; bits-= 6)
        {
            *outptr = (char)(((c >> bits) & 0x3F) | 0x80);
            outptr++;
        }
    }
    *outptr = 0;
}

/*##########################################################################
#
#   Name       : TFatLfn::CalculateUtf8Len
#
#   Purpose....: Calculate UTF-8 len of codepoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFatLfn::CalculateUtf8Len(unsigned int codepoint)
{
    if (codepoint <= 0x7F)
        return 1;

    if (codepoint <= 0x7FF)
        return 2;

    if (codepoint <= 0xFFFF)
        return 3;

    return 4;
}

/*##########################################################################
#
#   Name       : TFatLfn::DecodeUtf8
#
#   Purpose....: Decode UTF-8
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatLfn::DecodeUtf8(const unsigned char *utf8, int *size)
{
    unsigned char leading = utf8[0];
    int len = 0;
    utf8_pattern leading_pattern;
    bool matches = false;
    int i;

    do
    {
        leading_pattern = utf8_leading_bytes[len];
        len++;

        matches = (leading & leading_pattern.mask) == leading_pattern.value;

    } while (!matches && len < 4);

    if (!matches)
        return 0;

    unsigned int codepoint = leading & ~leading_pattern.mask;

    for (i = 1; i < len; i++)
    {
        unsigned char continuation = utf8[i];
        if (continuation == 0)
            return 0;

        if ((continuation & 0xC0) != 0x80)
            return 0;

        codepoint <<= 6;
        codepoint |= continuation & ~0xC0;
    }

    if (CalculateUtf8Len(codepoint) != len)
        return 0;

    if (codepoint < 0xFFFF && (codepoint & 0xF800) == 0xD800)
        return 0;

    if (codepoint > 0x10FFFF)
        return 0;

    *size = len;

    return codepoint;
}

/*##########################################################################
#
#   Name       : TFatLfn::EncodeUtf16
#
#   Purpose....: Encode UTF-16
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFatLfn::EncodeUtf16(short int *utf16, unsigned int codepoint)
{
    if (codepoint <= 0xFFFF)
    {
        utf16[0] = (short int)codepoint;
        return 1;
    }

    codepoint -= 0x10000;

    short int low = 0xDC00;
    low |= (short int)(codepoint & 0x03FF);

    codepoint >>= 10;

    short int high = 0xD800;
    high |= (short int)(codepoint & 0x03FF);

    utf16[0] = high;
    utf16[1] = low;

    return 2;
}

/*##########################################################################
#
#   Name       : TFatLfn::SetName
#
#   Purpose....: Set name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatLfn::SetName(const char *name)
{
    int Size = strlen(name);
    const unsigned char *inptr = (const unsigned char *)name;
    short int *outptr;
    unsigned int codepoint;
    int len;
    int tlen;

    MaxSize = Size + 2;
    Buf = new short int[MaxSize];
    tlen = 0;

    outptr = Buf;

    while (*inptr)
    {
        codepoint = DecodeUtf8(inptr, &len);
        inptr += len;

        if (!codepoint)
            break;

        len = EncodeUtf16(outptr, codepoint);
        outptr += len;
        tlen += len;
    }

    *outptr = 0;

    Count = (tlen - 1) / 13 + 1;
    Entries = Count;
}
