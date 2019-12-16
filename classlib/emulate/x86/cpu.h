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
* CPU.H
* CPU emulation class
*
*##########################################################################*/

#ifndef _CPU_H
#define _CPU_H

#include "int.h"

#pragma pack( push, 1 )

#define MAX_BREAKPOINTS 16

#define STATE_RESET             0
#define STATE_IDLE              1
#define STATE_BUSY              2

#define EFLAGS_ID               0x200000
#define EFLAGS_VIP              0x100000
#define EFLAGS_VIF              0x080000
#define EFLAGS_AC               0x040000
#define EFLAGS_VM               0x020000
#define EFLAGS_RF               0x010000
#define EFLAGS_NT               0x004000
#define EFLAGS_IOPL             0x003000
#define EFLAGS_OF               0x000800
#define EFLAGS_DF               0x000400
#define EFLAGS_IF               0x000200
#define EFLAGS_TF               0x000100
#define EFLAGS_SF               0x000080
#define EFLAGS_ZF               0x000040
#define EFLAGS_AF               0x000010
#define EFLAGS_PF               0x000004
#define EFLAGS_CF               0x000001

#define CR0_PG                  0x80000000
#define CR0_CD                  0x40000000
#define CR0_NW                  0x20000000
#define CR0_AM                  0x00040000
#define CR0_WP                  0x00010000
#define CR0_NE                  0x00000020
#define CR0_TS                  0x00000008
#define CR0_EM                  0x00000004
#define CR0_MP                  0x00000002
#define CR0_PE                  0x00000001

#define EFER_LME                0x100

#define ACCESS_RPL              0x03
#define ACCESS_DIR              0x10
#define ACCESS_READ             0x20
#define ACCESS_WRITE            0x40
#define ACCESS_32               0x80
#define ACCESS_64               0x100

#define SINGLE_FAULT    0x10
#define DOUBLE_FAULT    0x20
#define TRIPLE_FAULT    0x40
#define TRAP_FAULT              0x80

#define DEBUG_BREAK             1
#define DEBUG_RESUME    2

#define TLB_REGISTER            0x00000001
#define SYSTEM_REGISTER         0x00000010
#define DESCRIPTOR_REGISTER     0x00000100
#define GENERAL_REGISTER        0x00001000
#define CONTROL_REGISTER        0x00010000
#define INSTRUCTION_CODE_ONLY   0x00100000

typedef struct
{
 unsigned long long Offset;
 unsigned short int Selector;
} TLocation;

typedef struct
{
        unsigned long long base;
        unsigned long limit;
        unsigned short int selector;
        unsigned short int access;
} TDescriptor;

typedef struct
{
        unsigned long long tag;
        unsigned long long address;
} TTlbEntry;

typedef struct
{
        TTlbEntry tlb[32];
        unsigned long lru;
        unsigned long mask;
        unsigned long ptr;
} TTlb;

class TCpuState
{
public:
    TCpuState();
    ~TCpuState();

    void Reset();

// don't change data members here, without also changing in emulate.inc file

        unsigned long long Reg_cr0;
        unsigned long long Reg_cr2;
        unsigned long long Reg_cr3;
        unsigned long long Reg_cr4;
        unsigned long long Reg_dr0;
        unsigned long long Reg_dr1;
        unsigned long long Reg_dr2;
        unsigned long long Reg_dr3;
        unsigned long long Reg_dr6;
        unsigned long long Reg_dr7;
        unsigned long long Reg_eip;
        unsigned long long Reg_eflags;
        unsigned long long Reg_eax;
        unsigned long long Reg_ebx;
        unsigned long long Reg_ecx;
        unsigned long long Reg_edx;
        unsigned long long Reg_esp;
        unsigned long long Reg_ebp;
        unsigned long long Reg_esi;
        unsigned long long Reg_edi;
        unsigned long long Reg_r8;
        unsigned long long Reg_r9;
        unsigned long long Reg_r10;
        unsigned long long Reg_r11;
        unsigned long long Reg_r12;
        unsigned long long Reg_r13;
        unsigned long long Reg_r14;
        unsigned long long Reg_r15;
        TDescriptor Reg_gdt;
        TDescriptor Reg_idt;
        TDescriptor Reg_tr;
        TDescriptor Reg_ldt;
        TDescriptor Reg_es;
        TDescriptor Reg_cs;
        TDescriptor Reg_ss;
        TDescriptor Reg_ds;
        TDescriptor Reg_fs;
        TDescriptor Reg_gs;

        unsigned long long Reg_efer;

        unsigned long BitmapBase;

        char MathOp[2];
        char MathPrevOp[2];
        unsigned short int MathControl;
        unsigned short int MathStatus;
        unsigned short int Tag;
        unsigned long MathEip;
        unsigned short int MathCs;
        unsigned long MathOffset;
        unsigned short int MathSel;
        char st[8][10];

