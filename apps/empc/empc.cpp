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

#include <windows.h>
#include <conio.h>
#include <stdio.h>
#include "emulate.h"
#include "pic.h"
#include "pit.h"

#define STACK_SIZE	0x4000

TPic Pic0;
TPit Pit;

/*##################  PitSetOut0  ###############
*   Purpose....: Out 0 on PIT set								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void PitSetOut0()
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
void PitResetOut0()
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
		Pit.Counter[0].SetClk();
		Pit.Counter[2].SetClk();
	}
	else
	{
		Pit.Counter[0].ResetClk();
		Pit.Counter[2].ResetClk();
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
void __stdcall ReadFromMemory(TCpu *Cpu, void *Buffer, unsigned long Address, int Size)
{
	int i;
	unsigned long Ads;
	char *Dest;
	char *Source;

	if (Cpu->Running)
		AddCycles(Cpu, (Size - 1) / 4 + 1);

	Ads = Address;
	Dest = (char *)Buffer;

	for (i = 0; i < Size; i++)
	{
		if (Ads >= 0xFFF00000)
		{
			Source = (char *)Cpu->Eprom;
			Source += Ads & 0xFFFFF;
			*Dest = *Source;
		}
		else
		{
			if (Ads < 0x400000)
			{
				Source = (char *)Cpu->Dram;
				Source += Ads;
				*Dest = *Source;
			}
			else
				*Dest = 0xFF;
		}
		Ads++;
		Dest++;
	}
}

/*##################  WriteToMemory  ###############
*   Purpose....:  Write to memory				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void __stdcall WriteToMemory(TCpu *Cpu, void *Buffer, unsigned long Address, int Size)
{
	int i;
	unsigned long Ads;
	char *Dest;
	char *Source;

	if (Cpu->Running)
		AddCycles(Cpu, (Size - 1) / 4 + 1);

	Ads = Address;
	Dest = (char *)Buffer;

	for (i = 0; i < Size; i++)
	{
		if (Ads < 0x400000)
		{
			Source = (char *)Cpu->Dram;
			Source += Ads;
			*Source = *Dest;
		}
		Ads++;
		Dest++;
	}
}

/*##################  ReadFromIo  ###############
*   Purpose....: Read from IO				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void __stdcall ReadFromIo(TCpu *Cpu, void *Buffer, unsigned short int Port, int Size)
{
	char *Dest;

	if (Cpu->Running)
		AddCycles(Cpu, (Size - 1) / 4 + 1);

	Dest = (char *)Buffer;

	switch (Port & 0xFFF0)
	{
		case 0x20:
			*Dest = Pic0.In(Port & 0xF);
			break;

		case 0x40:
			*Dest = Pit.In(Port & 0xF);
			break;

		default:
			*Dest = 0;
	}
}

/*##################  WriteToIo  ###############
*   Purpose....: Read from IO				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void __stdcall WriteToIo(TCpu *Cpu, void *Buffer, unsigned short int Port, int Size)
{
	char *Dest;

	if (Cpu->Running)
		AddCycles(Cpu, (Size - 1) / 4 + 1);

	Dest = (char *)Buffer;

	switch (Port & 0xFFF0)
	{
		case 0x20:
			Pic0.Out(Port & 0xF, *Dest);
			break;

		case 0x40:
			Pit.Out(Port & 0xF, *Dest);
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
void Reset(TCpu *Cpu)
{
	HFILE file;
	int i;
	long l;
	long *LongPtr;

	Cpu->Eprom = malloc(0x100000);
	Cpu->Dram = malloc(0x400000);

	LongPtr = (long *)Cpu->Dram;
	for (l = 0; l < 0x100000; l++)
	{
		*LongPtr = 0x77777777;
		LongPtr++;
	}

	file = _lopen("bootprom.bin", 0);
	if (file)
	{
		_lread(file, Cpu->Eprom, 0x100000);
		_lclose(file);
	}

	Cpu->TotalCycles = 0;
	Cpu->Reg_eax = 0x12345678;
	Cpu->Reg_ebx = 0x12345678;
	Cpu->Reg_ecx = 0x12345678;
	Cpu->Reg_edx = 0x401;
	Cpu->Reg_esi = 0x12345678;
	Cpu->Reg_edi = 0x12345678;
	Cpu->Reg_ebp = 0x12345678;
	Cpu->Reg_esp = 0x12345678;
	Cpu->Reg_eflags = 2;
	Cpu->Reg_eip = 0xFFF0;
	Cpu->Reg_cs.selector = 0xF000;
	Cpu->Reg_cs.base = 0xFFFF0000;
	Cpu->Reg_cs.limit = 0xFFFF;
	Cpu->Reg_cs.access =	ACCESS_READ | ACCESS_WRITE;
	Cpu->Reg_ss.selector = 0;
	Cpu->Reg_ss.base = 0;
	Cpu->Reg_ss.limit = 0xFFFF;
	Cpu->Reg_ss.access = 	ACCESS_READ | ACCESS_WRITE;
	Cpu->Reg_ds.selector = 0;
	Cpu->Reg_ds.base = 0;
	Cpu->Reg_ds.limit = 0xFFFF;
	Cpu->Reg_ds.access = 	ACCESS_READ | ACCESS_WRITE;
	Cpu->Reg_es.selector = 0;
	Cpu->Reg_es.base = 0;
	Cpu->Reg_es.limit = 0xFFFF;
	Cpu->Reg_es.access = 	ACCESS_READ | ACCESS_WRITE;
	Cpu->Reg_fs.selector = 0;
	Cpu->Reg_fs.base = 0;
	Cpu->Reg_fs.limit = 0xFFFF;
	Cpu->Reg_fs.access =	ACCESS_READ | ACCESS_WRITE;
	Cpu->Reg_gs.selector = 0;
	Cpu->Reg_gs.base = 0;
	Cpu->Reg_gs.limit = 0xFFFF;
	Cpu->Reg_gs.access = 	ACCESS_READ | ACCESS_WRITE;

	Cpu->Reg_cr0 = 0x60000010;
	Cpu->Reg_cr2 = 0x12345678;
	Cpu->Reg_cr3 = 0x12345678;
	Cpu->Reg_gdt.base = 0x12345678;
	Cpu->Reg_gdt.limit = 0x1234;
	Cpu->Reg_idt.base = 0;
	Cpu->Reg_idt.limit = 0x3FF;
	Cpu->Reg_ldt.base = 0;
	Cpu->Reg_ldt.limit = 0x1234;
	Cpu->Reg_tr.selector = 0x1234;
	Cpu->Reg_tr.base = 0x12345678;

	Cpu->Running = FALSE;
	Cpu->PendingInt = 0;

	Pit.Counter[0].OnSetOut = PitSetOut0;
	Pit.Counter[1].OnResetOut = PitResetOut0;
}

/*##################  main  ###############
*   Purpose....: main				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
extern "C" void main(void)
{
	TCpu Cpu;
	int Done;
	unsigned int BreakCs;
	unsigned long BreakEip;
	int CheckHlt;
	int CheckDelay;
	int i;
	int FpuReg;
	int FpuTag;

	Reset(&Cpu);
	DisAssemble(&Cpu);
	WriteRegs(&Cpu);
	while (1)
	{
		switch (getch())
		{
			case 'f':
			case 'F':
				FpuTag = Cpu.Tag;
				FpuReg = Cpu.MathStatus >> 11;
				for (i = 7; i >= 0; i--)
				{
					switch ((FpuTag >> (2 * ((FpuReg + i) & 7))) & 3)
					{
						case 0:
							printf("ST(%d)= %Lg\r\n", i, Cpu.st[(FpuReg + i) & 7]);
							break;

						case 1:
							printf("ST(%d)=ZERO\r\n", i);
							break;

						case 2:
							printf("ST(%d)=NAN\r\n", i);
							break;

						case 3:
							printf("ST(%d)\r\n", i);
							break;
					}
				}
				break;

			case 'q':
			case 'Q':
				return;

			case 't':
			case 'T':
				if (Cpu.ReqBuffer[0] == 0xCC)
					Cpu.Reg_eip++;
				else
					Emulate(&Cpu);
				ReadInstruction(&Cpu);
				DisAssemble(&Cpu);
				WriteRegs(&Cpu);
				break;

			case 'p':
			case 'P':
				switch (Cpu.ReqBuffer[0])
				{
					case 0xCC:
						Cpu.Reg_eip++;
						ReadInstruction(&Cpu);
						Done = TRUE;
						break;

					case 0x9A:
						BreakCs = Cpu.Reg_cs.selector;
						BreakEip = Cpu.Reg_eip + 5;
						Emulate(&Cpu);
						ReadInstruction(&Cpu);
						Done = FALSE;
						CheckHlt = FALSE;
						break;

					case 0xE8:
						BreakCs = Cpu.Reg_cs.selector;
						BreakEip = Cpu.Reg_eip + 3;
						Emulate(&Cpu);
						ReadInstruction(&Cpu);
						Done = FALSE;
						CheckHlt = FALSE;
						break;

					case 0xF4:
						Done = FALSE;
						CheckHlt = TRUE;
						break;

					default:
						Emulate(&Cpu);
						ReadInstruction(&Cpu);
						Done = TRUE;
						break;
				}

				CheckDelay = 1000;
				while (!Done)
				{
					if (CheckHlt)
						Done = Cpu.ReqBuffer[0] != 0xF4;
					else
						Done = (BreakCs == Cpu.Reg_cs.selector &&
								BreakEip == Cpu.Reg_eip);
					if (!Done)
					{
						Emulate(&Cpu);
						if (Cpu.EmFlags & TRIPLE_FAULT)
							Done = TRUE;
						else
						{
							if (!CheckDelay)
							{
								CheckDelay = 1000;
								if  (kbhit())
								{
									getch();
									Done = TRUE;
								}
							}
							else
								CheckDelay--;
						}
						ReadInstruction(&Cpu);
					}
				}
				DisAssemble(&Cpu);
				WriteRegs(&Cpu);
				break;

			case 'g':
			case 'G':
				Done = Cpu.ReqBuffer[0] == 0xCC;
				CheckDelay = 1000;
				while (!Done)
				{
					Emulate(&Cpu);
					if (Cpu.EmFlags & TRIPLE_FAULT)
						Done = TRUE;
					ReadInstruction(&Cpu);
					if (Cpu.ReqBuffer[0] == 0xCC)
					{
						Done = TRUE;
						Cpu.Reg_eip++;
					}
					else
					{
						if (!CheckDelay)
						{
							CheckDelay = 1000;
							if (kbhit())
							{
								getch();
								Done = TRUE;
							}
						}
						else
							CheckDelay--;
					}
				}
				DisAssemble(&Cpu);
				WriteRegs(&Cpu);
				break;
		}
	}
}
