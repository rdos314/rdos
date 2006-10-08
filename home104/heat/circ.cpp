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
# circ.h
# Circulation pump class
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "circ.h"
#include "lowset.h"
#include "midset.h"
#include "highset.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TCirc::TCirc
#
#   Purpose....: Circulation pump constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCirc::TCirc()
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

	Start("Circ", 0x2000);
}

/*##########################################################################
#
#   Name       : TCirc::~TCirc
#
#   Purpose....: Circulation pump destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCirc::~TCirc()
{
}

/*##########################################################################
#
#   Name       : TCirc::DeviceName
#
#   Purpose....: Device name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCirc::DeviceName(char *Name, int Size) const
{
	strcpy(Name, "CIRC");
}

/*##########################################################################
#
#   Name       : TCirc::SetMaxMotor
#
#   Purpose....: Set current max motor
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCirc::SetMaxMotor(int motor)
{
    FSection.Enter();
    
    MotorCount++;
    MotorSum += motor;

    FSection.Leave();    
}

/*##########################################################################
#
#   Name       : TCirc::SetMaxTempError
#
#   Purpose....: Set current max temp error
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCirc::SetMaxTempError(int diff)
{
    FSection.Enter();
    
    TempCount++;
    TempSum += diff;

    FSection.Leave();    
}

/*##########################################################################
#
#   Name       : TCirc::GetSpeed
#
#   Purpose....: Get speed
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TCirc::GetSpeed()
{
    return FSpeed;
}

/*##########################################################################
#
#   Name       : TCirc::ReadCircValve
#
#   Purpose....: Read voltage on circ valve
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TCirc::ReadCircValve()
{
    int Valve;

    RdosReadSerialVal(2, 2, &Valve);
	return (long double)Valve / 0x7FFFFFFF * 10.0;
}

/*##########################################################################
#
#   Name       : TCirc::WriteCircValve
#
#   Purpose....: Write Circ valve
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCirc::WriteCircValve(long double value)
{
	int temp;

	temp = (int)(value / 10.0 * (long double)0x7FFFFFFF);
	if (temp < 0)
		temp = 0x7FFFFFFF;

	RdosWriteSerialVal(2, 2, temp);
}

/*##########################################################################
#
#   Name       : TCirc::Execute
#
#   Purpose....: Handler thread
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCirc::Execute()
{
	int year, month, day;
	int hour, min, sec;
	int ms;
	int LastMin;
	int i;
	long double ValArr[MAX_FUZZY_VARS];
	long double val;

	for (i = 0; i < MAX_FUZZY_VARS; i++)
		ValArr[i] = 0.0;

	FSpeed = ReadCircValve();
	RdosGetTime(&year, &month, &day, &hour, &LastMin, &sec, &ms);

	while (FInstalled)
	{
		RdosGetTime(&year, &month, &day, &hour, &min, &sec, &ms);

		if (min != LastMin)
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
			FSpeed += val;
			
			if (FSpeed < 0.0)
			    FSpeed = 0.0;

			if (FSpeed > 9.9)
			    FSpeed = 9.9;
			    
			WriteCircValve(FSpeed);
    
	    	RdosSetCursorPosition(16,0);
    		printf("%6.1Lf V", FSpeed);

		}

		RdosWaitMilli(1000);
	}
}
