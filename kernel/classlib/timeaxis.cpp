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
# timeaxis.cpp
# Time x-axis class
#
########################################################################*/

#include <stdio.h>

#include "timeaxis.h"

#define     FALSE	0
#define     TRUE	!FALSE

/*##########################################################################
#
#   Name       : TTimeXAxis::TTimeXAxis
#
#   Purpose....: Constructor for TTimeXAxis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTimeXAxis::TTimeXAxis(TFont *Font)
{
	FFont = Font;
	FScale = 0;
}

/*##########################################################################
#
#   Name       : TTimeXAxis::~TTimeXAxis
#
#   Purpose....: Destructor for TTimeXAxis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTimeXAxis::~TTimeXAxis()
{
}

/*##########################################################################
#
#   Name       : TTimeXAxis::PhysToLog
#
#   Purpose....: Convert value to logical coordinate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TTimeXAxis::PhysToLog(long double val)
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
#   Name       : TTimeXAxis::LogToPhys
#
#   Purpose....: Convert logical coordinate to value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TTimeXAxis::LogToPhys(long double rel)
{
	long double range;

	range = FValMax - FValMin;
	return FValMin + range * rel;
}

/*##########################################################################
#
#   Name       : TTimeXAxis::RequiredHeight
#
#   Purpose....: Get required height
#
#   In params..: *
#   Out params.: *
#   Returns....: Min pixels required
#
##########################################################################*/
int TTimeXAxis::RequiredHeight()
{
    int height;

    FFont->GetStringMetrics("-", &FScaleHeight, &height);

    if (FScaleHeight > 4)
        FScaleHeight = FScaleHeight / 2;

    return height + FScaleHeight + 2;
}

/*##########################################################################
#
#   Name       : TTimeXAxis::Draw
#
#   Purpose....: Draw axis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::Draw()
{
}
