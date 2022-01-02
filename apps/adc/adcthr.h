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
# adcthr.h
# ADC thread class
#
########################################################################*/

#ifndef _ADCTHR_H
#define _ADCTHR_H

#include "thread.h"
#include "sigdev.h"
#include "freq.h"

class TAdc;
class TAdcAna;
class TAdcData;

class TAdcThread : public TThread
{
public:
    TAdcThread(int Id, TAdc *Adc);
    ~TAdcThread();

    void Clear();
    void Process(TAdcData *Data, TAdcAna *Ana);

    bool Done;
    int FreqCount;

    int *Total;
    int *Count;
    int *SumA;
    int *SumB;
    int *MinA;
    int *MinB;
    int *MaxA;
    int *MaxB;
    struct TDelay *Delay;

    double *OptFreqVal;
    int *OptFreqMax;
    int *OptFreqPos;
    int OptFreqCount;
    int OptFreqStep;

protected:
    virtual void Execute();

    int GetPhaseA(TFreqData *fd, int Pos, int *Power);
    int GetPhaseB(TFreqData *fd, int Pos, int *Power);
    int UpdatePhaseA(TFreqData *fd, int Pos, int Phase, int *Power);
    int UpdatePhaseB(TFreqData *fd, int Pos, int Phase, int *Power);
    double OptFreq(TFreqData *fd, double StartFreq, double StopFreq, int Pos);
    void AnaFreq(TFreqData *fd, int *Max, int *Pos);

    TAdc *Adc;
    TFreq *Freq;
    TAdcData *AdcData;
    TAdcAna *AdcAna;
    TSignalDevice Signal;
};

#endif
