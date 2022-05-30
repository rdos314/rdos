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
# ana.cpp
# Phase analysator
#
########################################################################*/

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "freq.h"

int phase[] = {40,6,1,2,15,21,18,0,7,0,3,8,1,19,17,21,17,3,11,0,3,0,0,3,0,0,0,18,3,1,0,0,0,0,0,0,0,0,0,5,0,0,5,0,0,7,2,0,12,19,1,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,8,0,15,1,0,0,0,0,0,7,9,3,5,2,10,3,21,0,0,7,0,0,0,0,5,16,0,3,28,20,16,0,0,26,7,10,15,28,8,24,16,34,6,1,5,6,14,17,28,30,5,76,15,19,42,71,43,38,64,86,30,28,35,65,87,70,46,57,30,47,89,73,95,108,116,133,107,223,133,205,155,154,413,310,255,257,416,572,314,360,535,562,552,707,664,591,798,922,705,1128,1082,1108,824,1301,1462,1385,1454,1079,1488,1217,1703,1454,1357,1249,2659,1402,1438,1651,2140,1904,1753,1851,1731,1685,1903,1967,1974,2050,2215,2117,2225,2723,2701,2237,2651,2932,3040,3128,3504,3612,2713,4504,4346,4556,4646,5295,5944,5527,6550,7302,7365,7901,8679,9850,9839,10549,10932,11727,10639,14331,10895,12729,12069,12451,12112,12684,13720,13362,13995,14473,15006,14573,15189,15743,17751,18902,19629,20819,19082,20580,21011,20012,19294,18833,17006,15221,15612,14354,12725,13332,12335,12494,10874,12723,13267,12881,13862,14094,15521,16428,17719,17903,17499,16696,33546,18417,20852,25258,26988,27242,29102,26137,26883,29485,30058,31744,21822,27884,26813,27080,23565,27108,25321,15134,20191,19293,18366,16076,18569,13856,8971,15331,12235,10031,8849,7601,7786,4369,6954,5364,4287,5539,3352,3981,2516,2962,2753,1987,1632,2655,1339,929,1323,1125,660,885,558,793,342,445,386,227,374,214,265,237,161,196,62,95,146,136,123,89,84,72,82,76,62,47,47,17,10,57,87,59,11,8,30,60,14,7,0,53};

