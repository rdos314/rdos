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
#include "file.h"
#include "datetime.h"

static int PowerCount[32][3500];
static int PowerSumA[32][3500];
static int PowerSumB[32][3500];
static int PowerMaxA[32][3500];
static int PowerMaxB[32][3500];
static int DelayCount[32][3500][360];
static int CurrBlock;
static TAdcData *CurrData;
static int FreqPos[32];

static int TotalCount[3500][100];
static int TotalSumA[3500][100];
static int TotalSumB[3500][100];
static int TotalMaxA[3500][100];
static int TotalMaxB[3500][100];
static int TotalDelayMean[3500][100];
static int TotalDelaySd[3500][100];

static int DelayArr[360];


#define M_PI 3.14159265358979323846
int SCALE = 10;
int MAX_COUNT = 25600 * 8;

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

    RdosMoveToNewCore();

    FreqPos[pos] = -1;

    for (i = 0; i < 30000; i++)
    {
        while (CurrBlock < i)
            RdosWaitMilli(5);

        for (j = 1; j < 3000; j++)
        {
            if ((CurrBlock % 400) == 0)
            {
                PowerCount[pos][j] = 0;
                PowerSumA[pos][j] = 0;
                PowerSumB[pos][j] = 0;
                PowerMaxA[pos][j] = 0;
                PowerMaxB[pos][j] = 0;

                for (k = 0; k < 360; k++)
                    DelayCount[pos][j][k] = 0;
            }

            for (k = 0; k < 16; k++)
            {
                TAdc::CalcFreqPower(CurrData + 0x400 * (pos + k), 0x400, j * 0x40000 / 600 / SCALE , &PowerA, &PowerB, &Delay);

                if (PowerA > PowerMaxA[pos][j])
                    PowerMaxA[pos][j] = PowerA;

                if (PowerB > PowerMaxB[pos][j])
                    PowerMaxB[pos][j] = PowerB;

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
#   Name       : PrintSpot
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void PrintSpot(int index)
{
    int i;
    int j;
    int k;
    int mean;
    int sd;
    int vl;
    int RelA;
    int RelB;
    char str[100];
    static int TotalDirCount[3500];
    static int TotalDirArr[3500][16];
    int count = 0;

    for (i = 1; i < 3000; i++)
    {
        TotalCount[i][index] = 0;
        TotalSumA[i][index] = 0;
        TotalSumB[i][index] = 0;
        TotalMaxA[i][index] = 0;
        TotalMaxB[i][index] = 0;

        for (j = 0; j < 360; j++)
            DelayArr[j] = 0;

        for (j = 0; j < 32; j++)
        {
            if (PowerMaxA[j][i] > TotalMaxA[i][index])
                TotalMaxA[i][index] = PowerMaxA[j][i];

            if (PowerMaxB[j][i] > TotalMaxB[i][index])
                TotalMaxB[i][index] = PowerMaxB[j][i];

            TotalCount[i][index] += PowerCount[j][i];
            TotalSumA[i][index] += PowerSumA[j][i];
            TotalSumB[i][index] += PowerSumB[j][i];

            for (k = 0; k < 360; k++)
                DelayArr[k] += DelayCount[j][i][k];
        }

        if (TotalCount[i][index])
        {
            CalcMeanSd(DelayArr, &mean, &sd);
            TotalDelayMean[i][index] = mean;
            TotalDelaySd[i][index] = sd;
        }
        else
        {
            TotalDelayMean[i][index] = 0;
            TotalDelaySd[i][index] = 0;
        }

        if (TotalSumA[i][index] && TotalSumB[i][index])
        {
            RelA = 10 * TotalSumA[i][index] / TotalCount[i][index];
            RelB = 10 * TotalSumB[i][index] / TotalCount[i][index];
            sprintf(str, "%d.%01d: %d.%01d %d.%01d (%d), %d (%d)\r\n", i / 10, i % 10, RelA / 10, RelA % 10, RelB / 10, RelB % 10, TotalCount[i][index], TotalDelayMean[i][index], TotalDelaySd[i][index]);
            RdosWriteString(str);
        }
    }
}

/*##########################################################################
#
#   Name       : PrintCountSumary
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void PrintCountSumary(TFile &file, int CountArr[100])
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

    strcpy(str, "Count: ");
    RdosWriteString(str);
    file.Write(str, strlen(str));

    sprintf(str, "%5.1Lf (%5.1Lf) ", mean, sd);
    RdosWriteString(str);
    file.Write(str, strlen(str));
}

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
#   Name       : PrintSeriesSumary
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void PrintSeriesSumary(const char *Header, TFile &file, int SumArr[100], int CountArr[100])
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

    RdosWriteString(Header);
    file.Write(Header, strlen(Header));

    sprintf(str, "%5.1Lf (%5.1Lf) ", mean, sd);
    RdosWriteString(str);
    file.Write(str, strlen(str));
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
#   Name       : PrintMaxSumary
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void PrintMaxSumary(const char *Header, TFile &file, int MaxArr[100])
{
    int i;
    int max;
    char str[100];

    max = 0;  
    for (i = 0; i < 100; i++)
        if (MaxArr[i] > max)
            max = MaxArr[i];

    RdosWriteString(Header);
    file.Write(Header, strlen(Header));

    sprintf(str, "%d ", max);
    RdosWriteString(str);
    file.Write(str, strlen(str));
}

/*##########################################################################
#
#   Name       : PrintDelaySumary
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void PrintDelaySumary(TFile &file, int MeanArr[100], int CountArr[100])
{
    int i;
    int val;
    int mean;
    int sd;
    int count;
    char str[100];

    for (i = 0; i < 360; i++)
        DelayArr[i] = 0;

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

            DelayArr[val]++;
        }
    }

    CalcMeanSd(DelayArr, &mean, &sd);

    sprintf(str, "Phase: ");
    RdosWriteString(str);
    file.Write(str, strlen(str));

    sprintf(str, "%d (%d) ", mean, sd);
    RdosWriteString(str);
    file.Write(str, strlen(str));
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
        DelayArr[i] = 0;

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

            DelayArr[val]++;
        }
    }

    CalcMeanSd(DelayArr, &mean, &sd);

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

            PrintCountSumary(file, TotalCount[i]);
            PrintSeriesSumary("A: ", file, TotalSumA[i], TotalCount[i]);
            PrintSeriesSumary("B: ", file, TotalSumB[i], TotalCount[i]);
            PrintMaxSumary("Max A: ", file, TotalMaxA[i]);
            PrintMaxSumary("Max B: ", file, TotalMaxB[i]);
            PrintDelaySumary(file, TotalDelayMean[i], TotalCount[i]);

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
    int i;
    int j;
    bool ok;
    char str[80];
    int *parm;
    int freq;
    int hour;
    TDateTime curr;

    TAdc Adc(0x0, 30000);

    if (argc == 2)
    {
        hour = atoi(argv[1]);
        sprintf(str, "Wait unti %d:00", hour);
        RdosWriteString(str);

        TDateTime starttime(curr.GetYear(), curr.GetMonth(), curr.GetDay(), hour, 0, 0);

        while (!starttime.HasExpired())
            RdosWaitMilli(1000);
    }

    freq = 107;
    freq = freq * 0x40000 / 600;
    Adc.SetTrigger(freq, 14);

    if (Adc.Start())
    {
        RdosWriteString("ADC started\r\n");

        CurrBlock = -1;

        for (i = 0; i < 32; i++)
        {
            parm = new int[1];
            *parm = i;
            sprintf(str, "Freq %d", i);
            RdosCreateThread(FreqThread, str, parm, 0x4000);
        }

        RdosWaitMilli(100);

        for (i = 0; i < 30000; i++)
        {
            CurrData = Adc.GetBlock(i);
            CurrBlock = i;

            for (;;)
            {
                ok = true;
                for (j = 0; j < 32 && ok; j++)
                    if (FreqPos[j] != i)
                        ok = false;

                if (ok)
                    break;
                else
                    RdosWaitMilli(5);
            }

            if ((i % 50) == 49)
            {
                RdosWriteString("\r\n");
                PrintSpot(i / 400);
                sprintf(str, "%d", i);
                RdosWriteString(str);
            }
            else
                RdosWriteChar('.');
        }

        PrintFinal();

    }

    for (;;)
        RdosWaitMilli(100);
}
