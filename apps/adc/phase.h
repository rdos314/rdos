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
# phase.h
# Phase analysis class
#
########################################################################*/

#ifndef _PHASE_H
#define _PHASE_H

#define MAX_PHASE_DIST  8

class TPhaseDistr
{
public:
    TPhaseDistr(int Raw[360]);
    ~TPhaseDistr();

    void GetDiff(int Arr[360]);

protected:
    bool OptSd();
    bool OptPhase();
    void CalcDist(int Mean, int Peak, double Sd);
    double CalcFit();

    double FCurrFit;
    int FCurrArea;
    int FCurrPhase;
    int FCurrPeak;
    double FCurrSd;
    int FCurrDist[360];
    int FRaw[360];
};

class TPhase
{
public:
    TPhase(int Raw[360]);
    ~TPhase();

protected:
    TPhaseDistr *Add(int Raw[360]);

    int FPhaseCount;
    TPhaseDistr *FPhaseArr[MAX_PHASE_DIST];

    int FRaw[360];
};

#endif
