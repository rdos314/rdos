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

#define COUNTBUFFER     10
TLocation set_val,get_val;
TLocation       buffer_val[COUNTBUFFER];

#pragma aux EMAPI "_*" \
       parm routine [] \
       value struct float struct routine [eax] \
       modify [eax ecx edx];

extern "C" {

void UserBreak(TCpuState *CpuState);
#pragma aux (EMAPI) UserBreak;

void ReadInstruction(TCpuState *CpuState);
#pragma aux (EMAPI) ReadInstruction;

void DisAssemble(TCpuState *CpuState);
#pragma aux (EMAPI) DisAssemble;

void WriteRegs(TCpuState *CpuState);
#pragma aux (EMAPI) WriteRegs;

void WriteFpuRegs(TCpuState *CpuState);
#pragma aux (EMAPI) WriteFpuRegs;

void Emulate(TCpuState *CpuState);
#pragma aux (EMAPI) Emulate;

char GetIntVector(TCpuState *CpuState);
#pragma aux (EMAPI) GetIntVector;

void ReadFromMemory(TCpuState *CpuState, void *Buffer, unsigned long long Address, int Size);
#pragma aux (EMAPI) ReadFromMemory;

void WriteToMemory(TCpuState *CpuState, void *Buffer, unsigned long long Address, int Size);
#pragma aux (EMAPI) WriteToMemory;

void ReadFromIo(TCpuState *CpuState, void *Buffer, unsigned short int Port, int Size);
#pragma aux (EMAPI) ReadFromIo;

void WriteToIo(TCpuState *CpuState, void *Buffer, unsigned short int Port, int Size);
#pragma aux (EMAPI) WriteToIo;

void SysCall(TCpuState *CpuState);
#pragma aux (EMAPI) SysCall;

void Dis_ass_more(TCpuState *CpuState, unsigned long count);
#pragma aux (EMAPI) Dis_ass_more;

void initbuffer(void *buffer, unsigned long count);
#pragma aux (EMAPI) initbuffer;

void getvalue(TCpuState *CpuState);
#pragma aux (EMAPI) getvalue;

void setvalue(TLocation *position);
#pragma aux (EMAPI) setvalue;

void init_follow();            /* to initiate the follow procedure */
#pragma aux (EMAPI) init_follow;

void showdata(TCpuState *CpuState);  /* print ata on the screen */
#pragma aux (EMAPI) showdata;

};

