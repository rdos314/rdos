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
#include <string.h>
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

char ReadMemoryByte(TCpuState *CpuState, unsigned long long Address);
#pragma aux (EMAPI) ReadMemoryByte;

short int ReadMemoryWord(TCpuState *CpuState, unsigned long long Address);
#pragma aux (EMAPI) ReadMemoryWord;

long ReadMemoryDword(TCpuState *CpuState, unsigned long long Address);
#pragma aux (EMAPI) ReadMemoryDword;

long long ReadMemoryQword(TCpuState *CpuState, unsigned long long Address);
#pragma aux (EMAPI) ReadMemoryQword;

void WriteMemoryByte(TCpuState *CpuState, unsigned long long Address, char val);
#pragma aux (EMAPI) WriteMemoryByte;

void WriteMemoryWord(TCpuState *CpuState, unsigned long long Address, short int val);
#pragma aux (EMAPI) WriteMemoryWord;

void WriteMemoryDword(TCpuState *CpuState, unsigned long long Address, long val);
#pragma aux (EMAPI) WriteMemoryDword;

void WriteMemoryQword(TCpuState *CpuState, unsigned long long Address, long long val);
#pragma aux (EMAPI) WriteMemoryQword;

char ReadIoByte(TCpuState *CpuState, unsigned short int Port);
#pragma aux (EMAPI) ReadIoByte;

short int ReadIoWord(TCpuState *CpuState, unsigned short int Port);
#pragma aux (EMAPI) ReadIoWord;

long ReadIoDword(TCpuState *CpuState, unsigned short int Port);
#pragma aux (EMAPI) ReadIoDword;

void WriteIoByte(TCpuState *CpuState, unsigned short int Port, char val);
#pragma aux (EMAPI) WriteIoByte;

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

