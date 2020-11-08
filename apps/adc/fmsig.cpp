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
#   Name       : TFmSignal::TFmSignal
#
#   Purpose....: Constructor for FM signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFmSignal::TFmSignal(double sf, double f, double bw, int DataSize, int DataSamples)
{
    int Size;
    int val;

    SampleFreq = sf;
    Freq = f;

    PowerA = 0;
    PowerB = 0;

    PhaseIncr = GetPhaseIncr(Freq);
    val = GetPhaseIncr(Freq + bw);
    MaxPhaseIncr = (val - PhaseIncr) / DataSize;

    PhaseIncrSamples = DataSize;
    PhaseIncrCount = 0;
    PhaseIncrArr = new int[DataSamples];

    WorkSize = 0;
    Size = DataSize * DataSamples;
    WorkData = new TAdcData[Size];
    WorkBuf = new int[Size];

    SampleCount = 0;
    SampleSize = DataSamples;
    SampleData = new TAdcData[Size + DataSize];

    OffsetA = 0;
    OffsetB = 0;

    InitPhaseA = 0;
    InitPhaseB = 0;
    InitPhaseIncr = PhaseIncr;

    PhaseIncrCount = 1;
    PhaseIncrArr[0] = 0;
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
    delete WorkData;
    delete WorkBuf;
    delete SampleData;
}

/*##########################################################################
#
#   Name       : TFmSignal::SetPower
#
#   Purpose....: Set power
#
#   In params..:
#   Out params.: *
#   Returns....:
#
##########################################################################*/
void TFmSignal::SetPower(int pA, int pB)
{
    PowerA = pA;
    PowerB = pB;
}

/*##########################################################################
#
#   Name       : TFmSignal::SetPhase
#
#   Purpose....: Set phase
#
#   In params..:
#   Out params.: *
#   Returns....:
#
##########################################################################*/
void TFmSignal::SetPhase(int pA, int pB)
{
    InitPhaseA = pA;
    InitPhaseB = pB;
}

/*##########################################################################
#
#   Name       : TFmSignal::GetPhaseIncr
#
#   Purpose....: Get phase incr
#
#   In params..: Freq, SampleFreq
#   Out params.: *
#   Returns....: Phase incr
#
##########################################################################*/
int TFmSignal::GetPhaseIncr(double Freq)
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
#   Name       : TFmSignal::CalcDiff
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::CalcDiff(long long *DiffA, long long *DiffB)
{
    struct TAdcPower res;

    ::CalcPower(WorkData, WorkSize, &res);

    *DiffA  = res.PowA;
    *DiffB  = res.PowB;
}