/*##################  GetIntVector  ###############
*   Purpose....: Get interrupt vector                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char GetIntVector(TCpuState *CpuState)
{
    return CpuState->Cpu->AckInt();
}

/*##################  ReadFromMemory  ###############
*   Purpose....: Read from memory                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void ReadFromMemory(TCpuState *CpuState, void *Buffer, unsigned long long Address, int Size)
{
    if (CpuState->CodeFetch)
        CpuState->Cpu->ReadCode(Buffer, Address, Size);
    else
        CpuState->Cpu->ReadFromMemory(Buffer, Address, Size);
}

/*##################  WriteToMemory  ###############
*   Purpose....: Write to memory                                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteToMemory(TCpuState *CpuState, void *Buffer, unsigned long long Address, int Size)
{
    CpuState->Cpu->WriteToMemory(Buffer, Address, Size);
}

/*##################  ReadFromIo  ###############
*   Purpose....: Read from IO                                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void ReadFromIo(TCpuState *CpuState, void *Buffer, unsigned short Port, int Size)
{
    CpuState->Cpu->ReadFromIo(Buffer, Port, Size);
}

/*##################  WriteToIo  ###############
*   Purpose....: Write to IO                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteToIo(TCpuState *CpuState, void *Buffer, unsigned short Port, int Size)
{
    CpuState->Cpu->WriteToIo(Buffer, Port, Size);
}

/*##################  SysCall  ###############
*   Purpose....: Syscall                                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void SysCall(TCpuState *CpuState)
{
    CpuState->Cpu->SysCall();
}

/*##################  TCpuState::TCpuState  ###############
*   Purpose....: Constructor for CPU state                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TCpuState::TCpuState()
{    
    Reset();
}

/*##################  TCpuState::~TCpuState  ###############
*   Purpose....: Destructor for CPU state                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TCpuState::~TCpuState()
{    
}

/*##################  TCpuState::TCpuState  ###############
*   Purpose....: Reset CPU state                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpuState::Reset()
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
        Reg_cs.access = ACCESS_READ | ACCESS_WRITE;
        Reg_ss.selector = 0;
        Reg_ss.base = 0;
        Reg_ss.limit = 0xFFFF;
        Reg_ss.access =         ACCESS_READ | ACCESS_WRITE;
        Reg_ds.selector = 0;
        Reg_ds.base = 0;
        Reg_ds.limit = 0xFFFF;
        Reg_ds.access =         ACCESS_READ | ACCESS_WRITE;
        Reg_es.selector = 0;
        Reg_es.base = 0;
        Reg_es.limit = 0xFFFF;
        Reg_es.access =         ACCESS_READ | ACCESS_WRITE;
        Reg_fs.selector = 0;
        Reg_fs.base = 0;
        Reg_fs.limit = 0xFFFF;
        Reg_fs.access = ACCESS_READ | ACCESS_WRITE;
        Reg_gs.selector = 0;
        Reg_gs.base = 0;
        Reg_gs.limit = 0xFFFF;
        Reg_gs.access =         ACCESS_READ | ACCESS_WRITE;

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

/*##################  TCpu::TCpu  ###############
*   Purpose....: Constructor for CPU                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TCpu::TCpu()
{
        int i;

        CpuState.CodeFetch = 0;
        CpuState.Cpu = this;

        for (i = 0; i < MAX_BREAKPOINTS; i++)
                FBreakpoints[i] = 0;

        debugflag = SYSTEM_REGISTER | DESCRIPTOR_REGISTER | GENERAL_REGISTER | CONTROL_REGISTER;
        initbuffer(buffer_val,COUNTBUFFER); /* initialise le buffer*/

        OnIdle = 0;
        OnSetClk = 0;
        OnResetClk = 0;
        OnSysCall = 0;
        OnReadFromMemory = 0;
        OnWriteToMemory = 0;
        OnReadFromIo = 0;
        OnWriteToIo = 0;
        FUpdateCycles = FALSE;
        Reset();
        CpuState.CpuType = 5;
        CpuState.EflagsMask = 0x3FFFD7;
}

