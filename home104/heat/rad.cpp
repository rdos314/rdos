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
	while (FInstalled)
	{
		RdosSetCursorPosition(FRow + 1,0);

		if (RdosWriteSerialRaw(FAddress, 5, 2))
			printf("ok ");
		else
			printf("-- ");

		if (RdosReadSerialRaw(FAddress, 0, &Ref))
			printf("%4ld.%ld ", Ref / 10, Ref % 10);
		else
			printf("------ ");

		if (RdosReadSerialRaw(FAddress, 1, &Temp))
			printf("%4ld.%ld ", Temp / 10, Temp % 10);
		else
			printf("------ ");

		if (RdosReadSerialRaw(FAddress, 2, &Motor))
		{
		    Online();
			Motor = Motor * 10 / 25;
			printf("%4ld.%ld ", Motor / 10, Motor % 10);
		}
		else
		{
		    Offline();
			printf("------ ");
	    }

		if (RdosReadSerialRaw(FAddress, 3, &Light))
			printf("%4ld.%ld ", Light / 10, Light % 10);
		else
			printf("------ ");

		if (RdosReadSerialRaw(FAddress, 4, &AuxTemp))
			printf("%4ld.%ld ", AuxTemp / 10, AuxTemp % 10);
		else
			printf("------ ");

		RdosWaitMilli(1000);
	}
}
