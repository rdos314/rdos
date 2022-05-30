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
# phase.cpp
# Phase analysator
#
########################################################################*/

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "phase.h"

/*##########################################################################
#
#   Name       : TPhaseDistr::TPhaseDistr
#
#   Purpose....: Normal distribution for phase data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPhaseDistr::TPhaseDistr(int Raw[360])
{
    int i;
    int val;
    int max;
    int pos;
    bool more;
    int filtered[360];

    FCurrArea = 0;

    for (i = 0; i < 360; i++)
    {
        val = Raw[i];
        FRaw[i] = val;
        FCurrArea += val;
        filtered[i] = 0;
    }

    val = Raw[0];
    filtered[357] += val / 4;
    filtered[358] += val / 2;
    filtered[359] += val;
    filtered[0] += val;
    filtered[1] += val;
    filtered[2] += val / 2;
    filtered[3] += val / 4;

    val = Raw[1];
    filtered[358] += val / 4;
    filtered[359] += val / 2;
    filtered[0] += val;
    filtered[1] += val;
    filtered[2] += val;
    filtered[3] += val / 2;
    filtered[4] += val / 4;

    val = Raw[2];
    filtered[359] += val / 4;
    filtered[0] += val / 2;
    filtered[1] += val;
    filtered[2] += val;
    filtered[3] += val;
    filtered[4] += val / 2;
    filtered[5] += val / 4;

    val = Raw[359];
   filtered[356] += val / 4;
    filtered[357] += val / 2;
    filtered[358] += val;
    filtered[359] += val;
    filtered[0] += val;
    filtered[1] += val / 2;
    filtered[2] += val / 4;

    val = Raw[358];
    filtered[355] += val / 4;
    filtered[356] += val / 2;
    filtered[357] += val;
    filtered[358] += val;
    filtered[359] += val;
    filtered[0] += val / 2;
    filtered[1] += val / 4;

    val = Raw[357];
    filtered[354] += val / 4;
    filtered[355] += val / 2;
    filtered[356] += val;
    filtered[357] += val;
    filtered[358] += val;
    filtered[359] += val / 2;
    filtered[0] += val / 4;

    for (i = 3; i < 357; i++)
    {
        val = Raw[i];
        filtered[i-3] += val / 4;
        filtered[i-2] += val / 2;
        filtered[i-1] += val;
        filtered[i] += val;
        filtered[i+1] += val;
        filtered[i+2] += val / 2;
        filtered[i+3] += val / 4;
    }

    max = 0;

    FCurrPhase = 0;

    for (i = 0; i < 360; i++)
    {
        if (filtered[i] > max)
        {
            max = filtered[i];
            FCurrPhase = i;
        }
    }

    val = Raw[FCurrPhase];

    if (FCurrPhase == 0)
        pos = 0;
    else
        pos = FCurrPhase - 1;
    val += Raw[pos];

    if (FCurrPhase == 359)
        pos = 0;
    else
        pos = FCurrPhase + 1;
    val += Raw[pos];

    FCurrPeak = val / 3;

    FCurrSd = (double)FCurrArea / (double)FCurrPeak / sqrt(2.0 * 3.1415926);
    CalcDist(FCurrPhase, FCurrPeak, FCurrSd);
    FCurrFit = CalcFit();

    more = true;
    for (i = 0; i < 100 && more; i++)
        more = OptSd() || OptPhase();

    RejectChange();
}

/*##########################################################################
#
#   Name       : TPhaseDistr::~TPhaseDistr
#
#   Purpose....: Destructor for normal distribution for phase data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPhaseDistr::~TPhaseDistr()
{
}

/*##########################################################################
#
#   Name       : TPhaseDistr::GetPeak
#
#   Purpose....: Get peak value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPhaseDistr::GetPeak()
{
    return FNewPeak;
}

/*##########################################################################
#
#   Name       : TPhaseDistr::AddDist
#
#   Purpose....: Add distro to array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPhaseDistr::AddDist(int Arr[360])
{
    int i;

    for (i = 0; i < 360; i++)
        Arr[i] += FCurrDist[i];
}

/*##########################################################################
#
#   Name       : TPhaseDistr::ChangeSD
#
#   Purpose....: Modify SD
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPhaseDistr::ChangeSd(double diff)
{
    FNewSd = FCurrSd + diff;
    CalcDist(FNewPhase, FNewPeak, FNewSd);
}

/*##########################################################################
#
#   Name       : TPhaseDistr::ChangePeak
#
#   Purpose....: Modify peak
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPhaseDistr::ChangePeak(int diff)
{
    FNewPeak = FCurrPeak + diff;
    CalcDist(FNewPhase, FNewPeak, FNewSd);
}

/*##########################################################################
#
#   Name       : TPhaseDistr::ChangePhase
#
#   Purpose....: Modify phase
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPhaseDistr::ChangePhase(int diff)
{
    FNewPhase = FCurrPhase + diff;
    CalcDist(FNewPhase, FNewPeak, FNewSd);
}

/*##########################################################################
#
#   Name       : TPhaseDistr::AcceptChange
#
#   Purpose....: Accept change
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPhaseDistr::AcceptChange()
{
    FCurrSd = FNewSd;
    FCurrPeak = FNewPeak;
    FCurrPhase = FNewPhase;
}

/*##########################################################################
#
#   Name       : TPhaseDistr::RejectChange
#
#   Purpose....: Reject change
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPhaseDistr::RejectChange()
{
    FNewSd = FCurrSd;
    FNewPeak = FCurrPeak;
    FNewPhase = FCurrPhase;
    CalcDist(FNewPhase, FNewPeak, FNewSd);
}

/*##########################################################################
#
#   Name       : TPhaseDistr::CalcDist
#
#   Purpose....: Calc distribution data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPhaseDistr::CalcDist(int Phase, int Peak, double Sd)
{
    int i;
    double dval;
    int ival;
    int pos;
    double amp = (double)Peak;

    for (i = 0; i < 360; i++)
        FCurrDist[i] = 0;

    for (i = 0; i < 180; i++)
    {
        dval = (double)i;
        dval = dval * dval / 2.0 / Sd / Sd;
        dval = amp * exp(-dval);
        ival = (int)dval;

        pos = Phase + i;
        if (pos >= 360)
            pos -= 360;
        FCurrDist[pos] = ival;

        pos = Phase - i;
        if (pos < 0)
            pos += 360;
        FCurrDist[pos] = ival;
    }
}

/*##########################################################################
#
#   Name       : TPhaseDistr::CalcFit
#
#   Purpose....: Calc goodness of fit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPhaseDistr::CalcFit()
{
    long long diff;
    long long sum;
    int i;
    double val;

    sum = 0;
    for (i = 0; i < 360; i++)
    {
        diff = FCurrDist[i] - FRaw[i];
        sum += diff * diff;
    }

    val = (double)sum;
    val = sqrt(val);
    val = val / (double)FCurrArea;

    return val;
}

/*##########################################################################
#
#   Name       : TPhaseDistr::OptSd
#
#   Purpose....: Optimize SD
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPhaseDistr::OptSd()
{
    bool changed = false;
    double Fit;
    double Sd;

    Sd = FCurrSd + 0.01;
    CalcDist(FCurrPhase, FCurrPeak, Sd);
    Fit = CalcFit();

    if (Fit < FCurrFit)
    {
        while (Fit < FCurrFit)
        {
            changed = true;
            FCurrSd = Sd;
            FCurrFit = Fit;

            Sd = FCurrSd + 0.01;
            CalcDist(FCurrPhase, FCurrPeak, Sd);
            Fit = CalcFit();
        }
    }
    else
    {
        Sd = FCurrSd - 0.01;
        CalcDist(FCurrPhase, FCurrPeak, Sd);
        Fit = CalcFit();

        while (Fit < FCurrFit)
        {
            changed = true;
            FCurrSd = Sd;
            FCurrFit = Fit;

            Sd = FCurrSd - 0.01;
            CalcDist(FCurrPhase, FCurrPeak, Sd);
            Fit = CalcFit();
        }
    }

    CalcDist(FCurrPhase, FCurrPeak, FCurrSd);
    return changed;
}

/*##########################################################################
#
#   Name       : TPhaseDistr::OptPhase
#
#   Purpose....: Optimize phase
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPhaseDistr::OptPhase()
{
    bool changed = false;
    double Fit;
    int Phase;

    Phase = FCurrPhase + 1;
    CalcDist(Phase, FCurrPeak, FCurrSd);
    Fit = CalcFit();

    if (Fit < FCurrFit)
    {
        while (Fit < FCurrFit)
        {
            changed = true;
            FCurrPhase = Phase;
            FCurrFit = Fit;

            Phase = FCurrPhase + 1;
            CalcDist(Phase, FCurrPeak, FCurrSd);
            Fit = CalcFit();
        }
    }
    else
    {
        Phase = FCurrPhase - 1;
        CalcDist(Phase, FCurrPeak, FCurrSd);
        Fit = CalcFit();

        while (Fit < FCurrFit)
        {
            changed = true;
            FCurrPhase = Phase;
            FCurrFit = Fit;

            Phase = FCurrPhase - 1;
            CalcDist(Phase, FCurrPeak, FCurrSd);
            Fit = CalcFit();
        }
    }

    CalcDist(FCurrPhase, FCurrPeak, FCurrSd);
    return changed;
}

/*##########################################################################
#
#   Name       : TPhase::TPhase
#
#   Purpose....: Phase constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPhase::TPhase(int Raw[360])
{
    int i;
    int val;
    int Diff[360];

    FArea = 0;

    for (i = 0; i < 360; i++)
    {
        val = Raw[i];
        FRaw[i] = val;
        FArea += val;
    }

    FPhaseCount = 0;
    Add(Raw);
    CalcDist();
    FCurrFit = CalcFit();

    while (FCurrFit > 0.01 && FPhaseCount < MAX_PHASE_DIST)
    {
        GetDiff(Diff);
        Add(Diff);
        CalcDist();
        FCurrFit = CalcFit();
        Optimize();
    }
}

/*##########################################################################
#
#   Name       : TPhase::~TPhase
#
#   Purpose....: Destructor for phase
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPhase::~TPhase()
{
    int i;

    for (i = 0; i < FPhaseCount; i++)
        if (FPhaseArr[i])
            delete FPhaseArr[i];
}

/*##########################################################################
#
#   Name       : TPhase::Add
#
#   Purpose....: Add distr
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPhaseDistr *TPhase::Add(int Raw[360])
{
    TPhaseDistr *phase = new TPhaseDistr(Raw);
    FPhaseArr[FPhaseCount] = phase;
    FPhaseCount++;
    return phase;
}

/*##########################################################################
#
#   Name       : TPhase::CalcDist
#
#   Purpose....: Calc dist array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPhase::CalcDist()
{
    int i;

    for (i = 0; i < 360; i++)
       FCurrDist[i] = 0;

    for (i = 0; i < FPhaseCount; i++)
        FPhaseArr[i]->AddDist(FCurrDist);
}

/*##########################################################################
#
#   Name       : TPhase::CalcFit
#
#   Purpose....: Calc goodness of fit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPhase::CalcFit()
{
    long long diff;
    long long sum;
    int i;
    double val;

    sum = 0;
    for (i = 0; i < 360; i++)
    {
        diff = FCurrDist[i] - FRaw[i];
        sum += diff * diff;
    }

    val = (double)sum;
    val = sqrt(val);
    val = val / (double)FArea;

    return val;
}

/*##########################################################################
#
#   Name       : TPhase::GetDiff
#
#   Purpose....: Get difference array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPhase::GetDiff(int Arr[360])
{
    int i;
    int diff;

    for (i = 0; i < 360; i++)
    {
        diff = FCurrDist[i] - FRaw[i];
        if (diff > 0)
            Arr[i] = diff;
        else
            Arr[i] = 0;
    }
}

/*##########################################################################
#
#   Name       : TPhase::LowerSd
#
#   Purpose....: Try to lower SD to increase fit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPhase::LowerSd(TPhaseDistr *phase)
{
    double fit;
    bool changed = false;

    phase->ChangeSd(-0.01);
    CalcDist();
    fit = CalcFit();

    while (fit < FCurrFit)
    {
        changed = true;
        FCurrFit = fit;
        phase->AcceptChange();
        phase->ChangeSd(-0.01);
        CalcDist();
        fit = CalcFit();
    }

    phase->RejectChange();
    return changed;
}

/*##########################################################################
#
#   Name       : TPhase::LowerPeak
#
#   Purpose....: Try to lower peak to increase fit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPhase::LowerPeak(TPhaseDistr *phase)
{
    double fit;
    int peak = phase->GetPeak();
    int diff;
    bool changed = false;

    if (peak > 100)
        diff = -peak / 100;
    else
        diff = -1;

    phase->ChangePeak(diff);
    CalcDist();
    fit = CalcFit();

    while (fit < FCurrFit)
    {
        changed = true;
        FCurrFit = fit;
        phase->AcceptChange();
        phase->ChangePeak(diff);
        CalcDist();
        fit = CalcFit();
    }

    phase->RejectChange();
    return changed;
}

/*##########################################################################
#
#   Name       : TPhase::RaisePeak
#
#   Purpose....: Try to raise peak to increase fit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPhase::RaisePeak(TPhaseDistr *phase)
{
    double fit;
    int peak = phase->GetPeak();
    int diff;
    bool changed = false;

    if (peak > 100)
        diff = peak / 100;
    else
        diff = 1;

    phase->ChangePeak(diff);
    CalcDist();
    fit = CalcFit();

    while (fit < FCurrFit)
    {
        changed = true;
        FCurrFit = fit;
        phase->AcceptChange();
        phase->ChangePeak(diff);
        CalcDist();
        fit = CalcFit();
    }

    phase->RejectChange();
    return changed;
}

/*##########################################################################
#
#   Name       : TPhase::OptimizePhase
#
#   Purpose....: Try to move phase to increase fit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPhase::OptimizePhase(TPhaseDistr *phase)
{
    double fit;
    int diff;
    bool changed = false;

    phase->ChangePhase(-1);
    CalcDist();
    fit = CalcFit();

    if (fit < FCurrFit)
    {
        while (fit < FCurrFit)
        {
            changed = true;
            FCurrFit = fit;
            phase->AcceptChange();
            phase->ChangePhase(-1);
            CalcDist();
            fit = CalcFit();
        }
    }
    else
    {
        phase->ChangePhase(1);
        CalcDist();
        fit = CalcFit();

        while (fit < FCurrFit)
        {
            changed = true;
            FCurrFit = fit;
            phase->AcceptChange();
            phase->ChangePhase(1);
            CalcDist();
            fit = CalcFit();
        }
    }

    phase->RejectChange();
    return changed;
}

/*##########################################################################
#
#   Name       : TPhase::Optimize
#
#   Purpose....: Optimize a distro
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPhase::Optimize(TPhaseDistr *phase)
{
    bool anych = false;
    bool changed = true;
    int count;

    for (count = 0; count < 100 && changed; count++)
    {
        changed = LowerSd(phase);
        changed |= LowerPeak(phase);
        changed |= OptimizePhase(phase);
        anych |= changed;
    }
    return anych;
}

/*##########################################################################
#
#   Name       : TPhase::Optimize
#
#   Purpose....: Optimize distros
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPhase::Optimize()
{
    int i;
    int count;
    TPhaseDistr *phase;
    bool changed = true;

    for (count = 0; count < 100 && changed; count++)
    {
        changed = false;

        for (i = FPhaseCount - 2; i >= 0; i--)
        {
            phase = FPhaseArr[i];
            changed |= Optimize(phase);
        }

        phase = FPhaseArr[FPhaseCount-1];
        changed |= LowerSd(phase);
        changed |= RaisePeak(phase);
        changed |= OptimizePhase(phase);
    }
}
