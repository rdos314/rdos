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
* PIC.H
* PIC emulation
*
*##########################################################################*/

#ifndef	_PIC_H
#define _PIC_H

#define MODE_NORMAL	0
#define MODE_ICW1	1
#define MODE_ICW2	2
#define MODE_ICW3	3
#define MODE_ICW4	4

#define OCW3_RIS	1
#define OCW3_RR		2
#define OCW3_POLL	4

#define ICW1_ICW4_NEEDED	1
#define ICW1_SINGLE			2
#define ICW1_INTERVAL		4

#define ICW4_8086			1
#define ICW4_AUTO_EOI		2
#define ICW4_MS				4
#define ICW4_BUF			8
#define ICW4_SNFM			0x10

#include "isa.h"

class TPic : TIsaFunction
{
	public:
		TPic(TIsa *Isa, int Base);

		virtual void Out(int Num, int Offset, char Value);
		virtual char In(int Num, int Offset);

		void Cascade(int Number, TPic *Pic);
		void Set(int Number);
		void Reset(int Number);
		int IsIntActive();
		char GetVector();

	protected:
		int GetIrr();
		int GetIsr();
		void Eoi(int Number);
		void Command(int Command, int Number);

		TPic *FMaster;
		int FMasterLine;

	private:
		char FMode;
		char FRis;
		char FLowest;
		char FIcw1;
		char FIcw2;
		char FIcw3;
		char FIcw4;
		char FIrr;
		char FIsr;
		char FImr;

		TPic *FCascade[8];
};

#endif
