/*###########################################################################
* Em486 CPU emulator
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
* CMOS.CPP
* Cmos emulation
*
*##########################################################################*/

#include "cmos.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TCmos::TCmos  ###############
*   Purpose....: Constructor for KEYB							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TCmos::TCmos()
{
	int i;

	for (i = 0; i < 128; i++)
		FData[i] = 0;

	FPort = 0;
}

/*##################  TCmos::Out  ###############
*   Purpose....: Perform out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCmos::Out(int Port, char Value)
{
	switch (Port & 1)
	{
		case 0:
			FPort = Value & 0x7F;
			break;

		case 1:
			FData[FPort] = Value;
			break;

		default:
			break;
	}
}

/*##################  TCmos::In  ###############
*   Purpose....: Perform in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TCmos::In(int Port)
{
	char Val;

	switch (Port & 1)
	{
		case 0:
			return FPort;

		case 1:
			return FData[FPort];

		default:
			return 0xFF;
	}
}
