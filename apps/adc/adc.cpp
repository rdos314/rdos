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

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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

int CalcFreqPower(TAdcData *Data, int Size, int InitPhase, int PhaseIncr, struct TAdcFreqPower *Res);
#pragma aux (ANAAPI) CalcFreqPower;

int CreateSignal(int *Data, int Size, int InitPhase, int PhaseIncr, int Amp);
#pragma aux (ANAAPI) CreateSignal;

int CreateFmSignal(int *Data, int Size, int Amp, int InitPhase, int InitPeriod, int *PeriodDifd, int PeriodSize);
#pragma aux (ANAAPI) CreateFmSignal;

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

    TestData = 0;
    Intervals = 0;
    Freq = f;
    SampleFreq = f->SampleFreq;
    FreqCount = f->FreqCount;
    file = 0;
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
int TAdc::CalcFreqPower(TAdcData *Data, int Size, int InitPhase, int PhaseIncr, int *PowerA, int *PowerB, int *Delay)
{
    struct TAdcFreqPower res;
    long long val;
    int ival;
    int phase;
    double dval;
    double x, y;
    double phaseA;
    double phaseB;

    phase = ::CalcFreqPower(Data, Size, InitPhase, PhaseIncr, &res);

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

    return phase;
}

/*##########################################################################
#
#   Name       : TAdc::GetPhaseIncr
#
#   Purpose....: Get phase incr
#
#   In params..: Freq, SampleFreq
#   Out params.: *
#   Returns....: Phase incr
#
##########################################################################*/
int TAdc::GetPhaseIncr(double Freq)
{
    long long lval;
    double freq;

    freq = 1000000.0 * Freq;
    lval = (long long)freq;
    lval = lval * (long long)0x10000;
    lval = lval * (long long)0x10000;

    freq = 1000000.0 * SampleFreq;
    lval = lval / (long long)freq;

    return (int)lval;
}