/*##########################################################################
#
#   Name       : TFmSignal::CreatePhaseRef
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::CreatePhaseRef(int PhaseA, int PhaseB)
{
    int i;

    ::CreateFmSignal(WorkBuf, WorkSize, PowerA, PhaseA, InitPhaseIncr, PhaseIncrArr, PhaseIncrSamples);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chA = SampleData[i + OffsetA].chA - (short int)WorkBuf[i];

    ::CreateFmSignal(WorkBuf, WorkSize, PowerB, PhaseB, InitPhaseIncr, PhaseIncrArr, PhaseIncrSamples);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chB = SampleData[i + OffsetB].chB - (short int)WorkBuf[i];
}

/*##########################################################################
#
#   Name       : TFmSignal::OptimizePhase
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::OptimizePhase()
{
    int step;
    long long lowa, mida, higha;
    long long lowb, midb, highb;

    step = 0x10000000;

    CreatePhaseRef(InitPhaseA, InitPhaseB);
    CalcDiff(&mida, &midb);

    CreatePhaseRef(InitPhaseA + step, InitPhaseB + step);
    CalcDiff(&higha, &highb);

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

        CreatePhaseRef(InitPhaseA + step, InitPhaseB + step);
        CalcDiff(&higha, &highb);
    }

    CreatePhaseRef(InitPhaseA - step, InitPhaseB - step);
    CalcDiff(&lowa, &lowb);

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

        CreatePhaseRef(InitPhaseA - step, InitPhaseB - step);
        CalcDiff(&lowa, &lowb);
    }

    while (step > 1)
    {
        step = step / 2;

        CreatePhaseRef(InitPhaseA + step, InitPhaseB + step);
        CalcDiff(&higha, &highb);

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

        CreatePhaseRef(InitPhaseA - step, InitPhaseB - step);
        CalcDiff(&lowa, &lowb);

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
#   Name       : TFmSignal::CreatePhaseIncrRef
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::CreatePhaseIncrRef(int pi)
{
    int i;

    ::CreateFmSignal(WorkBuf, WorkSize, PowerA, InitPhaseA, pi, PhaseIncrArr, PhaseIncrSamples);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chA = SampleData[i + OffsetA].chA - (short int)WorkBuf[i];

    ::CreateFmSignal(WorkBuf, WorkSize, PowerB, InitPhaseB, pi, PhaseIncrArr, PhaseIncrSamples);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chB = SampleData[i + OffsetB].chB - (short int)WorkBuf[i];
}

/*##########################################################################
#
#   Name       : TFmSignal::OptimizePhaseIncr
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::OptimizePhaseIncr()
{
    int i;
    int Step;
    long long DiffA, DiffB;
    long long low, mid, high;

    Step = MaxPhaseIncr;

    CreatePhaseIncrRef(InitPhaseIncr);
    CalcDiff(&DiffA, &DiffB);
    mid = DiffA + DiffB;

    for (i = 0; i < 20; i++)
    {
        Step = Step / 2;

        CreatePhaseIncrRef(InitPhaseIncr + Step);
        CalcDiff(&DiffA, &DiffB);
        high = DiffA + DiffB;

        if (high < mid)
        {
            mid = high;
            InitPhaseIncr += Step;
        }
        else
        {
            CreatePhaseIncrRef(InitPhaseIncr - Step);
            CalcDiff(&DiffA, &DiffB);
            low = DiffA + DiffB;

            if (low < mid)
            {
                mid = low;
                InitPhaseIncr -= Step;
            }
        }

        if (low == high)
            break;
    }
}

/*##########################################################################
#
#   Name       : TAdc::CreateInitSeriesRef
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::CreateInitSeriesRef(int pi, int PhaseIncr0)
{
    int i;

    PhaseIncrArr[0] = PhaseIncr0;

    ::CreateFmSignal(WorkBuf, WorkSize, PowerA, InitPhaseA, pi, PhaseIncrArr, PhaseIncrSamples);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chA = SampleData[i + OffsetA].chA - (short int)WorkBuf[i];

    ::CreateFmSignal(WorkBuf, WorkSize, PowerB, InitPhaseB, pi, PhaseIncrArr, PhaseIncrSamples);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chB = SampleData[i + OffsetB].chB - (short int)WorkBuf[i];
}

/*##########################################################################
#
#   Name       : TFmSignal::OptimizeInitSeries
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::OptimizeInitSeries()
{
    int i;
    int Step;
    int PhaseIncr0 = PhaseIncrArr[0];
    int PhaseDiv = PhaseIncrSamples / 2;
    long long DiffA, DiffB;
    long long low, mid, high;

    Step = MaxPhaseIncr;

    CreateInitSeriesRef(InitPhaseIncr, PhaseIncr0);
    CalcDiff(&DiffA, &DiffB);
    mid = DiffA + DiffB;

    for (i = 0; i < 20; i++)
    {
        Step = Step / 2;

        CreateInitSeriesRef(InitPhaseIncr + Step, PhaseIncr0 - Step / PhaseDiv);
        CalcDiff(&DiffA, &DiffB);
        high = DiffA + DiffB;

        if (high < mid)
        {
            mid = high;
            InitPhaseIncr += Step;
            PhaseIncr0 -= Step / PhaseDiv;
        }
        else
        {
            CreateInitSeriesRef(InitPhaseIncr - Step, PhaseIncr0 + Step / PhaseDiv);
            CalcDiff(&DiffA, &DiffB);
            low = DiffA + DiffB;

            if (low < mid)
            {
                mid = low;
                InitPhaseIncr -= Step;
                PhaseIncr0 += Step / PhaseDiv;
            }
        }

        if (low == high)
            break;
    }

    PhaseIncrArr[0] = PhaseIncr0;
}

/*##########################################################################
#
#   Name       : TAdc::CreateSeriesRef
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::CreateSeriesRef(int p)
{
    int i;

    PhaseIncrArr[PhaseIncrCount - 1] = p;

    ::CreateFmSignal(WorkBuf, WorkSize, PowerA, InitPhaseA, InitPhaseIncr, PhaseIncrArr, PhaseIncrSamples);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chA = SampleData[i + OffsetA].chA - (short int)WorkBuf[i];

    ::CreateFmSignal(WorkBuf, WorkSize, PowerB, InitPhaseB, InitPhaseIncr, PhaseIncrArr, PhaseIncrSamples);

    for (i = 0; i < WorkSize; i++)
        WorkData[i].chB = SampleData[i + OffsetB].chB - (short int)WorkBuf[i];
}

/*##########################################################################
#
#   Name       : TFmSignal::OptimizeSeries
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::OptimizeSeries()
{
    int i;
    int Step;
    int pi = 0;
    long long DiffA, DiffB;
    long long low, mid, high;

    Step = MaxPhaseIncr;

    CreateSeriesRef(pi);
    CalcDiff(&DiffA, &DiffB);
    mid = DiffA + DiffB;

    for (i = 0; i < 20; i++)
    {
        Step = Step / 2;

        CreateSeriesRef(pi + Step);
        CalcDiff(&DiffA, &DiffB);
        high = DiffA + DiffB;

        if (high < mid)
        {
            mid = high;
            pi += Step;
        }
        else
        {
            CreateSeriesRef(pi - Step);
            CalcDiff(&DiffA, &DiffB);
            low = DiffA + DiffB;

            if (low < mid)
            {
                mid = low;
                pi -= Step;
            }
        }

        if (low == high)
            break;
    }

    PhaseIncrArr[PhaseIncrCount - 1] = pi;
}

/*##########################################################################
#
#   Name       : TFmSignal::Add
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmSignal::Add(TAdcData *Data)
{
    int i;
    int Base;

    if (SampleCount < SampleSize)
    {
        Base = SampleCount * PhaseIncrSamples;

        for (i = 0; i < PhaseIncrSamples; i++)
            SampleData[i + Base] = Data[i];

        SampleCount++;
    }

    switch (SampleCount)
    {
        case 1:
             break;

        case 2:
            PhaseIncrCount = 1;
            WorkSize = PhaseIncrSamples;

            for (i = 0; i < 4; i++)
            {
                OptimizePhaseIncr();
                OptimizeInitSeries();
            }
            break;

        default:
            PhaseIncrCount = SampleCount - 1;
            WorkSize = PhaseIncrCount * PhaseIncrSamples;
            OptimizeSeries();
            break;
    }
}
