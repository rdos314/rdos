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
* ZFSB.H
* ZFX86 south bridge PCI emulation
*
*##########################################################################*/

#ifndef _ZFSB_H
#define _ZFSB_H

#include "pci.h"

class TZfxSouthBridge : public TPciFunction
{
public:
	TZfxSouthBridge(TPci *Pci);

    virtual void WriteConfig(int Index, int Data);

protected:
    char FGpio[0x40];
};

#endif
