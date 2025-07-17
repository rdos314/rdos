/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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
#include "env.h"

#define FALSE 0
#define TRUE !FALSE

#define COND_CONFIG         0x1
#define COND_SECTIONS       0x2
#define COND_LIBRARIES      0x4
#define COND_ALIAS          0x8
#define COND_THREAD         0x10
#define COND_THREAD_INFO    0x20
#define COND_TRACE          0x40
#define COND_BREAK          0x80
#define COND_WATCH          0x100
#define COND_USER           0x200
#define COND_TERMINATE      0x400
#define COND_EXCEPTION      0x800
#define COND_MSG            0x1000
#define COND_STOP           0x2000

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
         real_math      reg[8];
};

struct x86_xmm
{
         char    xmm[8][16];
         long   mxcsr;
};

class x86_mad_registers
{
public:
    x86_mad_registers();
    void Init();
    void Read(TDebugThread *t);
    void Write(TDebugThread *t);

        struct x86_cpu  cpu;
        struct x86_fpu  fpu;
        struct x86_xmm  xmm;
};


/*##########################################################################
#
#   Name       : OnMsg
#
#   Purpose....: Notification of message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void OnMsg(TDebug *deb, const char *msg)
{
    ((TWdSocketServer *)(deb->Owner))->LogMsg(msg);
}

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
#   Name       : x86_mad_registers::Read
#
#   Purpose....: Read data from thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void x86_mad_registers::Read(TDebugThread *t)
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
    cpu.ds = (short)t->Ds;
    cpu.es = (short)t->Es;
    cpu.ss = (short)t->Ss;
    cpu.cs = (short)t->Cs;
    cpu.fs = (short)t->Fs;
    cpu.gs = (short)t->Gs;

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
#   Name       : x86_mad_registers::Write
#
#   Purpose....: Write data to thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void x86_mad_registers::Write(TDebugThread *t)
{
    int i;

    t->Eax = cpu.eax;
    t->Ebx = cpu.ebx;
    t->Ecx = cpu.ecx;
    t->Edx = cpu.edx;
    t->Esi = cpu.esi;
    t->Edi = cpu.edi;
    t->Ebp = cpu.ebp;
    t->Esp = cpu.esp;
    t->Eip = cpu.eip;
    t->Eflags = cpu.efl;

    t->Ds = cpu.ds;
    t->Es = cpu.es;
    t->Ss = cpu.ss;
    t->Cs = cpu.cs;
    t->Fs = cpu.fs;
    t->Gs = cpu.gs;

    t->MathControl = fpu.cw;
    t->MathStatus = fpu.sw;
    t->MathTag = fpu.tag;

    t->MathDataOffs = fpu.ip_err.offset;
    t->MathDataSel = (short)fpu.ip_err.segment;
    t->MathEip = fpu.op_err.offset;
    t->MathCs = (short)fpu.op_err.segment;

    for (i = 0; i < 8; i++)
        t->St[i] = fpu.reg[i];

    t->WriteRegs();
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
TWdSocketServer::TWdSocketServer(TWdSocketServerFactory *fact, const char *Name, int StackSize, TTcpSocket *Socket)
  : TSocketServer(Name, StackSize, Socket)
{
    FFactory = fact;
    FSupplList = 0;
    FDebug = 0;
    FIs19 = FALSE;
    FIs20 = FALSE;

    OnMsg = 0;
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
#   Name       : TWdSocketServer::LogMsg
#
#   Purpose....: Log message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::LogMsg(const char *msg)
{
    if (OnMsg)
        (*OnMsg)(this, msg);
}        

/*##########################################################################
#
#   Name       : TWdSocketServer::DebugLog
#
#   Purpose....: Log debug message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::DebugLog(const char *msg)
{
//    LogMsg(msg);
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
#   Name       : TWdSocketServer::GetData
#
#   Purpose....: Read data from input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::GetData(void *data, int size)
{
    int len = FInPtr - FInBuf;

    len = FInSize - len;

    if (len > size)
        len = size;

    if (len > 0)
    {
        memcpy(data, FInPtr, len);
        FInPtr += len;
    }
}

/*##########################################################################
#
#   Name       : TWdSocketServer::GetData
#
#   Purpose....: Read data from input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void *TWdSocketServer::GetData(int *size)
{
    int len = FInPtr - FInBuf;
    void *ptr;

    *size = FInSize - len;
    ptr = FInPtr;
    FInPtr += *size;
    return ptr;
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
#   Name       : TWdSocketServer::CheckFileExt
#
#   Purpose....: Check if path is valid file (with given extension)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TWdSocketServer::CheckFileExt(const char *path, const char *ext)
{
        TPathName FFullPath = TString(path);
        FFullPath += ext;

        if (FFullPath.IsFile())
        {
                 return FFullPath.Get();
        }
        else
                return TString();
}

/*##########################################################################
#
#   Name       : TWdSocketServer::CheckFileExt
#
#   Purpose....: Check if path + name is a valid file (with given extension)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TWdSocketServer::CheckFileExt(const char *path, const char *name, const char *ext)
{
        TPathName pn(path);
        pn += name;

        return CheckFileExt(pn.Get().GetData(), ext);
}

/*##########################################################################
#
#   Name       : TWdSocketServer::CheckPathFileExt
#
#   Purpose....: Find file through with path env var
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TWdSocketServer::CheckPathFileExt(char *path, const char *name, const char *ext)
{
        TString str;
        char *ptr;

        str = CheckFileExt(name, ext);

        if (str.GetSize())
                 return str;

        while (*path)
        {
                ptr = strchr(path, ';');
                if (ptr)
                {
                        *ptr = 0;
                        str = CheckFileExt(path, name, ext);

                        if (str.GetSize())
                                 return str;

                        path = ptr + 1;
                }
                else
                        return CheckFileExt(path, name, ext);
        }

        return TString();
}

/*##########################################################################
#
#   Name       : TWdSocketServer::GetFullPathName
#
#   Purpose....: Get full pathname of executable file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TWdSocketServer::GetFullPathName(char *name, const char *ext)
{
        char *path;
        TEnv *env;
        TString str;

        if (strchr(name, '\\'))
        {
                str = CheckFileExt(name, ext);

                if (str.GetSize())
                         return str;
         }

        if (strchr(name, '/'))
        {
                str = CheckFileExt(name, ext);

                if (str.GetSize())
                    return str;
    }

        if (strchr(name, ':'))
        {
            str = CheckFileExt(name, ext);
                if (str.GetSize())
                    return str;
    }

        path = new char[512];
        env = TEnv::OpenSysEnv();
        if (env->Find("PATH", path))
        {
                 str = CheckPathFileExt(path, name, ext);
            delete env;
                delete path;
                if (str.GetSize())
                        return str;
         }
         else
         {
                  delete env;
                  delete path;
         }

         return CheckFileExt(name, ext);
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

    if (ch == 17 || ch == 18)
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
         PutByte(0);
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
    long Offset = GetDword();
    int Sel = GetWord();
    int Handle = GetDword();
    TDebugModule *mod;
    TString str("MapAddr ID=%, not found", Handle);

    if (FDebug)
    {
        mod = FDebug->LockModule(Handle);
        if (mod)
        {
            switch (Sel)
            {
                case -2:
                    str.printf("Module ID=%d, Base: %04hX:%08lX, RVA: %08lX, Offset: %08lX, Size: %08lX", Handle, mod->DataSel, mod->ImageBase, mod->ObjectRva, Offset, mod->ImageSize);

                    PutDword(mod->ImageBase + mod->ObjectRva + Offset);
                    PutWord(mod->DataSel);
                    PutDword(0);
                    PutDword(mod->ImageSize - 1);
                    break;

                case -1:
                    str.printf("Module ID=%d, Base: %04hX:%08lX, RVA: %08lX, Offset: %08lX, Size: %08lX", Handle, mod->CodeSel, mod->ImageBase, mod->ObjectRva, Offset, mod->ImageSize);

                    PutDword(mod->ImageBase + mod->ObjectRva + Offset);
                    PutWord(mod->CodeSel);
                    PutDword(0);
                    PutDword(mod->ImageSize - 1);
                    break;

                case 0:
                case 1:
                    str.printf("MapAddr ID=%d, Code base: %04hX:%08lX, Size: %08lX", Handle, mod->CodeSel, Offset, mod->ImageSize);

                    PutDword(Offset);
                    PutWord(mod->CodeSel);
                    PutDword(0);
                    PutDword(mod->ImageSize - 1);
                    break;

                case 2:
                case 3:
                    str.printf("MapAddr ID=%d, Data base: %04hX:%08lX, Size: %08lX", Handle, mod->DataSel, Offset, mod->DataSize);

                    PutDword(Offset);
                    PutWord(mod->DataSel);
                    PutDword(0);
                    if (mod->DataSel && mod->DataSize)
                        PutDword(mod->DataSize - 1);
                    else
                        PutDword(0);
                    break;

                default:
                    str.printf("MapAddr ID=%d, default", Handle);

                    if (Sel == mod->CodeSel)
                    {
                        PutDword(Offset);
                        PutWord(mod->CodeSel);
                        PutDword(0);
                        PutDword(mod->ImageSize - 1);
                        break;
                    }

                    if (Sel == mod->DataSel)
                    {
                        PutDword(Offset);
                        PutWord(mod->DataSel);
                        PutDword(0);
                        if (mod->DataSel && mod->DataSize)
                            PutDword(mod->DataSize - 1);
                        else
                            PutDword(0);
                        break;
                    }

                    PutDword(Offset);
                    PutWord(0);
                    PutDword(0);
                    PutWord(0);
                    PutDword(0);
                    PutWord(0);
                    break;
            }
        }
        FDebug->UnlockModule();
    }
    DebugLog(str.GetData());
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
    int Size;
    long Offset;
    short int Sel;
    int Count = 0;
    char *Data;

    Offset = GetDword();
    Sel = GetWord();
    Size = GetWord();

    Data = new char[Size];

    Count = FDebug->ReadMem(Sel, Offset, Data, Size);

    TString str;

    str.printf("ReadMem %04hX:%08lX, Req %d bytes, Read %d bytes", Sel, Offset, Size, Count);
    DebugLog(str.GetData());

    if (Count)
        PutData(Data, Count);

    delete Data;
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
    int Size;
    char *Data;
    long Offset;
    short int Sel;

    Offset = GetDword();
    Sel = GetWord();
    Data = (char *)GetData(&Size);

    if (Size > 0)
        Size = FDebug->WriteMem(Sel, Offset, Data, Size);
    else
        Size = 0;

    PutWord((short int)Size);
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
        short int CondFlags = COND_THREAD_INFO;

        if (FDebug)
        {
                FDebug->Go();

                if (FDebug->IsTerminated())
                        CondFlags |= COND_TERMINATE;

                if (FDebug->HasThreadChange())
                {
                        FDebug->ClearThreadChange();
                        CondFlags |= COND_THREAD;
                        FCurrentThread = FDebug->GetCurrentThread();
                }

                if (FDebug->HasModuleChange())
                        CondFlags |= COND_LIBRARIES;

        if (FCurrentThread)
                {
            if (FCurrentThread->HasBreakOccurred())
                CondFlags |= COND_BREAK;

            if (FCurrentThread->HasTraceOccurred())
                CondFlags |= COND_WATCH;

            if (FCurrentThread->HasFaultOccurred())
                CondFlags |= COND_EXCEPTION;
        }
    }

    if (FCurrentThread)
    {
        PutDword(FCurrentThread->Esp);
        PutWord((short int)FCurrentThread->Ss);

        PutDword(FCurrentThread->Eip);
        PutWord((short int)FCurrentThread->Cs);

        PutWord(CondFlags);
    }
    else
        {
        PutDword(0);
        PutWord(0);

        PutDword(0);
        PutWord(0);

                PutWord(CondFlags);
        }
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
        short int CondFlags = COND_THREAD_INFO;

        if (FDebug)
        {
                FDebug->Trace();

                if (FDebug->IsTerminated())
                        CondFlags |= COND_TERMINATE;

                if (FDebug->HasThreadChange())
                {
                        FDebug->ClearThreadChange();
                        CondFlags |= COND_THREAD;
                        FCurrentThread = FDebug->GetCurrentThread();
                }

                if (FDebug->HasModuleChange())
                        CondFlags |= COND_LIBRARIES;

                if (FCurrentThread)
                {
                        if (FCurrentThread->HasBreakOccurred())
                                CondFlags |= COND_BREAK;

                        if (FCurrentThread->HasTraceOccurred())
                                CondFlags |= COND_TRACE;

            if (FCurrentThread->HasFaultOccurred())
                CondFlags |= COND_EXCEPTION;
        }
    }

    if (FCurrentThread)
    {
        PutDword(FCurrentThread->Esp);
        PutWord((short int)FCurrentThread->Ss);

        PutDword(FCurrentThread->Eip);
        PutWord((short int)FCurrentThread->Cs);

        PutWord(CondFlags);
    }
    else
    {
        PutDword(0);
        PutWord(0);

        PutDword(0);
        PutWord(0);

        PutWord(CondFlags);
    }
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
    char *argstr;
    TPathName curdir;
    TString str;

    if (FDebug)
        delete FDebug;

    FDebug = 0;
    FMainThread = 0;
    FCurrentThread = 0;
    FMainModule = 0;

    truearg = GetByte();
    GetString(name, 255);

    if (strlen(name))
    {
        str = GetFullPathName(name, ".com");

        if (str.GetSize() == 0)
            str =  GetFullPathName(name, ".exe");
    }

    if (str.GetSize() == 0)
    {
        str = name;
        str += ".exe";
    }

    argstr = name + strlen(name) + 1;
    FDebug = new TDebug(str.GetData(), argstr, curdir.Get().GetData());
    FDebug->Owner = this;
    FDebug->OnMsg = ::OnMsg;

    RdosWaitMilli(500);
    FDebug->WaitForLoad(5000);

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
    FRunning = FALSE;
    FMainThread = 0;
    FCurrentThread = 0;
    FMainModule = 0;

    PutDword(0);
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
    long Offset = GetDword();
    int Sel = GetWord();
    int Size = GetByte();

    if (FDebug)
        FDebug->AddWatch(Sel, Offset, Size);

    PutDword(0);
    PutDword(0x80000000 + 100000);
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
    long Offset = GetDword();
    int Sel = GetWord();
    int Size = GetByte();

    if (FDebug)
        FDebug->ClearWatch(Sel, Offset, Size);
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
    long Offset = GetDword();
    int Sel = GetWord();
    int Hw;

    if ((Sel & 3) == 0)
        Hw = TRUE;
    else
        Hw = FALSE;

    if (FDebug)
        FDebug->AddBreak(Sel, Offset, Hw);

    PutDword(0);
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
    long Offset = GetDword();
    int Sel = GetWord();

    if (FDebug)
        FDebug->ClearBreak(Sel, Offset);
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
    TString str;
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
                str.printf("LibName '%s' ID=%d", Module->ModuleName.GetData(), Handle);
                DebugLog(str.GetData());

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
    {
        DebugLog("LibName failed");
        PutDword(Handle);
    }
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
        int id = GetDword();

    switch (id)
    {
        case MSG_LOAD_FAIL:
            PutString("Cannot load program");
            break;

        case MSG_FILE_NOT_FOUND:
            PutString("File not found");
            break;

        case MSG_NO_THREAD:
            PutString("Thread not found");
            break;

        case MSG_FILE_MODE_ERROR:
            PutString("Invalid seek mode");
            break;

        default:
            PutString("Unknown error");
            break;
    }
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
    PutByte(8);

    if (FCurrentThread)
        PutString(FCurrentThread->FaultText.GetData());
    else
        PutString("Exception fault");
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
        reg.Read(FCurrentThread);

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
    x86_mad_registers reg;

    if (FCurrentThread)
    {
        reg.Read(FCurrentThread);
        GetData(&reg, sizeof(reg));
        reg.Write(FCurrentThread);
    }
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
    int size;
    int bitness;
    char info = GetByte();
    int offs = GetDword();
    int sel = GetWord();

    if (RdosGetSelectorInfo(sel, &size, &bitness))
    {
        if (size > 0xFFFF)
            bitness = 32;

        PutDword(0);
        PutDword(size);
        if (bitness == 16)
            PutByte(0);
        else
            PutByte(1);
    }
    else
    {
        PutDword(0);
        PutDword(0xFFFFFFFF);
        PutByte(1);
    }
}

/*##########################################################################
#
#   Name       : TWdSocketServer::NotifyMsg19
#
#   Purpose....: Notify 1.9 version message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::NotifyMsg19()
{
    unsigned char ch;

    ch = (unsigned char)GetByte();

    switch (ch & 0x7F)
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

    if (ch & 0x80)
        FSuppressAnswer = TRUE;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::NotifyMsg20
#
#   Purpose....: Notify version 2.0 message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::NotifyMsg20()
{
    unsigned char ch;

    ch = (unsigned char)GetByte();

    switch (ch & 0x7F)
    {
        case 0:
            DebugLog("Connect");
            ReqConnect();
            break;

        case 1:
            DebugLog("Disonnect");
            ReqDisconnect();
            break;

        case 2:
            DebugLog("Suspend");
            ReqSuspend();
            break;

        case 3:
            DebugLog("Resume");
            ReqResume();
            break;

        case 4:
            DebugLog("Req suppl");
            ReqGetSupplService();
            break;

        case 5:
            ReqPerformSupplService();
            break;

        case 6:
            DebugLog("GetSysConfig");
            ReqGetSysConfig();
            break;

        case 7:
            ReqMapAddr();
            break;

        case 8:
            DebugLog("ChecksumMem");
            ReqChecksumMem();
            break;

        case 9:
            ReqReadMem();
            break;

        case 10:
            DebugLog("WriteMem");
            ReqWriteMem();
            break;

        case 11:
            DebugLog("Readio");
            ReqReadIo();
            break;

        case 12:
            DebugLog("WriteIo");
            ReqWriteIo();
            break;

        case 13:
            DebugLog("Go");
            ReqProgGo();
            break;

        case 14:
            DebugLog("Step");
            ReqProgStep();
            break;

        case 15:
            DebugLog("LoadProg");
            ReqProgLoad();
            break;

        case 16:
            DebugLog("Kill");
            ReqProgKill();
            break;

        case 17:
            DebugLog("SetWatch");
            ReqSetWatch();
            break;

        case 18:
            DebugLog("ClearWatch");
            ReqClearWatch();
            break;

        case 19:
            DebugLog("SetBreak");
            ReqSetBreak();
            break;

        case 20:
            DebugLog("ClearBreak");
            ReqClearBreak();
            break;

        case 21:
            DebugLog("NextAlias");
            ReqGetNextAlias();
            break;

        case 22:
            DebugLog("UserScreen");
            ReqSetUserScreen();
            break;

        case 23:
            DebugLog("DebugScreen");
            ReqSetDebugScreen();
            break;

        case 24:
            DebugLog("UserKey");
            ReqReadUserKeyboard();
            break;

        case 25:
            ReqGetLibName();
            break;

        case 26:
            DebugLog("ErrorText");
            ReqGetErrText();
            break;

        case 27:
            DebugLog("MsgText");
            ReqGetMsgText();
            break;

        case 28:
            DebugLog("RedirIn");
            ReqRedirStdin();
            break;

        case 29:
            DebugLog("RedirOut");
            ReqRedirStdout();
            break;

        case 30:
            DebugLog("SplitCmd");
            ReqSplitCmd();
            break;

        case 31:
            DebugLog("ReadReg");
            ReqReadReg();
            break;

        case 32:
            DebugLog("WriteReg");
            ReqWriteReg();
            break;

        case 33:
            DebugLog("MachineData");
            ReqMachineData();
            break;

        default:
            char str[40];
            sprintf(str, "Req Error: %02hX", ch);
            LogMsg(str);
            ReqError();
            break;
    }

    if (ch & 0x80)
        FSuppressAnswer = TRUE;
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
    if (FIs19)
    {
        NotifyMsg19();
        return;
    }

    if (FIs20)
    {
        NotifyMsg20();
        return;
    }

    unsigned char ch;

    ch = (unsigned char)GetByte();

    switch (ch & 0x7F)
    {
        case 0:
            ReqConnect();
            break;

        case 1:
            ReqDisconnect();
            break;

        case 6:
            ReqGetSysConfig();
            break;

        case 33:
            ReqMachineData();
            FIs20 = TRUE;
            break;

        case 38:
            ReqMachineData();
            FIs19 = TRUE;
            break;

        default:
            LogMsg("Error req");
            ReqError();
            break;
    }

    if (ch & 0x80)
        FSuppressAnswer = TRUE;
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
    TString str;

    FRunning = TRUE;

    RdosStartDebugger(10000);

    while (FSocket->IsOpen() && FRunning)
    {
        if (FSocket->WaitForData(10000))
        {
            RdosKickDebugger();

            FInSize = 0;
            if (FSocket->Read((char *)&FInSize, 2) == 2)
            {

                if (FSocket->WaitForData(1000))
                {
                    count = FSocket->Read(FInBuf, FInSize);

                    if (count == FInSize)
                    {
                        FInPtr = FInBuf;
                        FOutPtr = FOutBuf;
                        FOutSize = 0;
                        FSuppressAnswer = FALSE;

                        NotifyMsg();

                        if (!FSuppressAnswer)
                        {
                            FSocket->Write((char *)&FOutSize, 2);
                            FSocket->Write(FOutBuf, FOutSize);
                            FSocket->Push();
                        }
                    }
                    else
                    {
                        str.printf("Expected %d, Received %d", FInSize, count);
                        LogMsg(str.GetData());
                    }
                }
                else
                    LogMsg("Data timeout");
            }
            else
                LogMsg("Read failed");
        }
        else
        {
            LogMsg("Push socket");
            FSocket->Push();
        }
    }

    if (!FRunning)
        LogMsg("Not running");

    if (!FSocket->IsOpen())
        LogMsg("Socket closed");

    FDebug->Stop();

    LogMsg("Wait for debug done");

    while (!FDebug->IsDone())
        RdosWaitMilli(250);

    LogMsg("Debug done");

    if (FDebug)
        delete FDebug;

    FDebug = 0;

    LogMsg("Stop debugger");

    RdosStopDebugger();
}
