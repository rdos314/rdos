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
* ZFUSB.CPP
* ZFX86 USB PCI emulation
*
*##########################################################################*/

#include "zfusb.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TZfxUsb::TZfxUsb  ###############
*   Purpose....: Constructor							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TZfxUsb::TZfxUsb(TPci *Pci)
  : TPciFunction(Pci)
{
    FConfig[0] = 0x11;
    FConfig[1] = 0xE;
    FConfig[2] = 0xF8;
    FConfig[3] = 0xA0;
    FConfig[6] = 0x80;
    FConfig[7] = 0x2;
    FConfig[8] = 0x7;
    FConfig[9] = 0x10;
    FConfig[0xA] = 0x3;
    FConfig[0xB] = 0xC;
    FConfig[0x2C] = 0x11;
    FConfig[0x2D] = 0xE;
    FConfig[0x2E] = 0xF8;
    FConfig[0x2F] = 0xA0;
    FConfig[0x3D] = 0x1;
    FConfig[0x3F] = 0x50;
    FConfig[0x42] = 0xF;
}