/*##################  TCpu::~TCpu  ###############
*   Purpose....: Destructor for CPU                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TCpu::~TCpu()
{
        ClearBreakpoints();
}

/*##################  TCpu::Force386  ###############
*   Purpose....: Force 386 CPU                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::Force386()
{
    CpuState.CpuType = 3;
    CpuState.EflagsMask = 0x3FFD7;
}

/*##################  TCpu::Force486  ###############
*   Purpose....: Force 486 CPU                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::Force486()
{
    CpuState.CpuType = 4;
    CpuState.EflagsMask = 0x7FFD7;
}

/*##################  TCpu::SetInt  ###############
*   Purpose....: Set interrupt state                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::SetInt(TInterrupt *Interrupt)
{
    CpuState.PendingInt = TRUE;
    FInterrupt = Interrupt;
}

/*##################  TCpu::ResetInt  ###############
*   Purpose....: Reset interrupt state                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::ResetInt(TInterrupt *Interrupt)
{
    CpuState.PendingInt = FALSE;
}

/*##################  TCpu::AckInt  ###############
*   Purpose....: Acknowledge int                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TCpu::AckInt()
{
    if (FInterrupt)
        return FInterrupt->Ack();
    else
        return 0;
}

/*##################  TCpu::Reset  ###############
*   Purpose....: Set CPU registers to reset state                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::Reset()
{
    CpuState.Reset();
}

/*##################  TCpu::AddBreakpoint  ###############
*   Purpose....: Add a breakpoint                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::AddBreakpoint(unsigned short Selector, unsigned long long Offset)
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
*   Purpose....: Clear all breakpoints                                                                      #
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
*   Purpose....: Notify idle                                                                                #
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
*   Purpose....: Notify set clk                                                                             #
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
*   Purpose....: Notify reset clk                                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::NotifyResetClk()
{
    if (OnResetClk)
        (*OnResetClk)(this);
}

/*##################  TCpu::SysCall  ###############
*   Purpose....: Do syscall                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::SysCall()
{
        if (OnSysCall)
                (*OnSysCall)(this);
}

/*##################  TCpu::ReadCode  ###############
*   Purpose....: Read code                                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TCpu::ReadCode(unsigned long long Address)
{
    return ReadFromMemory(Address);
}

/*##################  TCpu::ReadFromMemory  ###############
*   Purpose....: Read from memory                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TCpu::ReadFromMemory(unsigned long long Address)
{
        if (OnReadFromMemory)
                return (*OnReadFromMemory)(this, Address);
        else
                return 0xFF;
}

/*##################  TCpu::WriteToMemory  ###############
*   Purpose....: Write to memory                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::WriteToMemory(unsigned long long Address, char Value)
{
        if (OnWriteToMemory)
                (*OnWriteToMemory)(this, Address, Value);
}

/*##################  TCpu::ReadFromIo  ###############
*   Purpose....: Read from IO                                       #
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
*   Purpose....: Write to IO                                        #
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

/*##################  TCpu::ReadCode  ###############
*   Purpose....: Read code                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::ReadCode(void *Buffer, unsigned long long Address, int Size)
{
        int i;
        char *Dest;

        if (CpuState.Running)
                AddCycles((Size - 1) / 4 + 1);

        Dest = (char *)Buffer;

        for (i = 0; i < Size; i++)
        {
                *Dest = ReadCode(Address);
                Address++;
                Dest++;
        }
}

/*##################  TCpu::ReadFromMemory  ###############
*   Purpose....: Read from memory                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::ReadFromMemory(void *Buffer, unsigned long long Address, int Size)
{
        int i;
        char *Dest;

        if (CpuState.Running)
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
*   Purpose....:  Write to memory                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::WriteToMemory(void *Buffer, unsigned long long Address, int Size)
{
        int i;
        char *Dest;

        if (CpuState.Running)
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
*   Purpose....: Read from IO                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::ReadFromIo(void *Buffer, unsigned short int Port, int Size)
{
        char *Dest;
        int i;

        if (CpuState.Running)
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
*   Purpose....: Read from IO                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::WriteToIo(void *Buffer, unsigned short int Port, int Size)
{
        char *Dest;
        int i;

        if (CpuState.Running)
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
*   Purpose....: Emulate one instruction                                                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::EmulateOne()
{
    FUpdateCycles = TRUE;
    Emulate(&CpuState);
    FUpdateCycles = FALSE;
}

/*##################  TCpu::AddCycles  ###############
*   Purpose....: Add cpu cycles                                                                             #
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
                CpuState.TotalCycles += Cycles;
                Total = CpuState.TotalCycles / 8;
                if (Total & 1)
                        NotifySetClk();
                else
                        NotifyResetClk();
        }
}

/*##################  TCpu::Break  ###############
*   Purpose....: Break                                                                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::Break()
{
        if (CpuState.Running)
                UserBreak(&CpuState);
        else
                CpuState.EmDebug |= DEBUG_BREAK;
}

/*##################  TCpu::Trace  ###############
*   Purpose....: Trace                                                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::Trace()
{
        if (CpuState.ReqBuffer[0] == 0xCC)
                CpuState.Reg_eip++;
        else
                EmulateOne();
        ReadInstruction(&CpuState);
}

/*##################  TCpu::Pace  ###############
*   Purpose....: Pace                                                                               #
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

        switch (CpuState.ReqBuffer[0])
        {
                case 0xCC:
                        CpuState.Reg_eip++;
                        ReadInstruction(&CpuState);
                        Done = TRUE;
                        break;

                case 0x9A:
                        BreakCs = CpuState.Reg_cs.selector;
                        BreakEip = CpuState.Reg_eip + 5;
                        EmulateOne();
                        ReadInstruction(&CpuState);
                        Done = FALSE;
                        break;

                case 0xE0:
                case 0xE1:
                case 0xE2:
                        BreakCs = CpuState.Reg_cs.selector;
                        BreakEip = CpuState.Reg_eip + 2;
                        EmulateOne();
                        ReadInstruction(&CpuState);
                        Done = FALSE;
                        break;

                case 0xE8:
                        BreakCs = CpuState.Reg_cs.selector;
                        BreakEip = CpuState.Reg_eip + 3;
                        EmulateOne();
                        ReadInstruction(&CpuState);
                        Done = FALSE;
                        break;

                case 0xF4:
                        Done = FALSE;
                        CheckHlt = TRUE;
                        break;

                default:
                        BreakCs = CpuState.Reg_cs.selector;
                        BreakEip = CpuState.Reg_eip;
                        BreakOnEqual = FALSE;
                        EmulateOne();
                        ReadInstruction(&CpuState);
                        Done = FALSE;
                        break;
        }

        CheckDelay = 1000;
        while (!Done)
        {
                if (CheckHlt)
                        Done = CpuState.ReqBuffer[0] != 0xF4;
                else
                {
                        Done = (BreakCs == CpuState.Reg_cs.selector &&
                                        BreakEip == CpuState.Reg_eip);
                        if (!BreakOnEqual)
                                Done = !Done;
                }
                if (!Done)
                {
                        EmulateOne();
                        if (CpuState.EmDebug & DEBUG_BREAK)
                                Done = TRUE;
                        else
                        {
                                if (!CheckDelay)
                                {
                                        CheckDelay = 1000;
                                        NotifyIdle();
                                        if (CpuState.EmDebug & DEBUG_BREAK)
                                                Done = TRUE;
                                }
                                else
                                        CheckDelay--;
                        }
                        ReadInstruction(&CpuState);
                }
        }
}

/*##################  TCpu::Go  ###############
*   Purpose....: Go                                                                                                         #
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

        Done = CpuState.ReqBuffer[0] == 0xCC;
        CheckDelay = 1000;
        while (!Done)
        {
                EmulateOne();
                if (CpuState.EmDebug & DEBUG_BREAK)
                        Done = TRUE;

                for (i = 0; i < MAX_BREAKPOINTS; i++)
                        if (FBreakpoints[i])
                                if (CpuState.Reg_cs.selector == FBreakpoints[i]->Selector && CpuState.Reg_eip == FBreakpoints[i]->Offset)
                                        Done = TRUE;

                if (!Done)
                {
                        ReadInstruction(&CpuState);
                        if (CpuState.ReqBuffer[0] == 0xCC)
                        {
                                Done = TRUE;
                                CpuState.Reg_eip++;
                        }
                        else
                        {
                                if (!CheckDelay)
                                {
                                        CheckDelay = 1000;
                                        NotifyIdle();
                                        if (CpuState.EmDebug & DEBUG_BREAK)
                                                Done = TRUE;
                                }
                                else
                                        CheckDelay--;
                        }
                }
        }
}

/*##################  TCpu::Disassemble  ###############
*   Purpose....:  Disassemble 20 instruction                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 01-05-20                                                   #
*##########################################################################*/
void TCpu::ShowInstruction(int Count)
{
        TCpuState Cpu_backup;

        debugflag = INSTRUCTION_CODE_ONLY;
        Cpu_backup = CpuState;
        if (NewCs == 0)
                Dis_ass_more(&CpuState, Count);
        else
        {
                CpuState.Reg_cs.selector = NewCs;
                CpuState.Reg_eip = NewEip;
                
        Dis_ass_more(&CpuState, Count);
        }       
        
        CpuState = Cpu_backup;
    debugflag = SYSTEM_REGISTER | DESCRIPTOR_REGISTER | GENERAL_REGISTER | CONTROL_REGISTER;
}

