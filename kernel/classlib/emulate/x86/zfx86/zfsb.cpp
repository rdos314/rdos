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
* ZFSB.CPP
* ZFX86 south bridge PCI emulation
*
*##########################################################################*/

#include "zfsb.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TZfxSouthBridge::TZfxSouthBridge  ###############
*   Purpose....: Constructor							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TZfxSouthBridge::TZfxSouthBridge()
{
    FConfig[0] = 0x78;
    FConfig[1] = 0x10;
    FConfig[3] = 0x4;
    FConfig[5] = 0xF;
    FConfig[6] = 0x80;
    FConfig[7] = 0x2;
    FConfig[0xA] = 0x1;
    FConfig[0xB] = 0x6;
    FConfig[0xE] = 0x80;
    FConfig[0x19] = 0x1;
    FConfig[0x2C] = 0x78;
    FConfig[0x2D] = 0x10;
    FConfig[0x2F] = 0x4;
    FConfig[0x40] = 0x39;
    FConfig[0x43] = 0x2;
    FConfig[0x44] = 0x1;
    FConfig[0x46] = 0xFE;
    FConfig[0x4C] = 0xFF;
    FConfig[0x4D] = 0xFF;
    FConfig[0x4E] = 0xFF;
    FConfig[0x4F] = 0xFF;
    FConfig[0x50] = 0x7B;
    FConfig[0x51] = 0x40;
    FConfig[0x52] = 0x98;
    FConfig[0x5A] = 0x1;
    FConfig[0x5B] = 0x20;
    FConfig[0x6E] = 0xF0;
    FConfig[0x6F] = 0xFF;
}
