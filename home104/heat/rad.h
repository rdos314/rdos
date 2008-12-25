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
#include "radcntrl.h"

class TRad : public TDevice
{
public:
	TRad(TRadControl *control, int rad, int Address);
	~TRad();

	void DeviceName(char *Name, int Size) const;

	void SetDayRef();
	void SetNightRef();
	void SetWinterRef();
	void SetRef(int Temp);
	void SetAmbient(int rel);

    int GetAddress();

    int GetRef();
    int GetTemp();
    int GetMotor();
    int GetLight();
    int GetAuxTemp();
            
protected:
	virtual void Execute();

    TRadControl *FControl;
    int FIndex;
	int FAddress;

	int FUpdateRefType;
	int FUpdateRef;
	int FUpdateAmbient;

    int Ref;
    int Temp;
    int Motor;
    int Light;
    int AuxTemp;
	int Ambient;
	int RefType;

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

	TSection FSection;

};

#endif
