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
# secsamp.cpp
# Second basis sampling class
#
########################################################################*/

#include "secsamp.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TSecSample::TSecSample
#
#   Purpose....: Constructor for second sampling
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSecSample::TSecSample()
{
    FPrevSec = -1;
    FPrevMin = -1;
    FPrevHour = -1;
    FPrevDay = -1;
    FPrevMonth = -1;
    FPrevYear = -1;
}

/*##########################################################################
#
#   Name       : TSecSample::~TSecSample
#
#   Purpose....: Destructor for second sampling
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSecSample::~TSecSample()
{
}

/*##########################################################################
#
#   Name       : TSecSample::Add
#
#   Purpose....: Add a new sample
#
#   In params..: time       sample time
#                value      sample value
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSecSample::Add(TDateTime *time, long double value)
{
    int ok;

    ok = time->GetYear() == FPrevYear;

    if (ok)
        ok = time->GetMonth() == FPrevMonth;

    if (ok)
        ok = time->GetDay() == FPrevDay;

    if (ok)
        ok = time->GetHour() == FPrevHour;

    if (ok)
        ok = time->GetMin() == FPrevMin;

    if (ok)
        ok = time->GetSec() == FPrevSec;

    if (!ok)
    {
		Clear();
        FPrevYear = time->GetYear();
        FPrevMonth = time->GetMonth();
        FPrevDay = time->GetDay();
        FPrevHour = time->GetHour();
        FPrevMin = time->GetMin();
        FPrevSec = time->GetSec();
    }
    
    TSample::Add(time, value);
}
