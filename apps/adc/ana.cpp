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

int phase[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,3,3,0,7,12,7,20,29,31,41,107,92,178,197,278,489,400,917,1039,1463,1778,2379,4372,2811,5650,6752,7982,9771,11639,13506,11867,18807,20932,18718,22216,22122,23232,17681,23045,20537,18060,16044,12932,12048,9634,9211,6209,4212,2975,4869,1634,1286,1013,695,484,386,233,178,114,65,59,25,51,11,16,6,3,1,3,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

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
    double Fit;
    int Norm[360];

    CalcPhase(&Area, &Mean, &Peak);

    Sd = (double)Area / (double)Peak / sqrt(2.0 * 3.1415926);
    Sd = OptSd(Norm, Mean, Peak, Area, Sd);
    Fit = CalcFit(Norm, Area);
}
