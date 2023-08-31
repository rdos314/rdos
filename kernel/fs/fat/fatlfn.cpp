/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
    char sum;
    int i;
    char *ptr = entry->Base;

    if (Count == 0)
    {
        sum = 0;

        for (i = 0; i < 11; i++)
            sum = ((sum & 1) ? 0x80 : 0) + (sum >> 1) + ptr[i];

        if (sum == ChkSum)
            return true;
    }
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
    int i;
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
            *outptr = c;
            bits = -6;
        }
        else if (c < 0x800)
        {
            *outptr = ((c >> 6) & 0x1F) | 0xC0;
            bits = 0;
        }
        else if (c < 0x10000)
        {
           *outptr = ((c >> 12) & 0xF) | 0xE0;
           bits = 6;
        }
        else
        {
           *outptr = ((c >> 18) & 0x7) | 0xF0;
           bits = 12;
        }
        outptr++;

        for ( ; bits >= 0; bits-= 6)
        {
            *outptr = ((c >> bits) & 0x3F) | 0x80;
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
int TFatLfn::EncodeUtf16(short int *utf16, short int codepoint)
{
    if (codepoint <= 0xFFFF)
    {
        utf16[0] = codepoint;
        return 1;
    }

    codepoint -= 0x10000;

    short int low = 0xDC00;
    low |= codepoint & 0x03FF;

    codepoint >>= 10;

    short int high = 0xD800;
    high |= codepoint & 0x03FF;

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
    int count;

    MaxSize = Size + 2;
    Buf = new short int[MaxSize];

    outptr = Buf;

    while (*inptr)
    {
        codepoint = DecodeUtf8(inptr, &count);
        inptr += count;

        if (!codepoint)
            break;        

        count = EncodeUtf16(outptr, codepoint);
        outptr += count;        
    }

    *outptr = 0;
}