/*##################  ReadMemoryByte  ###############
*   Purpose....: Read memory byte                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char ReadMemoryByte(TCpuState *CpuState, unsigned long long Address)
{
    if (CpuState->Bus)
        return CpuState->Bus->ReadMemoryByte(Address);
    else
        return CpuState->Cpu->ReadMemoryByte(Address);
}

/*##################  ReadMemoryWord  ###############
*   Purpose....: Read memory word                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int ReadMemoryWord(TCpuState *CpuState, unsigned long long Address)
{
    if (CpuState->Bus)
        return CpuState->Bus->ReadMemoryWord(Address);
    else
        return CpuState->Cpu->ReadMemoryWord(Address);
}

/*##################  ReadMemoryDword  ###############
*   Purpose....: Read memory dword                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long ReadMemoryDword(TCpuState *CpuState, unsigned long long Address)
{
    if (CpuState->Bus)
        return CpuState->Bus->ReadMemoryDword(Address);
    else
        return CpuState->Cpu->ReadMemoryDword(Address);
}

/*##################  ReadMemoryQword  ###############
*   Purpose....: Read memory qword                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long long ReadMemoryQword(TCpuState *CpuState, unsigned long long Address)
{
    if (CpuState->Bus)
        return CpuState->Bus->ReadMemoryQword(Address);
    else
        return CpuState->Cpu->ReadMemoryQword(Address);
}

/*##################  WriteMemoryByte  ###############
*   Purpose....: Write memory byte                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteMemoryByte(TCpuState *CpuState, unsigned long long Address, char val)
{
    if (CpuState->Bus)
        CpuState->Bus->WriteMemoryByte(Address, val);
    else
        CpuState->Cpu->WriteMemoryByte(Address, val);
}

/*##################  WriteMemoryWord  ###############
*   Purpose....: Write memory word                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteMemoryWord(TCpuState *CpuState, unsigned long long Address, short int val)
{
    if (CpuState->Bus)
        CpuState->Bus->WriteMemoryWord(Address, val);
    else
        CpuState->Cpu->WriteMemoryWord(Address, val);
}

/*##################  WriteMemoryDword  ###############
*   Purpose....: Write memory dword                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteMemoryDword(TCpuState *CpuState, unsigned long long Address, long val)
{
    if (CpuState->Bus)
        CpuState->Bus->WriteMemoryDword(Address, val);
    else
        CpuState->Cpu->WriteMemoryDword(Address, val);
}

/*##################  WriteMemoryQword  ###############
*   Purpose....: Write memory qword                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteMemoryQword(TCpuState *CpuState, unsigned long long Address, long long val)
{
    if (CpuState->Bus)
        CpuState->Bus->WriteMemoryQword(Address, val);
    else
        CpuState->Cpu->WriteMemoryQword(Address, val);
}

/*##################  ReadIoByte  ###############
*   Purpose....: Read byte from IO                                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char ReadIoByte(TCpuState *CpuState, unsigned short Port)
{
    return CpuState->Cpu->ReadIoByte(Port);
}

/*##################  ReadIoWord  ###############
*   Purpose....: Read word from IO                                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int ReadIoWord(TCpuState *CpuState, unsigned short Port)
{
    return CpuState->Cpu->ReadIoWord(Port);
}

/*##################  ReadIoDword  ###############
*   Purpose....: Read dword from IO                                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long ReadIoDword(TCpuState *CpuState, unsigned short Port)
{
    return CpuState->Cpu->ReadIoDword(Port);
}

/*##################  WriteIoByte  ###############
*   Purpose....: Write byte to IO                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteIoByte(TCpuState *CpuState, unsigned short Port, char val)
{
    CpuState->Cpu->WriteIoByte(Port, val);
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
        Reg_eax = 0x12345678;
        Reg_ebx = 0x12345678;
        Reg_ecx = 0x12345678;
        Reg_edx = 0x301;
        Reg_esi = 0x12345678;
        Reg_edi = 0x12345678;
        Reg_r8 = 0;
        Reg_r9 = 0;
        Reg_r10 = 0;
        Reg_r11 = 0;
        Reg_r12 = 0;
        Reg_r13 = 0;
        Reg_r14 = 0;
        Reg_r15 = 0;
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
        Reg_cr4 = 0;
        Reg_gdt.base = 0x12345678;
        Reg_gdt.limit = 0x1234;
        Reg_idt.base = 0;
        Reg_idt.limit = 0x3FF;
        Reg_ldt.base = 0;
        Reg_ldt.limit = 0x1234;
        Reg_tr.selector = 0x1234;
        Reg_tr.base = 0x12345678;

        CodeStart = 0xFFFFFFFFFFFFFFFF;

        Tag = 0; 
        MathControl = 0;
        MathStatus = 0;

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

        CpuState.Cpu = this;
        CpuState.Bus = 0;

        for (i = 0; i < MAX_BREAKPOINTS; i++)
                FBreakpoints[i] = 0;

        FMaxBreak = 0;
        FCycleTime = 50;
        FMemTime = 150;
        FIoTime = 500;
        FExtClkTime = 838;
        FExtNs = 0;
        FTotalNs = 0;

        debugflag = SYSTEM_REGISTER | DESCRIPTOR_REGISTER | GENERAL_REGISTER | CONTROL_REGISTER;
        initbuffer(buffer_val,COUNTBUFFER); /* initialise le buffer*/

        OnExtClk = 0;
        OnSysCall = 0;
        OnReadMemoryByte = 0;
        OnReadMemoryWord = 0;
        OnReadMemoryDword = 0;
        OnReadMemoryQword = 0;

        OnWriteMemoryByte = 0;
        OnWriteMemoryWord = 0;
        OnWriteMemoryDword = 0;
        OnWriteMemoryQword = 0;
        
        OnReadIoByte = 0;
        OnReadIoWord = 0;
        OnReadIoDword = 0;

        OnWriteIoByte = 0;
        
        OnWriteToIo = 0;
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

