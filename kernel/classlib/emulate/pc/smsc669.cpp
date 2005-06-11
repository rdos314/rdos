/*###########################################################################
* RDOS operating system 
* Copyright (C) 1998-2000, Leif Ekblad
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version. The only exception to this rule
* is for commercial usage. For information on commercial usage,
* contact em486@rdos.net.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*
* The author of this program may be contacted at leif@rdos.net
*
* SMSC669.CPP
* SMSC FDC37C669 emulation
*
*##########################################################################*/

#include <stdio.h>

#include "smsc669.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TSmsc669::TSmsc669  ###############
*   Purpose....: Constructor									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TSmsc669::TSmsc669(TPic *Pic0, TPic *Pic1, int nRTS2)
{
	int i;

	for (i = 0; i < MAX_CONTROL_INDEX; i++)
		FData[i] = 0;

	if (nRTS2)
		FConfigBase = 0x370;
	else
		FConfigBase = 0x3F0;
	FPic0 = Pic0;
	FPic1 = Pic1;
	FLockCount = 0;
	FIndex = 0;

	FData[0] = 0x28;
	FData[1] = 0x9C;
	FData[2] = 0x88;
	FData[3] = 0x78;
	FData[6] = 0xFF;
	FData[0xD] = 3;
	FData[0xE] = 2;
	FData[0x1E] = 0x3C;
	FData[0x20] = 0x3C;
	FData[0x21] = 0x3C;
	FData[0x22] = 0x3D;
}


/*##################  TSmsc669::ConfigOut  ###############
*   Purpose....: Perform config out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TSmsc669::ConfigOut(int Port, char Value)
{
	if (Port & 1)
	{
		if (FLockCount >= 2)
			if (FIndex >= 0 && FIndex < MAX_CONTROL_INDEX)
				FData[FIndex] = Value;
	}
	else
	{
		switch (Value)
		{
			case 0x55:
				FLockCount++;
				break;

			case 0xAA:
				FLockCount = 0;
				break;

			default:
				if (FLockCount >= 2)
					FIndex = Value;
				break;
		}
	}
}

/*##################  TSmsc669::ConfigIn  ###############
*   Purpose....: Perform config in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TSmsc669::ConfigIn(int Port)
{
	if (Port & 1)
	{
		if (FLockCount >= 2)
			if (FIndex >= 0 && FIndex <= 0x29)
				return FData[FIndex];
	}
	
	return 0xFF;
}

/*##################  TSmsc669::Out  ###############
*   Purpose....: Perform out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TSmsc669::Out(int Port, char Value)
{
	if ((Port & 0x3FE) == FConfigBase)
		ConfigOut(Port, Value);
}

/*##################  TSmsc669::In  ###############
*   Purpose....: Perform in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TSmsc669::In(int Port)
{
	if ((Port & 0x3FE) == FConfigBase)
		return ConfigIn(Port);

	return 0xFF;
}

/*##################  TSmsc669::ShowInternals  ###############
*   Purpose....: Show settings									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TSmsc669::ShowInternals()
{
	int i;
	int j;
	int Index;

	for (i = 0; i < 0x10; i++)
	{
		printf("%02hX: ", 8 * i);
		for (j = 0; j < 8; j++)
		{
			Index = 8 * i + j;
			if (Index >= MAX_CONTROL_INDEX)
			{
				printf("\r\n");
				return;
			}
			else
				printf("%04hX ", FData[Index]);
		}
		printf("\r\n");
	}	
}
