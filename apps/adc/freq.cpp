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
# freq.cpp
# ADC freq class
#
########################################################################*/

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <rdos.h>
#include "freq.h"

/*##########################################################################
#
#   Name       : TFreqData::TFreqData
#
#   Purpose....: Determine samples & interval
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFreqData::TFreqData(double Freq, double sf, int periods)
{
    SampleFreq = sf;
    Periods = periods;
    Update(Freq);
}

/*##########################################################################
#
#   Name       : TFreqData::TFreqData
#
#   Purpose....: Copy constructor for freq data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFreqData::TFreqData(const TFreqData &src)
{
    UsedSamples = src.UsedSamples;
    Count = src.Count;
    PhasePerSample = src.PhasePerSample;
    SampleFreq = src.SampleFreq;
    Periods = src.Periods;
    Overlap = src.Overlap;
    Remain = src.Remain;
}

/*##########################################################################
#
#   Name       : TFreqData::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TFreqData &TFreqData::operator=(const TFreqData &src)
{
    UsedSamples = src.UsedSamples;
    Count = src.Count;
    PhasePerSample = src.PhasePerSample;
    SampleFreq = src.SampleFreq;
    Periods = src.Periods;
    Overlap = src.Overlap;
    Remain = src.Remain;

    return *this;
}

/*##########################################################################
#
#   Name       : TFreqData::~TFreqData
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFreqData::~TFreqData()
{
}

/*##########################################################################
#
#   Name       : TFreqData::Update
#
#   Purpose....: Update frequency
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFreqData::Update(double Freq)
{
    int diff;
    long long lval;
    double freq;
    double dval;

    if (Freq)
    {
        dval = SampleFreq * (double)Periods / Freq;
        UsedSamples = (int)(dval + 0.5);
        if (UsedSamples > 0x80000)
            UsedSamples = 0;
    }
    else
        UsedSamples = 0;

    if (UsedSamples)
    {
        freq = 1000000.0 * Freq;
        lval = (long long)freq;
        lval = lval * (long long)0x10000;
        lval = lval * (long long)0x10000;

        freq = 1000000.0 * SampleFreq;
        lval = lval / (long long)freq;

        PhasePerSample = (int)lval;

        Count = 0x80000 / UsedSamples;
        diff = 0x80000 - UsedSamples * Count;

        if (diff)
        {
            Count++;
            diff = UsedSamples * Count - 0x80000;
            Overlap = diff / (Count - 1);
            Remain = diff - Overlap * (Count - 1);
        }
        else
        {
            Overlap = 0;
            Remain = 0;
        }
    }
    else
        PhasePerSample = 0;
}

/*##########################################################################
#
#   Name       : TFreqPos::TFreqPos
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFreqPos::TFreqPos()
{
    Pos = 0;
    Sum = 0;
}

/*##########################################################################
#
#   Name       : TFreqPos::~TFreqPos
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFreqPos::~TFreqPos()
{
}

/*##########################################################################
#
#   Name       : TFreqPos::Clear
#
#   Purpose....: Clear pos
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFreqPos::Clear(TFreqData *fd)
{
    Sum = fd->Remain;
    Pos = 0;
}

/*##########################################################################
#
#   Name       : TFreqPos::Next
#
#   Purpose....: Next pos
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFreqPos::Next(TFreqData *fd)
{
    Pos += fd->UsedSamples - fd->Overlap;

    Sum += fd->Remain;
    if (Sum >= fd->Count)
    {
        Pos--;
        Sum -= fd->Count;
    }
}

/*##########################################################################
#
#   Name       : TFreq::TFreq
#
#   Purpose....: Create frequencies
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFreq::TFreq(double start, double stop, int decimals, double sf, int Periods)
{
    double temp;
    int i;

    SampleFreq = sf;
    Start = start;
    Stop = stop;
    Decimals = decimals;

    Step = 1.0;
    while (decimals > 0)
    {
        Step = Step / 10.0;
        decimals--;
    }

    while (decimals < 0)
    {
        Step = Step * 10.0;
        decimals++;
    }

    if (Decimals > 0)
        sprintf(CodeStr, "%%%d.%dLf", 2 + Decimals, Decimals);
    else
        strcpy(CodeStr, "%2Lf");

    temp = (Stop - Start) / Step;
    FreqCount = (int)temp + 1;
    FreqData = new TFreqData*[FreqCount];

    for (i = 0; i < FreqCount; i++)
    {
        temp = Start + i * Step;
        FreqData[i] = new TFreqData(temp, SampleFreq, Periods);
    }
}

/*##########################################################################
#
#   Name       : TFreq::~TFreq
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFreq::~TFreq()
{
    int i;

    for (i = 0; i < FreqCount; i++)
        delete FreqData[i];

    delete FreqData;
}

/*##########################################################################
#
#   Name       : TFreq::GetFreq
#
#   Purpose....: Get frequency
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TFreq::GetFreq(int index)
{
    if (index >= 0 && index < FreqCount)
        return Start + index * Step;
    else
        return 0.0;
}

/*##########################################################################
#
#   Name       : TFreq::CodeFreq
#
#   Purpose....: Code frequency
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFreq::CodeFreq(int index, char *str)
{
    double val;

    if (index >= 0 && index < FreqCount)
    {
        val = Start + index * Step;
        sprintf(str, CodeStr, val);
    }
    else
        strcpy(str, "!");
}
