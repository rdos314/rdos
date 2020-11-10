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
# fmsig.cpp
# FM signal class
#
########################################################################*/

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <rdos.h>
#include "fmsig.h"

struct TAdcFreqPower
{
    long long SinA;
    long long SinB;
    long long CosA;
    long long CosB;
};

struct TAdcFreqChanPower
{
    long long SinP;
    long long CosP;
};

struct TAdcPower
{
    long long PowA;
    long long PowB;
};

struct TAdcFmPower
{
    long long SinFm;
    long long SinSig;
    long long CosSig;
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

int CalcFreqPowerA(TAdcData *Data, int Size, int InitPhase, int PhasePerSample, struct TAdcFreqChanPower *Res);
#pragma aux (ANAAPI) CalcFreqPowerA;

int CalcFreqPowerB(TAdcData *Data, int Size, int InitPhase, int PhasePerSample, struct TAdcFreqChanPower *Res);
#pragma aux (ANAAPI) CalcFreqPowerB;

int CalcFmPowerA(TAdcData *Data, int Size, int InitPhase, int InitPhasePerSample, int PhasePerSampleIncr, int Amp, struct TAdcFmPower *Res);
#pragma aux (ANAAPI) CalcFmPowerA;

int CalcFmPowerB(TAdcData *Data, int Size, int InitPhase, int InitPhasePerSample, int PhasePerSampleIncr, int Amp, struct TAdcFmPower *Res);
#pragma aux (ANAAPI) CalcFmPowerB;

int CreateSignal(int *Data, int Size, int InitPhase, int PhaseIncr, int Amp);
#pragma aux (ANAAPI) CreateSignal;

int CreateFmSignal(int *Data, int Size, int Amp, int InitPhase, int InitPeriod, int *PeriodDifd, int PeriodSize);
#pragma aux (ANAAPI) CreateFmSignal;

};

#define M_PI 3.14159265358979323846

/*##########################################################################
#
#   Name       : TFmSignal::TFmSignal
#
#   Purpose....: Constructor for FM signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFmSignal::TFmSignal(double sf, double f)
{
    SampleFreq = sf;
    Freq = f;

    SamplesPerPeriod = SampleFreq / Freq;
    PhasePerSample = FreqToPhasePerSample(Freq);
    UsedSamples = round(20.0 * SamplesPerPeriod);

    FirstBlock = true;
}

/*##########################################################################
#
#   Name       : TFmSignal::~TFmSignal
#
#   Purpose....: Destructor for FM signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFmSignal::~TFmSignal()
{
}

/*##########################################################################
#
#   Name       : TFmSignal::FreqToPhasePerSample
#
#   Purpose....: Get phase per sample
#
#   In params..: Freq, SampleFreq
#   Out params.: *
#   Returns....: Phase incr
#
##########################################################################*/
int TFmSignal::FreqToPhasePerSample(double Freq)
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
#   Name       : TFmSignal::PhasePerSampleToFreq
#
#   Purpose....: Get freq from phase per sample
#
#   In params..: Freq, SampleFreq
#   Out params.: *
#   Returns....: Phase incr
#
##########################################################################*/
double TFmSignal::PhasePerSampleToFreq(int ps)
{
    long long lval;
    double freq;

    freq = SampleFreq * (double)ps;
    freq = freq / (double)0x10000;
    freq = freq / (double)0x10000;

    return freq;
}

