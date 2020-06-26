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
# adcana.cpp
# ADC analysator class
#
########################################################################*/

#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "adcana.h"
#include "adc.h"

/*##########################################################################
#
#   Name       : TAdcAna::TAdcAna
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdcAna::TAdcAna(int c, TFreq *f)
 : FSection("Ana")
{
    FreqCount = f->FreqCount;
    Freq = f;

    Size = c;
    Pos = 0;

    Total = new int[FreqCount];
    Count = new int[FreqCount];
    SumA = new int[FreqCount];
    SumB = new int[FreqCount];
    MaxA = new int[FreqCount];
    MaxB = new int[FreqCount];
    Delay = new struct TDelay[FreqCount];

    DelayMean = new int[FreqCount];
    DelaySd = new int[FreqCount];

    Clear();
}

/*##########################################################################
#
#   Name       : TAdcAna::~TAdcAna
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdcAna::~TAdcAna()
{
    delete Total;
    delete Count;
    delete SumA;
    delete SumB;
    delete MaxA;
    delete MaxB;
    delete Delay;
    delete DelayMean;
    delete DelaySd;
}

/*##########################################################################
#
#   Name       : TAdcAna::GetPos
#
#   Purpose....: Get current position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAdcAna::GetPos()
{
    return Pos;
}

/*##########################################################################
#
#   Name       : TAdcAna::IsDone
#
#   Purpose....: Check if done
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAdcAna::IsDone()
{
    if (Pos == Size)
        return true;
    else
        return false;
}

/*##########################################################################
#
#   Name       : TAdcAna::Clear
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcAna::Clear()
{
    int i;
    int j;

    for (i = 0; i < FreqCount; i++)
    {
        Total[i] = 0;
        Count[i] = 0;
        SumA[i] = 0;
        SumB[i] = 0;
        MaxA[i] = 0;
        MaxB[i] = 0;

        for (j = 0; j < 360; j++)
            Delay[i].Phase[j] = 0;
    }
}

/*##########################################################################
#
#   Name       : TAdcAna::Add
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcAna::Add(TAdcThread *adc)
{
    int i;
    int j;
    int mean;
    int sd;

    FSection.Enter();

    for (i = 0; i < FreqCount; i++)
    {
        if (adc->MaxA[i] > MaxA[i])
            MaxA[i] = adc->MaxA[i];

        if (adc->MaxB[i] > MaxB[i])
            MaxB[i] = adc->MaxB[i];

        Total[i] += adc->Total[i];
        Count[i] += adc->Count[i];
        SumA[i] += adc->SumA[i];
        SumB[i] += adc->SumB[i];

        for (j = 0; j < 360; j++)
            Delay[i].Phase[j] += adc->Delay[i].Phase[j];
    }

    Pos++;

    if (Pos == Size)
    {
        for (i = 0; i < FreqCount; i++)
        {
            if (Count[i])
            {
                TAdc::CalcMeanSd(Delay, &mean, &sd);
                DelayMean[i] = mean;
                DelaySd[i] = sd;
            }
            else
            {
                DelayMean[i] = 0;
                DelaySd[i] = 0;
            }
        }
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TAdcAna::Print
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcAna::Print()
{
    int i;
    int mean;
    int sd;
    int vl;
    int RelA;
    int RelB;
    char fstr[40];
    char str[100];
    int count = 0;

    FSection.Enter();

    for (i = 0; i < FreqCount; i++)
    {
        if (Count[i])
            TAdc::CalcMeanSd(Delay, &mean, &sd);
        else
        {
            mean = 0;
            sd = 0;
        }

        if (SumA[i] && SumB[i])
        {
            RelA = 10 * SumA[i] / Count[i];
            RelB = 10 * SumB[i] / Count[i];
            Freq->CodeFreq(i, fstr);
            sprintf(str, "%s: %d.%01d %d.%01d (%d), %d (%d)\r\n", fstr, RelA / 10, RelA % 10, RelB / 10, RelB % 10, Count[i], mean, sd);
            RdosWriteString(str);
        }
    }

    FSection.Leave();
}
