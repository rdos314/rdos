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
* SIM.CPP
* Main simulator
*
*##########################################################################*/

#include <rdos.h>
#include <stdio.h>
#include "v25.h"
#include "pic.h"
#include "pit.h"
#include "flash.h"
#include "ram.h"

void OpenScreen(const char *FileName);
void CloseScreen();

#define STACK_SIZE	0x4000

TIsa Isa;
TPic Pic0(&Isa, 0x20);
TPit Pit(&Isa, 0x40);
TFlash Flash(&Isa, 0x80000, 0x80000);
TRam Ram(&Isa, 0, 0x80000);
TV25Cpu Cpu;

/*##################  Idle  ###############
*   Purpose....: Idle								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void Idle(TCpu *Cpu)
{
	if (RdosPollKeyboard())
	{
		RdosReadKeyboard();
		Cpu->Break();
	}
}

/*##################  SetClk  ###############
*   Purpose....: 1 / 8 clk high notification					            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void SetClk(TCpu *Cpu)
{
	Pit.Counter[0]->SetClk();
	Pit.Counter[2]->SetClk();
}

/*##################  ResetClk  ###############
*   Purpose....: 1 / 8 clk low notification					            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void ResetClk(TCpu *Cpu)
{
	Pit.Counter[0]->ResetClk();
	Pit.Counter[2]->ResetClk();
	Cpu->PendingInt = Pic0.IsIntActive();
}

/*##################  GetIntVector  ###############
*   Purpose....: Get interrupt vector							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char __stdcall GetIntVector(TCpu *Cpu)
{
	return Pic0.GetVector();
}

/*##################  ReadFromMemory  ###############
*   Purpose....: Read from memory				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char ReadFromMemory(TCpu *Cpu, unsigned long Address)
{
	return Isa.ReadMem(Address);
}

/*##################  WriteToMemory  ###############
*   Purpose....:  Write to memory				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteToMemory(TCpu *Cpu, unsigned long Address, char Value)
{
	Isa.WriteMem(Address, Value);
}

/*##################  ReadFromIo  ###############
*   Purpose....: Read from IO				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char ReadFromIo(TCpu *Cpu, unsigned short int Port)
{
	return Isa.In(Port);
}

/*##################  WriteToIo  ###############
*   Purpose....: Read from IO				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteToIo(TCpu *Cpu, unsigned short int Port, char Value)
{
	Isa.Out(Port, Value);
}

/*##################  main  ###############
*   Purpose....: main				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void main(void)
{
	TFile FlashFile("ploader.bin");

	OpenScreen("f:\\sim.log");

	Flash.LoadTop(&FlashFile);

	Pit.Counter[0]->Define(&Pic0, 0);

	Cpu.Define(&Pic0);
	Cpu.OnSetClk = SetClk;
	Cpu.OnResetClk = ResetClk;
	Cpu.OnIdle = Idle;
	Cpu.OnReadFromMemory = ReadFromMemory;
	Cpu.OnWriteToMemory = WriteToMemory;
	Cpu.OnReadFromIo = ReadFromIo;
	Cpu.OnWriteToIo = WriteToIo;
	Cpu.Reset();

	while (1)
	{
		Cpu.Show();
		switch (RdosReadKeyboard() & 0xFF)
		{
			case 'f':
			case 'F':
				Cpu.ShowFpu();
				RdosReadKeyboard();
				break;

			case 'd':
			case 'D':
				Cpu.ShowData();
				RdosReadKeyboard();
				break;

			case 'q':
			case 'Q':
				return;

			case 't':
			case 'T':
				Cpu.Trace();
				break;

			case 'p':
			case 'P':
				Cpu.Pace();
				break;

			case 'g':
			case 'G':
				Cpu.Go();
				break;

			case 'u':
			case 'U':
				Cpu.ShowInstruction(20);
				RdosReadKeyboard();
				break;

			case 'b':
			case 'B':
				Cpu.ShowPreviousInstruction();
				RdosReadKeyboard();
				break;
		}
	}
	CloseScreen();
}
