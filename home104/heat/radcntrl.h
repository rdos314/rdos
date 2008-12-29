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
# radcntrl.h
# Radiator control class
#
########################################################################*/

#ifndef RADCNTRL_H
#define RADCNTRL_H

#include "control.h"

#define MAX_RAD_COUNT   10

class TRadControl : public TControl
{
public:
	TRadControl(TControlThread *dev, int xmin, int ymin, int width, int height);
	~TRadControl();

    void Define(int rad, const char *name);

	void SetRef(int rad);
	void SetRef(int rad, int val);

	void SetTemp(int rad);
	void SetTemp(int rad, int val);

	void SetMotor(int rad);
	void SetMotor(int rad, int val);

	void SetLight(int rad);
	void SetLight(int rad, int val);

	void SetAuxTemp(int rad);
	void SetAuxTemp(int rad, int val);

protected:
	virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);

    int FChangedName[MAX_RAD_COUNT];
    char *FName[MAX_RAD_COUNT];

    int FChangedRef[MAX_RAD_COUNT];
    int FHasRef[MAX_RAD_COUNT];
    int FRef[MAX_RAD_COUNT];

    int FChangedTemp[MAX_RAD_COUNT];
    int FHasTemp[MAX_RAD_COUNT];
    int FTemp[MAX_RAD_COUNT];

    int FChangedMotor[MAX_RAD_COUNT];
    int FHasMotor[MAX_RAD_COUNT];
    int FMotor[MAX_RAD_COUNT];    

    int FChangedLight[MAX_RAD_COUNT];
    int FHasLight[MAX_RAD_COUNT];
    int FLight[MAX_RAD_COUNT];

    int FChangedAuxTemp[MAX_RAD_COUNT];
    int FHasAuxTemp[MAX_RAD_COUNT];
    int FAuxTemp[MAX_RAD_COUNT];    

    TSection FSection;
};

#endif
