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
* ZFL.CPP
* ZF-Logic emulation
*
*##########################################################################*/

#include "zfl.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TZFLogic::TZFLogic  ###############
*   Purpose....: Constructor for ZF-Logic						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TZFLogic::TZFLogic(TIsa *Isa, int Base)
  : TIsaFunction(Isa)
{
	int i;

	FIndex = 0;
	for (i = 0; i < 0x82; i++)
		FData[i] = 0;

	FData[0x28] = 0xFF;
	FData[0x2B] = 0xFF;

	DefineIo(0, Base, 8, 0);
}

/*##################  TZFLogic::Out  ###############
*   Purpose....: Perform out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TZFLogic::Out(int Num, int Offset, char Value)
{
	switch (Offset)
	{
		case 0:
			FIndex = Value;
			break;

		case 1:
		case 2:
			FData[FIndex] = Value;
			break;

		case 3:
			FData[FIndex + 1] = Value;
			break;

		case 4:
			FData[FIndex + 2] = Value;
			break;

		case 5:
			FData[FIndex + 3] = Value;
			break;

		default:
			break;
	}
}

/*##################  TZFLogic::In  ###############
*   Purpose....: Perform in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TZFLogic::In(int Num, int Offset)
{
	switch (Offset)
	{
		case 0:
			return FIndex;

		case 1:
		case 2:
			return FData[FIndex];

		case 3:
			return FData[FIndex + 1];

		case 4:
			return FData[FIndex + 2];

		case 5:
			return FData[FIndex + 3];

		default:
			return 0xFF;
	}
}

/*##################  TZFLogic::WriteMem  ###############
*   Purpose....: Perform write instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TZFLogic::WriteMem(int Num, unsigned long Offset, char Value)
{
}

/*##################  TZFLogic::ReadMem ###############
*   Purpose....: Perform read instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TZFLogic::ReadMem(int Num, unsigned long Offset)
{
	return 0xFF;
}
