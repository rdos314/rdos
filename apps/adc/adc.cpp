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
#include <math.h>
#include <rdos.h>
#include "adcthr.h"
#include "adcana.h"
#include "adc.h"

struct TAdcFreqPower
{
    long long SinA;
    long long SinB;
    long long CosA;
    long long CosB;
};

struct TAdcPower
{
    long long PowA;
    long long PowB;
};


#pragma aux ANAAPI "_*" \
       parm routine [] \
       value struct float struct routine [eax] \
       modify [eax ecx edx];

extern "C" {

int GetSin(int Phase);
#pragma aux (ANAAPI) GetSin;

void CalcPower(TAdcData *Data, int Size, struct TAdcPower *Res);
#pragma aux (ANAAPI) CalcPower;

void CalcFreqPower(TAdcData *Data, int Size, int RelFreq, struct TAdcFreqPower *Res);
#pragma aux (ANAAPI) CalcFreqPower;

};

#define M_PI 3.14159265358979323846

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
TAdc::TAdc(char TestMode, int Blocks, TFreq *f)
{
    FTestMode = TestMode;
    FBlocks = Blocks;
    FBuf = (char *)RdosAllocateMem(0x200000);

    RdosSetupAdc(TestMode, 0, FBlocks);

    Intervals = 0;
    AdcAna = 0;
    Freq = f;
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
    int i;

    if (AdcAna)
    {
        for (i = 0; i < Intervals; i++)
            delete AdcAna[i];

        delete AdcAna;
    }

    RdosFreeMem(FBuf);
}

/*##########################################################################
#
#   Name       : TAdc::SetTrigger
#
#   Purpose....: set trigger
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::SetTrigger(int PhaseIncr, int Window)
{
    RdosSetAdcTrigger(PhaseIncr, Window);
}

/*##########################################################################
#
#   Name       : TAdc::StartAdc
#
#   Purpose....: start ADC
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAdc::StartAdc(int iv, int tc)
{
    int i;

    if (RdosStartAdc())
    {
        Intervals = iv;
        Threads = tc;

        AdcAna = new TAdcAna*[Intervals];
        
        for (i = 0; i < Intervals; i++)
            AdcAna[i] = new TAdcAna(Freq);

        Start("Adc", 0x4000);
        return true;
    }
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
#   In params..: Data, Size, PowerA, PowerB
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CalcPower(TAdcData *Data, int Size, int *PowerA, int *PowerB)
{
    struct TAdcPower res;
    long long val;
    int ival;
    double dval;

    ::CalcPower(Data, Size, &res);

    val  = res.PowA / Size;
    dval = sqrt(val);
    *PowerA = round(dval);

    val  = res.PowB / Size;
    dval = sqrt(val);
    *PowerB = round(dval);

}

/*##########################################################################
#
#   Name       : TAdc::CalcFreqPower
#
#   Purpose....: Calc power at a given frequency
#
#   In params..: Data, Size, RelFreq, PowerA, PowerB
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CalcFreqPower(TAdcData *Data, int Size, int RelFreq, int *PowerA, int *PowerB, int *Delay)
{
    struct TAdcFreqPower res;
    long long val;
    int ival;
    double dval;
    double x, y;
    double phaseA;
    double phaseB;

    ::CalcFreqPower(Data, Size, RelFreq, &res);

    res.SinA = res.SinA / Size / 0x2000;
    res.SinB = res.SinB / Size / 0x2000;
    res.CosA = res.CosA / Size / 0x2000;
    res.CosB = res.CosB / Size / 0x2000;

    x = (double)res.CosA;
    y = (double)res.SinA;
    phaseA = atan2(x, y);
    phaseA =  phaseA * 180.0 / M_PI;

    x = (double)res.CosB;
    y = (double)res.SinB;
    phaseB = atan2(x, y);
    phaseB =  phaseB * 180.0 / M_PI;

    dval =  phaseB - phaseA;
    ival = round(dval);

    while (ival < 0)
        ival += 360;

    while (ival >= 360)
        ival -= 360;

    *Delay = ival;

    val = res.SinA * res.SinA + res.CosA * res.CosA;
    dval = sqrt(val);
    *PowerA = round(dval);

    val = res.SinB * res.SinB + res.CosB * res.CosB;
    dval = sqrt(val);
    *PowerB = round(dval);
}

/*##########################################################################
#
#   Name       : TAdc::CalcMeanSdPos
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CalcMeanSdPos(struct TDelay *Delay, int Start, int *Mean, double *Sd)
{
    int i;
    int pos;
    long long sum;
    int count;
    int mean;
    double dval;

    sum = 0;
    count = 0;

    for (i = 0; i < 360; i++)
    {
        pos = i - Start;

        if (pos < -180)
            pos += 360;

        if (pos >= 180)
            pos -= 360;

        sum += Delay->Phase[i] * pos;
        count += Delay->Phase[i];
    }

    mean = round(sum / (long long)count);
    *Mean = mean;

    sum = 0;

    for (i = 0; i < 360; i++)
    {
        pos = i - Start;

        if (pos < -180)
            pos += 360;

        if (pos >= 180)
            pos -= 360;

        sum += Delay->Phase[i] * (pos - mean) * (pos - mean);
    }

    dval = (double)(sum / (long long)count);
    dval = sqrt(dval);
    *Sd = dval;
}

/*##########################################################################
#
#   Name       : TAdc::CalcMeanSd
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CalcMeanSd(struct TDelay *Delay, int *Mean, int *Sd)
{
    int pos;
    int mean;
    int cmean;
    double sd;
    double csd;

    cmean = 0;
    csd = 1000000.0;

    for (pos = 0; pos < 360; pos++)
    {
        CalcMeanSdPos(Delay, pos, &mean, &sd);
        if (sd < csd)
        {
            csd = sd;
            cmean = pos + mean;
        }
    }

    while (cmean < -180)
        cmean += 360;

    while (cmean >= 180)
        cmean -= 360;

    *Sd = round(csd);
    *Mean = cmean;
}

/*##########################################################################
#
#   Name       : TAdc::Execute
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::Execute()
{
    int i;
    int t;
    int count = FBlocks / Intervals;
    TAdcData *data;
    TAdcThread **AdcThread;
    TAdcThread *tf;
    TAdcAna *ta;

    AdcThread = new TAdcThread*[Threads];

    for (i = 0; i < Threads; i++)
        AdcThread[i] = new TAdcThread(i, Freq);

    for (i = 0; i < FBlocks; i++)
    {
        data = GetBlock(i);

        t = i % Threads;
        tf = AdcThread[t];

        t = i / count;
        ta = AdcAna[t];
            
        while (!tf->Done)
            RdosWaitMilli(5);

        tf->Process(data, ta);
    }

    for (i = 0; i < Threads; i++)
    {
        tf = AdcThread[i];
        while (!tf->Done)
            RdosWaitMilli(5);

        delete tf;
    }
    delete AdcThread;
}
