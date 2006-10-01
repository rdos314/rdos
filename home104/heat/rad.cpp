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
TRad::TRad(int Address, int Row, TLog *Log)
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

	FLog = Log;

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
    int year, month, day;
    int hour, min, sec;
    int milli;
    TRadLog RadLog;
    char name[100];

    FLogFile = 0;

    ClearAcc();

    RdosGetTime(&FYear, &FMonth, &FDay, &FHour, &FMin, &sec, &milli);

	sprintf(name, "rad%02x.dat", FAddress);

	while (FInstalled)
	{
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

        RdosGetTime(&year, &month, &day, &hour, &min, &sec, &milli);

        if (min != FMin)
        {
            if (FLogFile)
            {
                RadLog.Valid = TRUE;

                if (FRefCount)
                    RadLog.Ref = FRefSum / FRefCount;
                else
                    RadLog.Valid = FALSE;

                if (FTempCount)
                    RadLog.Temp = FTempSum / FTempCount;
                else
                    RadLog.Valid = FALSE;

                if (FMotorCount)
                    RadLog.Motor = FMotorSum / FMotorCount;
                else
                    RadLog.Valid = FALSE;

                if (FLightCount)
                    RadLog.Light = FLightSum / FLightCount;
                else
                    RadLog.Valid = FALSE;

                if (FAuxTempCount)
                    RadLog.AuxTemp = FAuxTempSum / FAuxTempCount;
                else
                    RadLog.Valid = FALSE;

				FLogFile->Write(&RadLog, sizeof(RadLog));

				if (FDay != day)
				{
					delete FLogFile;

					RadLog.Valid = FALSE;
					FLogFile = FLog->GetDayFile(year, month, day, hour, min, name, &RadLog, sizeof(RadLog));
				}
			}
			else
			{
				RadLog.Valid = FALSE;
				FLogFile = FLog->GetDayFile(year, month, day, hour, min, name, &RadLog, sizeof(RadLog));
			}

			ClearAcc();

            FYear = year;
            FMonth = month;
            FDay = day;
            FHour = hour;
            FMin = min;

        }

		RdosWaitMilli(1000);

	}
}
