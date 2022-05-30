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
void CalcPhase(int Filtered[360], int Arr[360], int *Area, int *Phase, int *Peak)
{
    double dval;
    int i;
    int val;
    int max;
    int pos;

    for (i = 0; i < 360; i++)
        Filtered[i] = 0;

    val = Arr[0];
    Filtered[357] += val / 4;
    Filtered[358] += val / 2;
    Filtered[359] += val;
    Filtered[0] += val;
    Filtered[1] += val;
    Filtered[2] += val / 2;
    Filtered[3] += val / 4;

    val = Arr[1];
    Filtered[358] += val / 4;
    Filtered[359] += val / 2;
    Filtered[0] += val;
    Filtered[1] += val;
    Filtered[2] += val;
    Filtered[3] += val / 2;
    Filtered[4] += val / 4;

    val = Arr[2];
    Filtered[359] += val / 4;
    Filtered[0] += val / 2;
    Filtered[1] += val;
    Filtered[2] += val;
    Filtered[3] += val;
    Filtered[4] += val / 2;
    Filtered[5] += val / 4;

    val = Arr[359];
    Filtered[356] += val / 4;
    Filtered[357] += val / 2;
    Filtered[358] += val;
    Filtered[359] += val;
    Filtered[0] += val;
    Filtered[1] += val / 2;
    Filtered[2] += val / 4;

    val = Arr[358];
    Filtered[355] += val / 4;
    Filtered[356] += val / 2;
    Filtered[357] += val;
    Filtered[358] += val;
    Filtered[359] += val;
    Filtered[0] += val / 2;
    Filtered[1] += val / 4;

    val = Arr[357];
    Filtered[354] += val / 4;
    Filtered[355] += val / 2;
    Filtered[356] += val;
    Filtered[357] += val;
    Filtered[358] += val;
    Filtered[359] += val / 2;
    Filtered[0] += val / 4;

    for (i = 3; i < 357; i++)
    {
        val = Arr[i];
        Filtered[i-3] += val / 4;
        Filtered[i-2] += val / 2;
        Filtered[i-1] += val;
        Filtered[i] += val;
        Filtered[i+1] += val;
        Filtered[i+2] += val / 2;
        Filtered[i+3] += val / 4;
    }

    max = 0;
    pos = 0;
    val = 0;

    for (i = 0; i < 360; i++)
    {
        val += Filtered[i];

        if (Filtered[i] > max)
        {
            max = Filtered[i];
            pos = i;
        }
    }

    *Phase = pos;
    *Peak = max;
    *Area = val;

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
#   Name       : IsInside
#
#   Purpose....: Check if distribution is inside
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool IsInside(int Filtered[360], int Arr[360])
{
    int i;

    for (i = 0; i < 360; i++)
        if (Arr[i] > Filtered[i])
            return false;

    return true;
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
double CalcFit(int Filtered[360], int Arr[360], int Area)
{
    long long diff;
    long long sum;
    int i;
    double val;

    sum = 0;
    for (i = 0; i < 360; i++)
    {
        diff = Arr[i] - Filtered[i];
        sum += diff * diff;
    }    

    val = (double)sum;
    val = sqrt(val);
    val = val / (double)Area;

    return val;
}

/*##########################################################################
#
#   Name       : OptPeak
#
#   Purpose....: Optimize peak
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int OptPeak(int Filtered[360], int Arr[360], int Mean, int Peak, int Area, double Sd)
{
    CalcNormal(Arr, Mean, Peak, Sd);

    if (!IsInside(Filtered, Arr))
    {
        Peak--;
        CalcNormal(Arr, Mean, Peak, Sd);

        while (!IsInside(Filtered, Arr))
        {
            Peak--;
            CalcNormal(Arr, Mean, Peak, Sd);
        }
    }
    else
    {
        CalcNormal(Arr, Mean, Peak + 1, Sd);
        while (IsInside(Filtered, Arr))
        {
            Peak++;
            CalcNormal(Arr, Mean, Peak + 1, Sd);
        }
    }

    return Peak;
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
double OptSd(int Filtered[360], int Arr[360], int Mean, int Peak, int Area, double Sd)
{
    double OptFit;
    double OptSd = Sd;
    double Fit;

    CalcNormal(Arr, Mean, Peak, Sd);
    OptFit = CalcFit(Filtered, Arr, Area);

    Sd = OptSd + 0.01;
    CalcNormal(Arr, Mean, Peak, Sd);

    if (IsInside(Filtered, Arr))
        Fit = CalcFit(Filtered, Arr, Area);
    else
        Fit = OptFit;

    if (Fit < OptFit)
    {
        while (Fit < OptFit)
        {
            OptSd = Sd;
            OptFit = Fit;

            Sd = OptSd + 0.01;
            CalcNormal(Arr, Mean, Peak, Sd);
            if (IsInside(Filtered, Arr))
                Fit = CalcFit(Filtered, Arr, Area);
        }
    }
    else
    {
        Sd = OptSd - 0.01;
        CalcNormal(Arr, Mean, Peak, Sd);
        if (IsInside(Filtered, Arr))
            Fit = CalcFit(Filtered, Arr, Area);
        else
            Fit = OptFit;

        while (Fit < OptFit)
        {
            OptSd = Sd;
            OptFit = Fit;

            Sd = OptSd - 0.01;
            CalcNormal(Arr, Mean, Peak, Sd);
            if (IsInside(Filtered, Arr))
                Fit = CalcFit(Filtered, Arr, Area);
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
int OptMean(int Filtered[360], int Arr[360], int Mean, int Peak, int Area, double Sd)
{
    double OptFit;
    int OptMean = Mean;
    double Fit;

    CalcNormal(Arr, Mean, Peak, Sd);
    OptFit = CalcFit(Filtered, Arr, Area);

    Mean = OptMean + 1;
    CalcNormal(Arr, Mean, Peak, Sd);
    if (IsInside(Filtered, Arr))
        Fit = CalcFit(Filtered, Arr, Area);
    else
        Fit = OptFit;

    if (Fit < OptFit)
    {
        while (Fit < OptFit)
        {
            OptMean = Mean;
            OptFit = Fit;

            Mean = OptMean + 1;
            CalcNormal(Arr, Mean, Peak, Sd);
            if (IsInside(Filtered, Arr))
                Fit = CalcFit(Filtered, Arr, Area);
        }
    }
    else
    {
        Mean = OptMean - 1;
        CalcNormal(Arr, Mean, Peak, Sd);
        if (IsInside(Filtered, Arr))
            Fit = CalcFit(Filtered, Arr, Area);
        else
            Fit = OptFit;

        while (Fit < OptFit)
        {
            OptMean = Mean;
            OptFit = Fit;

            Mean = OptMean - 1;
            CalcNormal(Arr, Mean, Peak, Sd);
            if (IsInside(Filtered, Arr))
                Fit = CalcFit(Filtered, Arr, Area);
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
    int NewPeak;
    double NewSd;
    bool New = true;
    int Count = 0;
    double Fit;
    int Norm[360];
    int Filtered[360];
    int phase[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,9,0,0,0,0,0,0,1,0,0,0,14,0,0,0,31,4,0,42,3,21,43,11,16,35,16,73,34,105,66,196,74,140,144,146,227,370,436,556,648,675,734,1257,1540,1756,2201,2285,3501,2923,4550,5417,5901,7458,8999,10980,11312,14100,16578,19513,17435,29215,23551,30680,32591,34565,36670,40972,39569,43147,41657,42167,40953,36843,39345,34600,31802,29043,27169,25828,16059,16914,16568,12130,11394,9379,8247,5067,7167,6628,4678,4859,3426,3254,2275,3630,2797,2229,1580,1346,1711,1840,1099,669,609,291,1733,256,218,309,271,357,275,101,104,36,88,73,82,20,21,5,28,16,6,25,14,5,0,45,42,0,0,13,5,0,2,15,0,11,0,0,3,0,0,0,12,0,0,0,0,0,0,10,0,4,0,0,0,0,0,0,0,0,0,0,0,14,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

    CalcPhase(Filtered, phase, &Area, &Mean, &Peak);

    Sd = (double)Area / (double)Peak / sqrt(2.0 * 3.1415926);
    CalcNormal(Norm, Mean, Peak, Sd);

    while (!IsInside(Filtered, Norm))
    {
        Sd = 0.9 * Sd;
        Peak = Peak * 9 / 10;
        CalcNormal(Norm, Mean, Peak, Sd);
    }

    for (Count = 0; Count < 100 && New; Count++)
    {
        New = false;

        NewPeak = OptPeak(Filtered, Norm, Mean, Peak, Area, Sd);
        if (Peak != NewPeak)
        {
            New = true;
            Peak = NewPeak;
        }

        NewSd = OptSd(Filtered, Norm, Mean, Peak, Area, Sd);
        if (Sd != NewSd)
        {
            New = true;
            Sd = NewSd;
        }

        NewMean = OptMean(Filtered, Norm, Mean, Peak, Area, Sd);
        if (Mean != NewMean)
        {
            New = true;
            Mean = NewMean;
        }
    }

    Fit = CalcFit(Filtered, Norm, Area);
}
