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
* CPU.CPP
* CPU emulation
*
*##########################################################################*/

#include <stdio.h>
#include "cpu.h"

#define FALSE 0
#define TRUE !FALSE

unsigned int NewCs = 0;
unsigned long NewEip = 0;
int debugflag;

#define COUNTBUFFER	10
TLocation set_val,get_val;
TLocation	buffer_val[COUNTBUFFER];

extern "C"
{

void __stdcall UserBreak(TCpu *Cpu);
void __stdcall ReadInstruction(TCpu *Cpu);
void __stdcall DisAssemble(TCpu *Cpu);
void __stdcall WriteRegs(TCpu *Cpu);
void __stdcall Emulate(TCpu *Cpu);
char __stdcall GetIntVector(TCpu *Cpu);
void __stdcall ReadFromMemory(TCpu *Cpu, void *Buffer, unsigned long Address, int Size);
void __stdcall WriteToMemory(TCpu *Cpu, void *Buffer, unsigned long Address, int Size);
void __stdcall ReadFromIo(TCpu *Cpu, void *Buffer, unsigned short int Port, int Size);
void __stdcall WriteToIo(TCpu *Cpu, void *Buffer, unsigned short int Port, int Size);
void __stdcall Dis_ass_more(TCpu *Cpu, unsigned long count);
void __stdcall initbuffer(void *buffer, unsigned long count);
void  __stdcall  getvalue(TCpu *Cpu);
void __stdcall setvalue(TLocation *position);
void __stdcall init_follow();		/* to initiate the follow procedure */
void  __stdcall  showdata(TCpu *Cpu);  /* print ata on the screen */

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
	return Cpu->GetIntVector();
}

/*##################  ReadFromMemory  ###############
*   Purpose....: Read from memory								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void __stdcall ReadFromMemory(TCpu *Cpu, void *Buffer, unsigned long Address, int Size)
{
	Cpu->ReadFromMemory(Buffer, Address, Size);
}

/*##################  WriteToMemory  ###############
*   Purpose....: Write to memory								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void __stdcall WriteToMemory(TCpu *Cpu, void *Buffer, unsigned long Address, int Size)
{
	Cpu->WriteToMemory(Buffer, Address, Size);
}

/*##################  ReadFromIo  ###############
*   Purpose....: Read from IO								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void __stdcall ReadFromIo(TCpu *Cpu, void *Buffer, unsigned short Port, int Size)
{
	Cpu->ReadFromIo(Buffer, Port, Size);
}

/*##################  WriteToIo  ###############
*   Purpose....: Write to IO								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void __stdcall WriteToIo(TCpu *Cpu, void *Buffer, unsigned short Port, int Size)
{
	Cpu->WriteToIo(Buffer, Port, Size);
}

/*##################  TCpu::TCpu  ###############
*   Purpose....: Constructor for CPU							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TCpu::TCpu()
{
	int i;

	for (i = 0; i < MAX_BREAKPOINTS; i++)
		FBreakpoints[i] = 0;

	debugflag = SYSTEM_REGISTER | DESCRIPTOR_REGISTER | GENERAL_REGISTER | CONTROL_REGISTER;
	initbuffer(buffer_val,COUNTBUFFER); /* initialise le buffer*/

	OnIdle = 0;
	OnSetClk = 0;
	OnResetClk = 0;
	OnReadFromMemory = 0;
	OnWriteToMemory = 0;
	OnReadFromIo = 0;
	OnWriteToIo = 0;
	FPic = 0;
	FUpdateCycles = FALSE;
	Reset();
}

