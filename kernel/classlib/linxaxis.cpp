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
# linxaxis.cpp
# Linear x-axis base class
#
########################################################################*/

#include "linxaxis.h"

#define     FALSE	0
#define     TRUE	!FALSE

/*##########################################################################
#
#   Name       : TLinXAxis::TLinXAxis
#
#   Purpose....: Constructor for TLinXAxis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLinXAxis::TLinXAxis(TFont *Font)
{
	FFont = Font;
}

/*##########################################################################
#
#   Name       : TLinXAxis::~TLinXAxis
#
#   Purpose....: Destructor for TLinXAxis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLinXAxis::~TLinXAxis()
{
}

/*##########################################################################
#
#   Name       : TLinXAxis::PhysToLog
#
#   Purpose....: Convert value to logical coordinate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TLinXAxis::PhysToLog(long double val)
{
	long double range;

	range = FValMax - FValMin;
	if (range)
		return (val - FValMin) / range;
	else
		return 0.0;
}

/*##########################################################################
#
#   Name       : TLinXAxis::LogToPhys
#
#   Purpose....: Convert logical coordinate to value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TLinXAxis::LogToPhys(long double rel)
{
	long double range;

	range = FValMax - FValMin;
	return FValMin + range * rel;
}

/*##########################################################################
#
#   Name       : TLinXAxis::Draw
#
#   Purpose....: Draw axis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLinXAxis::Draw()
{
}
