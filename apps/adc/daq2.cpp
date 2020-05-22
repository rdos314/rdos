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
static long long DelaySum[32][3500];
static long long DelayMin[32][3500];
static long long DelayMax[32][3500];
static int CurrBlock;
static TAdcData *CurrData;
static int FreqPos[32];

#define M_PI 3.14159265358979323846

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
    int PowerA;
    int PowerB;
    double Delay;
    int diff;
    int SCALE = 10;

    for (i = 0; i < 3500; i++)
    {
        PowerCount[pos][i] = 0;
        PowerSumA[pos][i] = 0;
        PowerSumB[pos][i] = 0;
        DelaySum[pos][i] = 0;
        DelayMin[pos][i] = 0;
        DelayMax[pos][i] = 0;
    }

    FreqPos[pos] = -1;

    for (i = 0; i < 10000; i++)
    {
        while (CurrBlock < i)
            RdosWaitMilli(25);

        for (j = 1; j < 3500; j++)
        {
            TAdc::CalcPower(CurrData + 0x4000 * pos, 0x4000, j * 0x40000 / 750 / SCALE , &PowerA, &PowerB, &Delay);
            if (PowerA >= 2 && PowerB >= 2)
            {
                diff = (int)(Delay * 30 * 1000 * SCALE / j);
                DelaySum[pos][j] += diff;
                if (PowerCount[pos][j])
                {
                    if (diff > DelayMax[pos][j])
                        DelayMax[pos][j] = diff;

                    if (diff < DelayMin[pos][j])
                        DelayMin[pos][j] = diff;
                }
                else
                {
                    DelayMin[pos][j] = diff;
                    DelayMax[pos][j] = diff;
                }

                PowerCount[pos][j]++;
                PowerSumA[pos][j] += PowerA;
                PowerSumB[pos][j] += PowerB;
            }
        }
        FreqPos[pos] = i;
    }
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
    double dval;
    static int TotalCount[3500];
    static int TotalSumA[3500];
    static int TotalSumB[3500];
    static long long TotalDelay[3500];
    static long long TotalDelaySq[3500];

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

            for (j = 0; j < 32; j++)
            {
                TotalCount[i] += PowerCount[j][i];
                TotalSumA[i] += PowerSumA[j][i];
                TotalSumB[i] += PowerSumB[j][i];
                TotalDelay[i] += DelaySum[j][i];
            }

            if (TotalSumA[i] && TotalSumB[i])
                printf("%d.%01d: %d %d (%d), %d\r\n", i / 10, i % 10, TotalSumA[i], TotalSumB[i], TotalCount[i], TotalDelay[i] / TotalCount[i]);
        }
    }

    for (;;)
        RdosWaitMilli(100);
}
