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
# fmsig.h
# FM signal class
#
########################################################################*/

#ifndef _FMSIG_H
#define _FMSIG_H

#include "thread.h"
#include "sigdev.h"
#include "file.h"
#include "adcdata.h"

class TFmSignal
{
public:
    TFmSignal(double SampleFreq, double Freq, double BandWidth, int DataSize, int DataSamples);
    ~TFmSignal();

    void SetPower(int PowerA, int PowerB);
    void SetPhase(int PhaseA, int PhaseB);
    void Add(TAdcData *Data);

protected:
    int GetPhaseIncr(double Freq);

    void CalcDiff(long long *DiffA, long long *DiffB);
    void CreatePhaseRef(int PhaseA, int PhaseB);
    void OptimizePhase();
    void CreatePhaseIncrRef(int PhaseIncr);
    void OptimizePhaseIncr();
    void CreateInitSeriesRef(int PhaseIncr, int Incr0);
    void OptimizeInitSeries();
    void CreateSeriesRef(int p);
    void OptimizeSeries();

    double SampleFreq;
    double Freq;
    int PhaseIncr;
    int MaxPhaseIncr;

    TAdcData *SampleData;
    int SampleSize;
    int SampleCount;

    int PowerA;
    int PowerB;

    int OffsetA;
    int OffsetB;
    int InitPhaseA;
    int InitPhaseB;
    int InitPhaseIncr;
    int PhaseIncrCount;
    int PhaseIncrSamples;

    int WorkSize;
    int *WorkBuf;
    TAdcData *WorkData;
    int *PhaseIncrArr;
};

#endif