/*##################  TCpu::DefineBus  ###############
*   Purpose....: Define bus                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::DefineBus(TBus *Bus)
{
    CpuState.Bus = Bus;
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

/*##################  TCpu::SetCycleTime  ###############
*   Purpose....: Set CPU cycle time in nanoseconds                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::SetCycleTime(int ns)
{
    FCycleTime = ns;
}

/*##################  TCpu::SetMemAccessTime  ###############
*   Purpose....: Set memory access time in nanoseconds                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::SetMemAccessTime(int ns)
{
    FMemTime = ns;
}

/*##################  TCpu::SetIoAccessTime  ###############
*   Purpose....: Set IO access time in nanoseconds                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::SetIoAccessTime(int ns)
{
    FIoTime = ns;
}

/*##################  TCpu::SetExtClkTime  ###############
*   Purpose....: Set clock notification interval in nanoseconds                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::SetExtClkTime(int ns)
{
    FExtClkTime = ns;
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

                        if (i >= FMaxBreak)
                            FMaxBreak = i + 1;
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

        FMaxBreak = 0;

        for (i = 0; i < MAX_BREAKPOINTS; i++)
                if (FBreakpoints[i])
                {
                        delete FBreakpoints[i];
                        FBreakpoints[i] = 0;
                }
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

/*##################  TCpu::ReadMemoryByte  ###############
*   Purpose....: Read memory byte                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TCpu::ReadMemoryByte(unsigned long long Address)
{
    if (OnReadMemoryByte)
        return (*OnReadMemoryByte)(this, Address);
    else
        return 0xFF;
}

/*##################  TCpu::ReadMemoryWord  ###############
*   Purpose....: Read memory word                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int TCpu::ReadMemoryWord(unsigned long long Address)
{
    if (OnReadMemoryWord)
        return (*OnReadMemoryWord)(this, Address);
    else
        return 0xFFFF;
}

/*##################  TCpu::ReadMemoryDword  ###############
*   Purpose....: Read memory dword                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TCpu::ReadMemoryDword(unsigned long long Address)
{
    if (OnReadMemoryDword)
        return (*OnReadMemoryDword)(this, Address);
    else
        return 0xFFFFFFFF;
}

/*##################  TCpu::ReadMemoryQword  ###############
*   Purpose....: Read memory qword                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long long TCpu::ReadMemoryQword(unsigned long long Address)
{
    if (OnReadMemoryQword)
        return (*OnReadMemoryQword)(this, Address);
    else
        return 0xFFFFFFFFFFFFFFFF;
}

/*##################  TCpu::WriteMemoryByte  ###############
*   Purpose....: Write memory byte                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::WriteMemoryByte(unsigned long long Address, char val)
{
    if (OnWriteMemoryByte)
        (*OnWriteMemoryByte)(this, Address, val);
}

/*##################  TCpu::WriteMemoryWord  ###############
*   Purpose....: Write memory word                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::WriteMemoryWord(unsigned long long Address, short int val)
{
    if (OnWriteMemoryWord)
        (*OnWriteMemoryWord)(this, Address, val);
}

/*##################  TCpu::WriteMemoryDword  ###############
*   Purpose....: Write memory dword                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::WriteMemoryDword(unsigned long long Address, long val)
{
    if (OnWriteMemoryDword)
        (*OnWriteMemoryDword)(this, Address, val);
}

/*##################  TCpu::WriteMemoryQword  ###############
*   Purpose....: Write memory qword                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::WriteMemoryQword(unsigned long long Address, long long val)
{
    if (OnWriteMemoryQword)
        (*OnWriteMemoryQword)(this, Address, val);
}

/*##################  TCpu::ReadIoByte  ###############
*   Purpose....: Read byte from IO                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TCpu::ReadIoByte(unsigned short Port)
{
    if (OnReadIoByte)
        return (*OnReadIoByte)(this, Port);
    else
        return 0xFF;
}

/*##################  TCpu::ReadIoWord  ###############
*   Purpose....: Read word from IO                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int TCpu::ReadIoWord(unsigned short Port)
{
    if (OnReadIoWord)
        return (*OnReadIoWord)(this, Port);
    else
        return 0xFFFF;
}

/*##################  TCpu::ReadIoDword  ###############
*   Purpose....: Read dword from IO                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TCpu::ReadIoDword(unsigned short Port)
{
    if (OnReadIoDword)
        return (*OnReadIoDword)(this, Port);
    else
        return 0xFFFFFFFF;
}

/*##################  TCpu::WriteIoByte  ###############
*   Purpose....: Write byte to IO                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::WriteIoByte(unsigned short Port, char Value)
{
    if (OnWriteIoByte)
        (*OnWriteIoByte)(this, Port, Value);
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
int TCpu::EmulateOne()
{
    int ns;
    
    CpuState.MemCount = 0;
    CpuState.IoCount = 0;

    Emulate(&CpuState);

    ns = FCycleTime + CpuState.MemCount * FMemTime + CpuState.IoCount * FIoTime;

    FTotalNs += ns;
    FExtNs += ns;

    while (FExtNs > FExtClkTime)
    {
        FExtNs -= FExtClkTime;

        if (OnExtClk)
            (*OnExtClk)(this);
    }

    return FALSE;
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
                        if (CpuState.Reg_cs.access & ACCESS_SIZE)
                            BreakEip = CpuState.Reg_eip + 7;
                        else
                            BreakEip = CpuState.Reg_eip + 5;
                        EmulateOne();
                        ReadInstruction(&CpuState);
                        Done = FALSE;
                        break;

                case 0xE0:
                case 0xE1:
                case 0xE2:
                        BreakCs = CpuState.Reg_cs.selector;
                        if (CpuState.Reg_cs.access & ACCESS_SIZE)
                            BreakEip = CpuState.Reg_eip + 4;
                        else
                            BreakEip = CpuState.Reg_eip + 2;
                        EmulateOne();
                        ReadInstruction(&CpuState);
                        Done = FALSE;
                        break;

                case 0xE8:
                        BreakCs = CpuState.Reg_cs.selector;
                        if (CpuState.Reg_cs.access & ACCESS_SIZE)
                            BreakEip = CpuState.Reg_eip + 5;
                        else                        
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
        long long offset;
        unsigned char ch;

        Done = CpuState.ReqBuffer[0] == 0xCC;
        CheckDelay = 1000;
        while (!Done)
        {
                EmulateOne();
                if (CpuState.EmDebug & DEBUG_BREAK)
                        Done = TRUE;

                for (i = 0; i < FMaxBreak; i++)
                        if (FBreakpoints[i])
                                if (CpuState.Reg_cs.selector == FBreakpoints[i]->Selector && CpuState.Reg_eip == FBreakpoints[i]->Offset)
                                        Done = TRUE;

                if (!Done)
                {
                        offset = CpuState.Reg_eip  + CpuState.Reg_cs.base - CpuState.CodeStart;
                        if (offset < 0 || offset >= 0x20)
                        {
                            ReadInstruction(&CpuState);
                            ch = CpuState.ReqBuffer[0];
                        }
                        else
                            ch = CpuState.CodeCache[offset];
                            
                        if (ch == 0xCC)
                        {
                                Done = TRUE;
                                CpuState.Reg_eip++;
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
        ShowExecTime();
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

/*##################  TCpu::ShowExecTime  ###############
*   Purpose....: Show execution time                                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TCpu::ShowExecTime()
{
    long long val;
    int remain;
    char str[20];

    val = FTotalNs;    
    remain = val % 1000;
    val = val / 1000;
    if (val)
        sprintf(&str[16], "%03ld", remain);
    else
        sprintf(&str[16], "%3ld", remain);
    
// us

    if (val)
    {
        remain = val % 1000;
        val = val / 1000;
        if (val)
            sprintf(&str[12], "%03ld", remain);
        else
            sprintf(&str[12], "%3ld", remain);
    }
    else
        strcpy(&str[12], "   ");

    str[15] = ' ';

// ms

    if (val)
    {
        remain = val % 1000;
        val = val / 1000;
        if (val)
            sprintf(&str[8], "%03ld", remain);
        else
            sprintf(&str[8], "%3ld", remain);
    }
    else
        strcpy(&str[8], "   ");

    str[11] = ' ';

// s

    if (val)
    {
        sprintf(str, "%7ld", val);
        str[7] = ',';
    }
    else
    {
        strcpy(str, "       ");
        str[7] = ' ';
    }

    printf("Execution time: ");
    printf(str);
    printf("\r\n");
}

