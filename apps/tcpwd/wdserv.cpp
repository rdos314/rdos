/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# wdserv.cpp
# WD socket server class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "wdserv.h"
#include "wdsuppl.h"
#include "wdmsg.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

struct x86_cpu
{
	 long eax;
	 long ebx;
	 long ecx;
	 long edx;
	 long esi;
	 long edi;
	 long ebp;
	 long esp;
	 long eip;
	 long efl;
	 long cr0;
	 long cr2;
	 long cr3;
	 short int ds;
	 short int es;
	 short int ss;
	 short int cs;
	 short int fs;
	 short int gs;
};

struct fpu_ptr
{
	long     offset;
	long     segment;
};

struct x86_fpu
{
	 long           cw;
	 long           sw;
	 long           tag;
	 fpu_ptr        ip_err;
	 fpu_ptr        op_err;
	 long double    reg[8];
};

struct x86_xmm
{
	 char    xmm[8][16];
	 long 	mxcsr;
};

class x86_mad_registers
{
public:
    x86_mad_registers();
    void Init();
    void Set(TDebugThread *t);

	struct x86_cpu  cpu;
	struct x86_fpu  fpu;
	struct x86_xmm  xmm;
};

/*##########################################################################
#
#   Name       : x86_mad_registers::Init
#
#   Purpose....: init data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void x86_mad_registers::Init()
{
	int i, j;
    
    cpu.eax = 0;
    cpu.ebx = 0;
    cpu.ecx = 0;
    cpu.edx = 0;
    cpu.esi = 0;
    cpu.edi = 0;
    cpu.ebp = 0;
    cpu.esp = 0;
    cpu.eip = 0;
    cpu.efl = 0;
    cpu.cr0 = 0;
    cpu.cr2 = 0;
    cpu.cr3 = 0;
    cpu.ds = 0;
    cpu.es = 0;
    cpu.ss = 0;
    cpu.cs = 0;
    cpu.fs = 0;
    cpu.gs = 0;

    fpu.cw = 0;
    fpu.sw = 0;
    fpu.tag = 0;
    fpu.ip_err.offset = 0;
    fpu.ip_err.segment = 0;
    fpu.op_err.offset = 0;
    fpu.op_err.segment = 0;

    for (i = 0; i < 8; i++)
        fpu.reg[i] = 0.0;    

    for (i = 0; i < 8; i++)
        for (j = 0; j < 16; j++)
            xmm.xmm[i][j] = 0;

    xmm.mxcsr = 0;
}

/*##########################################################################
#
#   Name       : x86_mad_registers::x86_mad_registers
#
#   Purpose....: x86_mad_registers constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
x86_mad_registers::x86_mad_registers()
{
    Init();
}

/*##########################################################################
#
#   Name       : x86_mad_registers::Set
#
#   Purpose....: Set data from thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void x86_mad_registers::Set(TDebugThread *t)
{
    int i;

    Init();

    cpu.eax = t->Eax;
    cpu.ebx = t->Ebx;
    cpu.ecx = t->Ecx;
    cpu.edx = t->Edx;
    cpu.esi = t->Esi;
    cpu.edi = t->Edi;
    cpu.ebp = t->Ebp;
    cpu.esp = t->Esp;
    cpu.eip = t->Eip;
    cpu.efl = t->Eflags;

    cpu.cr0 = 0;
    cpu.cr2 = 0;
    cpu.cr3 = t->Cr3;
    cpu.ds = t->Ds;
    cpu.es = t->Es;
    cpu.ss = t->Ss;
    cpu.cs = t->Cs;
    cpu.fs = t->Fs;
    cpu.gs = t->Gs;

    fpu.cw = t->MathControl;
    fpu.sw = t->MathStatus;
    fpu.tag = t->MathTag;

    fpu.ip_err.offset = t->MathDataOffs;
    fpu.ip_err.segment = t->MathDataSel;
    fpu.op_err.offset = t->MathEip;
    fpu.op_err.segment = t->MathCs;

    for (i = 0; i < 8; i++)
        fpu.reg[i] = t->St[i];    
}

/*##########################################################################
#
#   Name       : TWdSocketServer::TWdSocketServer
#
#   Purpose....: Socket server constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSocketServer::TWdSocketServer(TWdSocketServerFactory *fact, const char *Name, int StackSize, TSocket *Socket)
  : TSocketServer(Name, StackSize, Socket)
{
	 FFactory = fact;
	 FSupplList = 0;
	 FDebug = 0;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::~TWdSocketServer
#
#   Purpose....: Socket server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSocketServer::~TWdSocketServer()
{
    TWdSupplService *service;

    while (FSupplList)
    {
		  service = FSupplList->FNext;
        delete FSupplList;
        FSupplList = service;
    }
}

/*##########################################################################
#
#   Name       : TWdSocketServer::GetByte
#
#   Purpose....: Read byte from input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TWdSocketServer::GetByte()
{
    char ch = *FInPtr;
    FInPtr++;
    return ch;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::GetWord
#
#   Purpose....: Read word from input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
short int TWdSocketServer::GetWord()
{
    short int val = *(short int *)FInPtr;
    FInPtr += 2;
    return val;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::GetDword
#
#   Purpose....: Read dword from input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long TWdSocketServer::GetDword()
{
    long val = *(long *)FInPtr;
    FInPtr += 4;
    return val;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::GetString
#
#   Purpose....: Read string from input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::GetString(char *str, int maxsize)
{
    int len = FInPtr - FInBuf;

    len = FInSize - len;

    if (len >= maxsize)
        len = maxsize - 1;
    
    if (len > 0)
    {
        memcpy(str, FInPtr, len);
        FInPtr += len;
        str[len] = 0;
    }
    else
		  str[0] = 0;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::PutByte
#
#   Purpose....: Write byte to output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::PutByte(char val)
{
    *FOutPtr = val;
    FOutPtr++;
	 FOutSize++;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::PutWord
#
#   Purpose....: Write word to output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::PutWord(short int val)
{
    *(short int *)FOutPtr = val;
	 FOutPtr += 2;
    FOutSize += 2;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::PutDword
#
#   Purpose....: Write dword to output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::PutDword(long val)
{
    *(long *)FOutPtr = val;
	 FOutPtr += 4;
    FOutSize += 4;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::PutString
#
#   Purpose....: Write string to output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::PutString(const char *str)
{
	 int len = strlen(str);

    memcpy(FOutPtr, str, len + 1);
    FOutPtr += len + 1;
    FOutSize += len + 1;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::PutData
#
#   Purpose....: Write data to output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::PutData(void *ptr, int size)
{
    memcpy(FOutPtr, ptr, size);
    FOutPtr += size;
    FOutSize += size;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::GetDebug
#
#   Purpose....: Get debug object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebug *TWdSocketServer::GetDebug()
{
    return FDebug;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::AddSuppl
#
#   Purpose....: Add supplementary service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::AddSuppl(TWdSupplService *service)
{
    service->FNext = FSupplList;
    FSupplList = service;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqError
#
#   Purpose....: Req error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqError()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqConnect
#
#   Purpose....: Req connect
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqConnect()
{
    char ch;

    ch = GetByte();

    if (ch == 17)
    {
        PutWord(MAX_MSG_SIZE);
        PutByte(0);
    }
    else   
    {
        PutWord(0);
        PutString("Illegal version");
    }
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqDisconnect
#
#   Purpose....: Req disconnect
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqDisconnect()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqSuspend
#
#   Purpose....: Req suspend
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqSuspend()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqResume
#
#   Purpose....: Req resume
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqResume()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqGetSupplService
#
#   Purpose....: Req get suppl service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqGetSupplService()
{
    char name[256];
    TWdSupplFactory *factory;
    TWdSupplService *service;

    GetString(name, 255);

    factory = FFactory->GetSuppl(name);

    PutDword(0);

    if (factory)
    {
        service = factory->Create(this);
        PutDword((long)service);
	 }
    else
        PutDword(0);
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqPerformSupplService
#
#   Purpose....: Req perform suppl service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqPerformSupplService()
{
	 int done = FALSE;
    TWdSupplService *service;
    TWdSupplService *ID;

    ID = (TWdSupplService *)GetDword();

    service = FSupplList;

    while (service && !done)
    {
        if (service == ID)
            done = TRUE;
        else
            service = service->FNext;
    }

    if (done)
		  service->NotifyMsg();
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqGetSysConfig
#
#   Purpose....: Req sys config
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqGetSysConfig()
{
    int major, minor, release;

	 RdosGetVersion(&major, &minor, &release);
    
	 PutByte(0x3F);
	 PutByte(0xF);
	 PutByte((char)major);
	 PutByte((char)minor);
	 PutByte(10);
	 PutByte(3);
	 PutWord(1);
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqMapAddr
#
#   Purpose....: Req map address
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqMapAddr()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqAddrInfo
#
#   Purpose....: Req address info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqAddrInfo()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqChecksumMem
#
#   Purpose....: Req checksum memory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqChecksumMem()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqReadMem
#
#   Purpose....: Req read memory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqReadMem()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqWriteMem
#
#   Purpose....: Req write memory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqWriteMem()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqReadIo
#
#   Purpose....: Req read IO
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqReadIo()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqWriteIo
#
#   Purpose....: Req write IO
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqWriteIo()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqReadCpu
#
#   Purpose....: Req read CPU
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqReadCpu()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqReadFpu
#
#   Purpose....: Req read FPU
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqReadFpu()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqWriteCpu
#
#   Purpose....: Req write CPU
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqWriteCpu()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqWriteFpu
#
#   Purpose....: Req write FPU
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqWriteFpu()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqProgGo
#
#   Purpose....: Req run program
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqProgGo()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqProgStep
#
#   Purpose....: Req step program
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqProgStep()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqProgLoad
#
#   Purpose....: Req load program
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqProgLoad()
{
	char truearg;
	char name[256];
	TPathName curdir;

	if (FDebug)
		delete FDebug;

	FDebug = 0;

	truearg = GetByte();
	GetString(name, 255);

	FDebug = new TDebug(name, "", curdir.Get().GetData());

    FMainThread = FDebug->GetMainThread();
    FCurrentThread = FDebug->GetCurrentThread();
    FMainModule = FDebug->GetMainModule();

    if (FMainThread && FMainModule)
    {
        PutDword(0);
        PutDword(FMainThread->ThreadID);
        PutDword(FMainModule->Handle);
        PutByte(0x10);
    }
    else
    {
        PutDword(MSG_LOAD_FAIL);
        PutDword(0);
        PutDword(0);
        PutByte(0);
	 }
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqProgKill
#
#   Purpose....: Req kill program
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqProgKill()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqSetWatch
#
#   Purpose....: Req set watch
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqSetWatch()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqClearWatch
#
#   Purpose....: Req clear watch
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqClearWatch()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqSetBreak
#
#   Purpose....: Req set breakpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqSetBreak()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqClearBreak
#
#   Purpose....: Req clear breakpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqClearBreak()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqGetNextAlias
#
#   Purpose....: Req get next alias
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqGetNextAlias()
{
    PutWord(0);
    PutWord(0);
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqSetUserScreen
#
#   Purpose....: Req set user screen
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqSetUserScreen()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqSetDebugScreen
#
#   Purpose....: Req set debug screen
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqSetDebugScreen()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqReadUserKeyboard
#
#   Purpose....: Req read user keyboard
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqReadUserKeyboard()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqGetLibName
#
#   Purpose....: Req get library name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqGetLibName()
{
    int Handle = GetDword();
    TDebugModule *Module;

    if (FDebug)
    {
		Handle = FDebug->GetNextModule(Handle);

        if (Handle)
        {
            Module = FDebug->LockModule(Handle);
            if (Module)
            {
                PutDword(Handle);
                PutString(Module->ModuleName.GetData());
            }
            else
                Handle = 0;

            FDebug->UnlockModule();
		}
	}
    else
        Handle = 0;

    if (!Handle)
        PutDword(Handle);
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqGetErrText
#
#   Purpose....: Req get error text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqGetErrText()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqGetMsgText
#
#   Purpose....: Req get msg text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqGetMsgText()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqRedirStdin
#
#   Purpose....: Req redirect stdin
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqRedirStdin()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqRedirStdout
#
#   Purpose....: Req redirect stdout
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqRedirStdout()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqSplitCmd
#
#   Purpose....: Req split command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqSplitCmd()
{
	 char Cmd[256];
	 int CmdSize;
	 int ParamStart;
	 int Size;
	 int i;
	 int done = FALSE;
	 int HasParam = FALSE;

	 GetString(Cmd, 255);
	 Size = strlen(Cmd);

    for (i = 0; i < Size && !done; i++)
    {
        switch (Cmd[i])
        {
            case '/':
            case '=':
            case '(':
            case ';':
				case ',':
                CmdSize = i;
                ParamStart =  i;
					 done = TRUE;
                break;

            case ' ':
            case '\t':
                CmdSize = i;
                while (Cmd[i] == ' ' || Cmd[i] == '\t')
                    i++;

                ParamStart = i;
                done = TRUE;
                break;
        }
    }                                    

    if (!done)
    {
        CmdSize = Size;
        ParamStart = Size;
    }

    PutWord(CmdSize);
    PutWord(ParamStart);
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqReadReg
#
#   Purpose....: Req read registers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqReadReg()
{
    x86_mad_registers reg;

    if (FCurrentThread)
        reg.Set(FCurrentThread);
    
    PutData(&reg, sizeof(reg));
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqWriteReg
#
#   Purpose....: Req write registers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqWriteReg()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqMachineData
#
#   Purpose....: Req machine data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqMachineData()
{
    PutDword(0);
    PutDword(0xFFFFFFFF);
    PutByte(1);
}

/*##########################################################################
#
#   Name       : TWdSocketServer::NotifyMsg
#
#   Purpose....: Notify message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::NotifyMsg()
{
    char ch;

    ch = GetByte();

    switch (ch)
    {
        case 0:
            ReqConnect();
            break;

        case 1:
				ReqDisconnect();
            break;

        case 2:
            ReqSuspend();
            break;

        case 3:
            ReqResume();
				break;

        case 4:
            ReqGetSupplService();
            break;

        case 5:
            ReqPerformSupplService();
            break;

        case 6:
            ReqGetSysConfig();
            break;

        case 7:
            ReqMapAddr();
            break;

        case 8:
            ReqAddrInfo();
            break;

        case 9:
            ReqChecksumMem();
            break;

		  case 10:
            ReqReadMem();
            break;

        case 11:
            ReqWriteMem();
            break;

        case 12:
				ReqReadIo();
            break;

        case 13:
            ReqWriteIo();
            break;

        case 14:
            ReqReadCpu();
            break;

        case 15:
            ReqReadFpu();
            break;

        case 16:
            ReqWriteCpu();
            break;

        case 17:
            ReqWriteFpu();
            break;

        case 18:
            ReqProgGo();
            break;

        case 19:
            ReqProgStep();
            break;

        case 20:
            ReqProgLoad();
            break;

		  case 21:
            ReqProgKill();
            break;

        case 22:
            ReqSetWatch();
            break;

        case 23:
            ReqClearWatch();
            break;

        case 24:
            ReqSetBreak();
            break;

        case 25:
            ReqClearBreak();
            break;

        case 26:
            ReqGetNextAlias();
            break;

        case 27:
            ReqSetUserScreen();
				break;

        case 28:
            ReqSetDebugScreen();
            break;

		  case 29:
				ReqReadUserKeyboard();
				break;

		  case 30:
				ReqGetLibName();
				break;

		  case 31:
				ReqGetErrText();
				break;

		  case 32:
				ReqGetMsgText();
				break;

		  case 33:
				ReqRedirStdin();
				break;

		  case 34:
				ReqRedirStdout();
				break;

		  case 35:
				ReqSplitCmd();
				break;

		  case 36:
				ReqReadReg();
				break;

		  case 37:
				ReqWriteReg();
				break;

		  case 38:
				ReqMachineData();
				break;

		  default:
				ReqError();
            break;
    }    
}

/*##########################################################################
#
#   Name       : TWdSocketServer::HandleSocket
#
#   Purpose....: Handle socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::HandleSocket()
{
    int count;
    
	while (FSocket->IsOpen())
	{
	    FInSize = 0;
		if (FSocket->Read((char *)&FInSize, 2) == 2)
	    {
            count = FSocket->Read(FInBuf, FInSize);

            if (count == FInSize)
            {
                FInPtr = FInBuf;
                FOutPtr = FOutBuf;
                FOutSize = 0;

                NotifyMsg();

					 FSocket->Write((char *)&FOutSize, 2);
                FSocket->Write(FOutBuf, FOutSize);
                FSocket->Push();
            }
		}
	}
}
