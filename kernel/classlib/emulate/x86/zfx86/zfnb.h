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
* ZFNB.H
* ZFX86 north bridge emulation
*
*##########################################################################*/

#ifndef	_ZFNB_H
#define _ZFNB_H

#include "pci.h"

class TZfxNorthBridge : public TPciFunction
{
public:
	TZfxNorthBridge(TPci *Pci);
	~TZfxNorthBridge();

	virtual void Out(int Num, int Offset, char Value);
	virtual char In(int Num, int Offset);

protected:
    void UpdateData(int Index);

private:
	short int FPort;
	short int FData[0x400];
	char *FDram[4];
};

#endif
