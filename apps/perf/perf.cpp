/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# perf.cpp
# Graphical CPU load tool
#
########################################################################*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rdos.h"
#include "videodev.h"
#include "font.h"
#include "chart.h"
#include "timeaxis.h"
#include "linyaxis.h"
#include "png.h"

#define MAX_CORES   6
#define MAX_SAMPLES 2 * 60

#define FALSE   0
#define TRUE    !FALSE

int main(int argc, char **argv)
{
    TGraphicDevice *vbe;
    int width, height;
    int i;
    int Cores;
    TFont AxisFont(15);
    TChart *PerfChart[MAX_CORES];
    TTimeXAxis *XAxis[MAX_CORES];
    TLinYAxis *YAxis[MAX_CORES];
    long long CoreTicsArr[MAX_CORES];
    long long NullTicsArr[MAX_CORES];
    long long CoreTics;
    long long NullTics;
    long long CoreDiff;
    long long NullDiff;
    long double XVal;
    long double YVal;
    unsigned long Msb, Lsb;
    int Count = 0;
    TBitmapGraphicDevice *bitmap;
    TPngBitmapDevice *png;
    int Handle;
    int Index;
    char FileName[255];

    width = 640;
    height = 480;

    vbe = new TVideoGraphicDevice(24, width, height);

    for (Cores = 0; Cores < MAX_CORES; Cores++)
    {
        if (RdosGetCoreLoad(Cores, &NullTicsArr[Cores], &CoreTicsArr[Cores]))
        {
            XAxis[Cores] = new TTimeXAxis(&AxisFont);
            XAxis[Cores]->SetBackColor(0, 0, 0);
            XAxis[Cores]->SetForeColor(255, 255, 255);
            YAxis[Cores] = new TLinYAxis(&AxisFont);
            YAxis[Cores]->SetBackColor(0, 0, 0);
            YAxis[Cores]->SetForeColor(255, 255, 255);
            PerfChart[Cores] = new TChart(vbe, XAxis[Cores], YAxis[Cores]);
            if (Cores < 3)
                PerfChart[Cores]->SetWindow(20, 20 + Cores * 150, 300, 160 + Cores * 150);
            else
                PerfChart[Cores]->SetWindow(320, 20 + (Cores - 3) * 150, 600, 160 + (Cores - 3) * 150);
            PerfChart[Cores]->SetBackColor(0, 0, 0);
            PerfChart[Cores]->SetLineColor(0, 50, 200, 100);
            PerfChart[Cores]->SetYAxis(0.0, 100.0);
        }
        else
            break;
    }

    for (;;)
    {
        RdosWaitMilli(1000);
        for (i = 0; i < Cores; i++)
        {
            RdosGetTime(&Msb, &Lsb);
            XVal = (long double)Lsb / 65536.0 / 65536.0;
            XVal += (long double)Msb;
            
            RdosGetCoreLoad(i, &NullTics, &CoreTics);
            CoreDiff = CoreTics - CoreTicsArr[i];
            NullDiff = NullTics - NullTicsArr[i];
            CoreTicsArr[i] = CoreTics;
            NullTicsArr[i] = NullTics;
            if (CoreDiff > 1192 * 500)
            {
                YVal = 100.0 - (long double)NullDiff / (long double)CoreDiff * 100.0;
                if (Count == MAX_SAMPLES)
                    PerfChart[i]->Remove(0);

                PerfChart[i]->Add(0, XVal, YVal);                    
                PerfChart[i]->Draw();
            }            
        }
        if (Count < MAX_SAMPLES)
            Count++;

    }


    return 0;
}

