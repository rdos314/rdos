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
# popcorr.cpp
# Population correlation class
#
########################################################################*/

#include <math.h>
#include "popcorr.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TPopulationCorrelation::TPopulationCorrelation
#
#   Purpose....: Constructor for TPopulationCorrelation
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPopulationCorrelation::TPopulationCorrelation()
{
	int i;

	for (i = 0; i < MAX_QUESTIONS; i++)
	{
	    mean[i] = 0;
	    sd[i] = 0;
	    corr[i] = 0;
	    chi2[i] = 0;
	}
}

/*##########################################################################
#
#   Name       : TPopulationCorrelation::~TPopulationCorrelation
#
#   Purpose....: Destructor for TPopulationCorrelation
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPopulationCorrelation::~TPopulationCorrelation()
{
}

/*##########################################################################
#
#   Name       : TPopulationCorrelation::Correlate
#
#   Purpose....: Correlate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPopulationCorrelation::Correlate(TPopulation *pop1, TPopulation *pop2)
{
	int i, j;
	int e;
	int count;
	int sum;
	int ival;
	long double val;
	long double rsum;
	long double zx;
	long double zy;
	long double exp;
	long double cmean;
	long double csd;

	for (i = 0; i < MAX_QUESTIONS; i++)
	{
	    count = 0;
		sum = 0;
		for (e = 0; e < pop1->ValueCount; e++)
		{
		    ival = pop1->ValArr[e].Quiz[i];
		    if (ival)
		    {
		        count++;
		        ival--;
    			sum += ival;
    	    }
    	}

		for (e = 0; e < pop2->ValueCount; e++)
		{
		    ival = pop2->ValArr[e].Quiz[i];
		    if (ival)
		    {
		        count++;
		        ival--;
    			sum += ival;
    	    }
    	}

    	if (count > 1)
        {
    		mean[i] = (long double)sum / ((long double)count);

	    	rsum = 0;
		    for (e = 0; e < pop1->ValueCount; e++)
		    {
    		    ival = pop1->ValArr[e].Quiz[i];
	    	    if (ival)
		        {
		            ival--;
    			    val = (long double)ival - mean[i];
        			rsum += val * val;
		        }
		    }

    		for (e = 0; e < pop2->ValueCount; e++)
	    	{
    		    ival = pop2->ValArr[e].Quiz[i];
	    	    if (ival)
		        {
		            ival--;
        			val = (long double)ival - mean[i];
        			rsum += val * val;
        	    }
    		}

    		sd[i] = sqrtl(rsum / ((long double)count - 1));

        	cmean = (long double)pop1->Count[i] / ((long double)count);

        	val = 1.0 - cmean;
	        rsum = (long double)pop1->Count[i] * val * val;

    	    val = cmean;
		    rsum += (long double)pop2->Count[i] * val * val;

    	    csd = sqrtl(rsum / ((long double)count - 1));

    		rsum = 0;

    		if (csd == 0 || sd[i] == 0)
        		corr[i] = 1.0;
            else
    		{
    	    	zx = (1.0 - cmean) / csd;
	    	    for (e = 0; e < pop1->ValueCount; e++)
    	    	{
    		        ival = pop1->ValArr[e].Quiz[i];
    	    	    if (ival)
	    	        {
		                ival--;
        	    		zy = ((long double)ival - mean[i]) / sd[i];
        		    	rsum += zx * zy;
    		        }
	    	    }
    
        		zx = (0.0 - cmean) / csd;
	        	for (e = 0; e < pop2->ValueCount; e++)
		        {
        		    ival = pop2->ValArr[e].Quiz[i];
	        	    if (ival)
		            {
		                ival--;
        		    	zy = ((long double)ival - mean[i]) / sd[i];
            			rsum += zx * zy;
	    	        }
		        }
        		corr[i] = rsum / ((long double)count - 1);

		    }

    		rsum = 0;

	    	for (j = 0; j < 3; j++)
		    {
    			exp = (long double)pop2->ChiArr[i][j] * (long double)pop1->Count[i] / (long double)pop2->Count[i];
	    		if (exp >= 5.0)
		    	{
			    	val = (long double)pop1->ChiArr[i][j] - exp;
				    rsum += val * val / exp;
			    }
		    }

    		chi2[i] = rsum;
	    }
	    else
	    {
	        mean[i] = 0;
	        sd[i] = 0;
	        corr[i] = 0;
	        chi2[i] = 0;
	    }
	}
}

/*##########################################################################
#
#   Name       : TPopulationCorrelation::Sort
#
#   Purpose....: Sort correlations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPopulationCorrelation::Sort()
{
	int i, j;
	int e;
	long double val;

	for (i = 0; i < MAX_QUESTIONS; i++)
		IndArr[i] = i;

	for (i = 0; i < MAX_QUESTIONS; i++)
	{
		val = corr[IndArr[i]];

		for (j = i + 1; j < MAX_QUESTIONS; j++)
		{
			if (corr[IndArr[j]] > val)
			{
				e = IndArr[j];
				IndArr[j] = IndArr[i];
				IndArr[i] = e;
				val = corr[e];
			}
		}
	}
}
