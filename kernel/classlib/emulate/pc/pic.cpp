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
* PIC.CPP
* PIC emulation
*
*##########################################################################*/

#include "pic.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TPic::TPic  ###############
*   Purpose....: Constructor for PIC							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
TPic::TPic(TIsa *Isa, int Base)
  : TIsaFunction(Isa)
{
	int i;

	for (i = 0; i < 8; i++)
		FCascade[i] = 0;

	FMaster = 0;

	FIrr = 0;
	FImr = 0xFF;
	FIsr = 0;
	FIcw1 = 0;
	FIcw2 = 0;
	FIcw3 = 0;
	FIcw4 = 0;
	FMode = MODE_ICW1;
	FRis = FALSE;
	FLowest = 7;

	DefineIo(0, Base, 2, 0);
}

/*##################  TPic::Cascade  ###############
*   Purpose....: Cascade a PIC									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPic::Cascade(int Number, TPic *Pic)
{
	FCascade[Number] = Pic;
	Pic->FMaster = this;
	Pic->FMasterLine = Number;
}

/*##################  TPic::Set  ###############
*   Purpose....: Set IRQ line						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPic::Set(int Number)
{
	char Mask;

	Mask = 1 << Number;
	FIrr = FIrr | Mask;

	if (FMaster && (FIrr & ~FImr) != 0)
		FMaster->Set(FMasterLine);
}

/*##################  TPic::Reset  ###############
*   Purpose....: Reset IRQ line						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPic::Reset(int Number)
{
	char Mask;

	Mask = 1 << Number;
	FIrr = FIrr & ~Mask;

	if (FMaster && (FIrr & ~FImr) == 0)
		FMaster->Reset(FMasterLine);
}

/*##################  TPic::GetIrr  ###############
*   Purpose....: Get highest, non-masked IRR					            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int TPic::GetIrr()
{
	int Value;
	int Mask;
	int Number;

	Value = FIrr & ~FImr;
	if (Value)
	{
		Number = FLowest;
		Number++;
		if (Number == 8)
			Number = 0;
		Mask = 1 << Number;
		while (TRUE)
		{
			if (Mask & Value)
				return Number;
			else
			{
				Number++;
				if (Number == 8)
				{
					Number = 0;
					Mask = 1;
				}
				else
					Mask = Mask << 1;
			}
		}
	}
	else
		return -1;
}

/*##################  TPic::GetIsr  ###############
*   Purpose....: Get highest ISR								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int TPic::GetIsr()
{
	int Value;
	int Mask;
	int Number;

	Value = FIsr;
	if (Value)
	{
		Number = FLowest;
		Number++;
		if (Number == 8)
			Number = 0;
		Mask = 1 << Number;
		while (TRUE)
		{
			if (Mask & Value)
				return Number;
			else
			{
				Number++;
				if (Number == 8)
				{
					Number = 0;
					Mask = 1;
				}
				else
					Mask = Mask << 1;
			}
		}
	}
	else
		return -1;
}

/*##################  TPic::Eoi  ###############
*   Purpose....: EOI command											            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPic::Eoi(int Number)
{
	char Mask;

	if (Number >= 0)
	{
		Mask = 1 << Number;
		FIsr = FIsr & ~Mask;
	}
}

/*##################  TPic::Command  ###############
*   Purpose....: Command											            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPic::Command(int Command, int Number)
{
	switch (Command)
	{
		case 1:
			Number = GetIsr();
			Eoi(Number);
			break;

		case 3:
			Eoi(Number);
			break;

		case 6:
			FLowest = Number;
			break;

	}
}

/*##################  TPic::IsIntActive  ###############
*   Purpose....: Check if any interrupt is pending					            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int TPic::IsIntActive()
{
	if (GetIrr() >= 0)
		return TRUE;
	else
		return FALSE;
}

/*##################  TPic::GetVector  ###############
*   Purpose....: Get interrupt vector							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
char TPic::GetVector()
{
	int Number;
	char Mask;

	Number = GetIrr();
	if (Number >= 0)
	{
		if (FCascade[Number])
			return FCascade[Number]->GetVector();

		Mask = 1 << Number;
		FIrr = FIrr & ~Mask;
		FIsr = FIsr | Mask;
		if (FIcw4 && ICW4_8086)
			return (FIcw2 & 0xF8) | (char)Number;
		else
			return (FIcw2 & 0xF8) | 7;
	}
	else
		return (FIcw2 & 0xF8) | 7;
}

/*##################  TPic::Out  ###############
*   Purpose....: Perform out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPic::Out(int Num, int Offset, char Value)
{
	if (Offset)
	{
		switch (FMode)
		{
			case MODE_ICW1:
				break;

			case MODE_ICW2:
				FIcw2 = Value;
				if (FIcw1 & ICW1_SINGLE)
				{
					if (FIcw1 & ICW1_ICW4_NEEDED)
						FMode = MODE_ICW4;
					else
						FMode = MODE_NORMAL;
				}
				else
					FMode = MODE_ICW3;
				break;


			case MODE_ICW3:
				FIcw3 = Value;
				if (FIcw1 & ICW1_ICW4_NEEDED)
					FMode = MODE_ICW4;
				else
					FMode = MODE_NORMAL;
				break;

			case MODE_ICW4:
				FIcw4 = Value;
				FMode = MODE_NORMAL;
				break;

			case MODE_NORMAL:
				FImr = Value;
				break;
		}
	}
	else
	{
		if (Value & 0x10)
		{
			FIcw1 = Value;
			FMode = MODE_ICW2;
		}
		else
		{
			if (Value & 8)
			{
				if (Value & OCW3_RR)
				{
					if (Value & OCW3_RIS)
						FRis = TRUE;
					else
						FRis = FALSE;
				}	
			}
			else
				Command((Value >> 5) & 7, Value & 7);
		}
	}
}

/*##################  TPic::In  ###############
*   Purpose....: Perform in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
char TPic::In(int Num, int Offset)
{
	if (Offset)
		return FImr;
	else
	{
		if (FIsr)
			return FIsr;
		else
			return FIrr;
	}
}
