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
* 6117.H
* ALI6117 emulation
*
*##########################################################################*/

#ifndef	_6117_H
#define _6117_H

#include "keyb.h"

class T6117
{
	public:
		T6117(TKeyb *Keyb);

		void Out(int Port, char Value);
		char In(int Port);
		char Read(unsigned long Address);
		void Write(unsigned long Address, char Data);

		void SetClk();
		void ResetClk();

		void Reset();
		void DefineDram(int Bank, unsigned long Size);
		void DefineRom(unsigned long Size, char *FileName);

	protected:
		char ReadDram(unsigned long Address);
		void WriteDram(unsigned long Address, char Data);
		char ReadDram29(unsigned long Address);
		char ReadDram31(unsigned long Address);
		void WriteDram29(unsigned long Address, char Data);
		void WriteDram31(unsigned long Address, char Data);
		
	private:
		char FPort;
		char FLocked;
		char FData[0x80];

		TKeyb *FKeyb;
		int FClkCount;
		int FRefresh;

		char *FRom;
		int FRomSize;

		int FDramConfigured;
		int FDramMode;
		int FDramBanks[4];
		char *FDram;
		int FDramSize;
};

#endif