/*##################  TCpu::ShowPreviousInstruction  ###############
*   Purpose....:  Disassemble previous instruction                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 01-05-20                                                   #
*##########################################################################*/
void TCpu::ShowPreviousInstruction()
{
        TCpuState Cpu_backup;

        debugflag = INSTRUCTION_CODE_ONLY;
        Cpu_backup = CpuState;     
        getvalue(&CpuState);
        CpuState = Cpu_backup;
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
        TCpuState Cpu_backup;

        Cpu_backup = CpuState;             /* save Cpu context*/
        if (NewCs == 0)
                showdata(&CpuState);
        else
        {
                CpuState.Reg_gs.selector = NewCs;
                CpuState.Reg_esi = NewEip;
                
        showdata(&CpuState);
        }       

        CpuState = Cpu_backup;
    debugflag = SYSTEM_REGISTER | DESCRIPTOR_REGISTER | GENERAL_REGISTER | CONTROL_REGISTER;
}

/*##################  TCpu::Show  ###############
*   Purpose....: Show registers                                                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::Show()
{
        DisAssemble(&CpuState);
        WriteFpuRegs(&CpuState);
        WriteRegs(&CpuState);
}

/*##################  TCpu::ShowFpu  ###############
*   Purpose....: Show FPU                                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::ShowFpu()
{
        WriteFpuRegs(&CpuState);
}

