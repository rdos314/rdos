/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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

