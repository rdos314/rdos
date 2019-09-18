/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# vp.h
# Heat pump class
#
########################################################################*/

#ifndef VP_H
#define VP_H

#include "fuzzy.h"
#include "control.h"

#define MAX_LEVEL_HISTORY   601

class TVp : public TFuzzy
{
public:
        TVp(TControlThread *control);
        ~TVp();

        void DeviceName(char *Name, int Size) const;

        int GetTankTemp();
        int GetHeatTemp();

        int HasValidTankTemp();
        int HasValidHeatTemp();

        int HasValidTankP();
        long double GetTankP();

        int HasValidHeatP();
        long double GetHeatP();

    void SetMaxMotor(int motor);
    void SetSolarAlt(long double val);
    void SetTempError(int temp);
    void SetAmbient(int ref, int ambient);

protected:
    void UpdateCirc(int diostat);
    void UpdateVp(int diff);
    void WriteCircValve(long double value);
    void CalcLinearRegression(int Size);
    void UpdateHistory(long double val);

        virtual void Execute();

         int TempSum;
         int TempCount;
         long double AmbientSum;
         int AmbientCount;

    int FMotorCount;
    int FMotorSum;

    long double FSolarAlt;
         
    int FVpOn;
    int FPrevOn;
    int FValidCirc;
    int FCirc;
    int FIncCount;
    int FHasCirc;
    long double FCircSpeed;

    int FHasLowTemp;
    int FLowTemp;

    int FOffCounter;

        int FValidTank;
        int FValidHeat;

        int FTankTemp;
        int FHeatTemp;

        int FHeatSum;
        int FHeatCount;

        int FValidPTank;
        long double PTank;

        int FValidPHeat;
        long double PHeat;

        int ValidHeatArr[20];
        long double HeatArr[20];

        long double FRawHistory[MAX_LEVEL_HISTORY];
        int FHistoryIndex;

        long double FHistory[MAX_LEVEL_HISTORY];
        int FHistoryCount;
        long double FCurrMean;
        long double FCurrSl2;
        long double FCurrFlow;
        long double FCurrSlope;
        long double FCurrSd2;
        long double FCurrTurbulence;
        long double FCurrTemp;

         int FValidAmbient;
         int FAmbient;
         int FRef;

         int FMaxTank;

         TControlThread *FControl;

         TSection FSection;
};

#endif
