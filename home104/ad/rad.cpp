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
# rad.cpp
# Radiator class
#
########################################################################*/

#include <stdio.h>
#include <string.h>

#include "datetime.h"
#include "rdos.h"
#include "rad.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TRadiator::TRadiator
#
#   Purpose....: Constructor for radiator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRadiator::TRadiator(int channel)
{
	char str[40];

	FChannel = channel;
	FUpdateRef = FALSE;
	FUpdateInten = FALSE;
	FUpdateAmbient = FALSE;
	FInten = 50.0;
	FAmbient = 20.0;
	FRef = 20.0;
	FTemp = 20.0;
	FMotor = 0.0;

	sprintf(str, "RAD %d", channel);

	Start(str, 0x2000);
}

/*##########################################################################
#
#   Name       : TRadiator::~TRadiator
#
#   Purpose....: Destructor for radiator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRadiator::~TRadiator()
{
}

/*##########################################################################
#
#   Name       : TRadiator::DeviceName
#
#   Purpose....: Device name
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadiator::DeviceName(char *Name, int MaxLen) const
{
	char str[40];

	sprintf(str, "RAD %d", FChannel);
	strncpy(Name, str, MaxLen);
}

/*##########################################################################
#
#   Name       : TRadiator::SetRef
#
#   Purpose....: Set reference temperature
#
#   Out params.: Reference temperature
#   Returns....: *
#
##########################################################################*/
void TRadiator::SetRef(long double Temp)
{
	FRef = Temp;
	FUpdateRef = TRUE;
}

/*##########################################################################
#
#   Name       : TRadiator::SetIntensity
#
#   Purpose....: Set relative display intensity
#
#   Out params.: % of maximal brightness
#   Returns....: *
#
##########################################################################*/
void TRadiator::SetIntensity(long double rel)
{
	FInten = rel;
	FUpdateInten = TRUE;
}

/*##########################################################################
#
#   Name       : TRadiator::SetAmbient
#
#   Purpose....: Set ambient (outdoor) temperature
#
#   Out params.: ambient temperature
#   Returns....: *
#
##########################################################################*/
void TRadiator::SetAmbient(long double temp)
{
	FAmbient = temp;
	FUpdateAmbient = TRUE;
}

/*##########################################################################
#
#   Name       : TRadiator::GetRef
#
#   Purpose....: Get reference temperature
#
#   Out params.: *
#   Returns....: Reference temperature
#
##########################################################################*/
long double TRadiator::GetRef()
{
	return FRef;
}

/*##########################################################################
#
#   Name       : TRadiator::GetTemp
#
#   Purpose....: Get current temperature
#
#   Out params.: *
#   Returns....: Current temperature
#
##########################################################################*/
long double TRadiator::GetTemp()
{
	return FTemp;
}

/*##########################################################################
#
#   Name       : TRadiator::GetMotor
#
#   Purpose....: Get motor voltage (0..10.0)
#
#   Out params.: *
#   Returns....: Current motor voltage
#
##########################################################################*/
long double TRadiator::GetMotor()
{
	return FMotor;
}

/*##########################################################################
#
#   Name       : TRadiator::GetSettings
#
#   Purpose....: Get current settings
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadiator::GetSettings()
{
	int ok;
	int val;

	ok = TRUE;

	if (RdosReadSerialVal(FChannel, 1, &val))
	{
		val = val >> 23;
		FTemp = (long double)val / 10.0;
	}
	else
		ok = FALSE;

	if (RdosReadSerialVal(FChannel, 2, &val))
	{
		val = val >> 23;
		FMotor = (long double)val / 25.0;
	}
	else
		ok = FALSE;

	if (ok)
		Online();
	else
		Offline();
}

/*##########################################################################
#
#   Name       : TRadiator::Execute
#
#   Purpose....: Thread for updating devices
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadiator::Execute()
{
	TDateTime *RunUntil;
	int val;
	long double temp;

	Offline();

	RunUntil = new TDateTime;

	while (FInstalled)
	{
		if (FUpdateRef)
		{
			val = (int)(10.0 * FRef + 0.5);
			val = val << 23;			
			FUpdateRef = !RdosWriteSerialVal(FChannel, 0, val);
		}

		if (FUpdateInten)
		{
			val = (int)(FRef * 0.15 + 0.5);
			val = val << 27;
			FUpdateInten = !RdosWriteSerialVal(FChannel, 3, val);
		}

		if (FUpdateAmbient)
		{
			val = 127 + (int)(FAmbient - FRef);
			val = val << 23;
			FUpdateAmbient = !RdosWriteSerialVal(FChannel, 4, val);
		}

		if (RunUntil->HasExpired())
		{
			GetSettings();

			delete RunUntil;
			RunUntil = new TDateTime;
			if (IsOnline())
				RunUntil->AddMin(1);
			else
				RunUntil->AddSec(20);
		}

		RdosWaitMilli(5000);
	}
}
