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
# yearsamp.cpp
# Year basis sampling class
#
########################################################################*/

#include "yearsamp.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TYearSample::TYearSample
#
#   Purpose....: Constructor for year sampling
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TYearSample::TYearSample(int index, const char *unit)
  : TSample(index, unit)
{
    FPrevYear = -1;
}

/*##########################################################################
#
#   Name       : TYearSample::~TYearSample
#
#   Purpose....: Destructor for year sampling
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TYearSample::~TYearSample()
{
}

/*##########################################################################
#
#   Name       : TYearSample::Add
#
#   Purpose....: Add a new sample
#
#   In params..: time       sample time
#                value      sample value
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TYearSample::Add(TDateTime *time, long double value)
{
    int ok;

    ok = time->GetYear() == FPrevYear;

    if (!ok)
    {
		Clear();
        FPrevYear = time->GetYear();
    }
    
    TSample::Add(time, value);
}
