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
#include "graphdev.h"

class TLog;

class TVp : public TFuzzy
{
public:
	TVp(TGraphicDevice *dev, TLog *log);
	~TVp();

	void DeviceName(char *Name, int Size) const;

	int IsVpOn();
	int IsEpOn();

	int GetTankTemp();
	int GetHeatTemp();

	int HasValidTankTemp();
	int HasValidHeatTemp();

	int HasValidTankP();
	long double GetTankP();

	int HasValidHeatP();
	long double GetHeatP();
    
	void SetTempError(int temp);
	void SetAmbient(int ref, int ambient);
    
protected:
    void ReadTankData();
    
	virtual void Execute();

    TFuzzyVar FTempDiffVar;
    TFuzzyVar FAmbientVar;
    TFuzzyVar FOutputVar;

    int TempSum;
    int TempCount;
    long double AmbientSum;
    int AmbientCount;

    int FVpOn;
    int FEpOn;
    
    long double FLevel;
    
	int FValidTank;
	int FValidHeat;

	int FTankTemp;
	int FHeatTemp;

	int FTankSum;
	int FTankCount;

	int FHeatSum;
	int FHeatCount;

	int FValidPTank;
	long double PTank;

	int ValidTankArr[40];
	long double TankArr[40];

	int FValidPHeat;
	long double PHeat;

	int ValidHeatArr[20];
	long double HeatArr[20];

    int FMaxHeatTemp;
    int FMaxHeatDay;

    int FValidAmbient;
    int FAmbient;
    int FRef;

    TGraphicDevice *vbe;
	TFont Font;
    TLog *Log;

    TSection FSection;
};

#endif
