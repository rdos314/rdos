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
# dsmpop.cpp
# DSM-based population class
#
########################################################################*/

#include <math.h>
#include "dsmpop.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TDsmPopulation::TDsmPopulation
#
#   Purpose....: Constructor for TDsmPopulation
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDsmPopulation::TDsmPopulation()
{
	int i;

    for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
    {
		NoCat[i].ValueCount = 0;
		NoCat[i].MaxSize = 0;
		NoCat[i].DataArr = 0;

		SelfCat[i].ValueCount = 0;
		SelfCat[i].MaxSize = 0;
		SelfCat[i].DataArr = 0;

		DxCat[i].ValueCount = 0;
        DxCat[i].MaxSize = 0;
        DxCat[i].DataArr = 0;
    }        

}

/*##########################################################################
#
#   Name       : TDsmPopulation::~TDsmPopulation
#
#   Purpose....: Destructor for TDsmPopulation
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDsmPopulation::~TDsmPopulation()
{
    int i;

    for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
    {
        if (NoCat[i].DataArr)
            delete NoCat[i].DataArr;
            
        if (SelfCat[i].DataArr)
            delete SelfCat[i].DataArr;
            
        if (DxCat[i].DataArr)
            delete DxCat[i].DataArr;
    }            
}

/*##########################################################################
#
#   Name       : TDsmPopulation::AddNo
#
#   Purpose....: Add answer to no-dx category
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDsmPopulation::AddNo(int GlobalId, char score)
{
    TDsmElem *elem;
	int i;
	char *NewArr;

    if (GlobalId >= 0 && GlobalId < MAX_GLOBAL_QUESTIONS)
    {
        elem = &NoCat[GlobalId];
    
        if (elem->DataArr == 0)
	    {
		    elem->MaxSize = 8;
		    elem->DataArr = new char[elem->MaxSize];
	    }

	    if (elem->ValueCount >= elem->MaxSize)
	    {
		    elem->MaxSize = 3 * elem->MaxSize / 2;
		    NewArr = new char[elem->MaxSize];

		    for (i = 0; i < elem->ValueCount; i++)
			    NewArr[i] = elem->DataArr[i];

	        delete elem->DataArr;
	        elem->DataArr = NewArr;
	    }
	    
        elem->DataArr[elem->ValueCount] = score;
	    elem->ValueCount++;
	}
}

/*##########################################################################
#
#   Name       : TDsmPopulation::AddSelf
#
#   Purpose....: Add answer to self-dx category
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDsmPopulation::AddSelf(int GlobalId, char score)
{
	TDsmElem *elem;
	int i;
	char *NewArr;

    if (GlobalId >= 0 && GlobalId < MAX_GLOBAL_QUESTIONS)
    {
        elem = &SelfCat[GlobalId];
    
        if (elem->DataArr == 0)
	    {
		    elem->MaxSize = 8;
			elem->DataArr = new char[elem->MaxSize];
		}

	    if (elem->ValueCount >= elem->MaxSize)
	    {
		    elem->MaxSize = 3 * elem->MaxSize / 2;
		    NewArr = new char[elem->MaxSize];

		    for (i = 0; i < elem->ValueCount; i++)
			    NewArr[i] = elem->DataArr[i];

	        delete elem->DataArr;
	        elem->DataArr = NewArr;
	    }
	    
        elem->DataArr[elem->ValueCount] = score;
	    elem->ValueCount++;
	}
}

/*##########################################################################
#
#   Name       : TDsmPopulation::AddDx
#
#   Purpose....: Add answer to professional-dx category
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDsmPopulation::AddDx(int GlobalId, char score)
{
	TDsmElem *elem;
	int i;
	char *NewArr;

	if (GlobalId >= 0 && GlobalId < MAX_GLOBAL_QUESTIONS)
	{
		elem = &DxCat[GlobalId];

		if (elem->DataArr == 0)
		{
			elem->MaxSize = 8;
			elem->DataArr = new char[elem->MaxSize];
	    }

	    if (elem->ValueCount >= elem->MaxSize)
	    {
		    elem->MaxSize = 3 * elem->MaxSize / 2;
		    NewArr = new char[elem->MaxSize];

		    for (i = 0; i < elem->ValueCount; i++)
			    NewArr[i] = elem->DataArr[i];

	        delete elem->DataArr;
	        elem->DataArr = NewArr;
	    }
	    
        elem->DataArr[elem->ValueCount] = score;
	    elem->ValueCount++;
	}
}

/*##########################################################################
#
#   Name       : TDsmPopulation::Add
#
#   Purpose....: Add answer to given category
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDsmPopulation::Add(int cat, int GlobalId, char score)
{
    switch (cat)
    {
        case 0:
            AddNo(GlobalId, score);
            break;

        case 1:
            AddSelf(GlobalId, score);
            break;

        case 2:
            AddDx(GlobalId, score);
            break;
    }
}

/*##########################################################################
#
#   Name       : TDsmPopulation::Correlate
#
#   Purpose....: Correlate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDsmPopulation::Correlate()
{
    TDsmElem *elem;
    char score;
	int i, j;
	int e;
	int count;
	int sum;
	long double mean;
	long double sd;
	long double val;
	long double rsum;
	long double zx;
	long double zy;
	long double cmean;
	long double csd;

	for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
	{
	    count = 0;
		sum = 0;

		elem = &NoCat[i];

		for (e = 0; e < elem->ValueCount; e++)
		{
		    score = elem->DataArr[e];
		    count++;
    	    sum += score;
    	}

		elem = &SelfCat[i];

		for (e = 0; e < elem->ValueCount; e++)
		{
		    score = elem->DataArr[e];
		    count++;
    	    sum += score;
    	}
		elem = &DxCat[i];

		for (e = 0; e < elem->ValueCount; e++)
		{
		    score = elem->DataArr[e];
		    count++;
    	    sum += score;
    	}

		if (count > 1)
        {
    		mean = (long double)sum / ((long double)count);

    		rsum = 0;

    		elem = &NoCat[i];
    
	    	for (e = 0; e < elem->ValueCount; e++)
		    {
    		    score = elem->DataArr[e];
    			val = (long double)score - mean;
        		rsum += val * val;
        	}

    		elem = &SelfCat[i];
    
	    	for (e = 0; e < elem->ValueCount; e++)
		    {
    		    score = elem->DataArr[e];
    			val = (long double)score - mean;
        		rsum += val * val;
        	}

    		elem = &DxCat[i];
    
	    	for (e = 0; e < elem->ValueCount; e++)
		    {
    		    score = elem->DataArr[e];
    			val = (long double)score - mean;
        		rsum += val * val;
        	}

			sd = sqrtl(rsum / ((long double)count - 1));

        	cmean = (long double)(2 * DxCat[i].ValueCount + SelfCat[i].ValueCount) / ((long double)count);

            val = 2.0 - cmean;
            rsum = (long double)(DxCat[i].ValueCount * val * val);

            val = 1.0 - cmean;
            rsum += (long double)(SelfCat[i].ValueCount * val * val);

            val = 0.0 - cmean;
            rsum += (long double)(NoCat[i].ValueCount * val * val);

    	    csd = sqrtl(rsum / ((long double)count - 1));

    		rsum = 0;

			if (csd == 0 || sd == 0)
        		Corr[i] = 1.0;
            else
    		{
    	    	zx = (2.0 - cmean) / csd;
        		elem = &DxCat[i];
    
	        	for (e = 0; e < elem->ValueCount; e++)
		        {
        		    score = elem->DataArr[e];
					zy = ((long double)score - mean) / sd;
					rsum += zx * zy;
				}


				zx = (1.0 - cmean) / csd;
				elem = &SelfCat[i];

				for (e = 0; e < elem->ValueCount; e++)
				{
					score = elem->DataArr[e];
					zy = ((long double)score - mean) / sd;
					rsum += zx * zy;
				}


				zx = (0.0 - cmean) / csd;
				elem = &NoCat[i];

				for (e = 0; e < elem->ValueCount; e++)
				{
					score = elem->DataArr[e];
					zy = ((long double)score - mean) / sd;
					rsum += zx * zy;
				}

				Corr[i] = rsum / ((long double)count - 1);
			}
		}
		else
			Corr[i] = 0.0;
	}

	Sort();
}

/*##########################################################################
#
#   Name       : TDsmPopulation::Sort
#
#   Purpose....: Sort correlations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDsmPopulation::Sort()
{
	int i, j;
	int e;
	long double val;
    long double temp;

	for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
		IndArr[i] = i;

	for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
	{
		val = Corr[IndArr[i]];
		val = val * val;

		for (j = i + 1; j < MAX_GLOBAL_QUESTIONS; j++)
		{
		    temp = Corr[IndArr[j]];
			if (temp * temp > val)
			{
				e = IndArr[j];
				IndArr[j] = IndArr[i];
				IndArr[i] = e;
				val = Corr[e];
				val = val * val;
			}
		}
	}
}
