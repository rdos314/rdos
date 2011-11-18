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
# Midset.cpp
# Mid, linear fuzzy set class
#
########################################################################*/

#include "midset.h"

/*##########################################################################
#
#   Name       : TMidFuzzySet::TMidFuzzySet
#
#   Purpose....: Constructor for mid fuzzy set
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMidFuzzySet::TMidFuzzySet(long double Low, long double Mid, long double High)
{
    FLow = Low;
    FMid = Mid;
    FHigh = High;
    FLowSlope = 1.0 / (Mid - Low);
    FHighSlope = 1.0 / (High - Mid);
}

/*##########################################################################
#
#   Name       : TMidFuzzySet::~TMidFuzzySet
#
#   Purpose....: Destructor for mid fuzzy set
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMidFuzzySet::~TMidFuzzySet()
{
}

/*##########################################################################
#
#   Name       : TMidFuzzySet::GetValue
#
#   Purpose....: Get value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TMidFuzzySet::GetValue(long double val)
{
    if (val <= FLow)
        return 0.0;
    else
    {
        if (val >= FHigh)
            return 0.0;
        else
        {
            if (val >= FMid)
                return 1.0 - (val - FMid) * FHighSlope;
            else
                return 1.0 - (FMid - val) * FLowSlope;
        }
    }
}

/*##########################################################################
#
#   Name       : TMidFuzzySet::GetCenter
#
#   Purpose....: Get center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TMidFuzzySet::GetCenter()
{
    return FMid;
}
