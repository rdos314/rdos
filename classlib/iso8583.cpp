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
# iso8583.cpp
# ISO 8583 class
#
########################################################################*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <memory.h>

#include "iso8583.h"

#define     FALSE	0
#define     TRUE	!FALSE

static int ElemDigits[] = {
                              0,   0,  -2,   6,  16,   		    // 0 - 4
                             16,  16,  10,  12,   8,                // 5 - 9
                              8,  12,  14,   6,   4,                // 10 - 14
                              8,   4,   4,  -3,   3,                // 15 - 19
                              3,  22,  16,   3,   3,                // 20 - 24
                              4,   4,  27,   8,   3,                // 25 - 29
                             32,  23,  -2,  -2,  -4,                // 30 - 34
                             -2,  -3,  12,   6,   4,                // 35 - 39
                              3,  16,  -2,  -4   -4,                // 40 - 44
                             -2,  -3,  -3,  -3,  -4,                // 45 - 49
                             -3,  -3,   8,  -2,  -3,                // 50 - 54
                             -4,  -2,   3,  -2,  -3,                // 55 - 59
                             -3,  -3,  -3,  -3,   4,                // 60 - 64
                              8,  -3,   2,   9,  40,                // 65 - 69
                             18,  -4,  -4,   8, 156,                // 70 - 74
                             90,  -4,  -4,  -4,  -4,                // 75 - 79
                             -4,  -4,  -4,  -4,  -4,                // 80 - 84
                             -4,  -4,  -4,  -4,  -4,                // 85 - 89
                             -4,  -4,  -4,  -2,  -2,                // 90 - 94
                             -2,  -3,  21,  25,  -2,                // 95 - 99
                             -2,  -2,  -2,  -2,  -4,                // 100 - 104
                             -4,  -4,  -4,  -4,  -3,                // 105 - 109
                             -3,  -4,  -4,  -4,  -4,                // 110 - 114
                             -4,  -4,  -4,  -4,  -4,                // 115 - 119
                             -4,  -4,  -4,  -4,  -4,                // 120 - 124
                             -4,  -4,  -4,   4,   0,                // 125 - 129
                              0,   0,   0,   0,   0,                // 130 - 134
                              0,   0,   0,   0,   0,                // 135 - 139
                              0,   0,   0,   0,   0,                // 140 - 144
                              0,   0,   0,   0,   0,                // 145 - 149
                              0,   0,   0,   0,   0,                // 150 - 154
                              0,   0,   0,   0,   0,                // 155 - 159
                              0,   0,   0,   0,   0,                // 160 - 164
                              0,   0,   0,   0,   0,                // 165 - 169
                              0,   0,   0,   0,   0,                // 170 - 174
                              0,   0,   0,   0,   0,                // 175 - 179
                              0,   0,   0,   0,   0,                // 180 - 184
                              0,   0,   0,   0,   0,                // 185 - 189
                              0,   0,   0                           // 190 - 192
                           };


