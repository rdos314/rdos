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
* ZFNB.CPP
* ZFX86 north bridge emulation
*
*##########################################################################*/

#include "zfnb.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TZfxNorthBridge::TZfxNorthBridge  ###############
*   Purpose....: Constructor for north bridge							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TZfxNorthBridge::TZfxNorthBridge(TPci *Pci)
  : TPciFunction(Pci)
{
	int i;
	long l;
	long *LongPtr;

	for (i = 0; i < 4; i++)
	{
		FDram[i] = 0;
	}

	FDram[0] = new char[0x100000];
	LongPtr = (long *)FDram[0];
	for (l = 0; l < 0x40000; l++)
	{
		*LongPtr = 0x77777777;
		LongPtr++;
	}

	for (i = 0; i < 0x400; i++)
		FData[i] = 0;

	FData[0x119] = 0xA;
	FData[0x11A] = 0x200;
	FData[0x204] = 0xFFFF;
	FData[0x207] = 0xFFFF;
	FData[0x20A] = 0xFFFF;
	FData[0x20D] = 0xFFFF;
	FData[0x20F] = 1;
	FData[0x211] = 0x30A0;
	FData[0x213] = 0x320;
	FData[0x239] = 0xFFFF;

	FPort = 0;

	DefineIo(0, 0x24, 4, 0);

}

/*##################  TZfxNorthBridge::~TZfxNorthBridge  ###############
*   Purpose....: Destructor for north bridge							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TZfxNorthBridge::~TZfxNorthBridge()
{
	int i;

	for (i = 0; i < 4; i++)
		if (FDram[i])
			delete FDram[i];

}

/*##################  TZfxNorthBridge::Out  ###############
*   Purpose....: Perform out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TZfxNorthBridge::Out(int Num, int Offset, char Value)
{
	long LVal;

	LVal = (long)Value & 0xFF;

	switch (Offset)
	{
		case 0:
			FPort = LVal;
			break;

		case 1:
			FPort |= LVal << 8;
			break;

		case 2:
			FData[FPort] &= 0xFF00;
			FData[FPort] |= LVal;
			break;

		case 3:
			FData[FPort] &= 0x00FF;
			FData[FPort] |= LVal << 8;
			UpdateData(FPort);
			break;

		default:
			break;
	}
}

/*##################  TZfxNorthBridge::In  ###############
*   Purpose....: Perform in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TZfxNorthBridge::In(int Num, int Offset)
{
	char Val;

	switch (Offset)
	{
		case 0:
			return (char)(FPort & 0xFF);

		case 1:
			return (char)((FPort >> 8) & 0xFF);

		case 2:
			return (char)(FData[FPort] & 0xFF);

		case 3:
			return (char)((FData[FPort] >> 8) & 0xFF);

		default:
			return 0xFF;
	}
}

/*##################  TZfxNorthBridge::UpdateData  ###############
*   Purpose....: Update data            						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TZfxNorthBridge::UpdateData(int Index)
{
	short int Mask;
	unsigned long Base;

	switch (Index)
	{
		case 0x202:
		case 0x205:
		case 0x208:
		case 0x20B:
		case 0x20F:
			Mask = FData[0x20F];
			if (Mask & 0x1)
			{
				Base = (FData[0x202] & 0xF) << 20;
				DefineMem(0, Base, 0x100000, FDram[0]);
			}
			else
				UndefineMem(0);

			if (Mask & 0x2)
			{
				Base = (FData[0x205] & 0xF) << 20;
				DefineMem(1, Base, 0x100000, FDram[0]);
			}
			else
				UndefineMem(1);

			if (Mask & 0x4)
			{
				Base = (FData[0x208] & 0xF) << 20;
				DefineMem(2, Base, 0x100000, FDram[0]);
			}
			else
				UndefineMem(2);

			if (Mask & 0x8)
			{
				Base = (FData[0x20B] & 0xF) << 20;
				DefineMem(3, Base, 0x100000, FDram[0]);
			}
			else
				UndefineMem(3);

			break;

	}
}