/*##################  TCpu::~TCpu  ###############
*   Purpose....: Destructor for CPU							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TCpu::~TCpu()
{
	ClearBreakpoints();
}

/*##################  TCpu::Define  ###############
*   Purpose....: Define interupt controller						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::Define(TPic *Pic)
{
	FPic = Pic;
}

/*##################  TCpu::Reset  ###############
*   Purpose....: Set CPU registers to reset state				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::Reset()
{
	TotalCycles = 0;
	Reg_eax = 0x12345678;
	Reg_ebx = 0x12345678;
	Reg_ecx = 0x12345678;
	Reg_edx = 0x301;
	Reg_esi = 0x12345678;
	Reg_edi = 0x12345678;
	Reg_ebp = 0x12345678;
	Reg_esp = 0x0;
	Reg_eflags = 2;
	Reg_eip = 0xFFF0;
	Reg_cs.selector = 0xF000;
	Reg_cs.base = 0xFFFF0000;
	Reg_cs.limit = 0xFFFF;
	Reg_cs.access =	ACCESS_READ | ACCESS_WRITE;
	Reg_ss.selector = 0;
	Reg_ss.base = 0;
	Reg_ss.limit = 0xFFFF;
	Reg_ss.access = 	ACCESS_READ | ACCESS_WRITE;
	Reg_ds.selector = 0;
	Reg_ds.base = 0;
	Reg_ds.limit = 0xFFFF;
	Reg_ds.access = 	ACCESS_READ | ACCESS_WRITE;
	Reg_es.selector = 0;
	Reg_es.base = 0;
	Reg_es.limit = 0xFFFF;
	Reg_es.access = 	ACCESS_READ | ACCESS_WRITE;
	Reg_fs.selector = 0;
	Reg_fs.base = 0;
	Reg_fs.limit = 0xFFFF;
	Reg_fs.access =	ACCESS_READ | ACCESS_WRITE;
	Reg_gs.selector = 0;
	Reg_gs.base = 0;
	Reg_gs.limit = 0xFFFF;
	Reg_gs.access = 	ACCESS_READ | ACCESS_WRITE;

	Reg_cr0 = 0x60000010;
	Reg_cr2 = 0x12345678;
	Reg_cr3 = 0x12345678;
	Reg_gdt.base = 0x12345678;
	Reg_gdt.limit = 0x1234;
	Reg_idt.base = 0;
	Reg_idt.limit = 0x3FF;
	Reg_ldt.base = 0;
	Reg_ldt.limit = 0x1234;
	Reg_tr.selector = 0x1234;
	Reg_tr.base = 0x12345678;

	Running = FALSE;
	PendingInt = 0;
	EmDebug = 0;
}

/*##################  TCpu::AddBreakpoint  ###############
*   Purpose....: Add a breakpoint								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::AddBreakpoint(unsigned short Selector, unsigned long Offset)
{
	int i;

	for (i = 0; i < MAX_BREAKPOINTS; i++)
		if (!FBreakpoints[i])
		{
			FBreakpoints[i] = new TLocation;
			FBreakpoints[i]->Selector = Selector;
			FBreakpoints[i]->Offset = Offset;
			break;
		}
}

/*##################  TCpu::ClearBreakpoints  ###############
*   Purpose....: Clear all breakpoints								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::ClearBreakpoints()
{
	int i;

	for (i = 0; i < MAX_BREAKPOINTS; i++)
		if (FBreakpoints[i])
		{
			delete FBreakpoints[i];
			FBreakpoints[i] = 0;
		}
}

/*##################  TCpu::NotifyIdle  ###############
*   Purpose....: Notify idle									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::NotifyIdle()
{
	if (OnIdle)
		(*OnIdle)(this);
}

/*##################  TCpu::NotifySetClk  ###############
*   Purpose....: Notify set clk									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::NotifySetClk()
{
	if (OnSetClk)
		(*OnSetClk)(this);
}

/*##################  TCpu::NotifyResetClk  ###############
*   Purpose....: Notify reset clk									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::NotifyResetClk()
{
	if (FPic)
		PendingInt = FPic->IsIntActive();

	if (OnResetClk)
		(*OnResetClk)(this);
}

/*##################  TCpu::GetIntVector  ###############
*   Purpose....: Get interrupt vector							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TCpu::GetIntVector()
{
	if (FPic)
		return FPic->GetVector();
	else
		return 0;
}

/*##################  TCpu::ReadFromMemory  ###############
*   Purpose....: Read from memory				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TCpu::ReadFromMemory(unsigned long Address)
{
	if (OnReadFromMemory)
		return (*OnReadFromMemory)(this, Address);
	else
		return 0xFF;
}

/*##################  TCpu::WriteToMemory  ###############
*   Purpose....: Write to memory				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::WriteToMemory(unsigned long Address, char Value)
{
	if (OnWriteToMemory)
		(*OnWriteToMemory)(this, Address, Value);
}

/*##################  TCpu::ReadFromIo  ###############
*   Purpose....: Read from IO				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TCpu::ReadFromIo(unsigned short Port)
{
	if (OnReadFromIo)
		return (*OnReadFromIo)(this, Port);
	else
		return 0xFF;
}

/*##################  TCpu::WriteToIo  ###############
*   Purpose....: Write to IO				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::WriteToIo(unsigned short Port, char Value)
{
	if (OnWriteToIo)
		(*OnWriteToIo)(this, Port, Value);
}

/*##################  TCpu::ReadFromMemory  ###############
*   Purpose....: Read from memory				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::ReadFromMemory(void *Buffer, unsigned long Address, int Size)
{
	int i;
	char *Dest;

	if (Running)
		AddCycles((Size - 1) / 4 + 1);

	Dest = (char *)Buffer;

	for (i = 0; i < Size; i++)
	{
		*Dest = ReadFromMemory(Address);
		Address++;
		Dest++;
	}
}

/*##################  TCpu::WriteToMemory  ###############
*   Purpose....:  Write to memory				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::WriteToMemory(void *Buffer, unsigned long Address, int Size)
{
	int i;
	char *Dest;

	if (Running)
		AddCycles((Size - 1) / 4 + 1);

	Dest = (char *)Buffer;

	for (i = 0; i < Size; i++)
	{
		WriteToMemory(Address, *Dest);
		Address++;
		Dest++;
	}
}

/*##################  TCpu::ReadFromIo  ###############
*   Purpose....: Read from IO				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::ReadFromIo(void *Buffer, unsigned short int Port, int Size)
{
	char *Dest;
	int i;

	if (Running)
		AddCycles((Size - 1) / 4 + 1);

	Dest = (char *)Buffer;

	for (i = 0; i < Size; i++)
	{
		*Dest = ReadFromIo(Port);
		Port++;
		Dest++;
	}
}

/*##################  TCpu::WriteToIo  ###############
*   Purpose....: Read from IO				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::WriteToIo(void *Buffer, unsigned short int Port, int Size)
{
	char *Dest;
	int i;

	if (Running)
		AddCycles((Size - 1) / 4 + 1);

	Dest = (char *)Buffer;

	for (i = 0; i < Size; i++)
	{
		WriteToIo(Port, *Dest);
		Port++;
		Dest++;
	}
}

/*##################  TCpu::EmulateOne  ###############
*   Purpose....: Emulate one instruction									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::EmulateOne()
{
	FUpdateCycles = TRUE;
	Emulate(this);
	FUpdateCycles = FALSE;
}

/*##################  TCpu::AddCycles  ###############
*   Purpose....: Add cpu cycles									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::AddCycles(unsigned int Cycles)
{
	long Total;

	if (FUpdateCycles)
	{
		TotalCycles += Cycles;
		Total = TotalCycles / 8;
		if (Total & 1)
			NotifySetClk();
		else
			NotifyResetClk();
	}
}

/*##################  TCpu::Break  ###############
*   Purpose....: Break											            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::Break()
{
	if (Running)
		UserBreak(this);
	else
		EmDebug |= DEBUG_BREAK;
}

/*##################  TCpu::Trace  ###############
*   Purpose....: Trace									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::Trace()
{
	if (ReqBuffer[0] == 0xCC)
		Reg_eip++;
	else
		EmulateOne();
	ReadInstruction(this);
}

/*##################  TCpu::Pace  ###############
*   Purpose....: Pace									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::Pace()
{
	int Done;
	unsigned int BreakCs;
	unsigned long BreakEip;
	int CheckHlt = FALSE;
	int CheckDelay;
	int BreakOnEqual = TRUE;

	switch (ReqBuffer[0])
	{
		case 0xCC:
			Reg_eip++;
			ReadInstruction(this);
			Done = TRUE;
			break;

		case 0x9A:
			BreakCs = Reg_cs.selector;
			BreakEip = Reg_eip + 5;
			EmulateOne();
			ReadInstruction(this);
			Done = FALSE;
			break;

		case 0xE0:
		case 0xE1:
		case 0xE2:
			BreakCs = Reg_cs.selector;
			BreakEip = Reg_eip + 2;
			EmulateOne();
			ReadInstruction(this);
			Done = FALSE;
			break;

		case 0xE8:
			BreakCs = Reg_cs.selector;
			BreakEip = Reg_eip + 3;
			EmulateOne();
			ReadInstruction(this);
			Done = FALSE;
			break;

		case 0xF4:
			Done = FALSE;
			CheckHlt = TRUE;
			break;

		default:
			BreakCs = Reg_cs.selector;
			BreakEip = Reg_eip;
			BreakOnEqual = FALSE;
			EmulateOne();
			ReadInstruction(this);
			Done = FALSE;
			break;
	}

	CheckDelay = 1000;
	while (!Done)
	{
		if (CheckHlt)
			Done = ReqBuffer[0] != 0xF4;
		else
		{
			Done = (BreakCs == Reg_cs.selector &&
					BreakEip == Reg_eip);
			if (!BreakOnEqual)
				Done = !Done;
		}
		if (!Done)
		{
			EmulateOne();
			if (EmDebug & DEBUG_BREAK)
				Done = TRUE;
			else
			{
				if (!CheckDelay)
				{
					CheckDelay = 1000;
					NotifyIdle();
					if (EmDebug & DEBUG_BREAK)
						Done = TRUE;
				}
				else
					CheckDelay--;
			}
			ReadInstruction(this);
		}
	}
}

/*##################  TCpu::Go  ###############
*   Purpose....: Go												            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::Go()
{
	int Done;
	int CheckDelay;
	int i;

	Done = ReqBuffer[0] == 0xCC;
	CheckDelay = 1000;
	while (!Done)
	{
		EmulateOne();
		if (EmDebug & DEBUG_BREAK)
			Done = TRUE;

		for (i = 0; i < MAX_BREAKPOINTS; i++)
			if (FBreakpoints[i])
				if (Reg_cs.selector == FBreakpoints[i]->Selector && Reg_eip == FBreakpoints[i]->Offset)
					Done = TRUE;

// fixed breakpoints for ZFX86
		if (Reg_eip == 0x2517)
			Done = TRUE;

		if (!Done)
		{
			ReadInstruction(this);
			if (ReqBuffer[0] == 0xCC)
			{
				Done = TRUE;
				Reg_eip++;
			}
			else
			{
				if (!CheckDelay)
				{
					CheckDelay = 1000;
					NotifyIdle();
					if (EmDebug & DEBUG_BREAK)
						Done = TRUE;
				}
				else
					CheckDelay--;
			}
		}
	}
}

/*##################  TCpu::Disassemble  ###############
*   Purpose....:  Disassemble 20 instruction    		            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 01-05-20                                                   #
*##########################################################################*/
void TCpu::ShowInstruction(int Count)
{
	TCpu Cpu_backup;

	debugflag = INSTRUCTION_CODE_ONLY;
	Cpu_backup = *this;
	if (NewCs == 0)
		Dis_ass_more(this, Count);
	else
	{
		Reg_cs.selector = NewCs;
 		Reg_eip = NewEip;
 		
        Dis_ass_more(this, Count);
	}	
        
	*this = Cpu_backup;
    debugflag = SYSTEM_REGISTER | DESCRIPTOR_REGISTER | GENERAL_REGISTER | CONTROL_REGISTER;
}

