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
TVp::TVp(TGraphicDevice *dev)
{
	int i, j;
	int SetArr[MAX_FUZZY_VARS];
	int RuleArr[5][3] =
				{
					{3, 4, 4},
					{2, 3, 4},
					{2, 2, 2},
					{1, 1, 1},
					{0, 0, 0},
				};

	FMotorVar.Add(0, new TLowFuzzySet(25.0, 50.0));
	FMotorVar.Add(1, new TMidFuzzySet(25.0, 50.0, 75.0));
	FMotorVar.Add(2, new THighFuzzySet(50.0, 75.0));
	AddInput(0, &FMotorVar);

	FTempDiffVar.Add(0, new TLowFuzzySet(-0.5, -0.2));
	FTempDiffVar.Add(1, new TMidFuzzySet(-0.5, -0.2, 0.0));
	FTempDiffVar.Add(2, new TMidFuzzySet(-0.2, 0.0, 0.2));
	FTempDiffVar.Add(3, new TMidFuzzySet(0.0, 0.2, 0.5));
    FTempDiffVar.Add(4, new THighFuzzySet(0.2, 0.5)); 
    AddInput(1, &FTempDiffVar);

    FOutputVar.Add(0, new TLowFuzzySet(-0.4, -0.2));
    FOutputVar.Add(1, new TMidFuzzySet(-0.4, -0.2, 0.0));
    FOutputVar.Add(2, new TMidFuzzySet(-0.2, 0.0, 0.2));
    FOutputVar.Add(3, new TMidFuzzySet(0.0, 0.2, 0.4));
    FOutputVar.Add(4, new THighFuzzySet(0.2, 0.4));
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

	FMotorVar.SetInputValue(0.0);
	FTempDiffVar.SetInputValue(0.0);

	vbe = new TGraphicDevice(*dev);

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
	delete vbe;
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
#   Name       : TVp::SetMotor
#
#   Purpose....: Set current motor
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetMotor(int motor)
{
	FSection.Enter();
    
    MotorCount++;
    MotorSum += motor;

    FSection.Leave();    
}

/*##########################################################################
#
#   Name       : TVp::SetTempError
#
#   Purpose....: Set current temp error
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetTempError(int diff)
{
    FSection.Enter();
    
    TempCount++;
	TempSum += diff;

    FSection.Leave();    
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
	int LastMin;
	int i;
	long double ValArr[MAX_FUZZY_VARS];
	long double val;
	int diostat;
	char str[50];
	TFont font(10);

	vbe->SetFont(&font);

	MotorSum = 0;
	MotorCount = 0;
	TempSum = 0;
	TempCount = 0;

	for (i = 0; i < MAX_FUZZY_VARS; i++)
		ValArr[i] = 0.0;

	while (!RdosReadSerialLines(1, &diostat))
		RdosWaitMilli(250);

	if (diostat & 0x20)
		FOn = TRUE;
	else
		FOn = FALSE;

	if (FOn)
		FLevel = 9.9;
	else
		FLevel = 0.0;

	RdosGetTime(&year, &month, &day, &hour, &LastMin, &sec, &ms);

	while (FInstalled)
	{
		RdosGetTime(&year, &month, &day, &hour, &min, &sec, &ms);

		if (LastMin != min && MotorCount && TempCount)
		{
			LastMin = min;

			FSection.Enter();

			if (MotorCount)
				ValArr[0] = (long double)MotorSum / (long double)MotorCount / 10.0;

			if (TempCount)
				ValArr[1] = (long double)TempSum / (long double)TempCount / 10.0;

			MotorSum = 0;
			MotorCount = 0;
			TempSum = 0;
			TempCount = 0;

			FSection.Leave();

			val = Calc(ValArr);
			FLevel += val;
			
			if (FLevel < 0.0)
			    FLevel = 0.0;

			if (FLevel > 9.9)
			    FLevel = 9.9;


    		if (FLevel < 0.25 && FOn)
    			FOn = FALSE;

    	    if (FLevel > 0.75 && !FOn)
    			FOn = TRUE;

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

    		sprintf(str, "VP: %4.1Lf", FLevel);

            vbe->SetFilledStyle();
           	vbe->SetDrawColor(0, 0, 0);
	    	vbe->DrawRect(550, 300, 550 + 100, 300 + 16);
		
    	    vbe->SetDrawColor(255, 255, 255);
    	    vbe->DrawString(550, 300, str);

		}

		RdosWaitMilli(1000);
	}
}