/*##########################################################################
#
#   Name       : TFmSignal::CalcPowerA
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TFmSignal::CalcPowerA(TAdcData *Data, int Size)
{
    long long val;
    double dval;
    TAdcFreqChanPower res;

    ::CalcFreqPowerA(Data, Size, 0, PhasePerSample, &res);

    res.SinP = res.SinP / Size / 0x2000;
    res.CosP = res.CosP / Size / 0x2000;

    val = res.SinP * res.SinP + res.CosP * res.CosP;
    return sqrt(val / 2.0);
}

/*##########################################################################
#
#   Name       : TFmSignal::CalcPowerB
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TFmSignal::CalcPowerB(TAdcData *Data, int Size)
{
    long long val;
    double dval;
    TAdcFreqChanPower res;

    ::CalcFreqPowerB(Data, Size, 0, PhasePerSample, &res);

    res.SinP = res.SinP / Size / 0x2000;
    res.CosP = res.CosP / Size / 0x2000;

    val = res.SinP * res.SinP + res.CosP * res.CosP;
    return sqrt(val / 2.0);
}

/*##########################################################################
#
#   Name       : TFmSignal::CalcPhaseA
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TFmSignal::CalcPhaseA(TAdcData *Data, int Size)
{
    double x, y;
    double phase;
    TAdcFreqChanPower res;

    ::CalcFreqPowerA(Data, Size, 0, PhasePerSample, &res);

    x = (double)res.CosP;
    y = (double)res.SinP;
    phase = atan2(x, y);
    phase = phase / M_PI / 2.0;
    return phase;
}

/*##########################################################################
#
#   Name       : TFmSignal::CalcPhaseB
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TFmSignal::CalcPhaseB(TAdcData *Data, int Size)
{
    double x, y;
    double phase;
    TAdcFreqChanPower res;

    ::CalcFreqPowerB(Data, Size, 0, PhasePerSample, &res);

    x = (double)res.CosP;
    y = (double)res.SinP;
    phase = atan2(x, y);
    phase = phase / M_PI / 2.0;
    return phase;
}

/*##########################################################################
#
#   Name       : TFmSignal::CalcOffsets
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::CalcOffsets(TAdcData *Data)
{
    double phaseA, phaseB;
    double offsetA, offsetB;
    TAdcFmPower res;

    phaseA = CalcPhaseA(Data, UsedSamples);
    phaseB = CalcPhaseB(Data, UsedSamples);

    offsetA = (1.0 - phaseA) * SamplesPerPeriod;
    offsetB = (1.0 - phaseB) * SamplesPerPeriod;

    if (offsetA > offsetB)
    {
        if (offsetA - offsetB > SamplesPerPeriod / 2)
            offsetB += SamplesPerPeriod;
    }
    else
    {
        if (offsetB - offsetA > SamplesPerPeriod / 2)
            offsetA += SamplesPerPeriod;
    }

    CurrPosA = round(offsetA);
    CurrPosB = round(offsetB);
}

/*##########################################################################
#
#   Name       : TFmSignal::OptimizePhaseA
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::OptimizePhaseA(TAdcData *Data)
{
    int step;
    long long low, mid, high;
    TAdcFmPower res;

    step = 0x10000000;

    CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample, 0, CurrPowerA, &res);
    mid = res.CosSig * res.CosSig;

    CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA + step, PhasePerSample, 0, CurrPowerA, &res);
    high = res.CosSig * res.CosSig;

    while (high < mid)
    {
        mid = high;
        CurrPhaseA += step;

        CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA + step, PhasePerSample, 0, CurrPowerA, &res);
        high = res.CosSig * res.CosSig;
    }

    CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA - step, PhasePerSample, 0, CurrPowerA, &res);
    low = res.CosSig * res.CosSig;

    while (low < mid)
    {
        mid = low;
        CurrPhaseA -= step;

        CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA - step, PhasePerSample, 0, CurrPowerA, &res);
        low = res.CosSig * res.CosSig;
    }

    while (step > 1)
    {
        step = step / 2;


        CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA + step, PhasePerSample, 0, CurrPowerA, &res);
        high = res.CosSig * res.CosSig;

        if (high < mid)
        {
            mid = high;
            CurrPhaseA += step;
        }
        else
        {
            CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA - step, PhasePerSample, 0, CurrPowerA, &res);
            low = res.CosSig * res.CosSig;

            if (low < mid)
            {
                mid = low;
                CurrPhaseA -= step;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TFmSignal::OptimizePhaseB
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::OptimizePhaseB(TAdcData *Data)
{
    int step;
    long long low, mid, high;
    TAdcFmPower res;

    step = 0x10000000;

    CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample, 0, CurrPowerB, &res);
    mid = res.CosSig * res.CosSig;

    CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB + step, PhasePerSample, 0, CurrPowerB, &res);
    high = res.CosSig * res.CosSig;

    while (high < mid)
    {
        mid = high;
        CurrPhaseB += step;

        CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB + step, PhasePerSample, 0, CurrPowerB, &res);
        high = res.CosSig * res.CosSig;
    }

    CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB - step, PhasePerSample, 0, CurrPowerB, &res);
    low = res.CosSig * res.CosSig;

    while (low < mid)
    {
        mid = low;
        CurrPhaseB -= step;

        CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB - step, PhasePerSample, 0, CurrPowerB, &res);
        low = res.CosSig * res.CosSig;
    }

    while (step > 1)
    {
        step = step / 2;


        CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB + step, PhasePerSample, 0, CurrPowerB, &res);
        high = res.CosSig * res.CosSig;

        if (high < mid)
        {
            mid = high;
            CurrPhaseB += step;
        }
        else
        {
            CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB - step, PhasePerSample, 0, CurrPowerB, &res);
            low = res.CosSig * res.CosSig;

            if (low < mid)
            {
                mid = low;
                CurrPhaseB -= step;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TFmSignal::OptimizePowerA
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::OptimizePowerA(TAdcData *Data)
{
    int step;
    long long low, mid, high;
    TAdcFmPower res;

    step = CurrPowerA / 8;
    if (step < 2)
        step = 2;

    CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample, 0, CurrPowerA, &res);
    mid = res.CosSig * res.CosSig + res.SinSig * res.SinSig;

    CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample, 0, CurrPowerA + step, &res);
    high = res.CosSig * res.CosSig + res.SinSig * res.SinSig;

    while (high < mid)
    {
        mid = high;
        CurrPowerA += step;

        CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample, 0, CurrPowerA + step, &res);
        high = res.CosSig * res.CosSig + res.SinSig * res.SinSig;
    }

    CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample, 0, CurrPowerA - step, &res);
    low = res.CosSig * res.CosSig + res.SinSig * res.SinSig;

    while (low < mid)
    {
        mid = low;
        CurrPowerA -= step;

        CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample, 0, CurrPowerA - step, &res);
        low = res.CosSig * res.CosSig + res.SinSig * res.SinSig;
    }

    while (step > 1)
    {
        step = step / 2;


        CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample, 0, CurrPowerA + step, &res);
        high = res.CosSig * res.CosSig + res.SinSig * res.SinSig;

        if (high < mid)
        {
            mid = high;
            CurrPowerA += step;
        }
        else
        {
            CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample, 0, CurrPowerA - step, &res);
            low = res.CosSig * res.CosSig + res.SinSig * res.SinSig;

            if (low < mid)
            {
                mid = low;
                CurrPowerA -= step;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TFmSignal::OptimizePowerB
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::OptimizePowerB(TAdcData *Data)
{
    int step;
    long long low, mid, high;
    TAdcFmPower res;

    step = CurrPowerB / 8;
    if (step < 2)
        step = 2;

    CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample, 0, CurrPowerB, &res);
    mid = res.CosSig * res.CosSig + res.SinSig * res.SinSig;

    CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample, 0, CurrPowerB + step, &res);
    high = res.CosSig * res.CosSig + res.SinSig * res.SinSig;

    while (high < mid)
    {
        mid = high;
        CurrPowerB += step;

        CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample, 0, CurrPowerB + step, &res);
        high = res.CosSig * res.CosSig + res.SinSig * res.SinSig;
    }

    CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample, 0, CurrPowerB - step, &res);
    low = res.CosSig * res.CosSig + res.SinSig * res.SinSig;

    while (low < mid)
    {
        mid = low;
        CurrPowerB -= step;

        CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample, 0, CurrPowerB - step, &res);
        low = res.CosSig * res.CosSig + res.SinSig * res.SinSig;
    }

    while (step > 1)
    {
        step = step / 2;


        CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample, 0, CurrPowerB + step, &res);
        high = res.CosSig * res.CosSig + res.SinSig * res.SinSig;

        if (high < mid)
        {
            mid = high;
            CurrPowerB += step;
        }
        else
        {
            CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample, 0, CurrPowerB - step, &res);
            low = res.CosSig * res.CosSig + res.SinSig * res.SinSig;

            if (low < mid)
            {
                mid = low;
                CurrPowerB -= step;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TFmSignal::OptimizeFreq
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::OptimizeFreq(TAdcData *Data)
{
    int step;
    long long low, mid, high;
    TAdcFmPower res;

    step = PhasePerSample / 16;

    CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample, 0, CurrPowerA, &res);
    mid = res.CosSig * res.CosSig + res.SinSig * res.SinSig;
    CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample, 0, CurrPowerB, &res);
    mid += res.CosSig * res.CosSig + res.SinSig * res.SinSig;

    CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample + step, 0, CurrPowerA, &res);
    high = res.CosSig * res.CosSig + res.SinSig * res.SinSig;
    CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample + step, 0, CurrPowerB, &res);
    high += res.CosSig * res.CosSig + res.SinSig * res.SinSig;

    while (high < mid)
    {
        mid = high;
        PhasePerSample += step;

        CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample + step, 0, CurrPowerA, &res);
        high = res.CosSig * res.CosSig + res.SinSig * res.SinSig;
        CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample + step, 0, CurrPowerB, &res);
        high += res.CosSig * res.CosSig + res.SinSig * res.SinSig;
    }

    CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample - step, 0, CurrPowerA, &res);
    low = res.CosSig * res.CosSig + res.SinSig * res.SinSig;
    CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample - step, 0, CurrPowerB, &res);
    low += res.CosSig * res.CosSig + res.SinSig * res.SinSig;

    while (low < mid)
    {
        mid = low;
        PhasePerSample -= step;

        CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample - step, 0, CurrPowerA, &res);
        low = res.CosSig * res.CosSig + res.SinSig * res.SinSig;
        CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample - step, 0, CurrPowerB, &res);
        low += res.CosSig * res.CosSig + res.SinSig * res.SinSig;
    }

    while (step > 1)
    {
        step = step / 2;

        CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample + step, 0, CurrPowerA, &res);
        high = res.CosSig * res.CosSig + res.SinSig * res.SinSig;
        CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample + step, 0, CurrPowerB, &res);
        high += res.CosSig * res.CosSig + res.SinSig * res.SinSig;

        if (high < mid)
        {
            mid = high;
            PhasePerSample += step;
        }
        else
        {
            CalcFmPowerA(Data + CurrPosA, UsedSamples, CurrPhaseA, PhasePerSample - step, 0, CurrPowerA, &res);
            low = res.CosSig * res.CosSig + res.SinSig * res.SinSig;
            CalcFmPowerB(Data + CurrPosB, UsedSamples, CurrPhaseB, PhasePerSample - step, 0, CurrPowerB, &res);
            low += res.CosSig * res.CosSig + res.SinSig * res.SinSig;

            if (low < mid)
            {
                mid = low;
                PhasePerSample -= step;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TFmSignal::SetupA
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::SetupA(TAdcData *Data)
{
    double Phase;
    double Amp;
    double dval;
    int i;

    Amp = CalcPowerA(Data, UsedSamples);
    CurrPowerA = round(Amp);

    Phase = CalcPhaseA(Data + CurrPosA, UsedSamples);

    while (Phase >= 1.0)
        Phase -= 1.0;

    while (Phase <= -1.0)
        Phase += 1.0;

    dval = Phase * (double)0x10000;
    dval = dval * (double)0x10000;
    CurrPhaseA = round(dval);
}

/*##########################################################################
#
#   Name       : TFmSignal::SetupB
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::SetupB(TAdcData *Data)
{
    double Phase;
    double Amp;
    double dval;
    int i;

    Amp = CalcPowerB(Data, UsedSamples);
    CurrPowerB = round(Amp);

    Phase = CalcPhaseB(Data + CurrPosB, UsedSamples);

    while (Phase >= 1.0)
        Phase -= 1.0;

    while (Phase <= -1.0)
        Phase += 1.0;

    dval = Phase * (double)0x10000;
    dval = dval * (double)0x10000;
    CurrPhaseB = round(dval);
}

/*##########################################################################
#
#   Name       : TFmSignal::AddBlock
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::AddBlock(TAdcData *Data)
{
    int i;
    double freq;

    if (FirstBlock)
    {
        FirstBlock = false;

        CalcOffsets(Data);
        SetupA(Data);
        SetupB(Data);

        for (i = 0; i < 10; i++)
        {
            OptimizePhaseA(Data);
            OptimizePhaseB(Data);
            OptimizePowerA(Data);
            OptimizePowerB(Data);
            OptimizeFreq(Data);
        }

        freq = PhasePerSampleToFreq(PhasePerSample);
        freq -= Freq;

    }
}
