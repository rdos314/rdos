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

    PhasePerSample = GetPhasePerSample(Freq);
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
#   Name       : TFmSignal::GetPhasePerSample
#
#   Purpose....: Get phase per sample
#
#   In params..: Freq, SampleFreq
#   Out params.: *
#   Returns....: Phase incr
#
##########################################################################*/
int TFmSignal::GetPhasePerSample(double Freq)
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
    TAdcFreqChanPower resA;
    TAdcFreqChanPower resB;
    TAdcFreqPower res;

    ::CalcFreqPower(Data, 16, 0, PhasePerSample, &res);
    ::CalcFreqPowerA(Data, 16, 0, PhasePerSample, &resA);
    ::CalcFreqPowerB(Data, 16, 0, PhasePerSample, &resB);
}