/*##########################################################################
#
#   Name       : TIso8583Element::TIso8583Element
#
#   Purpose....: Constructor for TIso8583Element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIso8583Element::TIso8583Element(int Id, int *DigitTable)
{
    int digits = 0;

    if (Id > 0 && Id <= 192)
        digits = DigitTable[Id];

    if (digits)
    {
        FId = Id;

        if (digits > 0)
        {
            FFixedDigits = digits;
            FSizeDigits = 0;
        }
        else
        {
            FFixedDigits = 0;
            FSizeDigits = -digits;
        }
    }
    else
    {
        FId = 0;
        FSize = 0;
        FFixedDigits = 0;
        FSizeDigits = 0;
    }

    FBuf = 0;
    FSize = 0;    
}

/*##########################################################################
#
#   Name       : TIso8583Element::~TIso8583Element
#
#   Purpose....: Destructor for TIso8583Element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIso8583Element::~TIso8583Element()
{
    if (FBuf)
        delete FBuf;
}

/*##########################################################################
#
#   Name       : TIso8583Element::GetId
#
#   Purpose....: Get ID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIso8583Element::GetId()
{
    return FId;
}

/*##########################################################################
#
#   Name       : TIso8583Element::Decode
#
#   Purpose....: Decode data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TIso8583Element::Decode(char *buf, int *remsize)
{
    char SizeBuf[5];

    if (FBuf)
    {
        delete FBuf;
        FBuf = 0;
    }

    if (FSizeDigits)
    {
        if (FSizeDigits <= *remsize)
        {
            memcpy(SizeBuf, buf, FSizeDigits);
            SizeBuf[FSizeDigits] = 0;
            FSize = atoi(SizeBuf);

            buf += FSizeDigits;
            *remsize -= FSizeDigits;
        }
    }
    else
        FSize = FFixedDigits;

    if (FSize > 0 && FSize <= *remsize)
    {
        FBuf = new char[FSize + 1];
        memcpy(FBuf, buf, FSize);
        FBuf[FSize] = 0;
        buf += FSize;
        *remsize -= FSize;
        return buf;
    }
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TIso8583Element::Encode
#
#   Purpose....: Encode data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TIso8583Element::Encode(char *buf, int *remsize)
{
    char FormStr[10];

    if (FSizeDigits && FSize)
    {
        if (FSizeDigits <= *remsize)
        {
            sprintf(FormStr, "%%0%dd", FSizeDigits);
            sprintf(buf, FormStr, FSize); 

            if (strlen(buf) > FSizeDigits)
                return 0;

            buf += FSizeDigits;
            *remsize -= FSizeDigits;
        }
        else
            return 0;
    }

    if (FSize > 0 && FSize < *remsize)
    {
        memcpy(buf, FBuf, FSize);
        buf += FSize;
        *remsize -= FSize;
        return buf;
    }
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TIso8583Element::GetInt
#
#   Purpose....: Get data as int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIso8583Element::GetInt()
{
    if (FBuf)
        return atol(FBuf);
    else
        return 0;
}    


/*##########################################################################
#
#   Name       : TIso8583Element::GetLong
#
#   Purpose....: Get data as long long
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TIso8583Element::GetLong()
{
    if (FBuf)
        return atoll(FBuf);
    else
        return 0;
}    

/*##########################################################################
#
#   Name       : TIso8583Element::SetInt
#
#   Purpose....: Set data as int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583Element::SetInt(int val)
{
    char FormStr[10];

    if (FBuf)
    {
        delete FBuf;
        FBuf = 0;
    }

    if (FFixedDigits)
    {
        FSize = FFixedDigits;
        FBuf = new char[FFixedDigits + 10];
        sprintf(FormStr, "%%0%dd", FFixedDigits);
        sprintf(FBuf, FormStr, val);
    }
    else
    {
        FBuf = new char[20];
        sprintf(FBuf, "%d", val);
        FSize = strlen(FBuf);
    }
}    


/*##########################################################################
#
#   Name       : TIso8583Element::SetLong
#
#   Purpose....: Set data as long
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583Element::SetLong(long long val)
{
    char FormStr[10];

    if (FBuf)
    {
        delete FBuf;
        FBuf = 0;
    }

    if (FFixedDigits)
    {
        FSize = FFixedDigits;
        FBuf = new char[FFixedDigits + 20];
        sprintf(FormStr, "%%0%dlld", FFixedDigits);
        sprintf(FBuf, FormStr, val);
    }
    else
    {
        FBuf = new char[40];
        sprintf(FBuf, "%d", val);
        FSize = strlen(FBuf);
    }
}    


/*##########################################################################
#
#   Name       : TIso8583Element::GetString
#
#   Purpose....: Get data as string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TIso8583Element::GetString()
{
    return FBuf;
}    

/*##########################################################################
#
#   Name       : TIso8583Element::SetString
#
#   Purpose....: Set data as string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583Element::SetString(const char *str)
{
    int len = strlen(str);

    if (FBuf)
    {
        delete FBuf;
        FBuf = 0;
    }

    if (FFixedDigits)
    {
        FSize = FFixedDigits;
        FBuf = new char[FSize + 1];

        if (len > FSize)
        {
            memcpy(FBuf, str, FSize);
            FBuf[FSize] = 0;
        }
        else
        {
            strcpy(FBuf, str);
            while (strlen(FBuf) < FSize)
                strcat(FBuf, " ");
        }
    }
    else
    {
        FSize = len;
        FBuf = new char[FSize + 1];
        strcpy(FBuf, str);
    }
}    

/*##########################################################################
#
#   Name       : TIso8583Element::GetTime
#
#   Purpose....: Get data as time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TIso8583Element::GetTime()
{
    int year, month, day;
    int hour, min, sec;
    int count;

    year = 0;
    month = 1;
    day = 1;
    hour = 0;
    min = 0;
    sec = 0;

    switch (FSize)
    {
        case 10:
            count = sscanf(FBuf, "%02d%02d%02d%02d%02d", &month, &day, &hour, &min, &sec);
            break;

        case 12:
            count = sscanf(FBuf, "%02d%02d%02d%02d%02d%02d", &year, &month, &day, &hour, &min, &sec);
            break;

        case 14:
            count = sscanf(FBuf, "%04d%02d%02d%02d%02d%02d", &year, &month, &day, &hour, &min, &sec);
            break;
    
        case 6:
            count = sscanf(FBuf, "%02d%02d%02d", &year, &month, &day);
            break;

        case 4:
            count = sscanf(FBuf, "%02d%02d%02d", &year, &month);
            break;
    }

    if (year && year < 100)
        year += 2000;

    return TDateTime(year, month, day, hour, min, sec);

}    

/*##########################################################################
#
#   Name       : TIso8583Element::SetTime
#
#   Purpose....: Set data as time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583Element::SetTime(TDateTime &time)
{
    char str[20];

    switch (FFixedDigits)
    {
        case 10:
            sprintf(str, "%02d%02d%02d%02d%02d", time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(), time.GetSec());
            break;

        case 12:
            sprintf(str, "%02d%02d%02d%02d%02d%02d", time.GetYear() - 2000, time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(), time.GetSec());
            break;

        case 14:
            sprintf(str, "%04d%02d%02d%02d%02d%02d", time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(), time.GetSec());
            break;
    
        case 6:
            sprintf(str, "%02d%02d%02d", time.GetYear() - 2000, time.GetMonth(), time.GetDay());
            break;

        case 4:
            sprintf(str, "%02d%02d%02d", time.GetYear() - 2000, time.GetMonth());
            break;

        default:
            str[0] = 0;
    }

    SetString(str);
}    

/*##########################################################################
#
#   Name       : TIso8583Element::GetBinarySize
#
#   Purpose....: Get binary size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIso8583Element::GetBinarySize()
{
    return FSize;
}    

/*##########################################################################
#
#   Name       : TIso8583Element::GetBinaryData
#
#   Purpose....: Get data as binary
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TIso8583Element::GetBinaryData()
{
    return FBuf;
}    

/*##########################################################################
#
#   Name       : TIso8583Element::SetBinary
#
#   Purpose....: Set data as binary
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583Element::SetBinary(const char *data, int size)
{
    int i;

    if (FBuf)
    {
        delete FBuf;
        FBuf = 0;
    }

    if (FFixedDigits)
    {
        FSize = FFixedDigits;
        FBuf = new char[FSize];

        if (size > FSize)
            memcpy(FBuf, data, FSize);
        else
        {
            memcpy(FBuf, data, size);

            for (i = size; i < FSize; i++)
                FBuf[i] = 0;
        }
    }
    else
    {
        FSize = size;
        FBuf = new char[FSize];
        memcpy(FBuf, data, FSize);
    }
}    

/*##########################################################################
#
#   Name       : TIso8583Bitmap::TIso8583Bitmap
#
#   Purpose....: Constructor for TIso8583Bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIso8583Bitmap::TIso8583Bitmap(int *DigitTable)
{
    FDigitTable = DigitTable;

    Init();
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::~TIso8583Bitmap
#
#   Purpose....: Destructor for TIso8583Bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIso8583Bitmap::~TIso8583Bitmap()
{
    Reset();
}

/*##########################################################################
#
#   Name       : TIso8583::Init
#
#   Purpose....: Init elements
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583Bitmap::Init()
{
    int i;

    for (i = 0; i <= 63; i++)
        FIsoArr[i] = 0;
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::Reset
#
#   Purpose....: Reset elements
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583Bitmap::Reset()
{
    int i;

    for (i = 0; i <= 63; i++)
    {
        if (FIsoArr[i])
        {
            delete FIsoArr[i];
            FIsoArr[i] = 0;
        }
    }
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::GetElem
#
#   Purpose....: Get element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIso8583Element *TIso8583Bitmap::GetElem(int Id)
{
    return FIsoArr[Id];
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::AddElem
#
#   Purpose....: Add element using ID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIso8583Element *TIso8583Bitmap::AddElem(int Id)
{
    int digits = 0;

    if (Id > 0 && Id <= 63)
    {
        digits = FDigitTable[Id];
        if (digits)
        {
            if (FIsoArr[Id] == 0)
                FIsoArr[Id] = new TIso8583Element(Id, FDigitTable);

            return FIsoArr[Id];
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::AddElem
#
#   Purpose....: Add element from used array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIso8583Element *TIso8583Bitmap::AddElem()
{
    int digits = 0;
    int Id;

    for (Id = 1; Id <= 63; Id++)
    {
        if (FUsedArr[Id])
        {
            FUsedArr[Id] = 0;
            break;
        }
    }
 
    if (Id > 0 && Id <= 63)
    {
        digits = FDigitTable[Id];
        if (digits)
        {
            if (FIsoArr[Id] == 0)
                FIsoArr[Id] = new TIso8583Element(Id, FDigitTable);

            return FIsoArr[Id];
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::IsValid
#
#   Purpose....: Check if id is valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIso8583Bitmap::IsValid(int Id)
{
    TIso8583Element *elem = GetElem(Id);

    if (elem)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::GetInt
#
#   Purpose....: Get int element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIso8583Bitmap::GetInt(int Id)
{
    TIso8583Element *elem = GetElem(Id);

    if (elem)
        return elem->GetInt();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::GetLong
#
#   Purpose....: Get long long element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TIso8583Bitmap::GetLong(int Id)
{
    TIso8583Element *elem = GetElem(Id);

    if (elem)
        return elem->GetInt();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::GetString
#
#   Purpose....: Get string element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TIso8583Bitmap::GetString(int Id)
{
    TIso8583Element *elem = GetElem(Id);

    if (elem)
        return elem->GetString();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::GetTime
#
#   Purpose....: Get time element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TIso8583Bitmap::GetTime(int Id)
{
    TIso8583Element *elem = GetElem(Id);

    if (elem)
        return elem->GetTime();
    else
        return TDateTime();
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::GetBinarySize
#
#   Purpose....: Get binary element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIso8583Bitmap::GetBinarySize(int Id)
{
    TIso8583Element *elem = GetElem(Id);

    if (elem)
        return elem->GetBinarySize();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::GetBinaryData
#
#   Purpose....: Get binary element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TIso8583Bitmap::GetBinaryData(int Id)
{
    TIso8583Element *elem = GetElem(Id);

    if (elem)
        return elem->GetBinaryData();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::AddInt
#
#   Purpose....: Add int element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583Bitmap::AddInt(int Id, int val)
{
    TIso8583Element *elem = AddElem(Id);

    if (elem)
        elem->SetInt(val);
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::AddLong
#
#   Purpose....: Add long element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583Bitmap::AddLong(int Id, long long val)
{
    TIso8583Element *elem = AddElem(Id);

    if (elem)
        elem->SetLong(val);
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::AddString
#
#   Purpose....: Add string element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583Bitmap::AddString(int Id, const char *str)
{
    TIso8583Element *elem = AddElem(Id);

    if (elem)
        elem->SetString(str);
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::AddTime
#
#   Purpose....: Add time element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583Bitmap::AddTime(int Id, TDateTime &time)
{
    TIso8583Element *elem = AddElem(Id);

    if (elem)
        elem->SetTime(time);
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::AddBinary
#
#   Purpose....: Add binary element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583Bitmap::AddBinary(int Id, const char *data, int size)
{
    TIso8583Element *elem = AddElem(Id);

    if (elem)
        elem->SetBinary(data, size);
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::EncodeBitmap
#
#   Purpose....: Encode primary bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TIso8583Bitmap::EncodeBitmap(char *buf, int *remsize)
{
    int i, j;
    int elem;
    char mask;
    char ch;
    char *ptr = buf;

    if (*remsize >= 8)
    {
        for (i = 0; i < 8; i++)
        {
            elem = 8 * i + 1;
            mask = 0x80;
            ch = 0;

            for (j = 0; j < 8; j++)
            {
                if (FIsoArr[elem])
                    ch |= mask;

                mask = mask >> 1;
                elem++;
            }
            ptr[i] = ch;
        }
        *remsize -= 8;
        ptr += 8;
    }
    else
        return 0;

    return ptr;
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::Encode
#
#   Purpose....: Encode message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIso8583Bitmap::Encode(char *buf, int size)
{
    int remsize;
    char *ptr;
    int elem;

    if (size > 8)
    {
        ptr = buf;
        remsize = size;

        ptr = EncodeBitmap(ptr, &remsize);

        for (elem = 1; elem <= 63 && ptr; elem++)
            if (FIsoArr[elem])
                ptr = FIsoArr[elem]->Encode(ptr, &remsize);

        return size - remsize;

    }
    return 0;
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::DecodeBitmap
#
#   Purpose....: Decode primary bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TIso8583Bitmap::DecodeBitmap(char *buf, int *remsize)
{
    int i, j;
    int elem;
    char mask;
    char *ptr = buf;
    char ch;

    for (i = 0; i <= 63; i++)
        FUsedArr[i] = FALSE;

    if (*remsize >= 8)
    {
        for (i = 0; i < 8; i++)
        {
            elem = 8 * i + 1;
            mask = 0x80;
            ch = ptr[i];

            for (j = 0; j < 8; j++)
            {
                if (ch & mask)
                    FUsedArr[elem] = TRUE;

                mask = mask >> 1;
                elem++;
            }
        }
        *remsize -= 8;
        ptr += 8;
    }
    else
        return 0;

    return ptr;
}

/*##########################################################################
#
#   Name       : TIso8583Bitmap::Decode
#
#   Purpose....: Decode message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIso8583Bitmap::Decode(char *buf, int size)
{
    int remsize;
    char *ptr;
    TIso8583Element *e;

    if (size > 8)
    {
        ptr = buf;
        remsize = size;

        ptr = DecodeBitmap(ptr, &remsize);

        while (ptr)
        {
            e = AddElem();
            if (e)
                ptr = e->Decode(ptr, &remsize);
            else
                ptr = 0;
        }

        return size - remsize;

    }
    return 0;
}

/*##########################################################################
#
#   Name       : TIso8583::TIso8583
#
#   Purpose....: Constructor for TIso8583
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIso8583::TIso8583()
{
    FDigitTable = ElemDigits;

    Init();
}

/*##########################################################################
#
#   Name       : TIso8583::~TIso8583
#
#   Purpose....: Destructor for TIso8583
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIso8583::~TIso8583()
{
    Reset();
}

/*##########################################################################
#
#   Name       : TIso8583::Init
#
#   Purpose....: Init elements
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583::Init()
{
    int i;

    for (i = 0; i <= 192; i++)
        FIsoArr[i] = 0;

    FMsgType = 0;
}

/*##########################################################################
#
#   Name       : TIso8583::Reset
#
#   Purpose....: Reset elements
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583::Reset()
{
    int i;

    for (i = 0; i <= 192; i++)
    {
        if (FIsoArr[i])
        {
            delete FIsoArr[i];
            FIsoArr[i] = 0;
        }
    }
}

/*##########################################################################
#
#   Name       : TIso8583::Create
#
#   Purpose....: create a new msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583::Create(int MsgType)
{
    Reset();
    FMsgType = MsgType;
}

/*##########################################################################
#
#   Name       : TIso8583::GetElem
#
#   Purpose....: Get element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIso8583Element *TIso8583::GetElem(int Id)
{
    return FIsoArr[Id];
}

/*##########################################################################
#
#   Name       : TIso8583::AddElem
#
#   Purpose....: Add element using ID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIso8583Element *TIso8583::AddElem(int Id)
{
    int digits = 0;

    if (Id > 0 && Id <= 192)
    {
        digits = FDigitTable[Id];
        if (digits)
        {
            if (FIsoArr[Id] == 0)
                FIsoArr[Id] = new TIso8583Element(Id, FDigitTable);

            return FIsoArr[Id];
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TIso8583::AddElem
#
#   Purpose....: Add element from used array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIso8583Element *TIso8583::AddElem()
{
    int digits = 0;
    int Id;

    for (Id = 1; Id <= 192; Id++)
    {
        if (FUsedArr[Id])
        {
            FUsedArr[Id] = 0;
            break;
        }
    }
 
    if (Id > 0 && Id <= 192)
    {
        digits = FDigitTable[Id];
        if (digits)
        {
            if (FIsoArr[Id] == 0)
                FIsoArr[Id] = new TIso8583Element(Id, FDigitTable);

            return FIsoArr[Id];
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TIso8583::IsValid
#
#   Purpose....: Check if id is valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIso8583::IsValid(int Id)
{
    TIso8583Element *elem = GetElem(Id);

    if (elem)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TIso8583::GetInt
#
#   Purpose....: Get int element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIso8583::GetInt(int Id)
{
    TIso8583Element *elem = GetElem(Id);

    if (elem)
        return elem->GetInt();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TIso8583::GetLong
#
#   Purpose....: Get long long element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TIso8583::GetLong(int Id)
{
    TIso8583Element *elem = GetElem(Id);

    if (elem)
        return elem->GetInt();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TIso8583::GetString
#
#   Purpose....: Get string element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TIso8583::GetString(int Id)
{
    TIso8583Element *elem = GetElem(Id);

    if (elem)
        return elem->GetString();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TIso8583::GetTime
#
#   Purpose....: Get time element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TIso8583::GetTime(int Id)
{
    TIso8583Element *elem = GetElem(Id);

    if (elem)
        return elem->GetTime();
    else
        return TDateTime();
}

/*##########################################################################
#
#   Name       : TIso8583::GetBinarySize
#
#   Purpose....: Get binary element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIso8583::GetBinarySize(int Id)
{
    TIso8583Element *elem = GetElem(Id);

    if (elem)
        return elem->GetBinarySize();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TIso8583::GetBinaryData
#
#   Purpose....: Get binary element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TIso8583::GetBinaryData(int Id)
{
    TIso8583Element *elem = GetElem(Id);

    if (elem)
        return elem->GetBinaryData();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TIso8583::AddInt
#
#   Purpose....: Add int element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583::AddInt(int Id, int val)
{
    TIso8583Element *elem = AddElem(Id);

    if (elem)
        elem->SetInt(val);
}

/*##########################################################################
#
#   Name       : TIso8583::AddLong
#
#   Purpose....: Add long element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583::AddLong(int Id, long long val)
{
    TIso8583Element *elem = AddElem(Id);

    if (elem)
        elem->SetLong(val);
}

/*##########################################################################
#
#   Name       : TIso8583::AddString
#
#   Purpose....: Add string element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583::AddString(int Id, const char *str)
{
    TIso8583Element *elem = AddElem(Id);

    if (elem)
        elem->SetString(str);
}

/*##########################################################################
#
#   Name       : TIso8583::AddTime
#
#   Purpose....: Add time element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583::AddTime(int Id, TDateTime &time)
{
    TIso8583Element *elem = AddElem(Id);

    if (elem)
        elem->SetTime(time);
}

/*##########################################################################
#
#   Name       : TIso8583::AddBinary
#
#   Purpose....: Add binary element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIso8583::AddBinary(int Id, const char *data, int size)
{
    TIso8583Element *elem = AddElem(Id);

    if (elem)
        elem->SetBinary(data, size);
}

/*##########################################################################
#
#   Name       : TIso8583Element::EncodeBitmap1
#
#   Purpose....: Encode primary bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TIso8583::EncodeBitmap1(char *buf, int *remsize)
{
    int i, j;
    int elem;
    char mask;
    char ch;
    char *ptr = buf;
    int Has2 = FALSE;
    int Has3 = FALSE;

    for (i = 65; i <= 192; i++)
        if (FIsoArr[i])
            Has2 = TRUE;

    for (i = 129; i <= 192; i++)
        if (FIsoArr[i])
            Has3 = TRUE;

    if (*remsize >= 8)
    {
        for (i = 0; i < 8; i++)
        {
            elem = 8 * i + 1;
            mask = 0x80;

            if (i == 0 && Has2)
                ch = 0x80;
            else
                ch = 0;

            for (j = 0; j < 8; j++)
            {
                if (FIsoArr[elem])
                    ch |= mask;

                mask = mask >> 1;
                elem++;
            }
            ptr[i] = ch;
        }
        *remsize -= 8;
        ptr += 8;
    }
    else
        return 0;

    if (Has2 && *remsize >= 8)
    {
        for (i = 0; i < 8; i++)
        {
            elem = 64 + 8 * i + 1;
            mask = 0x80;

            if (i == 0 && Has3)
                ch = 0x80;
            else
                ch = 0;

            for (j = 0; j < 8; j++)
            {
                if (FIsoArr[elem])
                    ch |= mask;

                mask = mask >> 1;
                elem++;
            }
            ptr[i] = ch;
        }
        *remsize -= 8;
        ptr += 8;
    }

    return ptr;
}

/*##########################################################################
#
#   Name       : TIso8583::Encode
#
#   Purpose....: Encode message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIso8583::Encode(char *buf, int size)
{
    int remsize;
    char *ptr;
    int elem;

    if (size > 8)
    {
        sprintf(buf, "%04d", FMsgType);

        remsize = size - 4;
        ptr = buf + 4;

        ptr = EncodeBitmap1(ptr, &remsize);

        for (elem = 2; elem <= 64 && ptr; elem++)
            if (FIsoArr[elem])
                ptr = FIsoArr[elem]->Encode(ptr, &remsize);

        return size - remsize;

    }
    return 0;
}

/*##########################################################################
#
#   Name       : TIso8583Element::DncodeBitmap1
#
#   Purpose....: Decode primary bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TIso8583::DecodeBitmap1(char *buf, int *remsize)
{
    int i, j;
    int elem;
    char mask;
    char *ptr = buf;
    char ch;

    for (i = 0; i <= 192; i++)
        FUsedArr[i] = FALSE;

    if (*remsize >= 8)
    {
        for (i = 0; i < 8; i++)
        {
            elem = 8 * i + 1;
            mask = 0x80;
            ch = ptr[i];

            for (j = 0; j < 8; j++)
            {
                if (ch & mask)
                    FUsedArr[elem] = TRUE;

                mask = mask >> 1;
                elem++;
            }
        }
        *remsize -= 8;
        ptr += 8;
    }
    else
        return 0;

    if (FUsedArr[1] && *remsize >= 8)
    {
        FUsedArr[1] = FALSE;

        for (i = 0; i < 8; i++)
        {
            elem = 64 + 8 * i + 1;
            mask = 0x80;
            ch = ptr[i];

            for (j = 0; j < 8; j++)
            {
                if (ch & mask)
                    FUsedArr[elem] = TRUE;

                mask = mask >> 1;
                elem++;
            }
        }
        *remsize -= 8;
        ptr += 8;
    }

    return ptr;
}

/*##########################################################################
#
#   Name       : TIso8583::Decode
#
#   Purpose....: Decode message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIso8583::Decode(char *buf, int size)
{
    int remsize;
    char *ptr;
    char str[10];
    TIso8583Element *e;

    if (size > 8)
    {
        memcpy(str, buf, 4);
        str[4] = 0;
        FMsgType = atoi(str);

        remsize = size - 4;
        ptr = buf + 4;

        ptr = DecodeBitmap1(ptr, &remsize);

        while (ptr)
        {
            e = AddElem();
            if (e)
                ptr = e->Decode(ptr, &remsize);
            else
                ptr = 0;
        }

        return size - remsize;

    }
    return 0;
}
