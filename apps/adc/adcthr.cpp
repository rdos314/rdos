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
# adcthr.cpp
# ADC thread class
#
########################################################################*/

#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "adcthr.h"
#include "adcana.h"
#include "adc.h"

/*##########################################################################
#
#   Name       : TAdcThread::TAdcThread
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdcThread::TAdcThread(int Id, TAdc *adc)
{
    char str[40];

    Adc = adc;
    Freq = Adc->Freq;
    FreqCount = Freq->FreqCount;

    Total = new int[FreqCount];
    Count = new int[FreqCount];
    SumA = new int[FreqCount];
    SumB = new int[FreqCount];
    MinA = new int[FreqCount];
    MinB = new int[FreqCount];
    MaxA = new int[FreqCount];
    MaxB = new int[FreqCount];
    Delay = new struct TDelay[FreqCount];

    OptFreqStep = Adc->OptStep;
    OptFreqCount = FreqCount / OptFreqStep;
    OptFreqIndex = new int[OptFreqCount];
    OptFreqMax = new int[OptFreqCount];
    OptFreqPos = new int[OptFreqCount];

    AdcData = 0;
    AdcAna = 0;
    Clear();
    Done = true;

    sprintf(str, "Freq %d", Id);
    Start(str, 0x4000);
}

/*##########################################################################
#
#   Name       : TAdcThread::~TAdcThread
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdcThread::~TAdcThread()
{
    AdcData = 0;
    AdcAna = 0;
    FInstalled = false;
    Signal.Signal();

    while (IsRunning())
        RdosWaitMilli(25);

    delete Total;
    delete Count;
    delete SumA;
    delete SumB;
    delete MinA;
    delete MinB;
    delete MaxA;
    delete MaxB;
    delete Delay;

    delete OptFreqIndex;
    delete OptFreqMax;
    delete OptFreqPos;
}

/*##########################################################################
#
#   Name       : TAdcThread::Clear
#
#   Purpose....: Clear accs
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcThread::Clear()
{
    int j;
    int k;

    for (j = 0; j < FreqCount; j++)
    {
        Total[j] = 0;
        Count[j] = 0;
        SumA[j] = 0;
        SumB[j] = 0;
        MinA[j] = 30000;
        MinB[j] = 30000;
        MaxA[j] = 0;
        MaxB[j] = 0;

        for (k = 0; k < 360; k++)
            Delay[j].Phase[k] = 0;
    }

    for (j = 0; j < OptFreqCount; j++)
    {
        OptFreqIndex[j] = 0;
        OptFreqMax[j] = 0;
        OptFreqPos[j] = 0;
    }
}

/*##########################################################################
#
#   Name       : TAdcThread::Process
#
#   Purpose....: Start
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcThread::Process(TAdcData *Data, TAdcAna *Ana)
{
    Done = false;
    AdcData = Data;
    AdcAna = Ana;
    Signal.Signal();
}

/*##########################################################################
#
#   Name       : TAdcThread::AnaFreq
#
#   Purpose....: Analyze frequency
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcThread::AnaFreq( int Index, int Max, int Pos)
{
    TFreqData *fd = Freq->FreqData[Index];
    int PowerA;
    int PowerB;
    int Power;
    int Phase;
    int i;

    TAdc::CalcFreqPower(AdcData + Pos, fd->UsedSamples, 0, fd->PhasePerSample , &PowerA, &PowerB, &Phase);

    for (i = 0; i < 16; i++)
    {
        TAdc::CalcPowerA(AdcData + Pos, fd->UsedSamples, i * 0x1000, fd->PhasePerSample , &Power);
        TAdc::CalcPowerB(AdcData + Pos, fd->UsedSamples, i * 0x1000, fd->PhasePerSample , &Power);
    }
}

/*##########################################################################
#
#   Name       : TAdcThread::Execute
#
#   Purpose....: Execute
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcThread::Execute()
{
    int j;
    int k;
    int count;
    int start;
    int stop;
    int PowerA;
    int PowerB;
    int Phase;
    int Power;
    TFreqPos fp;
    TFreqData *fd;
    int *OptIndex;
    int *OptMax;
    int *OptPos;
    int OptCount;

    RdosMoveToNewCore();

    while (FInstalled)
    {
        Signal.WaitForever();

        if (AdcData)
        {
            Clear();

            OptCount = 0;
            OptIndex = OptFreqIndex;
            OptMax = OptFreqMax;
            OptPos = OptFreqPos;

            for (j = 0; j < FreqCount; j++)
            {
                fd = Freq->FreqData[j];

                if (fd->UsedSamples)
                {
                    fp.Clear(fd);
                    Total[j] += fd->Count;

                    count = fd->Count;
                    start = count / 4;
                    stop = count - start;

                    for (k = 0; k < count; k++)
                    {
                        TAdc::CalcFreqPower(AdcData + fp.Pos, fd->UsedSamples, 0, fd->PhasePerSample , &PowerA, &PowerB, &Phase);

                        if (PowerA >= Adc->Min && PowerB >= Adc->Min)
                        {
                            if (PowerA > MaxA[j])
                                MaxA[j] = PowerA;

                            if (PowerB > MaxB[j])
                                MaxB[j] = PowerB;

                            if (PowerA < MinA[j])
                                MinA[j] = PowerA;

                            if (PowerB < MinB[j])
                                MinB[j] = PowerB;

                            Count[j]++;
                            SumA[j] += PowerA;
                            SumB[j] += PowerB;
                            Delay[j].Phase[Phase]++;

                            if (k >= start && k <= stop)
                            {
                                Power = PowerA * PowerA + PowerB * PowerB;
                                if (*OptMax < Power)
                                {
                                    *OptMax = Power;
                                    *OptIndex = j;
                                    *OptPos = k;
                                }
                            }
                        }

                        fp.Next(fd);
                    }
                }

                OptCount++;

                if (OptCount == OptFreqStep)
                {
                    AnaFreq(*OptIndex, *OptMax, *OptPos);

                    OptCount = 0;
                    OptIndex++;
                    OptMax++;
                    OptPos++;
                }
            }
            AdcAna->Add(this);
            Done = true;
            Adc->NotifyDone();
        }
    }
}
