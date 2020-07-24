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
#include "file.h"
#include "datetime.h"
#include "freq.h"
#include "adcthr.h"
#include "adcana.h"
#include "adc.h"

static int TotalCount[3500][100];
static int TotalSumA[3500][100];
static int TotalSumB[3500][100];
static int TotalMaxA[3500][100];
static int TotalMaxB[3500][100];
static int TotalDelayMean[3500][100];
static int TotalDelaySd[3500][100];

static struct TDelay DelayArr;


#define M_PI 3.14159265358979323846
int MAX_COUNT = 25600 * 8;



/*##########################################################################
#
#   Name       : PrintCountDetail
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static bool PrintCountDetail(TFile &file, int CountArr[100])
{
    int i;
    double sum;
    double mean;
    double sd;
    double val;
    int Rel;
    char str[100];

    sum = 0;
    for (i = 0; i < 100; i++)
        sum += CountArr[i];

    mean = sum / 100.0;

    sum = 0;
    for (i = 0; i < 100; i++)
    {
        val = mean - (double)CountArr[i];
        sum += val * val;
    }

    val = sum / 99.0;
    sd = sqrt(val);

    mean = mean * 100.0 / (double)MAX_COUNT;
    sd = sd * 100.0 / (double)MAX_COUNT;

    if (sd > 5.0)
    {
        strcpy(str, "Count: ");
        RdosWriteString(str);
        file.Write(str, strlen(str));

        for (i = 0; i < 100; i++)
        {
            val = (double)CountArr[i] * 100.0 / (double)MAX_COUNT;
            sprintf(str, "%5.1Lf ", val);
            RdosWriteString(str);
            file.Write(str, strlen(str));
        }

        sprintf(str, "\r\n");
        RdosWriteString(str);
        file.Write(str, strlen(str));
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : PrintSeriesDetail
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static bool PrintSeriesDetail(const char *Header, TFile &file, int SumArr[100], int CountArr[100])
{
    int i;
    int count;
    double sum;
    double mean;
    double sd;
    double val;
    int Rel;
    char str[100];

    sum = 0;
    count = 0;
    for (i = 0; i < 100; i++)
    {
        if (CountArr[i])
        {
            sum += (double)SumArr[i] / (double)CountArr[i];
            count++;
        }
    }

    mean = sum / (double)count;

    if (count >= 10)
    {
        sum = 0;
        count = 0;
        for (i = 0; i < 100; i++)
        {
            if (CountArr[i])
            {
                val = (double)SumArr[i] / (double)CountArr[i];
                val = val - mean;
                sum += val * val;
                count++;
            }
        }

        val = sum / (double)(count - 1);
        sd = sqrt(val);
    }
    else
        sd = 0.0;

    if (sd > 2.0)
    {
        RdosWriteString(Header);
        file.Write(Header, strlen(Header));

        if (count > 10)
        {
            for (i = 0; i < 100; i++)
            {
                if (CountArr[i])
                {
                    Rel = 10 * SumArr[i] / CountArr[i];
                    sprintf(str, "%d.%01d ", Rel / 10, Rel % 10);
                }
                else
                    strcpy(str, "* ");

                RdosWriteString(str);
                file.Write(str, strlen(str));
            }

            sprintf(str, "\r\n");
            RdosWriteString(str);
            file.Write(str, strlen(str));
        }
        else
        {
            for (i = 0; i < 100; i++)
            {
                if (CountArr[i])
                {
                    Rel = 10 * SumArr[i] / CountArr[i];
                    sprintf(str, "%d:%d.%01d ", i, Rel / 10, Rel % 10);
                    RdosWriteString(str);
                    file.Write(str, strlen(str));
                }
            }

            sprintf(str, "\r\n");
            RdosWriteString(str);
            file.Write(str, strlen(str));
        }
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : PrintDelayDetail
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static bool PrintDelayDetail(TFile &file, int MeanArr[100], int CountArr[100])
{
    int i;
    int val;
    int mean;
    int sd;
    int count;
    char str[100];

    for (i = 0; i < 360; i++)
        DelayArr.Phase[i] = 0;

    count = 0;
    for (i = 0; i < 100; i++)
    {
        if (CountArr[i])
        {
            count++;
            val = MeanArr[i];

            while (val < 0)
                val += 360;

            while (val >= 360)
                val -= 360;

            DelayArr.Phase[val]++;
        }
    }

    TAdc::CalcMeanSd(&DelayArr, &mean, &sd);

    if (sd > 5)
    {
        sprintf(str, "Phase: ");
        RdosWriteString(str);
        file.Write(str, strlen(str));

        if (count > 10)
        {
            for (i = 0; i < 100; i++)
            {
                if (CountArr[i])
                    sprintf(str, "%d ", MeanArr[i]);
                else
                    strcpy(str, "* ");

                RdosWriteString(str);
                file.Write(str, strlen(str));
            }

            sprintf(str, "\r\n");
            RdosWriteString(str);
            file.Write(str, strlen(str));
        }
        else
        {
            for (i = 0; i < 100; i++)
            {
                if (CountArr[i])
                {
                    sprintf(str, "%d:%d ", i, MeanArr[i]);
                    RdosWriteString(str);
                    file.Write(str, strlen(str));
                }
            }

            sprintf(str, "\r\n");
            RdosWriteString(str);
            file.Write(str, strlen(str));
        }
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : PrintFinal
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void PrintFinal()
{
    int i;
    int j;
    bool ok;
    int count;
    char str[100];
    TFile file("res.txt", 0);

    for (i = 1; i < 3000; i++)
    {
        count = 0;
        for (j = 0; j < 100; j++)
            if (TotalCount[i][j])
                count++;

        if (count)
        {
            sprintf(str, "%d.%01d: %d ",  i / 10, i % 10, count);
            RdosWriteString(str);
            file.Write(str, strlen(str));

            sprintf(str, "\r\n");
            RdosWriteString(str);
            file.Write(str, strlen(str));

            ok = PrintCountDetail(file, TotalCount[i]);
            ok |= PrintSeriesDetail("A: ", file, TotalSumA[i], TotalCount[i]);
            ok |= PrintSeriesDetail("B: ", file, TotalSumB[i], TotalCount[i]);
            ok |= PrintDelayDetail(file, TotalDelayMean[i], TotalCount[i]);

            if (ok)
            {
                sprintf(str, "\r\n");
                RdosWriteString(str);
                file.Write(str, strlen(str));
            }
        }
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
int main(int argc, char **argv)
{
    int CurrInt;
    int Pos;
    int CurrPos;
    TAdcAna *CurrAna;
    int CurrIndex;
    char str[80];
    int *parm;
    int hour;
    TDateTime curr;

    double SampleFreq = 600.0;
    TFreq Freq(0.1, SampleFreq / 2.0, 1, SampleFreq, 100);

    TAdc Adc(0x0, 30000, &Freq);

    if (argc == 2)
    {
        hour = atoi(argv[1]);
        sprintf(str, "Wait until %d:00", hour);
        RdosWriteString(str);

        TDateTime starttime(curr.GetYear(), curr.GetMonth(), curr.GetDay(), hour, 0, 0);

        while (!starttime.HasExpired())
            RdosWaitMilli(1000);
    }

    if (Adc.StartAdc(100, 22))
    {
        RdosWriteString("ADC started\r\n");

        CurrInt = 0;
        Pos = 0;

        for (CurrInt = 0; CurrInt < Adc.Intervals; CurrInt++)
        {
            CurrAna = Adc.AdcAna[CurrInt];

            while (!CurrAna->IsDone())
            {
                CurrPos = CurrInt * Adc.AnaSize + CurrAna->GetPos();
                if (Pos == CurrPos)
                    RdosWaitMilli(250);
                else
                {
                    while (Pos != CurrPos)
                    {
                        if ((Pos % Adc.AnaSize) != 0 && (Pos % 50) == 0)
                        {
                            RdosWriteString("\r\n");
                            CurrAna->PrintSnap();
                            sprintf(str, "%d", Pos);
                            RdosWriteString(str);
                        }
                        else
                            RdosWriteChar('.');

                        Pos++;
                    }
                }
            }
            RdosWriteString("\r\n");
            CurrAna->PrintSnap();
            sprintf(str, "%d", Pos);
            RdosWriteString(str);
        }

        Adc.PrintFinal();
    }

    for (;;)
        RdosWaitMilli(100);
}