/*##########################################################################
#
#   Name       : CalcPhase
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void CalcPhase(int *Area, int *Phase, int *Peak)
{
    double dval;
    int i;
    int val;
    int ip[360];
    int max;
    int pos;
  
    val = 0;

    for (i = 0; i < 360; i++)
    {
        ip[i] = 0;
        val += phase[i];
    }

    *Area = val;

    val = phase[0];
    ip[357] += val / 4;
    ip[358] += val / 2;
    ip[359] += val;
    ip[0] += val;
    ip[1] += val;
    ip[2] += val / 2;
    ip[3] += val / 4;

    val = phase[1];
    ip[358] += val / 4;
    ip[359] += val / 2;
    ip[0] += val;
    ip[1] += val;
    ip[2] += val;
    ip[3] += val / 2;
    ip[4] += val / 4;

    val = phase[2];
    ip[359] += val / 4;
    ip[0] += val / 2;
    ip[1] += val;
    ip[2] += val;
    ip[3] += val;
    ip[4] += val / 2;
    ip[5] += val / 4;

    val = phase[359];
    ip[356] += val / 4;
    ip[357] += val / 2;
    ip[358] += val;
    ip[359] += val;
    ip[0] += val;
    ip[1] += val / 2;
    ip[2] += val / 4;

    val = phase[358];
    ip[355] += val / 4;
    ip[356] += val / 2;
    ip[357] += val;
    ip[358] += val;
    ip[359] += val;
    ip[0] += val / 2;
    ip[1] += val / 4;

    val = phase[357];
    ip[354] += val / 4;
    ip[355] += val / 2;
    ip[356] += val;
    ip[357] += val;
    ip[358] += val;
    ip[359] += val / 2;
    ip[0] += val / 4;

    for (i = 3; i < 357; i++)
    {
        val = phase[i];
        ip[i-3] += val / 4;
        ip[i-2] += val / 2;
        ip[i-1] += val;
        ip[i] += val;
        ip[i+1] += val;
        ip[i+2] += val / 2;
        ip[i+3] += val / 4;
    }

    max = 0;
    pos = 0;

    for (i = 0; i < 360; i++)
    {
        if (phase[i] > max)
        {
            max = phase[i];
            pos = i;
        }
    }

    *Phase = pos;
    *Peak = max;
}

/*##########################################################################
#
#   Name       : CalcNormal
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void CalcNormal(int Arr[360], int Mean, int Peak, double Sd)
{
    int i;
    double dval;
    int ival;
    int pos;
    double amp = (double)Peak;

    for (i = 0; i < 360; i++)
        Arr[i] = 0;

    for (i = 0; i < 180; i++)
    {
        dval = (double)i;
        dval = dval * dval / 2.0 / Sd / Sd;
        dval = amp * exp(-dval);
        ival = (int)dval;

        pos = Mean + i;
        if (pos >= 360)
            pos -= 360;
        Arr[pos] = ival;

        pos = Mean - i;
        if (pos < 0)
            pos += 360;
        Arr[pos] = ival;    
    }
}

/*##########################################################################
#
#   Name       : CalcFit
#
#   Purpose....: Calc goodness of fit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double CalcFit(int Arr[360], int Area)
{
    long long diff;
    long long sum;
    int i;
    double val;

    sum = 0;
    for (i = 0; i < 360; i++)
    {
        diff = Arr[i] - phase[i];
        sum += diff * diff;
    }    

    val = (double)sum;
    val = sqrt(val);
    val = val / (double)Area;

    return val;
}

/*##########################################################################
#
#   Name       : OptSd
#
#   Purpose....: Optimize SD
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double OptSd(int Arr[360], int Mean, int Peak, int Area, double Sd)
{
    double OptFit;
    double OptSd = Sd;
    double Fit;

    CalcNormal(Arr, Mean, Peak, Sd);
    OptFit = CalcFit(Arr, Area);

    Sd = OptSd + 0.01;
    CalcNormal(Arr, Mean, Peak, Sd);
    Fit = CalcFit(Arr, Area);

    if (Fit < OptFit)
    {
        while (Fit < OptFit)
        {
            OptSd = Sd;
            OptFit = Fit;

            Sd = OptSd + 0.01;
            CalcNormal(Arr, Mean, Peak, Sd);
            Fit = CalcFit(Arr, Area);
        }
    }
    else
    {
        Sd = OptSd - 0.01;
        CalcNormal(Arr, Mean, Peak, Sd);
        Fit = CalcFit(Arr, Area);

        while (Fit < OptFit)
        {
            OptSd = Sd;
            OptFit = Fit;

            Sd = OptSd - 0.01;
            CalcNormal(Arr, Mean, Peak, Sd);
            Fit = CalcFit(Arr, Area);
        }
    }   

    CalcNormal(Arr, Mean, Peak, OptSd);
    return OptSd;
}

/*##########################################################################
#
#   Name       : OptMean
#
#   Purpose....: Optimize mean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int OptMean(int Arr[360], int Mean, int Peak, int Area, double Sd)
{
    double OptFit;
    int OptMean = Mean;
    double Fit;

    CalcNormal(Arr, Mean, Peak, Sd);
    OptFit = CalcFit(Arr, Area);

    Mean = OptMean + 1;
    CalcNormal(Arr, Mean, Peak, Sd);
    Fit = CalcFit(Arr, Area);

    if (Fit < OptFit)
    {
        while (Fit < OptFit)
        {
            OptMean = Mean;
            OptFit = Fit;

            Mean = OptMean + 1;
            CalcNormal(Arr, Mean, Peak, Sd);
            Fit = CalcFit(Arr, Area);
        }
    }
    else
    {
        Mean = OptMean - 1;
        CalcNormal(Arr, Mean, Peak, Sd);
        Fit = CalcFit(Arr, Area);

        while (Fit < OptFit)
        {
            OptMean = Mean;
            OptFit = Fit;

            Mean = OptMean - 1;
            CalcNormal(Arr, Mean, Peak, Sd);
            Fit = CalcFit(Arr, Area);
        }
    }   

    CalcNormal(Arr, Mean, Peak, Sd);
    return OptMean;
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
    int Mean;
    int Peak;
    int Area;
    double Sd;
    int NewMean;
    double NewSd;
    bool New = true;
    int Count = 0;
    double Fit;
    int Norm[360];

    CalcPhase(&Area, &Mean, &Peak);

    Sd = (double)Area / (double)Peak / sqrt(2.0 * 3.1415926);

    for (Count = 0; Count < 100 && New; Count++)
    {
        New = false;

        NewSd = OptSd(Norm, Mean, Peak, Area, Sd);
        if (Sd != NewSd)
        {
            New = true;
            Sd = NewSd;
        }

        NewMean = OptMean(Norm, Mean, Peak, Area, Sd);
        if (Mean != NewMean)
        {
            New = true;
            Mean = NewMean;
        }
    }

    Fit = CalcFit(Norm, Area);
}
