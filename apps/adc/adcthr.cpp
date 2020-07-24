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
    MaxA = new int[FreqCount];
    MaxB = new int[FreqCount];
    Delay = new struct TDelay[FreqCount];

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

    delete Total;
    delete Count;
    delete SumA;
    delete SumB;
    delete MaxA;
    delete MaxB;
    delete Delay;
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
        MaxA[j] = 0;
        MaxB[j] = 0;

        for (k = 0; k < 360; k++)
            Delay[j].Phase[k] = 0;
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
    int PowerA;
    int PowerB;
    int Phase;
    TFreqPos fp;
    TFreqData *fd;

    RdosMoveToNewCore();

    while (FInstalled)
    {
        Signal.WaitForever();

        if (AdcData)
        {
            Clear();

            for (j = 0; j < FreqCount; j++)
            {
                fd = Freq->FreqData[j];

                if (fd->UsedSamples)
                {
                    fp.Clear(fd);
                    Total[j] += fd->Count;

                    for (k = 0; k < fd->Count; k++)
                    {
                        TAdc::CalcFreqPower(AdcData + fp.Pos, fd->UsedSamples, fd->Step , &PowerA, &PowerB, &Phase);

                        if (PowerA > MaxA[j])
                            MaxA[j] = PowerA;

                        if (PowerB > MaxB[j])
                            MaxB[j] = PowerB;

                        if (PowerA >= 2 && PowerB >= 2)
                        {
                            Count[j]++;
                            SumA[j] += PowerA;
                            SumB[j] += PowerB;
                            Delay[j].Phase[Phase]++;
                        }

                        fp.Next(fd);
                    }
                }
            }
            AdcAna->Add(this);
            Done = true;
            Adc->NotifyDone();
        }
    }
}