/*##########################################################################
#
#   Name       : TAdc::CreateSignal
#
#   Purpose....: Create a signal at a given phase & frequency
#
#   In params..: Data, Size, RelFreq, PowerA, PowerB
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAdc::CreateSignal(int *Buf, int Size, int InitPhase, int PhaseIncr, int Amp)
{
    return ::CreateSignal(Buf, Size, InitPhase, PhaseIncr, Amp);
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
#   Name       : TAdc::CalcDirections
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAdc::CalcDirections(int DirArr[MAX_DIR], int WaveLen, int Mean, int Sd, int Distance)
{
    int Pos;
    int Count;
    double Dir;
    int Tol = Sd * WaveLen / 360;

    Pos = Mean * WaveLen / 360;
    while (Pos - WaveLen + Tol > -Distance)
        Pos -= WaveLen;

    Count = 0;

    while (Count < MAX_DIR)
    {
        if (Pos <= -Distance)
        {
            DirArr[Count] = 270;
            Count++;
        }
        else
        {
            if (Pos >= Distance)
            {
                DirArr[Count] = 90;
                Count++;
            }
            else
            {
                Dir = (double)Pos / (double)Distance;
                Dir = asin(Dir) * 180.0 / M_PI;

                if (Dir >= 0)
                {
                    DirArr[Count] = round(Dir);
                    Count++;

                    if (Count < 16)
                    {
                        DirArr[Count] = 180 - round(Dir);
                        Count++;
                    }
                }
                else
                {
                    DirArr[Count] = 360 + round(Dir);
                    Count++;

                    if (Count < MAX_DIR)
                    {
                        DirArr[Count] = 180 - round(Dir);
                        Count++;
                    }
                }
            }
        }

        if (Pos + WaveLen - Tol < Distance)
            Pos += WaveLen;
        else
            break;
    }

    return Count;
}

/*##########################################################################
#
#   Name       : TAdc::Write
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::Write(const char *str)
{
    RdosWriteString(str);
    if (file)
        file->Write(str, strlen(str));
}

/*##########################################################################
#
#   Name       : TAdc::PrintDelay
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::PrintDelay(struct TDelay *d, bool header)
{
    int i;
    int hil;
    int lowl;
    int index;
    double val;
    double sum;
    double mean;
    int HiIndex;
    int HiVal;
    bool First;
    bool Used[360];
    char str[100];

    sum = 0;
    for (i = 0; i < 360; i++)
        sum += (double)d->Phase[i];

    mean = sum / 360.0;

    sum = 0;
    for (i = 0; i < 360; i++)
    {
        val = mean - (double)d->Phase[i];
        sum += val * val;
    }

    val = sum / 359.0;
    hil = (int)(mean + 2.0 * sqrt(val));
    if (hil < 3)
        hil = 3;

    lowl = (int)mean;
    if (lowl < 0)
        lowl = 0;

    for (i = 0; i < 360; i++)
        Used[i] = false;

    HiIndex = 0;
    First = true;

    while (HiIndex >= 0)
    {
        HiIndex = -1;
        HiVal = 0;

        for (i = 0; i < 360; i++)
        {
            if (!Used[i] && d->Phase[i] >= hil)
            {
                if (d->Phase[i] > HiVal)
                {
                    HiVal = d->Phase[i];
                    HiIndex = i;
                }
            }
        }

        if (HiIndex >= 0)
        {
            for (i = 0; i < 360; i++)
            {
                index = (HiIndex + i) % 360;
                if (Used[index])
                    break;
                else
                {
                    if (d->Phase[index] >= lowl)
                        Used[index] = true;
                    else
                        break;
                }
            }

            for (i = 1; i < 360; i++)
            {
                index = (HiIndex + 360 - i) % 360;
                if (Used[index])
                    break;
                else
                {
                    if (d->Phase[index] >= lowl)
                        Used[index] = true;
                    else
                        break;
                }
            }

            if (First)
            {
                First = false;

                if (header)
                    sprintf(str, "Peaks: ");
                else
                    sprintf(str, "{");

                Write(str);
            }
            else
            {
                sprintf(str, " ");
                Write(str);
            }

            if (HiIndex > 180)
                HiIndex -= 360;

            sprintf(str, "%d", HiIndex);
            Write(str);
        }
    }

    if (First)
    {
        sprintf(str, "Noise ");
        Write(str);
    }
    else
    {
        if (!header)
        {
            sprintf(str, "} ");
            Write(str);
        }
    }
}

/*##########################################################################
#
#   Name       : TAdc::PrintCountSumary
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::PrintCountSumary(int Index)
{
    TAdcAna *ana;
    int i;
    double sum;
    double mean;
    double sd;
    double val;
    char str[100];

    strcpy(str, "Count: ");
    Write(str);

    ana = AdcAna[0];

    sum = 0;
    for (i = 0; i < Intervals; i++)
    {
        ana = AdcAna[i];
        sum += (double)ana->Count[Index];
    }

    mean = sum / (double)Intervals;

    if (Intervals > 1)
    {
        sum = 0;
        for (i = 0; i < Intervals; i++)
        {
            ana = AdcAna[i];
            val = (double)ana->Count[Index];
            val = mean - val;
            sum += val * val;
        }

        val = sum / (double)(Intervals - 1);
        sd = sqrt(val);
        sd = sd * 100.0 / (double)ana->Total[Index];
        mean = mean * 100.0 / (double)ana->Total[Index];

        sprintf(str, "%5.1Lf (%5.1Lf) ", mean, sd);
    }
    else
    {
        mean = mean * 100.0 / (double)ana->Total[Index];
        sprintf(str, "%5.1Lf ", mean);
    }

    Write(str);
}

/*##########################################################################
#
#   Name       : TAdc::PrintASumary
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::PrintASumary(int Index)
{
    TAdcAna *ana;
    int i;
    int count;
    double sum;
    double mean;
    int min;
    int max;
    char str[100];

    strcpy(str, "A: ");
    Write(str);

    count = 0;
    sum = 0;
    for (i = 0; i < Intervals; i++)
    {
        ana = AdcAna[i];
        if (ana->Count[Index])
        {
            sum += (double)ana->SumA[Index];
            count += ana->Count[Index];
        }
    }

    mean = sum / (double)count;
    sprintf(str, "%5.1Lf ", mean);
    Write(str);

    min = 30000;
    max = 0;
    for (i = 0; i < Intervals; i++)
    {
        ana = AdcAna[i];

        if (ana->MaxA[Index] > max)
            max = ana->MaxA[Index];

        if (ana->MinA[Index] < min)
            min = ana->MinA[Index];
    }

    sprintf(str, "[%d-%d] ", min, max);
    Write(str);
}

/*##########################################################################
#
#   Name       : TAdc::PrintBSumary
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::PrintBSumary(int Index)
{
    TAdcAna *ana;
    int i;
    int count;
    double sum;
    double mean;
    int min;
    int max;
    char str[100];

    strcpy(str, "B: ");
    Write(str);

    count = 0;
    sum = 0;
    for (i = 0; i < Intervals; i++)
    {
        ana = AdcAna[i];
        if (ana->Count[Index])
        {
            sum += (double)ana->SumB[Index];
            count += ana->Count[Index];
        }
    }

    mean = sum / (double)count;
    sprintf(str, "%5.1Lf ", mean);
    Write(str);

    min = 30000;
    max = 0;
    for (i = 0; i < Intervals; i++)
    {
        ana = AdcAna[i];

        if (ana->MaxB[Index] > max)
            max = ana->MaxB[Index];

        if (ana->MinB[Index] < min)
            min = ana->MinB[Index];
    }

    sprintf(str, "[%d-%d] ", min, max);
    Write(str);
}

/*##########################################################################
#
#   Name       : TAdc::PrintDelaySumary
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::PrintDelaySumary(int Index)
{
    TAdcAna *ana;
    int i;
    int j;
    int mean;
    int sd;
    char str[100];

    for (i = 0; i < 360; i++)
        Delay.Phase[i] = 0;

    for (i = 0; i < Intervals; i++)
    {
        ana = AdcAna[i];

        for (j = 0; j < 360; j++)
            Delay.Phase[j] += ana->Delay[Index].Phase[j];
    }

    CalcMeanSd(&Delay, &mean, &sd);

    sprintf(str, "Phase: ");
    Write(str);

    sprintf(str, "%d (%d) ", mean, sd);
    Write(str);

    PrintDelay(&Delay, true);
}

/*##########################################################################
#
#   Name       : TAdc::PrintCountDetail
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAdc::PrintCountDetail(int Index)
{
    TAdcAna *ana;
    int i;
    double sum;
    double mean;
    double sd;
    double val;
    double total;
    char str[100];

    ana = AdcAna[0];
    total = (double)ana->Total[Index];

    sum = 0;
    for (i = 0; i < Intervals; i++)
    {
        ana = AdcAna[i];
        sum += (double)ana->Count[Index];
    }

    mean = sum / (double)Intervals;

    if (Intervals > 1)
    {
        sum = 0;
        for (i = 0; i < Intervals; i++)
        {
            ana = AdcAna[i];
            val = (double)ana->Count[Index];
            val = mean - val;
            sum += val * val;
        }

        val = sum / (double)(Intervals - 1);
        sd = sqrt(val);
    }
    else
        sd = 0;

    if (sd > 5.0)
    {
        strcpy(str, "Count: ");
        Write(str);

        for (i = 0; i < Intervals; i++)
        {
            ana = AdcAna[i];
            val = (double)ana->Count[Index] * 100.0 / total;
            sprintf(str, "%5.1Lf ", val);
            Write(str);
        }

        sprintf(str, "\r\n");
        Write(str);
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TAdc::PrintADetail
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAdc::PrintADetail(int Index)
{
    TAdcAna *ana;
    int i;
    int count;
    double sum;
    double mean;
    double sd;
    double val;
    int Rel;
    char str[100];

    sum = 0;
    count = 0;
    for (i = 0; i < Intervals; i++)
    {
        ana = AdcAna[i];
        if (ana->Count[Index])
        {
            sum += (double)ana->SumA[Index] / (double)ana->Count[Index];
            count++;
        }
    }

    mean = sum / (double)count;

    if (count >= 10)
    {
        sum = 0;
        count = 0;
        for (i = 0; i < Intervals; i++)
        {
            ana = AdcAna[i];
            if (ana->Count[Index])
            {
                val = (double)ana->SumA[Index] / (double)ana->Count[Index];
                val = val - mean;
                sum += val * val;
                count++;
            }
        }

        val = sum / (double)(count - 1);
        sd = sqrt(val);
    }
    else
        sd = 0.0;

    if (sd > 2.0)
    {
        strcpy(str, "A: ");
        Write(str);

        if (count > 10)
        {
            for (i = 0; i < Intervals; i++)
            {
                ana = AdcAna[i];
                if (ana->Count[Index])
                {
                    Rel = 10 * ana->SumA[Index] / ana->Count[Index];
                    sprintf(str, "%d.%01d ", Rel / 10, Rel % 10);
                }
                else
                    strcpy(str, "* ");

                Write(str);
            }

            sprintf(str, "\r\n");
            Write(str);
        }
        else
        {
            for (i = 0; i < Intervals; i++)
            {
                ana = AdcAna[i];
                if (ana->Count[Index])
                {
                    Rel = 10 * ana->SumA[Index] / ana->Count[Index];
                    sprintf(str, "%d:%d.%01d ", i, Rel / 10, Rel % 10);
                    Write(str);
                }
            }

            sprintf(str, "\r\n");
            Write(str);
        }
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TAdc::PrintBDetail
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAdc::PrintBDetail(int Index)
{
    TAdcAna *ana;
    int i;
    int count;
    double sum;
    double mean;
    double sd;
    double val;
    int Rel;
    char str[100];

    sum = 0;
    count = 0;
    for (i = 0; i < Intervals; i++)
    {
        ana = AdcAna[i];
        if (ana->Count[Index])
        {
            sum += (double)ana->SumB[Index] / (double)ana->Count[Index];
            count++;
        }
    }

    mean = sum / (double)count;

    if (count >= 10)
    {
        sum = 0;
        count = 0;
        for (i = 0; i < Intervals; i++)
        {
            ana = AdcAna[i];
            if (ana->Count[Index])
            {
                val = (double)ana->SumB[Index] / (double)ana->Count[Index];
                val = val - mean;
                sum += val * val;
                count++;
            }
        }

        val = sum / (double)(count - 1);
        sd = sqrt(val);
    }
    else
        sd = 0.0;

    if (sd > 2.0)
    {
        strcpy(str, "B: ");
        Write(str);

        if (count > 10)
        {
            for (i = 0; i < Intervals; i++)
            {
                ana = AdcAna[i];
                if (ana->Count[Index])
                {
                    Rel = 10 * ana->SumB[Index] / ana->Count[Index];
                    sprintf(str, "%d.%01d ", Rel / 10, Rel % 10);
                }
                else
                    strcpy(str, "* ");

                Write(str);
            }

            sprintf(str, "\r\n");
            Write(str);
        }
        else
        {
            for (i = 0; i < Intervals; i++)
            {
                ana = AdcAna[i];
                if (ana->Count[Index])
                {
                    Rel = 10 * ana->SumB[Index] / ana->Count[Index];
                    sprintf(str, "%d:%d.%01d ", i, Rel / 10, Rel % 10);
                    Write(str);
                }
            }

            sprintf(str, "\r\n");
            Write(str);
        }
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TAdc::PrintDelayDetail
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAdc::PrintDelayDetail(int Index)
{
    TAdcAna *ana;
    int i;
    int j;
    int val;
    int mean;
    int sd;
    int count;
    char str[100];

    count = 0;

    for (i = 0; i < 360; i++)
        Delay.Phase[i] = 0;

    for (i = 0; i < Intervals; i++)
    {
        ana = AdcAna[i];

        for (j = 0; j < 360; j++)
            Delay.Phase[j] += ana->Delay[Index].Phase[j];

        if (ana->Count[Index])
            count++;
    }

    CalcMeanSd(&Delay, &mean, &sd);

    if (sd > 5)
    {
        sprintf(str, "Phase: ");
        Write(str);

        if (count > 10)
        {
            for (i = 0; i < Intervals; i++)
            {
                ana = AdcAna[i];
                if (ana->Count[Index])
                    PrintDelay(&ana->Delay[Index], false);
                else
                {
                    strcpy(str, "* ");
                    Write(str);
                }
            }
        }
        else
        {
            for (i = 0; i < Intervals; i++)
            {
                ana = AdcAna[i];
                if (ana->Count[Index])
                {
                    sprintf(str, "%d:", i);
                    Write(str);
                    PrintDelay(&ana->Delay[Index], false);
                }
            }
        }

        sprintf(str, "\r\n");
        Write(str);

        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TAdc::PrintResult
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::PrintResult()
{
    TAdcAna *ana;
    int i;
    int j;
    bool ok;
    int count;
    char fstr[40];
    char str[100];

    for (i = 0; i < FreqCount; i++)
    {
        count = 0;
        for (j = 0; j < Intervals; j++)
        {
            ana = AdcAna[j];
            count += ana->Count[i];
        }

        if (count)
        {
            Freq->CodeFreq(i, fstr);
            sprintf(str, "%s: ", fstr);
            Write(str);

            PrintCountSumary(i);
            PrintASumary(i);
            PrintBSumary(i);
            PrintDelaySumary(i);

            sprintf(str, "\r\n");
            Write(str);

            ok = PrintCountDetail(i);
            ok |= PrintADetail(i);
            ok |= PrintBDetail(i);
            ok |= PrintDelayDetail(i);

            if (ok)
            {
                sprintf(str, "\r\n");
                Write(str);
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TAdc::NotifyDone
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::NotifyDone()
{
    FSignal.Signal();
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
    TAdcData *data;
    TAdcThread **AdcThread;
    TAdcThread *tf;
    TAdcAna *ta;

    AdcThread = new TAdcThread*[Threads];

    for (i = 0; i < Threads; i++)
        AdcThread[i] = new TAdcThread(i, this);

    for (i = 0; i < FBlocks; i++)
    {
        t = i % Threads;
        tf = AdcThread[t];

        while (!tf->Done)
            FSignal.WaitForever();

        t = i / AnaSize;
        ta = AdcAna[t];

        data = GetBlock(i);
        tf->Process(data, ta);
    }

    for (i = 0; i < Threads; i++)
    {
        tf = AdcThread[i];
        while (!tf->Done)
            FSignal.WaitForever();

        delete tf;
    }
    delete AdcThread;
}

/*##########################################################################
#
#   Name       : TAdc::RunAdc
#
#   Purpose....: Run ADC
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAdc::RunAdc()
{
    int i;
    TAdcData *data;

    if (RdosStartAdc())
    {
        RdosWriteString("ADC started\r\n");

        file = new TFile("raw.dat", 0);
        data = GetBlock(0);

        for (i = 0; i < 0x80000; i++)
            file->Write(&data[i], sizeof(TAdcData));
        delete file;

        for (i = 0; i < FBlocks; i++)
            data = GetBlock(i);

        RdosWriteString("ADC done\r\n");
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TAdc::LoadTestData
#
#   Purpose....: Load test data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAdc::LoadTestData(const char *FileName)
{
    TFile file(FileName);
    TAdcData *data;

    if (file.IsOpen())
    {
        TestData = new TAdcData[0x80000];
        file.Read(TestData, 0x200000);
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TAdc::RunAna
#
#   Purpose....: Run analysis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::RunAna(int iv, int tc, int min, const char *ResultFile)
{
    int i;
    int CurrInt;
    int Pos;
    int CurrPos;
    TAdcAna *ana;
    char str[100];

    Intervals = iv;
    AnaSize = FBlocks / Intervals;

    AdcAna = new TAdcAna*[Intervals];

    for (i = 0; i < Intervals; i++)
        AdcAna[i] = new TAdcAna(AnaSize, Freq);

    Min = min;
    Threads = tc;

    Start("Adc", 0x4000);

    CurrInt = 0;
    Pos = 0;

    for (CurrInt = 0; CurrInt < Intervals; CurrInt++)
    {
        CurrPos = CurrInt * AnaSize;
        sprintf(str, "%d", CurrPos);
        RdosWriteString(str);

        ana = AdcAna[CurrInt];

        while (!ana->IsDone())
        {
            CurrPos = CurrInt * AnaSize + ana->GetPos();
            if (Pos == CurrPos)
                RdosWaitMilli(250);
            else
            {
                while (Pos != CurrPos)
                {
                    if ((Pos % AnaSize) != 0 && (Pos % 50) == 0)
                    {
                        RdosWriteString("\r\n");
                        ana->PrintSnap();
                        sprintf(str, "%d", Pos);
                        RdosWriteString(str);
                    }
                    else
                        RdosWriteChar('.');

                    Pos++;
                }
            }
        }
        RdosWriteString("\r\n");
        ana->PrintSnap();
    }

    while (IsRunning())
        RdosWaitMilli(250);

    file = new TFile(ResultFile, 0);
    PrintResult();
    delete file;
    file = 0;
}

/*##########################################################################
#
#   Name       : TAdc::CleanupAna
#
#   Purpose....: Cleanup analysis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CleanupAna()
{
    int i;

    if (AdcAna)
    {
        for (i = 0; i < Intervals; i++)
            delete AdcAna[i];

        delete AdcAna;
        AdcAna = 0;
    }
}

/*##########################################################################
#
#   Name       : TAdc::GetMaxPeriodic
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAdc::GetMaxPeriodic()
{
    TAdcAna *ana;
    int i;
    int j;
    double MaxCount = 0.0;
    double MaxPower = 0.0;
    int MaxIndex = 0;
    int SumA;
    int SumB;
    int count;
    double dcount;
    double dpow;

    for (i = 0; i < FreqCount; i++)
    {
        count = 0;
        SumA = 0;
        SumB = 0;

        for (j = 0; j < Intervals; j++)
        {
            ana = AdcAna[j];
            count += ana->Count[i];
            SumA += ana->SumA[i];
            SumB += ana->SumA[i];
        }

        dcount = (double)count / (double)ana->Total[i];
        dpow = sqrt((double)SumA * (double)SumA + (double)SumB * (double)SumB) / (double)count;

        if (dcount > MaxCount)
        {
            MaxPower = dpow;
            MaxCount = dcount;
            MaxIndex = i;
        }
        else
        {
            if (dcount == MaxCount && dpow > MaxPower)
            {
                MaxPower = dpow;
                MaxCount = dcount;
                MaxIndex = i;
            }
        }
    }
    return MaxIndex;
}

/*##########################################################################
#
#   Name       : TAdc::CalcFmPower
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CalcFmPower(double Freq, TAdcData *Ref)
{
    int pi = GetPhaseIncr(Freq);
    struct TAdcFreqPower res;
    int val;
    double dval;
    int Base = 0;
    int Count = 0x80000 / WorkSize;
    double PowerA = 0;
    double PowerB = 0;
    int i;

    for (i = 0; i < Count; i++)
    {
        ::CalcFreqPower(Ref + i * WorkSize, WorkSize, 0, pi, &res);

        res.SinA = res.SinA / WorkSize / 0x2000;
        res.SinB = res.SinB / WorkSize / 0x2000;
        res.CosA = res.CosA / WorkSize / 0x2000;
        res.CosB = res.CosB / WorkSize / 0x2000;

        val = res.SinA * res.SinA + res.CosA * res.CosA;
        PowerA += sqrt(val) / 2.0;

        val = res.SinB * res.SinB + res.CosB * res.CosB;
        PowerB += sqrt(val) / 2.0;
    }

    CurrPowerA = round(PowerA / (double)Count);
    CurrPowerB = round(PowerB / (double)Count);
}

/*##########################################################################
#
#   Name       : TAdc::CalcInitPhase
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CalcInitPhase(double Freq, TAdcData *Ref)
{
    double x, y;
    double phase;
    int pi = GetPhaseIncr(Freq);
    struct TAdcFreqPower res;

    ::CalcFreqPower(Ref, WorkSize, 0, pi, &res);

    res.SinA = res.SinA / WorkSize / 0x2000;
    res.SinB = res.SinB / WorkSize / 0x2000;
    res.CosA = res.CosA / WorkSize / 0x2000;
    res.CosB = res.CosB / WorkSize / 0x2000;

    x = (double)res.CosA;
    y = (double)res.SinA;
    phase = atan2(x, y);
    phase = phase / M_PI / 2.0;
    phase = phase * (double)0x10000;
    phase = phase * (double)0x10000;
    CurrPhaseA =  (int)phase;

    x = (double)res.CosB;
    y = (double)res.SinB;
    phase = atan2(x, y);
    phase = phase / M_PI / 2.0;
    phase = phase * (double)0x10000;
    phase = phase * (double)0x10000;
    CurrPhaseB =  (int)phase;
}

/*##########################################################################
#
#   Name       : TAdc::CreateFreqRef
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CreateFreqRef(int FreqIncr, TAdcData *Ref)
{
    int i;

    ::CreateSignal(WorkBuf, WorkSize, CurrPhaseA, FreqIncr, CurrPowerA);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chA = Ref[i].chA - (short int)WorkBuf[i];

    ::CreateSignal(WorkBuf, WorkSize, CurrPhaseB, FreqIncr, CurrPowerB);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chB = Ref[i].chB - (short int)WorkBuf[i];
}

/*##########################################################################
#
#   Name       : TAdc::CreateAmpRef
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CreateAmpRef(int PowerA, int PowerB, TAdcData *Ref)
{
    int i;

    ::CreateSignal(WorkBuf, WorkSize, CurrPhaseA, CurrFreqIncr, PowerA);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chA = Ref[i].chA - (short int)WorkBuf[i];

    ::CreateSignal(WorkBuf, WorkSize, CurrPhaseB, CurrFreqIncr, PowerB);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chB = Ref[i].chB - (short int)WorkBuf[i];
}

/*##########################################################################
#
#   Name       : TAdc::CreatePhaseRef
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CreatePhaseRef(int PhaseA, int PhaseB, TAdcData *Ref)
{
    int i;

    ::CreateSignal(WorkBuf, WorkSize, PhaseA, CurrFreqIncr, CurrPowerA);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chA = Ref[i].chA - (short int)WorkBuf[i];

    ::CreateSignal(WorkBuf, WorkSize, PhaseB, CurrFreqIncr, CurrPowerB);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chB = Ref[i].chB - (short int)WorkBuf[i];
}

/*##########################################################################
#
#   Name       : TAdc::UpdateRef
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::UpdateRef(TAdcData *Ref)
{
    int i;

    ::CreateSignal(WorkBuf, WorkSize, CurrPhaseA, CurrFreqIncr, CurrPowerA);

    for (i = 0; i < WorkSize; i++)
        Ref[i].chA = Ref[i].chA - (short int)WorkBuf[i];

    ::CreateSignal(WorkBuf, WorkSize, CurrPhaseB, CurrFreqIncr, CurrPowerB);

    for (i = 0; i < WorkSize; i++)
        Ref[i].chB = Ref[i].chB - (short int)WorkBuf[i];

}

/*##########################################################################
#
#   Name       : TAdc::CalcDiff
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CalcDiff(int FreqIncr, long long *DiffA, long long *DiffB)
{
    struct TAdcFreqPower res;

    ::CalcFreqPower(WorkData, WorkSize, 0, FreqIncr, &res);

    res.SinA = res.SinA / 0x2000;
    res.SinB = res.SinB / 0x2000;
    res.CosA = res.CosA / 0x2000;
    res.CosB = res.CosB / 0x2000;

    *DiffA = (res.SinA * res.SinA + res.CosA * res.CosA) / WorkSize;
    *DiffB = (res.SinB * res.SinB + res.CosB * res.CosB) / WorkSize;
}

/*##########################################################################
#
#   Name       : TAdc::OptimizeFreq
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TAdc::OptimizeFreq(double InitFreq, double InitStep, TAdcData *Ref)
{
    double Step;
    double CurrFreq;
    int fi;
    int i;
    long long DiffA, DiffB;
    long long low, mid, high;

    CurrFreq = InitFreq;
    Step = InitStep;

    fi = GetPhaseIncr(CurrFreq);
    CreateFreqRef(fi, Ref);
    CalcDiff(fi, &DiffA, &DiffB);
    mid = DiffA + DiffB;

    fi = GetPhaseIncr(CurrFreq + Step);
    CreateFreqRef(fi, Ref);
    CalcDiff(fi, &DiffA, &DiffB);
    high = DiffA + DiffB;

    while (high < mid)
    {
        mid = high;
        CurrFreq = CurrFreq + Step;

        fi = GetPhaseIncr(CurrFreq + Step);
        CreateFreqRef(fi, Ref);
        CalcDiff(fi, &DiffA, &DiffB);
        high = DiffA + DiffB;
    }

    fi = GetPhaseIncr(CurrFreq - Step);
    CreateFreqRef(fi, Ref);
    CalcDiff(fi, &DiffA, &DiffB);
    low = DiffA + DiffB;

    while (low < mid)
    {
        mid = low;
        CurrFreq = CurrFreq - Step;

        fi = GetPhaseIncr(CurrFreq - Step);
        CreateFreqRef(fi, Ref);
        CalcDiff(fi, &DiffA, &DiffB);
        low = DiffA + DiffB;
    }

    for (i = 0; i < 20; i++)
    {
        Step = Step / 2.0;

        fi = GetPhaseIncr(CurrFreq + Step);
        CreateFreqRef(fi, Ref);
        CalcDiff(fi, &DiffA, &DiffB);
        high = DiffA + DiffB;

        if (high < mid)
        {
            mid = high;
            CurrFreq = CurrFreq + Step;
        }
        else
        {
            fi = GetPhaseIncr(CurrFreq - Step);
            CreateFreqRef(fi, Ref);
            CalcDiff(fi, &DiffA, &DiffB);
            low = DiffA + DiffB;

            if (low < mid)
            {
                mid = low;
                CurrFreq = CurrFreq - Step;
            }
        }

        if (low == high)
            break;
    }

    return CurrFreq;
}

/*##########################################################################
#
#   Name       : TAdc::OptimizeAmp
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::OptimizeAmp(TAdcData *Ref)
{
    int sa, sb;
    long long lowa, mida, higha;
    long long lowb, midb, highb;

    sa = CurrPowerA / 2;
    if (sa <= 0)
        sa = 1;

    sb = CurrPowerB / 2;
    if (sb <= 0)
        sb = 1;

    CreateAmpRef(CurrPowerA, CurrPowerB, Ref);
    CalcDiff(CurrFreqIncr, &mida, &midb);

    CreateAmpRef(CurrPowerA + sa, CurrPowerB + sb, Ref);
    CalcDiff(CurrFreqIncr, &higha, &highb);

    while (higha < mida || highb < midb)
    {
        if (higha < mida)
        {
            mida = higha;
            CurrPowerA += sa;
        }

        if (highb < midb)
        {
            midb = highb;
            CurrPowerB += sa;
        }

        CreateAmpRef(CurrPowerA + sa, CurrPowerB + sb, Ref);
        CalcDiff(CurrFreqIncr, &higha, &highb);
    }

    CreateAmpRef(CurrPowerA - sa, CurrPowerB - sb, Ref);
    CalcDiff(CurrFreqIncr, &lowa, &lowb);

    while (lowa < mida || lowb < midb)
    {
        if (lowa < mida)
        {
            mida = lowa;
            CurrPowerA -= sa;
        }

        if (lowb < midb)
        {
            midb = lowb;
            CurrPowerB -= sb;
        }

        CreateAmpRef(CurrPowerA - sa, CurrPowerB - sb, Ref);
        CalcDiff(CurrFreqIncr, &lowa, &lowb);
    }

    while (sa > 1 && sb > 1)
    {
        sa = sa / 2;
        sb = sb / 2;

        CreateAmpRef(CurrPowerA + sa, CurrPowerB + sb, Ref);
        CalcDiff(CurrFreqIncr, &higha, &highb);

        if (higha < mida)
        {
            mida = higha;
            CurrPowerA += sa;
        }

        if (highb < midb)
        {
            midb = highb;
            CurrPowerB += sb;
        }

        CreateAmpRef(CurrPowerA - sa, CurrPowerB - sb, Ref);
        CalcDiff(CurrFreqIncr, &lowa, &lowb);

        if (lowa < mida)
        {
            mida = lowa;
            CurrPowerA -= sa;
        }

        if (lowb < midb)
        {
            midb = lowb;
            CurrPowerB -= sb;
        }
    }

}

/*##########################################################################
#
#   Name       : TAdc::OptimizePhase
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::OptimizePhase(TAdcData *Ref)
{
    int step;
    long long lowa, mida, higha;
    long long lowb, midb, highb;

    step = 0x10000000;

    CreatePhaseRef(CurrPhaseA, CurrPhaseB, Ref);
    CalcDiff(CurrFreqIncr, &mida, &midb);

    CreatePhaseRef(CurrPhaseA + step, CurrPhaseB + step, Ref);
    CalcDiff(CurrFreqIncr, &higha, &highb);

    while (higha < mida || highb < midb)
    {
        if (higha < mida)
        {
            mida = higha;
            CurrPhaseA += step;
        }

        if (highb < midb)
        {
            midb = highb;
            CurrPhaseB += step;
        }

        CreatePhaseRef(CurrPhaseA + step, CurrPhaseB + step, Ref);
        CalcDiff(CurrFreqIncr, &higha, &highb);
    }

    CreatePhaseRef(CurrPhaseA - step, CurrPhaseB - step, Ref);
    CalcDiff(CurrFreqIncr, &lowa, &lowb);

    while (lowa < mida || lowb < midb)
    {
        if (lowa < mida)
        {
            mida = lowa;
            CurrPhaseA -= step;
        }

        if (lowb < midb)
        {
            midb = lowb;
            CurrPhaseB -= step;
        }

        CreatePhaseRef(CurrPhaseA - step, CurrPhaseB - step, Ref);
        CalcDiff(CurrFreqIncr, &lowa, &lowb);
    }

    while (step > 1)
    {
        step = step / 2;

        CreatePhaseRef(CurrPhaseA + step, CurrPhaseB + step, Ref);
        CalcDiff(CurrFreqIncr, &higha, &highb);

        if (higha < mida)
        {
            mida = higha;
            CurrPhaseA += step;
        }

        if (highb < midb)
        {
            midb = highb;
            CurrPhaseB += step;
        }

        CreatePhaseRef(CurrPhaseA - step, CurrPhaseB - step, Ref);
        CalcDiff(CurrFreqIncr, &lowa, &lowb);

        if (lowa < mida)
        {
            mida = lowa;
            CurrPhaseA -= step;
        }

        if (lowb < midb)
        {
            midb = lowb;
            CurrPhaseB -= step;
        }
    }

}

/*##########################################################################
#
#   Name       : TAdc::CreatePhaseFmRef
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CreateFmPhaseRef(TAdcData *Ref, int PhaseA, int PhaseB)
{
    int i;

    ::CreateFmSignal(WorkBuf, WorkSize, CurrPowerA, PhaseA, InitPeriod, WorkPeriodArr, WorkPeriodSize);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chA = Ref[i].chA - (short int)WorkBuf[i];

    ::CreateFmSignal(WorkBuf, WorkSize, CurrPowerB, PhaseB, InitPeriod, WorkPeriodArr, WorkPeriodSize);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chB = Ref[i].chB - (short int)WorkBuf[i];
}

/*##########################################################################
#
#   Name       : TAdc::OptimizeFmPhase
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::OptimizeFmPhase(TAdcData *Ref)
{
    int step;
    long long lowa, mida, higha;
    long long lowb, midb, highb;

    step = 0x10000000;

    CreateFmPhaseRef(Ref, InitPhaseA, InitPhaseB);
    CalcDiff(CurrFreqIncr, &mida, &midb);

    CreateFmPhaseRef(Ref, InitPhaseA + step, InitPhaseB + step);
    CalcDiff(CurrFreqIncr, &higha, &highb);

    while (higha < mida || highb < midb)
    {
        if (higha < mida)
        {
            mida = higha;
            InitPhaseA += step;
        }

        if (highb < midb)
        {
            midb = highb;
            InitPhaseB += step;
        }

        CreateFmPhaseRef(Ref, InitPhaseA + step, InitPhaseB + step);
        CalcDiff(CurrFreqIncr, &higha, &highb);
    }

    CreateFmPhaseRef(Ref, InitPhaseA - step, InitPhaseB - step);
    CalcDiff(CurrFreqIncr, &lowa, &lowb);

    while (lowa < mida || lowb < midb)
    {
        if (lowa < mida)
        {
            mida = lowa;
            InitPhaseA -= step;
        }

        if (lowb < midb)
        {
            midb = lowb;
            InitPhaseB -= step;
        }

        CreateFmPhaseRef(Ref, InitPhaseA - step, InitPhaseB - step);
        CalcDiff(CurrFreqIncr, &lowa, &lowb);
    }

    while (step > 1)
    {
        step = step / 2;

        CreateFmPhaseRef(Ref, InitPhaseA + step, InitPhaseB + step);
        CalcDiff(CurrFreqIncr, &higha, &highb);

        if (higha < mida)
        {
            mida = higha;
            InitPhaseA += step;
        }

        if (highb < midb)
        {
            midb = highb;
            InitPhaseB += step;
        }

        CreateFmPhaseRef(Ref, InitPhaseA - step, InitPhaseB - step);
        CalcDiff(CurrFreqIncr, &lowa, &lowb);

        if (lowa < mida)
        {
            mida = lowa;
            InitPhaseA -= step;
        }

        if (lowb < midb)
        {
            midb = lowb;
            InitPhaseB -= step;
        }
    }
}

/*##########################################################################
#
#   Name       : TAdc::CreateFmPeriodRef
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::CreateFmPeriodRef(TAdcData *Ref, int Period)
{
    int i;

    ::CreateFmSignal(WorkBuf, WorkSize, CurrPowerA, InitPhaseA, Period, WorkPeriodArr, WorkPeriodSize);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chA = Ref[i].chA - (short int)WorkBuf[i];

    ::CreateFmSignal(WorkBuf, WorkSize, CurrPowerB, InitPhaseB, Period, WorkPeriodArr, WorkPeriodSize);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chB = Ref[i].chB - (short int)WorkBuf[i];
}

/*##########################################################################
#
#   Name       : TAdc::OptimizeFmPeriod
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::OptimizeFmPeriod(TAdcData *Ref)
{
    int i;
    int Step;
    long long DiffA, DiffB;
    long long low, mid, high;

    Step = 0x10000000;

    CreateFmPeriodRef(Ref, InitPeriod);
    CalcDiff(CurrFreqIncr, &DiffA, &DiffB);
    mid = DiffA + DiffB;

    CreateFmPeriodRef(Ref, InitPeriod + Step);
    CalcDiff(CurrFreqIncr, &DiffA, &DiffB);
    high = DiffA + DiffB;

    while (high < mid)
    {
        mid = high;
        InitPeriod += Step;

        CreateFmPeriodRef(Ref, InitPeriod + Step);
        CalcDiff(CurrFreqIncr, &DiffA, &DiffB);
        high = DiffA + DiffB;
    }

    CreateFmPeriodRef(Ref, InitPeriod - Step);
    CalcDiff(CurrFreqIncr, &DiffA, &DiffB);
    low = DiffA + DiffB;

    while (low < mid)
    {
        mid = low;
        InitPeriod -= Step;

        CreateFmPeriodRef(Ref, InitPeriod - Step);
        CalcDiff(CurrFreqIncr, &DiffA, &DiffB);
        low = DiffA + DiffB;
    }

    for (i = 0; i < 20; i++)
    {
        Step = Step / 2;

        CreateFmPeriodRef(Ref, InitPeriod + Step);
        CalcDiff(CurrFreqIncr, &DiffA, &DiffB);
        high = DiffA + DiffB;

        if (high < mid)
        {
            mid = high;
            InitPeriod += Step;
        }
        else
        {
            CreateFmPeriodRef(Ref, InitPeriod - Step);
            CalcDiff(CurrFreqIncr, &DiffA, &DiffB);
            low = DiffA + DiffB;

            if (low < mid)
            {
                mid = low;
                InitPeriod -= Step;
            }
        }

        if (low == high)
            break;
    }
}

/*##########################################################################
#
#   Name       : TAdc::RemoveFreq
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdc::RemoveFreq(double Freq)
{
    int i;
    double CurrFreq;
    int Base = 0;
    TAdcData *Data = TestData;
    double rel;
    char str[40];
    int MaxWorkSize = 1024;

    WorkData = new TAdcData[MaxWorkSize];
    WorkBuf = new int[MaxWorkSize];

    WorkPeriodSize = 16;
    WorkPeriodArr = new int[MaxWorkSize / WorkPeriodSize];

    WorkSize = WorkPeriodSize;

    InitPhaseA = 0;
    InitPhaseB = 0;
    InitPeriod = GetPhaseIncr(Freq);
    WorkPeriodCount = 1;
    WorkPeriodArr[0] = 0;

    CalcFmPower(Freq, Data);
    OptimizeFmPhase(Data);
    OptimizeFmPeriod(Data);


    while (Base < 0x80000)
    {
        CalcInitPhase(Freq, Data + Base);
        CurrFreq = OptimizeFreq(Freq, 0.1, Data + Base);
        CurrFreqIncr = GetPhaseIncr(CurrFreq);

        rel = 1000.0 * (CurrFreq - Freq);
        sprintf(str, "%10.2Lf kHz\r\n", rel);
        Write(str);

        CurrPhaseA += WorkSize * CurrFreqIncr / 2;
        CurrPhaseB += WorkSize * CurrFreqIncr / 2;
        Base += WorkSize / 2;
    }

    delete WorkBuf;
    delete WorkData;

}