        TTlb Reg_tlb;

        unsigned long long OrgEip;
        unsigned long long OrgEsp;
        unsigned long OrgStack;

        unsigned long long CodeStart;
        unsigned char CodeCache[32];

        unsigned char ReqBuffer[32];

        long IoCount;
        long MemCount;

        short int EmFlags;

        char PendingInt;

        char EmDebug;
        char EmSreg;
        char EmPl;
        char EmTransfer;
        char EmParams;
        char EmIst;
        char EmRex;
        char EmModrm;
        char EmExtraBytes;
        short int EmErrorCode;

        short int DisAsmHandle;
        char OpcodeText[80];
        unsigned long long DataOffset;
        unsigned long DataSelector;
        char DataValid;
        char CpuType;
        long EflagsMask;

        TCpu *Cpu;
        TBus *Bus;

};

class TCpu
{
public:
    TCpu();
    ~TCpu();

    virtual void DefineBus(TBus *Bus);

    void Force386();
    void Force486();

    void SetCycleTime(int ns);
    void SetMemAccessTime(int ns);
    void SetIoAccessTime(int ns);
    void SetExtClkTime(int ns);

    void Show();
    void ShowFpu();

    void ShowCpu();
    void ShowInstruction();
    void ShowExecTime();

    int LoadUserDescriptor(int Sel);
    void ShowData(int Sel, int Offset);

    void SetInt(TInterrupt *Interrupt);
    void ResetInt(TInterrupt *Interrupt);
    char AckInt();

    void Trace();
    void Pace();
    void Go();
    void Break();

    virtual void Reset();

    virtual char ReadMemoryByte(unsigned long long Address);
    virtual short int ReadMemoryWord(unsigned long long Address);
    virtual long ReadMemoryDword(unsigned long long Address);
    virtual long long ReadMemoryQword(unsigned long long Address);

    virtual void WriteMemoryByte(unsigned long long Address, char val);
    virtual void WriteMemoryWord(unsigned long long Address, short int val);
    virtual void WriteMemoryDword(unsigned long long Address, long val);
    virtual void WriteMemoryQword(unsigned long long Address, long long val);

    virtual char ReadIoByte(unsigned short int Port);
    virtual short int ReadIoWord(unsigned short int Port);
    virtual long ReadIoDword(unsigned short int Port);

    virtual void WriteIoByte(unsigned short int Port, char val);
    virtual void WriteIoWord(unsigned short int Port, short int val);
    virtual void WriteIoDword(unsigned short int Port, long val);

    virtual void WriteMsr(unsigned long Address, long long val);
    virtual long long ReadMsr(unsigned long Address);

    virtual void Fint();

    virtual void UpdateTime(int ns);

    void SysCall();
    void AddBreakpoint(unsigned short Selector, unsigned long long Offset);
    void ClearBreakpoints();

    TCpuState CpuState;

    void (*OnExtClk)(TCpu *Cpu);
    char (*OnReadMemoryByte)(TCpu *Cpu, unsigned long long Address);
    short int (*OnReadMemoryWord)(TCpu *Cpu, unsigned long long Address);
    long (*OnReadMemoryDword)(TCpu *Cpu, unsigned long long Address);
    long long (*OnReadMemoryQword)(TCpu *Cpu, unsigned long long Address);

    void (*OnWriteMemoryByte)(TCpu *Cpu, unsigned long long Address, char val);
    void (*OnWriteMemoryWord)(TCpu *Cpu, unsigned long long Address, short int val);
    void (*OnWriteMemoryDword)(TCpu *Cpu, unsigned long long Address, long val);
    void (*OnWriteMemoryQword)(TCpu *Cpu, unsigned long long Address, long long val);

    char (*OnReadIoByte)(TCpu *Cpu, unsigned short Port);
    short int (*OnReadIoWord)(TCpu *Cpu, unsigned short Port);
    long (*OnReadIoDword)(TCpu *Cpu, unsigned short Port);

    void (*OnWriteIoByte)(TCpu *Cpu, unsigned short Port, char val);
    void (*OnWriteIoWord)(TCpu *Cpu, unsigned short Port, short int val);
    void (*OnWriteIoDword)(TCpu *Cpu, unsigned short Port, long val);

    void (*OnSysCall)(TCpu *Cpu);

    TInterrupt *FInterrupt;

    TDescriptor UserDescriptor;

protected:
    void ShowDescriptor(const char *str, TDescriptor *des);
    int EmulateOne();

    TLocation *FBreakpoints[MAX_BREAKPOINTS];
    int FMaxBreak;

    int FCycleTime;
    int FMemTime;
    int FIoTime;
    int FExtClkTime;

    int FExtNs;
    long long FTotalNs;

private:
};

#pragma pack( pop )

#endif
