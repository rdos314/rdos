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
# heat.cpp
# Heat class
#
########################################################################*/

#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "heat.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : THeat::THeat
#
#   Purpose....: Constructor for heat
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeat::THeat()
{
	FStat = 0;
	FStarted = FALSE;
	FUpdate = FALSE;
	FStartReq = FALSE;
	FStopReq = FALSE;
	FVpStopTime = 0;
	FEpPending = FALSE;
	FEpStart = FALSE;

	Start("HEAT", 0x2000);
}

/*##########################################################################
#
#   Name       : THeat::~THeat
#
#   Purpose....: Destructor for heat
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeat::~THeat()
{
	if (FVpStopTime)
		delete FVpStopTime;
}

/*##########################################################################
#
#   Name       : THeat::DeviceName
#
#   Purpose....: Device name
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::DeviceName(char *Name, int MaxLen) const
{
	strncpy(Name, "HEAT", MaxLen);
}

/*##########################################################################
#
#   Name       : THeat::ReadEpValve
#
#   Purpose....: Read voltage on EP valve
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double THeat::ReadEpValve()
{
	return (long double)FEpValve / 0x7FFFFFFF * 10.0;
}

/*##########################################################################
#
#   Name       : THeat::ReadVpValve
#
#   Purpose....: Read voltage on VP valve
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double THeat::ReadVpValve()
{
	return (long double)FVpValve / 0x7FFFFFFF * 10.0;
}

/*##########################################################################
#
#   Name       : THeat::ToggleVpLine
#
#   Purpose....: Toggle VP line
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::ToggleVpLine()
{
	RdosToggleSerialLine(1, 5);
}

/*##########################################################################
#
#   Name       : THeat::ToggleEpLine
#
#   Purpose....: Toggle EP line
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::ToggleEpLine()
{
	RdosToggleSerialLine(1, 6);
}

/*##########################################################################
#
#   Name       : THeat::WriteVpValve
#
#   Purpose....: Write VP valve
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::WriteVpValve(int value)
{
	RdosWriteSerialVal(2, 0, value);
}

/*##########################################################################
#
#   Name       : THeat::WriteEpValve
#
#   Purpose....: Write EP valve
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::WriteEpValve(int value)
{
	RdosWriteSerialVal(2, 1, value);
}

/*##########################################################################
#
#   Name       : THeat::StartHeat
#
#   Purpose....: Start (v„rmepump mot tank)
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::StartHeat(TDateTime &RunUntil)
{
	FStopReq = FALSE;

	if (FVpStopTime)
		delete FVpStopTime;
	FVpStopTime = new TDateTime(RunUntil);
		
	FStartReq = TRUE;
}

/*##########################################################################
#
#   Name       : THeat::UpdateStart
#
#   Purpose....: Update start
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::UpdateStart()
{
	if (FVpStopTime)
	{
		if (FVpStopTime->HasExpired())
			FStartReq = FALSE;
	}
	else
		FStartReq = FALSE;

	if (FStartReq)
	{
		if (FVpValve < 0x40000000)
		{
			if (IsVpStarted())
				FStartReq = FALSE;
			else
				ToggleVpLine();
		}
	}
}

/*##########################################################################
#
#   Name       : THeat::StopHeat
#
#   Purpose....: Stop (v„rmepump mot tank)
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::StopHeat()
{
	FStartReq = FALSE;
	if (FVpStopTime)
	{
		delete FVpStopTime;
		FVpStopTime = 0;
	}
	FStopReq = TRUE;
}

/*##########################################################################
#
#   Name       : THeat::UpdateStop
#
#   Purpose....: Update stop
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::UpdateStop()
{
	if (IsVpStarted())
		if (FVpValve < 0x40000000)
			ToggleVpLine();
}

/*##########################################################################
#
#   Name       : THeat::IsStartedEP
#
#   Purpose....: Check if started EP (elpatron)
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THeat::IsEpStarted()
{
	if (FStat & 0x40)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : THeat::StartEP
#
#   Purpose....: Start EP (elpatron)
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::StartEp()
{
	if (!IsEpStarted())
		ToggleEpLine();
}

/*##########################################################################
#
#   Name       : THeat::StopEp
#
#   Purpose....: Stop EP (elpatron)
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::StopEp()
{
	if (IsEpStarted())
		ToggleEpLine();
}

/*##########################################################################
#
#   Name       : THeat::IsVpStarted
#
#   Purpose....: Check if started VP (v„rmepump)
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THeat::IsVpStarted()
{
	if (FStat & 0x20)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : THeat::StartVp
#
#   Purpose....: Start VP (v„rmepump)
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::StartVp()
{
	if (!IsVpStarted())
		if (FVpValve > 0x40000000)
		{
			ToggleVpLine();
			if (FEpValve == 0)
				WriteEpValve(0x7FFFFFFF);
		}

	WriteVpValve(0x7FFFFFFF);
}

/*##########################################################################
#
#   Name       : THeat::StopVp
#
#   Purpose....: Stop VP (v„rmepump)
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::StopVp()
{
	WriteVpValve(0);
}

/*##########################################################################
#
#   Name       : THeat::UpdateEp
#
#   Purpose....: Update EP temp
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::UpdateEp(long double value)
{
	FUpdate = TRUE;
	FEpTemp = value;
}

/*##########################################################################
#
#   Name       : THeat::Update
#
#   Purpose....: Update min values after states have been read
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::Update()
{
	FUpdate = FALSE;

	if (FEpValve > 0x70000000)
		WriteEpValve(0);

	if (IsEpStarted())
		FEpPending = TRUE;

	if (FEpValve > 0x40000000)
		FEpPending = TRUE;

	if (FEpPending)
	{
		if (FEpTemp < 39.0)
			StartEp();

		if (FEpTemp > 47.0)
		{
			FEpStart = TRUE;

			if (FVpValve > 0x40000000)
			{
				if (FVpStopTime == 0)
				{
					FVpStopTime = new TDateTime;
					FVpStopTime->AddHour(1);
				}
				StopVp();
			}

			if (FEpTemp > 55.0)
			{
				FEpPending = FALSE;
				FEpStart = FALSE;
				StopEp();
			}
		}
		else
			StartVp();

		if (FEpStart)
			if (!IsVpStarted())
				StartEp();

	}
	else
	{
		if (FEpTemp < 42.0)
		{
			FEpPending = TRUE;
			StartVp();
		}
	}
}

/*##########################################################################
#
#   Name       : THeat::Execute
#
#   Purpose....: Thread for updating devices
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::Execute()
{
	int lines;
	int vp;
	int ep;

	while (FInstalled)
	{
		lines = RdosReadSerialLines(1, &FStat);
		vp = RdosReadSerialVal(2, 0, &FVpValve);
		ep = RdosReadSerialVal(2, 1, &FEpValve);

		if (lines && vp && ep)
		{
			if (FVpStopTime && FVpStopTime->HasExpired())
				StopHeat();

			if (FUpdate)
				Update();

			if (FStartReq)
				UpdateStart();

			if (FStopReq)
				UpdateStop();

			RdosWaitMilli(15000);

		}
		else
			RdosWaitMilli(1500);
	}
}
