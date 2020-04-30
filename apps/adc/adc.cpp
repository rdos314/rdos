/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2020, Leif Ekblad
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
# adc.cpp
# ADC class
#
########################################################################*/

#include <stdio.h>
#include <rdos.h>
#include "adc.h"

struct TAdcPower
{
    long long SinA;
    long long SinB;
    long long CosA;
    long long CosB;
};


#pragma aux ANAAPI "_*" \
       parm routine [] \
       value struct float struct routine [eax] \
       modify [eax ecx edx];

extern "C" {

int GetSin(int Phase);
#pragma aux (ANAAPI) GetSin;

void CalcPower(TAdcData *Data, int Size, int RelFreq, struct TAdcPower *Res);
#pragma aux (ANAAPI) CalcPower;

};


/*##########################################################################
#
#   Name       : TAdc::TAdc
#
#   Purpose....: Constructor for Adc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdc::TAdc(char TestMode, int Blocks)
{
    FTestMode = TestMode;
    FBlocks = Blocks;
    FBuf = (char *)RdosAllocateMem(0x200000);

    RdosSetupAdc(TestMode, 0, FBlocks);
}

/*##########################################################################
#
#   Name       : TAdc::~TAdc
#
#   Purpose....: Destructor for Adc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdc::~TAdc()
{
    RdosFreeMem(FBuf);
}

/*##########################################################################
#
#   Name       : TAdc::Start
#
#   Purpose....: start ADC
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAdc::Start()
{
    char state = RdosStartAdc();

    if (state & 0x20)
         return true;
    else
        return false;
}

/*##########################################################################
#
#   Name       : TAdc::GetBlock
#
#   Purpose....: Get ADC block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdcData *TAdc::GetBlock(int Block)
{
    bool ok;

    ok = RdosMapAdcBlock(Block, FBuf);
    if (ok)
        return (TAdcData *)FBuf;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TAdc::FindStart
#
#   Purpose....: Find start of ADC data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdcData *TAdc::FindStart(int *Entries)
{
    int i;
    TAdcData *data = GetBlock(0);

    if (data)
    {
        *Entries = 0x80000;

        switch (FTestMode)
        {
            case 0:
                *Entries -= 0x20;
                return data + 0x20;

            case 0x5:
                for (i = 0; i < 0x20; i++)
                {
                    if (data->chA == -41 && data->chB == -41)
                        return data;
                    else
                    {
                        data++;
                        (*Entries)--;
                    }
                }
                return 0;

            case 0xF:
                for (i = 0; i < 0x20; i++)
                {
                    if (data->chA == 0 && data->chB == 0)
                        return data;
                    else
                    {
                        data++;
                        (*Entries)--;
                    }
                }
                return 0;

           default:
               return 0;
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TAdc::CheckRamp
#
#   Purpose....: Check ramp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TAdc::CheckRamp(TAdcData *data, int Block, int Samples, char Start)
{
    int i;
    char curr = Start;
    int Errors = 0;

    for (i = 0; i < Samples; i++)
    {
        if (data[i].chA != curr || data[i].chB != curr)
        {
            if (Errors < 4)
            {
                if (data[i].chA == data[i].chB)
                {
                    printf("Block %d, sample %d: Expected <%02hX>, found <%04hX>\r\n", Block, i, curr, data[i].chA);
                    curr = (char)data[i].chA & 0x7F;
                }
                else
                    printf("Block %d, sample %d: A <%04hX>, B <%04hX>\r\n", Block, i, data[i].chA, data[i].chB);
            }
            Errors++;
        }

        if (curr == 0x7F)
            curr = 0;
        else
            curr++;
    }

    if (Errors >= 4)
        printf("Block %d has %d errors\r\n", Block, Errors);

    return curr;
}

/*##########################################################################
#
#   Name       : TAdc::CheckRamp
#
#   Purpose....: Check ramp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CheckRamp()
{
    TAdcData *data;
    int entries;
    char ch;
    int i;

    data = FindStart(&entries);

    if (data)
    {
        ch = CheckRamp(data, 0, entries, 0);

        for (i = 1; i < 5000; i++)
        {
            data = GetBlock(i);
            if (data)
                ch = CheckRamp(data, i, 0x80000, ch);
        }
    }
}

/*##########################################################################
#
#   Name       : TAdc::InitPn
#
#   Purpose....: Init PN generator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAdc::InitPn()
{
    return 0x7FAE00;
}

/*##########################################################################
#
#   Name       : TAdc::UpdatePn
#
#   Purpose....: Update PN generator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAdc::UpdatePn(int start)
{
    int i;
    int a = start;
    int bit;

    for (i = 0; i < 14; i++)
    {
        bit = (((a >> 22) ^ (a >> 17)) & 1);
        a = (a << 1) | bit;
    }

    return a;
}

/*##########################################################################
#
#   Name       : TAdc::CheckPn
#
#   Purpose....: Check long PN sequence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAdc::CheckPn(TAdcData *data, int Block, int Samples, int Start)
{
    int i;
    int curr = Start;
    short int exp;
    short int a, b;
    int Errors = 0;

    for (i = 0; i < Samples; i++)
    {
        exp = (short int)((curr >> 9) & 0x3FFF);
        a = data[i].chA & 0x3FFF;
        b = data[i].chB & 0x3FFF;

        if (a != exp || b != exp)
        {
            if (Errors < 4)
            {
                if (data[i].chA == data[i].chB)
                {
                    printf("Block %d, sample %d: Expected <%04hX>, found <%04hX>\r\n", Block, i, exp, data[i].chA);
                    curr = (char)data[i].chA & 0x7F;
                }
                else
                    printf("Block %d, sample %d: A <%04hX>, B <%04hX>\r\n", Block, i, data[i].chA, data[i].chB);
            }
            Errors++;
        }

        curr = UpdatePn(curr);
    }

    if (Errors >= 4)
        printf("Block %d has %d errors\r\n", Block, Errors);

    return curr;
}

/*##########################################################################
#
#   Name       : TAdc::CheckPn
#
#   Purpose....: Check long PN sequence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CheckPn()
{
    TAdcData *data;
    int entries;
    int pn;
    int i;

    data = FindStart(&entries);

    if (data)
    {
        pn = InitPn();
        pn = CheckPn(data, 0, entries, pn);

        for (i = 1; i < FBlocks; i++)
        {
            data = GetBlock(i);
            if (data)
                pn = CheckPn(data, i, 0x80000, pn);
        }
    }
}

/*##########################################################################
#
#   Name       : TAdc::Check
#
#   Purpose....: Check test sequence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::Check()
{
    switch (FTestMode)
    {
        case 0x5:
            CheckPn();
            break;

        case 0xF:
            CheckRamp();
            break;
    }
}

/*##########################################################################
#
#   Name       : TAdc::GetSin
#
#   Purpose....: Get sin() value
#
#   In params..: Phase
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAdc::GetSin(int Phase)
{
    return ::GetSin(Phase);
}

/*##########################################################################
#
#   Name       : TAdc::CalcPower
#
#   Purpose....: Calc power
#
#   In params..: Data, Size, RelFreq, PowerA, PowerB
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CalcPower(TAdcData *Data, int Size, int RelFreq, int *PowerA, int *PowerB)
{
    struct TAdcPower res;
    long long val;

    ::CalcPower(Data, Size, RelFreq, &res);

    val = (res.SinA + res.CosA) / Size / 0x7FFF;
    *PowerA = (int)val;

    val = (res.SinB + res.CosB) / Size / 0x7FFF;
    *PowerB = (int)val;
}
