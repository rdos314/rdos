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
#include "cpu.h"
#include "pic.h"
#include "pit.h"
#include "keyb.h"
#include "pci.h"
#include "zfnb.h"
#include "zfsb.h"
#include "zfsmi.h"
#include "zfide.h"
#include "zfxbus.h"
#include "zfusb.h"
#include "cmos.h"

void OpenScreen(const char *FileName);
void CloseScreen();

#define STACK_SIZE	0x4000

TPic Pic0;
TPit Pit(&Pic0);
TKeyb Keyb;
TCmos Cmos;
TPci Pci;
TCpu Cpu;
void *Eprom;
char *LowRam;

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

/*##################  PitSetOut0  ###############
*   Purpose....: Out 0 on PIT set								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void PitSetOut0(void *Cpu)
{
	Pic0.Set(0);
}

/*##################  PitResetOut0  ###############
*   Purpose....: Out 0 on PIT reset								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void PitResetOut0(void *Cpu)
{
	Pic0.Reset(0);
}

/*##################  AddCycles  ###############
*   Purpose....: Add cpu cycles									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void AddCycles(TCpu *Cpu, unsigned int Cycles)
{
	long TotalCycles;

	TotalCycles = Cpu->TotalCycles + Cycles;
	Cpu->TotalCycles = TotalCycles;
	TotalCycles = TotalCycles / 8;
	if (TotalCycles & 1)
	{
		Pit.Counter[0]->SetClk();
		Pit.Counter[2]->SetClk();
	}
	else
	{
		Pit.Counter[0]->ResetClk();
		Pit.Counter[2]->ResetClk();
		Cpu->PendingInt = Pic0.IsIntActive();
	}
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
	char *Source;

	if (Address >= 0xFFFC0000 || (Address >= 0xC0000 && Address < 0x100000))
	{
		Source = (char *)Eprom;
		Source += Address & 0x3FFFF;
		return *Source;
	}
	else
	{
        if (Address < 0x10000 && Address >= 0xF000)
            return *(LowRam + Address);
        else
	        return Pci.ReadMem(Address);
	}
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
    if (Address < 0x10000 && Address >= 0xF000)
        *(LowRam + Address) = Value;
    else
		Pci.WriteMem(Address, Value);
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
	switch (Port & 0xFFF0)
	{
		case 0x20:
		    switch (Port)
		    {
		        case 0x20:
		        case 0x21:
        			return Pic0.In(Port & 1);

        	    default:
        		    return Pci.In(Port);
			}
        	break;

		case 0x40:
			return Pit.In(Port & 0xF);

		case 0x60:
		    if (Pci.IsKeyboardEnabled())
    			return Keyb.In(Port & 0xF);
			else
				return 0xFF;

		case 0x70:
			return Cmos.In(Port & 0xF);

		default:
		    return Pci.In(Port);
	}
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
	switch (Port & 0xFFF0)
	{
		case 0x20:
		    switch (Port)
		    {
				case 0x20:
		        case 0x21:
        			Pic0.Out(Port & 1, Value);
        			break;

        	    default:
        	        Pci.Out(Port, Value);
        	        break;
        	}
        	break;


			break;

		case 0x40:
			Pit.Out(Port & 0xF, Value);
			break;

		case 0x60:
		    if (Pci.IsKeyboardEnabled())
				Keyb.Out(Port & 0xF, Value);
			break;

		case 0x70:
			Cmos.Out(Port & 0xF, Value);
			break;

		default:
			Pci.Out(Port, Value);
			break;
	}
}

/*##################  Reset  ###############
*   Purpose....: Set CPU registers to reset state				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void Reset()
{
	int file;
	int i;
	long l;
	long *LongPtr;
	int size;
	Eprom = new char[0x40000];
	LowRam = new char[0x10000];

	file = RdosOpenFile("demo.rom", 0);
	if (file)
	{
		size = RdosGetFileSize(file);
		RdosReadFile(file, ((char *)Eprom) + 0x40000 - size, size);
		RdosCloseFile(file);
	}

	Pit.Counter[0]->OnSetOut = PitSetOut0;
	Pit.Counter[1]->OnResetOut = PitResetOut0;
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
	OpenScreen("c:\\sim.log");

	Pci.RegisterFunction(new TZfxNorthBridge(&Pci), 0, 0, 0);
	Pci.RegisterFunction(new TZfxSouthBridge(&Pci), 0, 0x12, 0);
	Pci.RegisterFunction(new TZfxSmi(&Pci), 0, 0x12, 1);
	Pci.RegisterFunction(new TZfxIde(&Pci), 0, 0x12, 2);
	Pci.RegisterFunction(new TZfxXbus(&Pci), 0, 0x12, 3);
	Pci.RegisterFunction(new TZfxUsb(&Pci), 0, 0x13, 0);

	Cpu.OnIdle = Idle;
	Cpu.OnReadFromMemory = ReadFromMemory;
	Cpu.OnWriteToMemory = WriteToMemory;
	Cpu.OnReadFromIo = ReadFromIo;
	Cpu.OnWriteToIo = WriteToIo;
	Cpu.Reset();

	Reset();

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
