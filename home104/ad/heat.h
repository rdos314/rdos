/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# heat.h
# Heat class
#
########################################################################*/

#ifndef _HEAT_H
#define _HEAT_H

#include "minsamp.h"
#include "datetime.h"
#include "device.h"

class THeat : public TDevice
{
public:
	THeat();
	virtual ~THeat();

	virtual void DeviceName(char *Name, int MaxLen) const;

	void StartHeat();
	void StopHeat();
	void UpdateEp(long double value);

	void SetEpLimit(long double limit);
	void EnableEpTop();
	void DisableEpTop();

	void StartCirc();
	void StopCirc();
	int IsCircStarted();
	void WriteCircValve(long double value);
	long double ReadCircValve();

	int IsEpStarted();
	int IsVpStarted();
	long double ReadEpValve();
	long double ReadVpValve();

protected:
	void ToggleCircLine();
	void ToggleEpLine();
	void ToggleVpLine();
	void WriteEpValve(int value);
	void WriteVpValve(int value);

	void UpdateHeat();
	void Update();
	virtual void Execute();

private:
	void StartEp();
	void StopEp();
	void StartVp();
	void StopVp();

	int FStarted;
	int FStat;
	long double FEpTemp;
	int FUpdate;
	int FCircValve;
	int FEpValve;
	int FVpValve;
	int FHeatOn;
	int FEpPending;
	int FEpStart;
	int FCircOn;
	int FEpTopEnabled;
	long double FEpLimit;
};

#endif

