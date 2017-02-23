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
                             -4,  -4,  -4,   4                      // 125 - 128
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
TIso8583Element::TIso8583Element(int Id)
{
    int digits = 0;

    if (Id > 0 && Id <=128)
        digits = ElemDigits[Id];

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

    if (FSize > 0 && FSize < *remsize)
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
    char SizeBuf[5];

    if (FSizeDigits && FSize)
    {
        if (FSizeDigits <= *remsize)
        {
            sprintf(FormStr, "%d%%d", FSizeDigits);
            sprintf(buf, FormStr, FSize); 
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
}
