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
	FMax = 0.0;
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
int THeat::IsStartedEP()
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
void THeat::StartEP()
{
	if (!IsStartedEP())
		RdosToggleDigitalLine(1, 6);
}

/*##########################################################################
#
#   Name       : THeat::StopEP
#
#   Purpose....: Stop EP (elpatron)
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::StopEP()
{
	if (IsStartedEP())
		RdosToggleDigitalLine(1, 6);
}

/*##########################################################################
#
#   Name       : THeat::IsStartedVP
#
#   Purpose....: Check if started VP (v„rmepump)
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THeat::IsStartedVP()
{
	if (FStat & 0x20)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : THeat::StartVP
#
#   Purpose....: Start VP (v„rmepump)
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::StartVP()
{
	if (!IsStartedVP())
		RdosToggleDigitalLine(1, 5);
}

/*##########################################################################
#
#   Name       : THeat::StopVP
#
#   Purpose....: Stop VP (v„rmepump)
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::StopVP()
{
	if (IsStartedVP())
		RdosToggleDigitalLine(1, 5);
}

/*##########################################################################
#
#   Name       : THeat::UpdateOff
#
#   Purpose....: Handle new sample in OFF state
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::UpdateOff(long double value)
{
	FMax = value;

	if (value < 42.5)
		StartVP();
}

/*##########################################################################
#
#   Name       : THeat::UpdateOn
#
#   Purpose....: Handle new sample in ON state
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::UpdateOn(long double value)
{
	if (value > FMax)
		FMax = value;

	if ((value < FMax - 2.0) || (value < 40.0))
		StartEP();

	if (value > 49.0)
	{
		StopVP();

		if (value > 55.0)
			StopEP();
		else
			StartEP();
	}
}

/*##########################################################################
#
#   Name       : THeat::NotifyBeforeClear
#
#   Purpose....: Handle samples
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::NotifyBeforeClear()
{
	TDateTime time;

	if (RdosReadDigital(1, &FStat))
	{
		RdosSetCursorPosition(12, 0);

		if ((FStat & 0x60) == 0)
			UpdateOff(GetMean(&time));
		else
			UpdateOn(GetMean(&time));
	}
	TSample::NotifyBeforeClear();
}

