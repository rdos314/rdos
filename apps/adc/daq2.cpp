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
#include "adc.h"

static int PowerCount[16][101];
static int PowerSumA[16][101];
static int PowerSumB[16][101];
static int CurrBlock;
static TAdcData *CurrData;
static int FreqPos[16];

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

    for (i = 0; i < 101; i++)
    {
        PowerCount[pos][i] = 0;
        PowerSumA[pos][i] = 0;
        PowerSumB[pos][i] = 0;
    }

    FreqPos[pos] = -1;

    for (i = 0; i < 10000; i++)
    {
        while (CurrBlock < i)
            RdosWaitMilli(25);

        for (j = 0; j < 101; j++)
        {
            TAdc::CalcPower(CurrData + 0x8000 * pos, 0x8000, (j + 45000) * 0x40000 / 750000 , &PowerA, &PowerB);
            if (PowerA >= 2 && PowerB >= 2)
            {
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
    int freq;
    bool ok;
    char str[80];
    int *parm;
    static int TotalCount[101];
    static int TotalSumA[101];
    static int TotalSumB[101];

    TAdc Adc(0x0, 10000);

    freq = 45;
    freq = freq * 0x40000 / 750;
    Adc.SetTrigger(freq, 5000);

    if (Adc.Start())
    {
        CurrBlock = -1;

        for (i = 0; i < 16; i++)
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
                for (j = 0; j < 16 && ok; j++)
                    if (FreqPos[j] != i)
                        ok = false;

                if (ok)
                    break;
                else
                    RdosWaitMilli(25);
            }
        }

        for (i = 0; i < 101; i++)
        {
            freq = 45000 + i;
            TotalCount[i] = 0;
            TotalSumA[i] = 0;
            TotalSumB[i] = 0;

            for (j = 0; j < 16; j++)
            {
                TotalCount[i] += PowerCount[j][i];
                TotalSumA[i] += PowerSumA[j][i];
                TotalSumB[i] += PowerSumB[j][i];
            }

            if (TotalSumA[i] && TotalSumB[i])
                printf("%d.%03d: %d %d (%d)\r\n", freq / 1000, freq % 1000, TotalSumA[i], TotalSumB[i], TotalCount[i]);
        }
    }

    for (;;)
        RdosWaitMilli(100);
}
