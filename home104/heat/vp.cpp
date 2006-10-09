/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# vp.h
# Heat pump class
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "vp.h"
#include "lowset.h"
#include "midset.h"
#include "highset.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TVp::TVp
#
#   Purpose....: VP constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVp::TVp(TCirc *Circ)
{
    int i, j;
    int SetArr[MAX_FUZZY_VARS];
	int RuleArr[5][3] =
                {
                    {0, 0, 1},
                    {0, 1, 1},
                    {0, 1, 2},
                    {1, 1, 2},
                    {1, 2, 2},
				};

    FCirc = Circ;
    
    FMotorVar.Add(0, new TLowFuzzySet(2.5, 5.0));
    FMotorVar.Add(1, new TMidFuzzySet(2.5, 5.0, 7.5));
    FMotorVar.Add(2, new THighFuzzySet(5.0, 7.5));
    AddInput(0, &FMotorVar);

    FMotorDiffVar.Add(0, new TLowFuzzySet(-0.4, -0.2));
    FMotorDiffVar.Add(1, new TMidFuzzySet(-0.4, -0.2, 0.0));
    FMotorDiffVar.Add(2, new TMidFuzzySet(-0.2, 0.0, 0.2));
    FMotorDiffVar.Add(3, new TMidFuzzySet(0.0, 0.2, 0.4));
    FMotorDiffVar.Add(4, new THighFuzzySet(0.2, 0.4)); 
    AddInput(1, &FMotorDiffVar);

    FOutputVar.Add(0, new TLowFuzzySet(0.0, 0.5));
    FOutputVar.Add(1, new TMidFuzzySet(0.0, 0.5, 1.0));
    FOutputVar.Add(2, new THighFuzzySet(0.5, 1.0));
    AddOutput(&FOutputVar);

    for (i = 0; i < 5; i++)
    {
		for (j = 0; j < 3; j++)
        {
            SetArr[0] = j;
            SetArr[1] = i;
            DefineRule(SetArr, RuleArr[i][j]);
        }
    }

	Start("Vp", 0x2000);
}

/*##########################################################################
#
#   Name       : TVp::~TVp
#
#   Purpose....: Circulation pump destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVp::~TVp()
{
}

/*##########################################################################
#
#   Name       : TVp::DeviceName
#
#   Purpose....: Device name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::DeviceName(char *Name, int Size) const
{
	strcpy(Name, "VP");
}

/*##########################################################################
#
#   Name       : TVp::IsOn
#
#   Purpose....: Is on?
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::IsOn()
{
    return FOn;
}

/*##########################################################################
#
#   Name       : TVp::Execute
#
#   Purpose....: Handler thread
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::Execute()
{
	int year, month, day;
	int hour, min, sec;
	int ms;
    int i;
	int LastMin;
	long double ValArr[MAX_FUZZY_VARS];
	long double LastSpeed;
	long double Speed;
	long double SpeedSum;
	long double DiffSum;
	int Count;
	long double val;
	int diostat;

	for (i = 0; i < MAX_FUZZY_VARS; i++)
		ValArr[i] = 0.0;

    while (!RdosReadSerialLines(1, &diostat))
        RdosWaitMilli(250);

	if (diostat & 0x20)
	    FOn = TRUE;
	else
	    FOn = FALSE;

	LastSpeed = FCirc->GetSpeed();
	SpeedSum = 0;
	DiffSum = 0;
	Count = 0;

	RdosGetTime(&year, &month, &day, &hour, &LastMin, &sec, &ms);

	while (FInstalled)
	{
		RdosGetTime(&year, &month, &day, &hour, &min, &sec, &ms);

		if (min != LastMin)
		{
			LastMin = min;

			Speed = FCirc->GetSpeed();

            SpeedSum += Speed;
            DiffSum += Speed - LastSpeed;
            Count++;

            LastSpeed = Speed;

            if (min % 15 == 0 && Count)
            {
                ValArr[0] = SpeedSum / (long double)Count;
                ValArr[1] = DiffSum / (long double)Count;
    
	    		SpeedSum = 0;
			    DiffSum = 0;
			    Count = 0;

    			val = Calc(ValArr);

    			if (val < 0.25 && FOn)
    			    FOn = FALSE;

    			if (val > 0.75 && !FOn)
    			    FOn = TRUE;
    
    	    	RdosSetCursorPosition(17,0);
        		printf("%6.2Lf", val);

            }

            if (RdosReadSerialLines(1, &diostat))
            {
            	if (diostat & 0x20)
            	{
            	    if (!FOn)
            	        RdosToggleSerialLine(1, 5);
            	}
            	else
            	{
            	    if (FOn)
            	        RdosToggleSerialLine(1, 5);
            	}
            }
		}

		RdosWaitMilli(1000);
	}
}
