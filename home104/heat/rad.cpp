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
# rad.h
# Radiator class
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "rad.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TRad::TRad
#
#   Purpose....: Radiator constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRad::TRad(int Address, int Row)
{
	char str[40];

	FAddress = Address;
	FRow = Row;
	Offline();
	Ref = 200;
	Temp = 200;
	Motor = 51;
	Light = 0;
	AuxTemp = 200;
	RefType = 0;

    FUpdateRefType = FALSE;
	FUpdateRef = FALSE;
	FUpdateAmbient = FALSE;

    ClearAcc();

	sprintf(str, "RAD %d", Address);
	Start(str, 0x2000);
}

/*##########################################################################
#
#   Name       : TRad::DeviceName
#
#   Purpose....: Device name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::DeviceName(char *Name, int Size) const
{
	strcpy(Name, "RAD");
}

/*##########################################################################
#
#   Name       : TRad::SetDayRef
#
#   Purpose....: Set day time reference
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::SetDayRef()
{
	RefType = 0;
	FUpdateRefType = TRUE;
}

/*##########################################################################
#
#   Name       : TRad::SetNightRef
#
#   Purpose....: Set night time reference
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::SetNightRef()
{
	RefType = 1;
	FUpdateRefType = TRUE;
}

/*##########################################################################
#
#   Name       : TRad::SetWinterRef
#
#   Purpose....: Set winter time (night) reference
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::SetWinterRef()
{
	RefType = 2;
	FUpdateRefType = TRUE;
}

/*##########################################################################
#
#   Name       : TRad::SetRef
#
#   Purpose....: Set reference temperature
#
#   Out params.: Reference temperature
#   Returns....: *
#
##########################################################################*/
void TRad::SetRef(int Temp)
{
	Ref = Temp;
	FUpdateRef = TRUE;
}

/*##########################################################################
#
#   Name       : TRad::SetAmbient
#
#   Purpose....: Set ambient (outdoor) temperature
#
#   Out params.: ambient temperature
#   Returns....: *
#
##########################################################################*/
void TRad::SetAmbient(int temp)
{
	Ambient = temp;
	FUpdateAmbient = TRUE;
}

/*##########################################################################
#
#   Name       : TRad::GetAddress
#
#   Purpose....: Get address
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRad::GetAddress()
{
    return FAddress;
}

/*##########################################################################
#
#   Name       : TRad::ClearAcc
#
#   Purpose....: Clear accumulated values
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::ClearAcc()
{
    FRefSum = 0;
    FRefCount = 0;
    FTempSum = 0;
    FTempCount = 0;
    FMotorSum = 0;
    FMotorCount = 0;
    FLightSum = 0;
    FLightCount = 0;
    FAuxTempSum = 0;
    FAuxTempCount = 0;
}

/*##########################################################################
#
#   Name       : TRad::GetRef
#
#   Purpose....: Get reference temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRad::GetRef(int *val)
{
	int ok;

	FSection.Enter();

	if (FRefCount)
	{
		*val = FRefSum / FRefCount;
		ok = TRUE;
	}
	else
		ok = FALSE;

	FSection.Leave();
	return ok;
}

/*##########################################################################
#
#   Name       : TRad::GetTemp
#
#   Purpose....: Get temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRad::GetTemp(int *val)
{
	int ok;

	FSection.Enter();

	if (FTempCount)
	{
		*val = FTempSum / FTempCount;
		ok = TRUE;
	}
	else
		ok = FALSE;

	FSection.Leave();
	return ok;
}

/*##########################################################################
#
#   Name       : TRad::GetMotor
#
#   Purpose....: Get motor value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRad::GetMotor(int *val)
{
	int ok;

	FSection.Enter();

	if (FMotorCount)
	{
		*val = FMotorSum / FMotorCount;
		ok = TRUE;
	}
	else
		ok = FALSE;

	FSection.Leave();
	return ok;
}

/*##########################################################################
#
#   Name       : TRad::GetLight
#
#   Purpose....: Get light value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRad::GetLight(int *val)
{
	int ok;

	FSection.Enter();

	if (FLightCount)
	{
		*val = FLightSum / FLightCount;
		ok = TRUE;
	}
	else
		ok = FALSE;

	FSection.Leave();
	return ok;
}

/*##########################################################################
#
#   Name       : TRad::GetAuxTemp
#
#   Purpose....: Get aux-temp value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRad::GetAuxTemp(int *val)
{
	int ok;

    FSection.Enter();

    if (FAuxTempCount)
    {
        *val = FAuxTempSum / FAuxTempCount;
		ok = TRUE;
    }
    else
        ok = FALSE;

    FSection.Leave();
    return ok;
}


/*##########################################################################
#
#   Name       : TRad::Execute
#
#   Purpose....: Execute
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::Execute()
{
	int val;

	while (FInstalled)
	{
	    FSection.Enter();

		if (FUpdateRef)
		{
			val = Ref;
			FUpdateRef = !RdosWriteSerialRaw(FAddress, 0, val);
		}

		if (FUpdateAmbient)
		{
			val = 127 + (Ambient - Ref) / 10;
			FUpdateAmbient = !RdosWriteSerialRaw(FAddress, 4, val);
		}

		if (FUpdateRefType)
			FUpdateRefType = !RdosWriteSerialRaw(FAddress, 5, RefType);

		RdosSetCursorPosition(FRow + 1,0);

		if (RdosWriteSerialRaw(FAddress, 5, 2))
			printf("ok ");
		else
			printf("-- ");

		if (RdosReadSerialRaw(FAddress, 0, &Ref))
		{
			FRefSum += Ref;
			FRefCount++;
			printf("%4ld.%ld ", Ref / 10, Ref % 10);
		}
		else
			printf("------ ");

		if (RdosReadSerialRaw(FAddress, 1, &Temp))
		{
			if (Temp < 50)
				Temp += 256;

		    FTempSum += Temp;
		    FTempCount++;
		        
			printf("%4ld.%ld ", Temp / 10, Temp % 10);
	    }
		else
			printf("------ ");

		if (RdosReadSerialRaw(FAddress, 2, &Motor))
		{
		    Online();

		    FMotorSum = Motor;
		    FMotorCount++;
		    
			Motor = Motor * 10 / 25;
			printf("%4ld.%ld ", Motor / 10, Motor % 10);
		}
		else
		{
		    Offline();
			printf("------ ");
	    }

		if (RdosReadSerialRaw(FAddress, 3, &Light))
		{
		    FLightSum += Light;
		    FLightCount++;
		    
			printf("%4ld.%ld ", Light / 10, Light % 10);
	    }
		else
			printf("------ ");

		if (RdosReadSerialRaw(FAddress, 4, &AuxTemp))
		{
		    if (AuxTemp < 50)
		        AuxTemp += 256;

            FAuxTempSum += AuxTemp;
            FAuxTempCount++;
		       
			printf("%4ld.%ld ", AuxTemp / 10, AuxTemp % 10);
		}
		else
			printf("------ ");


        FSection.Leave();


		RdosWaitMilli(1000);

	}
}
