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
# adc.h
# ADC class
#
########################################################################*/

#ifndef _ADC_H
#define _ADC_H

#include "thread.h"
#include "sigdev.h"
#include "freq.h"
#include "file.h"

#define MAX_DIR 16

class TAdcData
{
public:
    short int chA;
    short int chB;
};

struct TDelay
{
    int Phase[360];
};

class TAdaAna;

class TAdc : public TThread
{
public:
    TAdc(char TestMode, int Blocks, TFreq *Freq);
    ~TAdc();

    bool RunAdc();
    bool LoadTestData(const char *FileName);
    void RunAna(int Intervals, int Threads, int Min, const char *ResultName);
    void CleanupAna();

    void RemoveFreq(double Freq);

    void NotifyDone();

    void SetTrigger(int PhaseIncr, int Window);
    void Check();

    int GetMaxPeriodic();

    static int GetSin(int Phase);
    static void CalcPower(TAdcData *Data, int Size, int *PowerA, int *PowerB);
    static int CalcFreqPower(TAdcData *Data, int Size, int InitPhase, int PhaseIncr, int *PowerA, int *PowerB, int *Delay);
    static int CreateSignal(int *Buf, int Size, int InitPhase, int PhaseIncr, int Amp);

    static void CalcMeanSd(struct TDelay *Delay, int *Mean, int *Sd);
    static int CalcDirections(int DirArr[MAX_DIR], int WaveLen, int Mean, int Sd, int Distance);

    double SampleFreq;
    TFreq *Freq;
    int Min;

protected:
    static void CalcMeanSdPos(struct TDelay *Delay, int Start, int *Mean, double *Sd);

    void Write(const char *str);

    void PrintDelay(struct TDelay *delay, bool header);

    void PrintCountSumary(int Index);
    void PrintASumary(int Index);
    void PrintBSumary(int Index);
    void PrintDelaySumary(int Index);

    bool PrintCountDetail(int Index);
    bool PrintADetail(int Index);
    bool PrintBDetail(int Index);
    bool PrintDelayDetail(int Index);

    void PrintResult();

    TAdcData *GetBlock(int Block);
    TAdcData *FindStart(int *Entries);

    char CheckRamp(TAdcData *data, int Block, int Samples, char Start);
    void CheckRamp();

    int InitPn();
    int UpdatePn(int start);
    int CheckPn(TAdcData *data, int Block, int Samples, int Start);
    void CheckPn();

    int GetPhaseIncr(double Freq);
    void CalcPowerPhase(double Freq, TAdcData *Data, int Size);
    void CreateRef(double Freq, TAdcData *Ref, TAdcData *Data, int Size);
    void CalcDiff(double Freq, TAdcData *Data, int Size, int *DiffA, int *DiffB);

    virtual void Execute();

    int PowerA;
    int PowerB;
    int PhaseA;
    int PhaseB;

    TAdcData *TestData;
    TAdcAna **AdcAna;
    int Intervals;
    int AnaSize;
    int FreqCount;

    int Threads;
    TFile *file;
    struct TDelay Delay;

    int FBlocks;
    TSignalDevice FSignal;
    char FTestMode;
    char *FBuf;
};

#endif
