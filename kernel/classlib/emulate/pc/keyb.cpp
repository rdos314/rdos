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
* KEYB.CPP
* PC keyboard emulation
*
*##########################################################################*/

#include "keyb.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TKeyb::TKeyb  ###############
*   Purpose....: Constructor for KEYB							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TKeyb::TKeyb()
{
	FRefresh = FALSE;
	FLast = 0;
	FHasData = FALSE;
	FEnabled = FALSE;
}

/*##################  TKeyb::Out  ###############
*   Purpose....: Perform out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TKeyb::Out(int Port, char Value)
{
	switch (Port & 7)
	{
		case 0:
			FLast = 0;
			break;

		case 1:
			break;

		case 4:
			FLast = 4;
			switch (Value)
			{
				case 0xAA:
					FHasData = TRUE;
					FData = 0x55;
					break;

				case 0xAD:
					FEnabled = FALSE;
					break;

				case 0xAE:
					FEnabled = TRUE;
					break;

				case 0xC0:
					FHasData = TRUE;
					FData = 0x70;
					break;
			}
			break;

		default:
			break;
	}
}

/*##################  TKeyb::In  ###############
*   Purpose....: Perform in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TKeyb::In(int Port)
{
	char Val;

	switch (Port & 7)
	{
		case 0:
			if (FHasData)
			{
				FHasData = FALSE;
				return FData;
			}
			else
				return 0xFF;

		case 1:
			if (FRefresh)
				return 0x10;
			else
				return 0;

		case 4:
			Val = 0;
			if (FHasData)
				Val |= 1;

			if (FLast == 0)
				Val |= 8;

			if (FEnabled)
				Val |= 0x10;			
			return Val;

		default:
			return 0xFF;
	}
}

/*##################  TKeyb::SetRefresh  ###############
*   Purpose....: Set refresh state						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TKeyb::SetRefresh(int Value)
{
	FRefresh = Value;
}
 
