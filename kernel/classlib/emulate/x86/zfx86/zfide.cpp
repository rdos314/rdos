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
* ZFIDE.CPP
* ZFX86 IDE PCI emulation
*
*##########################################################################*/

#include "zfide.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TZfxIde::TZfxIde  ###############
*   Purpose....: Constructor							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TZfxIde::TZfxIde(TPci *Pci)
  : TPciFunction(Pci)
{
    int i;
    
    FConfig[0] = 0x78;
    FConfig[1] = 0x10;
    FConfig[2] = 0x2;
    FConfig[3] = 0x4;
    FConfig[6] = 0x80;
    FConfig[7] = 0x2;
    FConfig[8] = 0x1;
    FConfig[9] = 0x80;
    FConfig[0xA] = 0x1;
    FConfig[0xB] = 0x1;
    FConfig[0x2C] = 0x78;
    FConfig[0x2D] = 0x10;
    FConfig[0x2E] = 0x2;
    FConfig[0x2F] = 0x4;
    FConfig[0x40] = 0x72;
    FConfig[0x41] = 0x91;
    FConfig[0x44] = 0x71;
    FConfig[0x45] = 0x77;
    FConfig[0x46] = 0x07;
    FConfig[0x48] = 0x72;
    FConfig[0x49] = 0x91;
    FConfig[0x4C] = 0x71;
    FConfig[0x4D] = 0x77;
    FConfig[0x4E] = 0x07;
    FConfig[0x50] = 0x72;
    FConfig[0x51] = 0x91;
    FConfig[0x54] = 0x71;
    FConfig[0x55] = 0x77;
    FConfig[0x56] = 0x07;
    FConfig[0x58] = 0x72;
    FConfig[0x59] = 0x91;
    FConfig[0x5C] = 0x71;
    FConfig[0x5D] = 0x77;
    FConfig[0x5E] = 0x07;

	for (i = 0; i < 0x10; i++)
		FIdeData[i] = 0;
}

/*##################  TZfxIde::WriteConfig  ###############
*   Purpose....: Write config							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TZfxIde::WriteConfig(int Index, int Data)
{
	int val;

	TPciFunction::WriteConfig(Index, Data);

	switch (Index)
	{
		case 0x20:
		case 0x21:
		case 0x22:
		case 0x23:
			val = FConfig[0x20] & 0xF0;
			val |= (FConfig[0x21] & 0xFF) << 8;
			val |= (FConfig[0x22] & 0xFF) << 16;
			val |= (FConfig[0x23] & 0xFF) << 24;			
			if (val >= 0x400)
				DefineIo(0, val, 0x10, FIdeData);
		    else
				UndefineIo(0);
			break;
	}			
}
