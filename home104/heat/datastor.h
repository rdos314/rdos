/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2006, Leif Ekblad
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
# datastor.h
# Permanent data store class
#
########################################################################*/

#ifndef DATASTOR_H
#define DATASTOR_H

#include "thread.h"
#include "storlist.h"
#include "rad.h"
#include "ws2300.h"
#include "circ.h"
#include "vp.h"

#define RAD_COUNT   16

struct TRadData
{
    char HasData;
	 int Address;
	 long double Ref;
	 long double Temp;
	 long double Motor;
	 long double Light;
	 long double AuxTemp;
};

struct THeatData
{
	 unsigned long Msb;
	 unsigned long Lsb;

	 char HasWs;
	 long double IndoorTemp;
	 long double IndoorHumidity;
	 long double OutdoorTemp;
	 long double OutdoorHumidity;
	 long double DewPoint;
	 long double WindChill;
	 long double WindSpeed;
	 long double WindDir;
	 long double AirPressure;

	 char HasRain;
	 long Rain1h;

	 char HasCirc;
	 long double CircSpeed;

	 char HasVp;
	 char VpOn;
	 char EpOn;
	 char HasTankTemp;
	 long TankTemp;
	 char HasTankP;
	 long TankP;
	 char HasHeatTemp;
	 long HeatTemp;
	 char HasHeatP;
	 long HeatP;

	 TRadData Rad[RAD_COUNT];
};

class TDataStore : public TThread
{
public:
	TDataStore();
	~TDataStore();

	void Add(TRad *rad);
    void Add(TWs2300 *ws);	
    void Add(TCirc *circ);
    void Add(TVp *vp);
    
protected:
    void GetCurrRad(TRad *rad, TRadData *data);
    void GetCurrData(THeatData *data);

    virtual void Execute();

    int FYear;
    int FMonth;
    int FDay;
    int FHour;
    int FMin;

	 TStorageList *FStorList;
    TRad *FRadArr[RAD_COUNT];
    TWs2300 *FWs;
    TCirc *FCirc;
	TVp *FVp;
};


#endif
