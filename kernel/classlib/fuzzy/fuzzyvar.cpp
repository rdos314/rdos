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
# fuzzyvar.cpp
# Fuzzy variable class
#
########################################################################*/

#include "fuzzyvar.h"

/*##########################################################################
#
#   Name       : TFuzzyVar::TFuzzyVar
#
#   Purpose....: Constructor for fuzzy variable
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFuzzyVar::TFuzzyVar()
{
    FCount = 0;
}

/*##########################################################################
#
#   Name       : TFuzzyVar::~TFuzzyVar
#
#   Purpose....: Destructor for fuzzy variable
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFuzzyVar::~TFuzzyVar()
{
    int i;

    for (i = 0; i < FCount; i++)
        delete FSetArr[i];
}

/*##########################################################################
#
#   Name       : TFuzzyVar::Add
#
#   Purpose....: Add new set
#
#   In params..: Set
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFuzzyVar::Add(TFuzzyBaseSet *set)
{
    if (FCount != MAX_SETS)
    {
        FSetArr[FCount] = set;
        FCount++;
    }
    else
        delete set;
}

/*##########################################################################
#
#   Name       : TFuzzyVar::SetInputValue
#
#   Purpose....: Set input value of sets
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFuzzyVar::SetInputValue(long double val)
{
    FVal = val;
}

/*##########################################################################
#
#   Name       : TFuzzyVar::GetSetCount
#
#   Purpose....: Get number of active sets
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFuzzyVar::GetSetCount()
{
    return FCount;
}

/*##########################################################################
#
#   Name       : TFuzzyVar::GetValue
#
#   Purpose....: Get value for a set
#
#   In params..: Set #
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TFuzzyVar::GetValue(int index)
{
    if (index < 0 || index >= FCount)
        return 0.0;
    else
        return FSetArr[index]->GetValue(FVal);
}
