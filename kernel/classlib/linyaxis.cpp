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
# linyaxis.cpp
# Linear y-axis class
#
########################################################################*/

#include "linyaxis.h"

#define     FALSE	0
#define     TRUE	!FALSE

/*##########################################################################
#
#   Name       : TLinYAxis::TLinYAxis
#
#   Purpose....: Constructor for TLinYAxis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLinYAxis::TLinYAxis(TFont *Font)
{
	FFont = Font;
}

/*##########################################################################
#
#   Name       : TLinYAxis::~TLinYAxis
#
#   Purpose....: Destructor for TLinYAxis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLinYAxis::~TLinYAxis()
{
}

/*##########################################################################
#
#   Name       : TLinYAxis::PhysToLog
#
#   Purpose....: Convert value to logical coordinate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TLinYAxis::PhysToLog(long double val)
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
#   Name       : TLinYAxis::LogToPhys
#
#   Purpose....: Convert logical coordinate to value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TLinYAxis::LogToPhys(long double rel)
{
	long double range;

	range = FValMax - FValMin;
	return FValMin + range * rel;
}

/*##########################################################################
#
#   Name       : TLinYAxis::Draw
#
#   Purpose....: Draw axis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLinYAxis::Draw()
{
}