/*##################  TCpu::ShowPreviousInstruction  ###############
*   Purpose....:  Disassemble previous instruction    		    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 01-05-20                                                   #
*##########################################################################*/
void TCpu::ShowPreviousInstruction()
{
	TCpu Cpu_backup;

	debugflag = INSTRUCTION_CODE_ONLY;
	Cpu_backup = *this;	
	getvalue(this);
	*this = Cpu_backup;
    debugflag = SYSTEM_REGISTER | DESCRIPTOR_REGISTER | GENERAL_REGISTER | CONTROL_REGISTER;
}

/*##################  TCpu::ShowData  ###############
*   Purpose....:  print data on the screnn
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 17-06-2001                                                   #
*##########################################################################*/
void TCpu::ShowData()
{
	TCpu Cpu_backup;

	Cpu_backup = *this;		/* save Cpu context*/
	if (NewCs == 0)
		showdata(this);
	else
	{
		Reg_gs.selector = NewCs;
 		Reg_esi = NewEip;
 		
        showdata(this);
	}	

	*this = Cpu_backup;
    debugflag = SYSTEM_REGISTER | DESCRIPTOR_REGISTER | GENERAL_REGISTER | CONTROL_REGISTER;
}

/*##################  TCpu::Show  ###############
*   Purpose....: Show registers									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::Show()
{
	DisAssemble(this);
	WriteRegs(this);
}

/*##################  TCpu::ShowFpu  ###############
*   Purpose....: Show FPU									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::ShowFpu()
{
	int FpuReg;
	int FpuTag;
	int i;

	FpuTag = Tag;
	FpuReg = MathStatus >> 11;
	for (i = 7; i >= 0; i--)
	{
		switch ((FpuTag >> (2 * ((FpuReg + i) & 7))) & 3)
		{
			case 0:
				printf("ST(%d)= %Lg\r\n", i, st[(FpuReg + i) & 7]);
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
}
