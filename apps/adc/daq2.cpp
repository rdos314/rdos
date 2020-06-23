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
#include "thread.h"
#include "sigdev.h"

class TFreqData
{
friend class TFreqPos;
public:
    TFreqData(double Freq, double SampleFreq, int Periods);
    ~TFreqData();

    int UsedSamples;
    int Count;
    int Step;

protected:
    int Overlap;
    int Remain;
};

class TFreqPos
{
public:
    TFreqPos();
    ~TFreqPos();

    void Clear(TFreqData *fd);
    void Next(TFreqData *fd);

    int Pos;

protected:
    int Sum;
};

class TAdcAna;

class TAdcThread : TThread
{
public:
    TAdcThread(int Id);
    ~TAdcThread();

    void Clear();
    void Run(TAdcData *Data, TAdcAna *Ana);

    bool Done;
 
    int Total[3500];
    int Count[3500];
    int SumA[3500];
    int SumB[3500];
    int MaxA[3500];
    int MaxB[3500];
    int Delay[3500][360];

protected:
    virtual void Execute();

    TAdcData *AdcData;
    TAdcAna *AdcAna;
    TSignalDevice Signal;
};

class TAdcAna : TThread
{
public:
    TAdcAna();
    ~TAdcAna();

    void Add(TAdcThread *Adc);

    int Total[3500];
    int Count[3500];
    int SumA[3500];
    int SumB[3500];
    int MaxA[3500];
    int MaxB[3500];
    int DelayMean[3500];
    int DelaySd[3500];

protected:
    void Clear();
    virtual void Execute();
};


static TFreqData *FreqData[3500];
static TAdcThread *AdcThread[23];
static TAdcAna *AdcAna[100];

static int TotalCount[3500][100];
static int TotalSumA[3500][100];
static int TotalSumB[3500][100];
static int TotalMaxA[3500][100];
static int TotalMaxB[3500][100];
static int TotalDelayMean[3500][100];
static int TotalDelaySd[3500][100];

static int DelayArr[360];


#define M_PI 3.14159265358979323846
int MAX_COUNT = 25600 * 8;

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
#   Name       : TFreqData::TFreqData
#
#   Purpose....: Determine samples & interval
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFreqData::TFreqData(double Freq, double SampleFreq, int Periods)
{
    int diff;
    double dval;

    if (Freq)
    {
        dval = SampleFreq * (double)Periods / Freq;
        UsedSamples = (int)(dval + 0.5);
        if (UsedSamples > 0x80000)
            UsedSamples = 0;
    }
    else
        UsedSamples = 0;

    if (UsedSamples)
    {
        dval = Freq / SampleFreq * 0x40000;
        Step = (int)(dval + 0.5);

        Count = 0x80000 / UsedSamples;
        diff = 0x80000 - UsedSamples * Count;

        if (diff)
        {
            Count++;
            diff = UsedSamples * Count - 0x80000;
            Overlap = diff / (Count - 1);
            Remain = diff - Overlap * (Count - 1);
        }
        else
        {
            Overlap = 0;
            Remain = 0;
        }
    }
    else
        Step = 0;
}


/*##########################################################################
#
#   Name       : TFreqData::~TFreqData
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFreqData::~TFreqData()
{
}

/*##########################################################################
#
#   Name       : TFreqPos::TFreqPos
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFreqPos::TFreqPos()
{
    Pos = 0;
    Sum = 0;
}

/*##########################################################################
#
#   Name       : TFreqPos::~TFreqPos
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFreqPos::~TFreqPos()
{
}

/*##########################################################################
#
#   Name       : TFreqPos::Clear
#
#   Purpose....: Clear pos
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFreqPos::Clear(TFreqData *fd)
{
    Sum = fd->Remain;
    Pos = 0;
}

/*##########################################################################
#
#   Name       : TFreqPos::Next
#
#   Purpose....: Next pos
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFreqPos::Next(TFreqData *fd)
{
    Pos += fd->UsedSamples - fd->Overlap;

    Sum += fd->Remain;
    if (Sum >= fd->Count)
    {
        Pos--;
        Sum -= fd->Count;
    }
}

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
TAdcThread::TAdcThread(int Id)
{
    char str[40];

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

    for (j = 1; j < 3500; j++)
    {
        Total[j] = 0;
        Count[j] = 0;
        SumA[j] = 0;
        SumB[j] = 0;
        MaxA[j] = 0;
        MaxB[j] = 0;

        for (k = 0; k < 360; k++)
            Delay[j][k] = 0;
    }
}

/*##########################################################################
#
#   Name       : TAdcThread::Run
#
#   Purpose....: Start
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcThread::Run(TAdcData *Data, TAdcAna *Ana)
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

    for (;;)
    {
        Signal.WaitForever();

        if (AdcData)
        {
            Clear();

            for (j = 1; j < 3500; j++)
            {
                fd = FreqData[j];
                if (fd && fd->UsedSamples)
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
                            Delay[j][Phase]++;
                        }

                        fp.Next(fd);
                    }
                }
            }
            AdcAna->Add(this);
            Done = true;
        }
    }
}

/*##########################################################################
#
#   Name       : ClearTotal
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void ClearTotal(int index)
{
    int i;
    int j;

    for (i = 1; i < 3500; i++)
    {
        TotalCount[i][index] = 0;
        TotalSumA[i][index] = 0;
        TotalSumB[i][index] = 0;
        TotalMaxA[i][index] = 0;
        TotalMaxB[i][index] = 0;

        for (j = 0; j < 360; j++)
            DelayArr[j] = 0;
    }
}

/*##########################################################################
#
#   Name       : AddTotal
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void AddTotal(int index, TAdcThread *adc)
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
        if (adc->MaxA[i] > TotalMaxA[i][index])
            TotalMaxA[i][index] = adc->MaxA[i];

        if (adc->MaxB[i] > TotalMaxB[i][index])
            TotalMaxB[i][index] = adc->MaxB[i];

        TotalCount[i][index] += adc->Count[i];
        TotalSumA[i][index] += adc->SumA[i];
        TotalSumB[i][index] += adc->SumB[i];

        for (k = 0; k < 360; k++)
            DelayArr[k] += adc->Delay[i][k];

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
    TFreqData *fd;
    TAdcData *data;
    int tindex;
    TAdcThread *tf;
    TAdcAna *tf;
    int last;

    for (i = 0; i < 3500; i++)
        FreqData[i] = 0;

    for (i = 1; i < 3000; i++)
        FreqData[i] = new TFreqData((double)i / 10.0, 600.0, 100);

    for (i = 0; i < 100; i++)
        AdcAna[i] = new TAdcAna();

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

        for (i = 0; i < 23; i++)
            AdcThread[i] = new TAdcThread(i);

        for (i = 0; i < 30000; i++)
        {
            data = Adc.GetBlock(i);

            tindex = i % 23;
            tf = AdcThread[tindex];

            tindex = i / 300;
            ta = AdcAna[tindex];
            
            while (!tf->Done)
                RdosWaitMilli(5);

            tf->Run(data, ta);
        }

        PrintFinal();

    }

    for (;;)
        RdosWaitMilli(100);
}
