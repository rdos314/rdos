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
* PIT.H
* PIT emulation
*
*##########################################################################*/

#ifndef	_PIT_H
#define _PIT_H

#include "isa.h"
#include "pic.h"

class TPitCounter
{
	friend class TPit;
public:
	TPitCounter();

	void Define(TPic *Pic, int Irq);
	void SetClk();
	void ResetClk();
	void SetGate();
	void ResetGate();

protected:
	void LoadPeriod(char Value);
	void LoadCounter(char Value);
	void ModifyOut(char Value);
	char Read();
	void Load(char Value);
	void SetMode(char Mode);

private:
	int FClk;
	int FGate;
	int FOut;
	char FMode;
	int FRunning;
	short int FPeriod;
	short int FCount;
	short int FLatchedCount;
	int FLatched;
	char FByteCounter;
	char FRl;
	TPic *FPic;
	int FIrq;
};

class TPit : public TIsaFunction
{
public:
	TPit(TIsa *Isa, int Base);
	~TPit();

	virtual void Out(int Num, int Offset, char Value);
	virtual char In(int Num, int Offset);

	TPitCounter *Counter[3];

};

#endif
