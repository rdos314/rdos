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
#   Name       : THeat::StartEP
#
#   Purpose....: Start EP
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::StartEP()
{
	if (FStat & 0x40)
		RdosToggleDigitalLine(1, 6);
}

/*##########################################################################
#
#   Name       : THeat::StopEP
#
#   Purpose....: Stop EP
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::StopEP()
{
	if ((FStat & 0x40) == 0)
		RdosToggleDigitalLine(1, 6);
}

/*##########################################################################
#
#   Name       : THeat::StartVP
#
#   Purpose....: Start VP
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::StartVP()
{
	if (FStat & 0x20)
		RdosToggleDigitalLine(1, 5);
}

/*##########################################################################
#
#   Name       : THeat::StopVP
#
#   Purpose....: Stop VP
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeat::StopVP()
{
	if ((FStat & 0x20) == 0)
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

	if (value < 42.0)
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

	if (value < FMax - 2.0)
		StartEP();

	if (value > 55.0)
	{
		StopEP();
		StopVP();
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
		if ((FStat & 0x60) == 0)
			UpdateOff(GetMean(&time));
		else
			UpdateOn(GetMean(&time));
	}
    TSample::NotifyBeforeClear();
}
