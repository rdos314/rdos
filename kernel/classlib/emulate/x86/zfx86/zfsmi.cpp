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
* ZFSMI.CPP
* ZFX86 SMI and power management PCI emulation
*
*##########################################################################*/

#include "zfsmi.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TZfxSmi::TZfxSmi  ###############
*   Purpose....: Constructor							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TZfxSmi::TZfxSmi()
{
    FConfig[0] = 0x78;
    FConfig[1] = 0x10;
    FConfig[2] = 0x1;
    FConfig[3] = 0x4;
    FConfig[6] = 0x80;
    FConfig[7] = 0x2;
	FConfig[0x10] = 0x1;
    FConfig[0x2C] = 0x78;
    FConfig[0x2D] = 0x10;
    FConfig[0x2E] = 0x1;
    FConfig[0x2F] = 0x4;
}
