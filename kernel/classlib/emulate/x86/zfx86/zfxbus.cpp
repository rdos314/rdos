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
* ZFXBUS.CPP
* ZFX86 XBUS PCI emulation
*
*##########################################################################*/

#include "zfxbus.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TZfxXbus::TZfxXbus  ###############
*   Purpose....: Constructor							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TZfxXbus::TZfxXbus(TPci *Pci)
  : TPciFunction(Pci)
{
	int i;

    FConfig[0] = 0x78;
    FConfig[1] = 0x10;
    FConfig[2] = 0x3;
    FConfig[3] = 0x4;
    FConfig[6] = 0x80;
    FConfig[7] = 0x2;
    FConfig[0x2C] = 0x78;
    FConfig[0x2D] = 0x10;
    FConfig[0x2E] = 0x3;
    FConfig[0x2F] = 0x4;

	for (i = 0; i < 0x40; i++)
		FData[i] = 0;

	FData[0] = 0x7;
	FData[2] = 0xC;
	FData[3] = 0x1;
	FData[9] = 0x9;
}

/*##################  TZfxXbus::WriteConfig  ###############
*   Purpose....: Write config							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TZfxXbus::WriteConfig(int Index, int Data)
{
	int val;

	TPciFunction::WriteConfig(Index, Data);

	switch (Index)
	{
		case 0x10:
		case 0x11:
		case 0x12:
		case 0x13:
			val = FConfig[0x10] & 0xC0;
			val |= (FConfig[0x11] & 0xFF) << 8;
			val |= (FConfig[0x12] & 0xFF) << 16;
			val |= (FConfig[0x13] & 0xFF) << 24;			
			if (val >= 0x400 && (FConfig[0x10] & 1))
				DefineIo(0, val, 0x40, FData);
		    else
				UndefineIo(0);
			break;
	}			
}
