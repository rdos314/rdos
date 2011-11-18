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

#define FALSE   0
#define TRUE    !FALSE

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
	int i;

	for (i = 0; i < MAX_FUZZY_SETS; i++)
		FSetArr[i] = 0;
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

	for (i = 0; i < MAX_FUZZY_SETS; i++)
		if (FSetArr[i])
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
void TFuzzyVar::Add(int index, TFuzzyBaseSet *set)
{
    if (index < 0 || index >= MAX_FUZZY_SETS)
        delete set;
    else
    {
        if (FSetArr[index])
            delete FSetArr[index];

        FSetArr[index] = set;
    }
}

/*##########################################################################
#
#   Name       : TFuzzyVar::HasSet
#
#   Purpose....: Check if set is defined
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFuzzyVar::HasSet(int index)
{
    if (index < 0 || index >= MAX_FUZZY_SETS)
        return FALSE;
    else
    {
        if (FSetArr[index])
            return TRUE;
        else
            return FALSE;
    }
}

/*##########################################################################
#
#   Name       : TFuzzyVar::GetSets
#
#   Purpose....: Get number of active sets
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFuzzyVar::GetSets()
{
    int i;
    int count = 0;

    for (i = 0; i < MAX_FUZZY_SETS; i++)
        if (FSetArr[i])
            count++;

    return count;
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
#   Name       : TFuzzyVar::GetCenter
#
#   Purpose....: Get center for a set
#
#   In params..: Set #
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TFuzzyVar::GetCenter(int index)
{
	if (index < 0 || index >= MAX_FUZZY_SETS)
		return 0.0;
	else
	{
		if (FSetArr[index])
			return FSetArr[index]->GetCenter();
		else
			return 0.0;
	}
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
	if (index < 0 || index >= MAX_FUZZY_SETS)
		return 0.0;
	else
	{
		if (FSetArr[index])
			return FSetArr[index]->GetValue(FVal);
		else
			return 0.0;
	}
}

