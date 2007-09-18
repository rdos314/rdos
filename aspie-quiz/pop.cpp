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
# pop.cpp
# Population class
#
########################################################################*/

#include <math.h>
#include "pop.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TPopulation::TPopulation
#
#   Purpose....: Constructor for TPopulation
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPopulation::TPopulation(int questions)
{
	int i,j;

    ValArr = 0;

    N = questions;

    ValueCount = 0;
    MaxSize = 0;

	for (i = 0; i < N; i++)
	{
		Count[i] = 0;
		Sum[i] = 0;
        for (j = 0; j < MAX_CATS; j++)
			ChiArr[i][j] = 0;
	}
}

/*##########################################################################
#
#   Name       : TPopulation::~TPopulation
#
#   Purpose....: Destructor for TPopulation
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPopulation::~TPopulation()
{
    if (ValArr)
        delete ValArr;
}

/*##########################################################################
#
#   Name       : TPopulation::Add
#
#   Purpose....: Add an answer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPopulation::Add(int AsScore, int NtScore, int As, char Arr[MAX_QUESTIONS], int GroupScore[8])
{
	 int val;
	 int i;
	 TValArr *NewArr;

	 if (ValArr == 0)
	 {
		  MaxSize = 8;
		  ValArr = new TValArr[MaxSize];
	 }

	 if (ValueCount >= MaxSize)
	 {
		  MaxSize = 3 * MaxSize / 2;
		  NewArr = new TValArr[MaxSize];

		  for (i = 0; i < ValueCount; i++)
				NewArr[i] = ValArr[i];

		  delete ValArr;
		  ValArr = NewArr;
	 }

	 ValArr[ValueCount].As = As;
	 ValArr[ValueCount].AsScore = AsScore;
	 ValArr[ValueCount].NtScore = NtScore;
	 for (i = 0; i < N; i++)
	 {
		val = Arr[i];
		ValArr[ValueCount].Quiz[i] = val;
		if (val)
		{
		    val--;
			ChiArr[i][val]++;
			Sum[i] += val;
			Count[i]++;
		}
	 }

	 for (i = 0; i < 8; i++)
	    ValArr[ValueCount].GroupScore[i] = GroupScore[i];

	 ValueCount++;
}

/*##########################################################################
#
#   Name       : TPopulation::Add
#
#   Purpose....: Add an answer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPopulation::Add(int Score, char Arr[MAX_QUESTIONS])
{
	 int val;
	 int i;
	 TValArr *NewArr;

	 if (ValArr == 0)
	 {
		  MaxSize = 8;
		  ValArr = new TValArr[MaxSize];
	 }

	 if (ValueCount >= MaxSize)
	 {
		  MaxSize = 3 * MaxSize / 2;
		  NewArr = new TValArr[MaxSize];

		  for (i = 0; i < ValueCount; i++)
				NewArr[i] = ValArr[i];

		  delete ValArr;
		  ValArr = NewArr;
	 }

	 ValArr[ValueCount].As = FALSE;
	 ValArr[ValueCount].AsScore = Score;
	 ValArr[ValueCount].NtScore = 0;
	 
	 for (i = 0; i < N; i++)
	 {
		val = Arr[i];
		ValArr[ValueCount].Quiz[i] = val;
		if (val)
		{
		    val--;
			ChiArr[i][val]++;
			Sum[i] += val;
			Count[i]++;
		}
	 }

	 for (i = 0; i < 8; i++)
	    ValArr[ValueCount].GroupScore[i] = 0;

	 ValueCount++;
}

/*##########################################################################
#
#   Name       : TPopulation::GetMean
#
#   Purpose....: Get mean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TPopulation::GetMean(int QuestionNr)
{
    if (QuestionNr >= 0 && QuestionNr < N)
    {
        if (Count[QuestionNr])
            return (long double)Sum[QuestionNr] / Count[QuestionNr];
        else
            return 0;
    }
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TPopulation::GetSd
#
#   Purpose....: Get standard deviation
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TPopulation::GetSd(int QuestionNr)
{
    int e;
    int ival;
	long double val;
	long double rsum = 0;
	long double mean = GetMean(QuestionNr);
	int count;

	if (QuestionNr >= 0 && QuestionNr < N)
	{
        count = 0;
            
    	for (e = 0; e < ValueCount; e++)
    	{
    	    ival = ValArr[e].Quiz[QuestionNr];
            if (ival)
            {
                count++;
                ival--;
    	    	val = (long double)ival - mean;
        	    rsum += val * val;
        	}
    	}
    	
        if (count > 1)
            return sqrtl(rsum / ((long double)count - 1));
        else
            return 0;
    }
    else
        return 0;
}
