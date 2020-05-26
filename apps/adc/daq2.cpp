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

#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "adc.h"

static int PowerCount[32][3500];
static int PowerSumA[32][3500];
static int PowerSumB[32][3500];
static int DelayCount[32][3500][360];
static int CurrBlock;
static TAdcData *CurrData;
static int FreqPos[32];

#define M_PI 3.14159265358979323846
int SCALE = 10;

/*##########################################################################
#
#   Name       : FreqThread
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void FreqThread(void *param)
{
    int *p = (int *)param;
    int pos = *p;
    int i;
    int j;
    int k;
    int PowerA;
    int PowerB;
    int Delay;
    int diff;

    for (i = 0; i < 3500; i++)
    {
        PowerCount[pos][i] = 0;
        PowerSumA[pos][i] = 0;
        PowerSumB[pos][i] = 0;

        for (j = 0; j < 360; j++)
            DelayCount[pos][i][j] = 0;
    }

    FreqPos[pos] = -1;

    for (i = 0; i < 10000; i++)
    {
        while (CurrBlock < i)
            RdosWaitMilli(25);

        for (j = 1; j < 3500; j++)
        {
            for (k = 0; k < 2; k++)
            {
                TAdc::CalcPower(CurrData + 0x2000 * (pos + k), 0x2000, j * 0x40000 / 750 / SCALE , &PowerA, &PowerB, &Delay);
                if (PowerA >= 2 && PowerB >= 2)
                {
                    PowerCount[pos][j]++;
                    PowerSumA[pos][j] += PowerA;
                    PowerSumB[pos][j] += PowerB;
                    DelayCount[pos][j][Delay]++;
                }
            }
        }
        FreqPos[pos] = i;
    }
}

/*##########################################################################
#
#   Name       : CalcMeanSdPos
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void CalcMeanSdPos(int DelayArr[360], int Start, int *Mean, double *Sd)
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

        sum += DelayArr[i] * pos;
        count += DelayArr[i];
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

        sum += DelayArr[i] * (pos - mean) * (pos - mean);
    }

    dval = (double)(sum / (long long)count);
    dval = sqrt(dval);
    *Sd = dval;
}

/*##########################################################################
#
#   Name       : CalcMeanSd
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void CalcMeanSd(int DelayArr[360], int *Mean, int *Sd)
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
        CalcMeanSdPos(DelayArr, pos, &mean, &sd);
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
#   Name       : CalcDirections
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static int CalcDirections(int DirArr[16], int WaveLen, int Mean, int Sd, int Distance)
{
    int Pos;
    int Count;
    double Dir;
    int Tol = Sd * WaveLen / 360;

    Pos = Mean * WaveLen / 360;
    while (Pos - WaveLen + Tol > -Distance)
        Pos -= WaveLen;

    Count = 0;

    while (Count < 16)
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

                    if (Count < 16)
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
#   Name       : main
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void main()
{
    int i;
    int j;
    int k;
    bool ok;
    char str[80];
    int *parm;
    int freq;
    long long val;
    int ival;
    int mean;
    int sd;
    int vl;
    int RelA;
    int RelB;
    double dval;
    static int TotalCount[3500];
    static int TotalSumA[3500];
    static int TotalSumB[3500];
    static int TotalDelayMean[3500];
    static int TotalDelaySd[3500];
    static int TotalDirCount[3500];
    static int TotalDirArr[3500][16];
    static int DelayArr[360];

    TAdc Adc(0x0, 10000);

    freq = 107;
    freq = freq * 0x40000 / 750;
    Adc.SetTrigger(freq, 14);

    if (Adc.Start())
    {
        CurrBlock = -1;

        for (i = 0; i < 32; i++)
        {
            parm = new int[1];
            *parm = i;
            sprintf(str, "Freq %d", i);
            RdosCreateThread(FreqThread, str, parm, 0x4000);
        }

        RdosWaitMilli(100);

        for (i = 0; i < 10000; i++)
        {
            CurrData = Adc.GetBlock(i);
            CurrBlock = i;
            printf("%d\r\n", i);

            for (;;)
            {
                ok = true;
                for (j = 0; j < 32 && ok; j++)
                    if (FreqPos[j] != i)
                        ok = false;

                if (ok)
                    break;
                else
                    RdosWaitMilli(25);
            }
        }

        for (i = 1; i < 3500; i++)
        {
            TotalCount[i] = 0;
            TotalSumA[i] = 0;
            TotalSumB[i] = 0;

            for (k = 0; k < 360; k++)
                DelayArr[k] = 0;

            for (j = 0; j < 32; j++)
            {
                TotalCount[i] += PowerCount[j][i];
                TotalSumA[i] += PowerSumA[j][i];
                TotalSumB[i] += PowerSumB[j][i];

                for (k = 0; k < 360; k++)
                    DelayArr[k] += DelayCount[j][i][k];
            }

            if (TotalCount[i])
            {
                CalcMeanSd(DelayArr, &mean, &sd);
                TotalDelayMean[i] = mean;
                TotalDelaySd[i] = sd;

                vl = 30 * 1000 * SCALE / i;
                TotalDirCount[i] = CalcDirections(TotalDirArr[i], vl, mean, sd, 250);
            }
            else
            {
                TotalDelayMean[i] = 0;
                TotalDelaySd[i] = 0;
            }

            if (TotalSumA[i] && TotalSumB[i])
            {
                RelA = 10 * TotalSumA[i] / TotalCount[i];
                RelB = 10 * TotalSumB[i] / TotalCount[i];
                printf("%d.%01d: %d.%01d %d.%01d (%d), %d (%d)", i / 10, i % 10, RelA / 10, RelA % 10, RelB / 10, RelB % 10, TotalCount[i], TotalDelayMean[i], TotalDelaySd[i]);

                for (j = 0; j < TotalDirCount[i]; j++)
                    printf(" %d", TotalDirArr[i][j]);

                printf("\r\n");
            }
        }
    }

    for (;;)
        RdosWaitMilli(100);
}
