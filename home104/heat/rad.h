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
# rad.h
# Radiator class
#
########################################################################*/

#ifndef RAD_H
#define RAD_H

#include "device.h"
#include "log.h"

struct TRadLog
{
    int Valid;
    int Ref;
    int Temp;
    int Motor;
    int Light;
    int AuxTemp;
};

class TRad : public TDevice
{
public:
	TRad(int Address, int Row, TLog *Log);

	void DeviceName(char *Name, int Size) const;

    int Ref;
    int Temp;
    int Motor;
    int Light;
    int AuxTemp;
    
protected:
    void ClearAcc();
	virtual void Execute();

	int FAddress;
	int FRow;
	TLog *FLog;
	TFile *FLogFile;

	int FYear;
	int FMonth;
	int FDay;
	int FHour;
	int FMin;

	int FRefSum;
	int FRefCount;
	int FTempSum;
	int FTempCount;
	int FMotorSum;
	int FMotorCount;
	int FLightSum;
	int FLightCount;
	int FAuxTempSum;
	int FAuxTempCount;

};

#endif
