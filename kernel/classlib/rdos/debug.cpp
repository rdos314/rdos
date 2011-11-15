/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2009, Leif Ekblad
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
# debug.cpp
# Debug class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "debug.h"

#define FALSE   0
#define TRUE    !FALSE

#define EVENT_EXCEPTION         1
#define EVENT_CREATE_THREAD     2
#define EVENT_CREATE_PROCESS    3
#define EVENT_TERMINATE_THREAD  4
#define EVENT_TERMINATE_PROCESS 5
#define EVENT_LOAD_DLL          6
#define EVENT_FREE_DLL          7
#define EVENT_KERNEL            8

/*##########################################################################
#
#   Name       : TDebugThread::TDebugThread
#
#   Purpose....: Debug thread constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugThread::TDebugThread(TCreateProcessEvent *event)
{
    ThreadID = event->Thread;
    FsLinear = event->FsLinear;
    Eip = event->StartEip;
    Cs = event->StartCs;

    FDebug = FALSE;

    ReadState();
}

/*##########################################################################
#
#   Name       : TDebugThread::TDebugThread
#
#   Purpose....: Debug thread constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugThread::TDebugThread(TCreateThreadEvent *event)
{
    ThreadID = event->Thread;
    FsLinear = event->FsLinear;
    Eip = event->StartEip;
    Cs = event->StartCs;

    FDebug = FALSE;
    FWasTrace = FALSE;

    FHasBreak = FALSE;
    FHasTrace = FALSE;
    FHasException = FALSE;

    ReadState();
}

/*##########################################################################
#
#   Name       : TDebugThread::~TDebugThread
#
#   Purpose....: Debug thread destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugThread::~TDebugThread()
{
}

/*##########################################################################
#
#   Name       : TDebugThread::IsDebug
#
#   Purpose....: Check if thread is in debug state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebugThread::IsDebug()
{
    return FDebug;
}

/*##########################################################################
#
#   Name       : TDebugThread::HasBreakOccurred
#
#   Purpose....: Check if thread is stopped on breakpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebugThread::HasBreakOccurred()
{
    return FHasBreak;
}

/*##########################################################################
#
#   Name       : TDebugThread::HasTraceOccurred
#
#   Purpose....: Check if thread is stopped on trace / watchpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebugThread::HasTraceOccurred()
{
    return FHasTrace;
}

/*##########################################################################
#
#   Name       : TDebugThread::HasFaultOccurred
#
#   Purpose....: Check if thread is stopped on fault
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebugThread::HasFaultOccurred()
{
    return FHasException;
}

/*##########################################################################
#
#   Name       : TDebugThread::ClearBreak
#
#   Purpose....: Clear break flag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebugThread::ClearBreak()
{
    FHasBreak = FALSE;
}

/*##########################################################################
#
#   Name       : TDebugThread::GetMemoryModel
#
#   Purpose....: Return current memory model for thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebugThread::GetMemoryModel()
{
    int limit;
    int bitness;
    
    if (Cs == 0x1B3)
        return DEBUG_MEMORY_MODEL_FLAT;

    if (RdosGetSelectorInfo(Cs, &limit, &bitness))
    {
        if (limit == 0xFFFFFFFF)
            return DEBUG_MEMORY_MODEL_FLAT;
        
        if (bitness == 16)    
            return DEBUG_MEMORY_MODEL_16;

        if (bitness == 32)
            return DEBUG_MEMORY_MODEL_32;
    }

    return DEBUG_MEMORY_MODEL_16;
}

/*##########################################################################
#
#   Name       : TDebugThread::ReadMem
#
#   Purpose....: Read memory in thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebugThread::ReadMem(int Sel, long Offset, char *Buf, int Size)
{
    return RdosReadThreadMem(ThreadID, Sel, Offset, Buf, Size);
}

/*##########################################################################
#
#   Name       : TDebugThread::WriteMem
#
#   Purpose....: Write memory in thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebugThread::WriteMem(int Sel, long Offset, char *Buf, int Size)
{
    return RdosWriteThreadMem(ThreadID, Sel, Offset, Buf, Size);
}

/*##########################################################################
#
#   Name       : TDebugThread::SetupGo
#
#   Purpose....: Setup before run
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebugThread::SetupGo()
{
    int update = FALSE;
    Tss tss;
    unsigned char ch = 0;

    FDebug = FALSE;
    
    FWasTrace = FALSE;

    RdosGetThreadTss(ThreadID, &tss);
    RdosReadThreadMem(ThreadID, tss.cs, tss.eip, (char *)&ch, 1);

    if (ch == 0xCC)
    {
        tss.eip++;
        update = TRUE;
    }

    if ((tss.eflags & 0x100) != 0)
    {
        tss.eflags &= ~0x100;
        update = TRUE;
    }

    if (update)
        RdosSetThreadTss(ThreadID, &tss);

}

/*##########################################################################
#
#   Name       : TDebugThread::SetupTrace
#
#   Purpose....: Setup for execution of single instruction
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebugThread::SetupTrace()
{
    int update = FALSE;
    Tss tss;
    unsigned char ch = 0;

    FWasTrace = TRUE;
    FDebug = FALSE;

    RdosGetThreadTss(ThreadID, &tss);

    RdosReadThreadMem(ThreadID, tss.cs, tss.eip, (char *)&ch, 1);

    if (ch == 0xCC)
    {
        tss.eip++;
        update = TRUE;
    }

    if ((tss.eflags & 0x100) == 0)
    {
        tss.eflags |= 0x100;
        update = TRUE;
    }

    if (update)
        RdosSetThreadTss(ThreadID, &tss);
}

/*##########################################################################
#
#   Name       : TDebugThread::ActivateBreaks
#
#   Purpose....: Activate breakpoints
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebugThread::ActivateBreaks(TDebugBreak *BreakList, TDebugWatch *WatchList)
{
    TDebugBreak *b = BreakList;
    TDebugWatch *w = WatchList;
    char brinstr = 0xCC;
    int bnum = 0;

    while (w)
    {
        if (bnum < 4)
        {
            RdosSetWriteDataBreak(ThreadID, bnum, w->Sel, w->Offset, w->Size);
            bnum++;
        }
        w = w->Next;
    }


    while (b)
    {
        if ((b->Sel & 0x3) == 0x3)
        {
            RdosReadThreadMem(ThreadID, b->Sel, b->Offset, &b->Instr, 1);
            RdosWriteThreadMem(ThreadID, b->Sel, b->Offset, &brinstr, 1);
        }
        else
        {
            if (bnum < 4)
            {
                RdosSetCodeBreak(ThreadID, bnum, b->Sel, b->Offset);
                bnum++;
            }
        }

        b = b->Next;
    }
}

/*##########################################################################
#
#   Name       : TDebugThread::DeactivateBreaks
#
#   Purpose....: Deactivate breakpoints
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebugThread::DeactivateBreaks(TDebugBreak *BreakList, TDebugWatch *WatchList)
{
    TDebugBreak *b = BreakList;
    TDebugWatch *w = WatchList;
    int bnum = 0;

    if (!FWasTrace)
    {
        while (w)
        {
            if (bnum < 4)
            {
                RdosClearBreak(ThreadID, bnum);
                bnum++;
            }
            w = w->Next;
        }

        while (b)
        {
            if ((b->Sel & 0x3) == 0x3)
                RdosWriteThreadMem(ThreadID, b->Sel, b->Offset, &b->Instr, 1);
            else
            {
                if (bnum < 4)
                {
                    RdosClearBreak(ThreadID, bnum);
                    bnum++;
                }
            }
            b = b->Next;
        }
    }
}

/*##########################################################################
#
#   Name       : TDebugThread::SetException
#
#   Purpose....: Set exception state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebugThread::SetException(TExceptionEvent *event)
{
    Tss tss;
    int i;
    unsigned char ch = 0;

    FHasBreak = FALSE;
    FHasTrace = FALSE;
    FHasException = FALSE;

    ReadState();
    RdosGetThreadTss(ThreadID, &tss);

    Cs = event->Cs;
    Eip = event->Eip;

    RdosReadThreadMem(ThreadID, Cs, Eip, (char *)&ch, 1);
        
    if (ch == 0xCC)
        event->Code = 0x80000003;    

    switch (event->Code)
    {
        case 0x80000003:
            FHasBreak = TRUE;
            break;

        case 0x80000004:
            FHasTrace = TRUE;
            break;

        case 0xC0000005:
            FaultText = "Access violation";
            FHasException = TRUE;
            break;

        case 0xC0000017:
            FaultText = "No memory";
            FHasException = TRUE;
            break;

        case 0xC000001D:
            FaultText = "Illegal instruction";
            FHasException = TRUE;
            break;
            
        case 0xC0000025:
            FaultText = "Noncontinuable exception";
            FHasException = TRUE;
            break;

        case 0xC000008C:
            FaultText = "Array bounds exceeded";
            FHasException = TRUE;
            break;

        case 0xC0000094:
            FaultText = "Integer divide by zero";
            FHasException = TRUE;
            break;

        case 0xC0000095:
            FaultText = "Integer overflow";
            FHasException = TRUE;
            break;

        case 0xC0000096:
            FaultText = "Priviliged instruction";
            FHasException = TRUE;
            break;

        case 0xC00000FD:
            FaultText = "Stack overflow";
            FHasException = TRUE;
            break;

        case 0xC000013A:
            FaultText = "Control-C exit";
            FHasException = TRUE;
            break;

        case 0xC000008D:
            FaultText = "Float denormal operand";
            FHasException = TRUE;
            break;

        case 0xC000008E:
            FaultText = "Float divide by zero";
            FHasException = TRUE;
            break;

        case 0xC000008F:
            FaultText = "Float inexact result";
            FHasException = TRUE;
            break;

        case 0xC0000090:
            FaultText = "Float invalid operation";
            FHasException = TRUE;
            break;

        case 0xC0000091:
            FaultText = "Float overflow";
            FHasException = TRUE;
            break;

        case 0xC0000092:
            FaultText = "Float stack check";
            FHasException = TRUE;
            break;

        case 0xC0000093:
            FaultText = "Float underflow";
            FHasException = TRUE;
            break;

        default:
            FaultText = "Protection fault";
            FHasException = TRUE;
            break;
    }

    Cr3 = tss.cr3;
    Eflags = tss.eflags;
    Eax = tss.eax;
    Ecx = tss.ecx;
    Edx = tss.edx;
    Ebx = tss.ebx;
    Esp = tss.esp;
    Ebp = tss.ebp;
    Esi = tss.esi;
    Edi = tss.edi;
    Es = tss.es;
    Ss = tss.ss;
    Ds = tss.ds;
    Fs = tss.fs;
    Gs = tss.gs;
    Ldt = tss.ldt;

    for (i = 0; i < 4; i++)
        Dr[i] = tss.dr[i];

    Dr7 = tss.dr7;
    MathControl = tss.MathControl;
    MathStatus = tss.MathStatus;
    MathTag = tss.MathTag;
    MathEip = tss.MathEip;
    MathCs = tss.MathCs;
    MathDataOffs = tss.MathDataOffs;
    MathDataSel = tss.MathDataSel;

    for (i = 0; i < 8; i++)
        St[i] = tss.st[i];

    FDebug = TRUE;
}

/*##########################################################################
#
#   Name       : TDebugThread::SetException
#
#   Purpose....: Set exception state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebugThread::SetException(TKernelExceptionEvent *event)
{
    Tss tss;
    int i;

    FHasBreak = FALSE;
    FHasTrace = FALSE;
    FHasException = FALSE;

    ReadState();
    RdosGetThreadTss(ThreadID, &tss);

    switch (event->Vector)
    {
        case 0:
            FaultText = "Integer divide by zero";
            FHasException = TRUE;
            break;

        case 1:
            FaultText = "Hardware breakpoint";
            FHasTrace = TRUE;
            break;

        case 3:
            FaultText = "Software breakpoint";
            FHasException = TRUE;
            break;

        case 4:
            FaultText = "Integer overflow";
            FHasException = TRUE;
            break;

        case 5:
            FaultText = "Array bounds exceeded";
            FHasException = TRUE;
            break;

        case 6:
            FaultText = "Illegal instruction";
            FHasException = TRUE;
            break;

        case 7:
            FaultText = "Float invalid operation";
            FHasException = TRUE;
            break;

        case 10:
            FaultText = "Invalid TSS";
            FHasException = TRUE;
            break;

        case 11:
            FaultText = "Segment not present";
            FHasException = TRUE;
            break;

        case 12:
            FaultText = "Stack overflow";
            FHasException = TRUE;
            break;

        default:
            FaultText = "Protection fault";
            FHasException = TRUE;
            break;
    }

    Cs = tss.cs;
    Eip = tss.eip;
    Cr3 = tss.cr3;
    Eflags = tss.eflags;
    Eax = tss.eax;
    Ecx = tss.ecx;
    Edx = tss.edx;
    Ebx = tss.ebx;
    Esp = tss.esp;
    Ebp = tss.ebp;
    Esi = tss.esi;
    Edi = tss.edi;
    Es = tss.es;
    Ss = tss.ss;
    Ds = tss.ds;
    Fs = tss.fs;
    Gs = tss.gs;
    Ldt = tss.ldt;

    for (i = 0; i < 4; i++)
        Dr[i] = tss.dr[i];

    Dr7 = tss.dr7;
    MathControl = tss.MathControl;
    MathStatus = tss.MathStatus;
    MathTag = tss.MathTag;
    MathEip = tss.MathEip;
    MathCs = tss.MathCs;
    MathDataOffs = tss.MathDataOffs;
    MathDataSel = tss.MathDataSel;

    for (i = 0; i < 8; i++)
        St[i] = tss.st[i];

    FDebug = TRUE;
}

/*##########################################################################
#
#   Name       : TDebugThread::WriteRegs
#
#   Purpose....: Write regs back to TSS
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebugThread::WriteRegs()
{
    Tss tss;
    int i;

    RdosGetThreadTss(ThreadID, &tss);

    tss.eflags = Eflags;
    tss.eax = Eax;
    tss.ecx = Ecx;
    tss.edx = Edx;
    tss.ebx = Ebx;
    tss.esp = Esp;
    tss.ebp = Ebp;
    tss.esi = Esi;
    tss.edi = Edi;
    tss.es = Es;
    tss.ss = Ss;
    tss.ds = Ds;
    tss.fs = Fs;
    tss.gs = Gs;

    tss.MathControl = MathControl;
    tss.MathStatus = MathStatus;
    tss.MathTag = MathTag;

    for (i = 0; i < 8; i++)
        tss.st[i] = St[i];

    RdosSetThreadTss(ThreadID, &tss);
}

/*##########################################################################
#
#   Name       : TDebugThread::ReadState
#
#   Purpose....: Read thread state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebugThread::ReadState()
{
    ThreadState state;
    int i;
    int ok;
    char str[21];

    ok = FALSE;
    
    for (i = 0; i < 256 && !ok; i++)
    {
        RdosGetThreadState(i, &state);
        if (state.ID == ThreadID)
            ok = TRUE;
    }

    if (ok)
    {
        strncpy(str, state.Name, 20);
        str[20] = 0;
        
        for (i = 19; i >= 0; i--)
            if (str[i] == ' ')
                str[i] = 0;
            else
                break;
    
        ThreadName = str;

        strncpy(str, state.List, 20);
        str[20] = 0;
        
        for (i = 19; i >= 0; i--)
            if (str[i] == ' ')
                str[i] = 0;
            else
                break;

        ThreadList = str;
        
        ListOffset = state.Offset;
        ListSel = state.Sel;
    }
}

/*##########################################################################
#
#   Name       : TDebugModule::TDebugModule
#
#   Purpose....: Debug module constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugModule::TDebugModule(TCreateProcessEvent *event)
{
    FileHandle = event->FileHandle;
    Handle = event->Handle;
    ImageBase = event->ImageBase;
    ImageSize = event->ImageSize;
    ObjectRva = event->ObjectRva;
    CodeSel = 0;
    DataSel = 0;

    FNew = FALSE;

    ReadName();
}

/*##########################################################################
#
#   Name       : TDebugModule::TDebugModule
#
#   Purpose....: Debug module constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugModule::TDebugModule(TLoadDllEvent *event)
{
    FileHandle = event->FileHandle;
    Handle = event->Handle;
    ImageBase = event->ImageBase;
    ImageSize = event->ImageSize;
    ObjectRva = event->ObjectRva;
    CodeSel = 0;
    DataSel = 0;

    FNew = TRUE;

    ReadName();
}

/*##########################################################################
#
#   Name       : TDebugModule::TDebugModule
#
#   Purpose....: Debug module constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugModule::TDebugModule(int Cs)
{
    char Name[256];

    FileHandle = 0;

    if (RdosGetDeviceInfo(Cs, Name, &ImageSize, &DataSel, &DataSize)) 
    {
        Handle = 0x8000 | Cs;
        ImageBase = 0;
        ObjectRva = 0;
        CodeSel = Cs;

        if (Cs == 0x30)
            strcpy(Name, "\\rdos\\kernel\\os\\kernel.exe");

        ModuleName = TString(Name);
    }
    else
        Handle = 0;
        
    FNew = TRUE;
}

/*##########################################################################
#
#   Name       : TDebugModule::~TDebugModule
#
#   Purpose....: Debug module destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugModule::~TDebugModule()
{
}

/*##########################################################################
#
#   Name       : TDebugModule::ReadName
#
#   Purpose....: Read module name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebugModule::ReadName()
{
    char str[256];
    int size;

    size = RdosGetModuleName(Handle, str, 255);
    str[size] = 0;

    ModuleName = str;    
}

/*##########################################################################
#
#   Name       : TDebugBreak::TDebugBreak
#
#   Purpose....: Debug breakpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugBreak::TDebugBreak(int sel, long offset, int Hw)
{
    Sel = sel;
    Offset = offset;
    Instr = 0xCC;
    Next = 0;
    UseHw = Hw;
}

/*##########################################################################
#
#   Name       : TDebugWatch::TDebugWatch
#
#   Purpose....: Debug watchpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugWatch::TDebugWatch(int sel, long offset, int size)
{
    Sel = sel;
    Offset = offset;
    Size = size;
    Next = 0;
}

/*##########################################################################
#
#   Name       : TDebug::TDebug
#
#   Purpose....: Debugger constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebug::TDebug(const char *Program, const char *Param, const char *StartDir, const char *LogFile)
 : FProgram(Program),
   FParam(Param),
   FStartDir(StartDir),
   FLogFile(LogFile, 0)
{
    ThreadList = 0;
    ModuleList = 0;
    CurrentThread = 0;
    NewThread = 0;
    BreakList = 0;
    WatchList = 0;

    FThreadChanged = FALSE;
    FModuleChanged = FALSE;
    FHandle = 0;

    FMemoryModel = DEBUG_MEMORY_MODEL_FLAT;
    FConfigChange = FALSE;
    
    FAsyncBreak = FALSE;
    FAsyncSel = 0;
    FAsyncOffset = 0;

    FWaitLoad = TRUE;
    
    Start("Debug device", 0x4000);
}

/*##########################################################################
#
#   Name       : TDebug::~TDebug
#
#   Purpose....: Debugger destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebug::~TDebug()
{
    if (FHandle)
        RdosFreeProcessHandle(FHandle);
}

/*##########################################################################
#
#   Name       : TDebug::DeviceName
#
#   Purpose....: Returns device-name
#
#   In params..: MaxLen max size of name
#   Out params.: Name   device name
#   Returns....: *
#
##########################################################################*/
void TDebug::DeviceName(char *Name, int MaxLen) const
{
        strncpy(Name,"Debug device",MaxLen);
}

/*##########################################################################
#
#   Name       : TDebug::LogMsg
#
#   Purpose....: Log message
#
##########################################################################*/
void TDebug::LogMsg(const char *Msg)
{
    char timestr[128];
    TString str(Msg);
    unsigned long msb, lsb;
    int year, month, day;
    int hour, min, sec;
    int ms, us;

    str += "\r\n";

    RdosWriteString(str.GetData());

    if (FLogFile.IsOpen())
    {
        RdosGetTime(&msb, &lsb);
        RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
        RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us); 

        sprintf(timestr, "%4d-%02d-%02d %02d.%02d.%02d,%03d %03d ", 
                                year, month, day,
                                hour, min, sec,
                                ms, us);
        str = timestr;
        str += Msg;
        str += "\r\n";        
        
        FLogFile.Write(str.GetData());
    }
}

/*##########################################################################
#
#   Name       : TDebug::Add
#
#   Purpose....: Add object to wait
#
#   In params..: wait
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::Add(TWait *Wait)
{
    if (FHandle)
        RdosAddWaitForDebugEvent(Wait->GetHandle(), FHandle, this);
}

/*##########################################################################
#
#   Name       : TDebug::InsertThread
#
#   Purpose....: Add new thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::InsertThread(TDebugThread *thread)
{
    TDebugThread *t;

    FSection.Enter();

    thread->Next = 0;

    t = ThreadList;
    if (t)
    {
        while (t->Next)
            t = t->Next;

        t->Next = thread;            
    }
    else
        ThreadList = thread;

    if (!CurrentThread)
        CurrentThread = thread;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TDebug::FindModule
#
#   Purpose....: Find module with specific CS selector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugModule *TDebug::FindModule(int Cs)
{
    TDebugModule *m;

    FSection.Enter();

    m = ModuleList;

    while (m)
    {
        if (m->CodeSel == Cs)
            break;

        m = m->Next;
    }

    FSection.Leave();

    return m;
}

/*##########################################################################
#
#   Name       : TDebug::InsertModule
#
#   Purpose....: Add new module
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::InsertModule(TDebugModule *mod)
{
    TDebugModule *m;

    FSection.Enter();

    mod->Next = 0;

    m = ModuleList;
    if (m)
    {
        while (m->Next)
            m = m->Next;

        m->Next = mod;            
    }
    else
        ModuleList = mod;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TDebug::RemoveThread
#
#   Purpose....: Remove a thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::RemoveThread(int thread)
{
    TDebugThread *p;
    TDebugThread *t;

    FSection.Enter();

    p = 0;
    t = ThreadList;

    while (t)
    {
        if (t->ThreadID == thread)
        {
            if (p)
                p->Next = t->Next;
            else
                ThreadList = t->Next;
            break;            
        }
        else
        {
            p = t;
            t = t->Next;
        }
    }

    if (t)
    {
        if (t == CurrentThread)
        {
            CurrentThread = 0;
            FSection.Leave();

            RdosWaitMilli(25);

            FSection.Enter();
        }
        delete t;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TDebug::RemoveModule
#
#   Purpose....: Remove a module
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::RemoveModule(int module)
{
    TDebugModule *p;
    TDebugModule *m;

    FSection.Enter();

    p = 0;
    m = ModuleList;

    while (m)
    {
        if (m->Handle == module)
        {
            if (p)
                p->Next = m->Next;
            else
                ModuleList = m->Next;
            break;            
        }
        else
        {
            p = m;
            m = m->Next;
        }
    }

    if (m)
        delete m;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TDebug::WaitForLoad
#
#   Purpose....: Wait for app to load
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::WaitForLoad(int timeout)
{
//    UserSignal.WaitTimeout(timeout);
    UserSignal.WaitForever();
}

/*##########################################################################
#
#   Name       : TDebug::HasThreadChange
#
#   Purpose....: Check for thread change event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebug::HasThreadChange()
{
    return FThreadChanged || NewThread;
}

/*##########################################################################
#
#   Name       : TDebug::ClearThreadChange
#
#   Purpose....: Clear thread change event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::ClearThreadChange()
{
    FThreadChanged = FALSE;
    NewThread = 0;
}

/*##########################################################################
#
#   Name       : TDebug::HasModuleChange
#
#   Purpose....: Check for module change event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebug::HasModuleChange()
{
    return FModuleChanged;
}

/*##########################################################################
#
#   Name       : TDebug::ClearModuleChange
#
#   Purpose....: Clear module change event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::ClearModuleChange()
{
    FModuleChanged = FALSE;
}

/*##########################################################################
#
#   Name       : TDebug::HasConfigChange
#
#   Purpose....: Check for configuration change
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebug::HasConfigChange()
{
    return FConfigChange;
}

/*##########################################################################
#
#   Name       : TDebug::ClearConfigChange
#
#   Purpose....: Clear config change event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::ClearConfigChange()
{
    FConfigChange = FALSE;
}

/*##########################################################################
#
#   Name       : TDebug::IsTerminated
#
#   Purpose....: Check for termination
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebug::IsTerminated()
{
    return !FInstalled;
}

/*##########################################################################
#
#   Name       : TDebug::GetMainThread
#
#   Purpose....: Get main thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugThread *TDebug::GetMainThread()
{
    return ThreadList;
}

/*##########################################################################
#
#   Name       : TDebug::GetMainModule
#
#   Purpose....: Get main module
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugModule *TDebug::GetMainModule()
{
    return ModuleList;
}

/*##########################################################################
#
#   Name       : TDebug::GetCurrentThread
#
#   Purpose....: Get current thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugThread *TDebug::GetCurrentThread()
{
    return CurrentThread;
}

/*##########################################################################
#
#   Name       : TDebug::GetNewThread
#
#   Purpose....: Get new thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugThread *TDebug::GetNewThread()
{
    return NewThread;
}

/*##########################################################################
#
#   Name       : TDebug::SetCurrentThread
#
#   Purpose....: Set current thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::SetCurrentThread(int ThreadID)
{
    TDebugThread *t;

    FSection.Enter();

    t = ThreadList;
    while (t && t->ThreadID != ThreadID)
        t = t->Next;

    if (t)
        CurrentThread = t;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TDebug::GetNextThread
#
#   Purpose....: Get next thread ID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebug::GetNextThread(int ThreadID)
{
    int ID = 0xFFFF;
    TDebugThread *t;

    FSection.Enter();

    t = ThreadList;
    while (t)
    {
        if (t->ThreadID > ThreadID && t->ThreadID < ID)
            ID = t->ThreadID;

        t = t->Next;            
    }

    FSection.Leave();

    if (ID != 0xFFFF)
        return ID;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TDebug::GetNextModule
#
#   Purpose....: Get next module handle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebug::GetNextModule(int ModuleHandle)
{
    int Handle = 0xFFFF;
    TDebugModule *m;
    TDebugModule *rm = 0;

    FSection.Enter();

    m = ModuleList;
    while (m)
    {
        if (m->FNew && m->Handle > ModuleHandle && m->Handle < Handle)
        {
            rm = m;
            Handle = m->Handle;
        }

        m = m->Next;            
    }

    FSection.Leave();

    if (rm)
    {
        rm->FNew = FALSE;
        return Handle;
    }
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TDebug::GetMemoryModel
#
#   Purpose....: Get current memory model
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebug::GetMemoryModel()
{
    return FMemoryModel;
}

/*##########################################################################
#
#   Name       : TDebug::LockThread
#
#   Purpose....: Lock thread list and return thread object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugThread *TDebug::LockThread(int ThreadID)
{
    TDebugThread *t;

    FSection.Enter();

    t = ThreadList;
    while (t && t->ThreadID != ThreadID)
        t = t->Next;            

    return t;
}

/*##########################################################################
#
#   Name       : TDebug::UnlockThread
#
#   Purpose....: Unlock thread list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::UnlockThread()
{
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TDebug::LockModule
#
#   Purpose....: Lock module list and return module object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebugModule *TDebug::LockModule(int Handle)
{
    TDebugModule *m;

    FSection.Enter();

    m = ModuleList;
    while (m && m->Handle != Handle)
        m = m->Next;            

    return m;
}

/*##########################################################################
#
#   Name       : TDebug::UnlockModule
#
#   Purpose....: Unlock module list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::UnlockModule()
{
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TDebug::HasModule
#
#   Purpose....: Check for a loaded module
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebug::HasModule(const char *Name)
{
    TString SearchName(Name);
    TDebugModule *m;
    int found = FALSE;

    FSection.Enter();

    m = ModuleList;
    while (m && !found)
    {
        if (SearchName == m->ModuleName)
            found = TRUE;
        m = m->Next;    
    }        
    FSection.Leave();

    return found;
}

/*##########################################################################
#
#   Name       : TDebug::UpdateModules
#
#   Purpose....: Update loaded modules
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::UpdateModules()
{
    TDebugModule *m;
    int model;

    model = CurrentThread->GetMemoryModel();                    
    if (model != FMemoryModel)
    {
        FMemoryModel = model;
        FConfigChange = TRUE;

        switch (FMemoryModel)
        {
            case DEBUG_MEMORY_MODEL_FLAT:
                LogMsg("Flat");
                break;

            case DEBUG_MEMORY_MODEL_16:
                LogMsg("16-bit device");
                break;

            case DEBUG_MEMORY_MODEL_32:
                LogMsg("32-bit device");
                break;
        }
    }
    
    if (FMemoryModel != DEBUG_MEMORY_MODEL_FLAT)
    {
        if (!FindModule(CurrentThread->Cs))
        {
            m = new TDebugModule(CurrentThread->Cs);
            if (m->Handle)
            {
                InsertModule(m);
                FModuleChanged = TRUE;
            }
            else
                delete m;
        }
    }
}

/*##########################################################################
#
#   Name       : TDebug::IsBreak
#
#   Purpose....: Check for breakpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebug::IsBreak(int Sel, long Offset)
{
    TDebugBreak *b;
    int ok = FALSE;
    
    FSection.Enter();

    b = BreakList;

    while (b && !ok)
    {
        if (b->Sel == Sel && b->Offset == Offset)
            ok = TRUE;
        else
            b = b->Next;
    }

    FSection.Leave();

    return ok;
}

/*##########################################################################
#
#   Name       : TDebug::IsWatch
#
#   Purpose....: Check for watch-point
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebug::IsWatch(int Sel, long Offset)
{
    TDebugWatch *w;
    int ok = FALSE;
    
    FSection.Enter();

    w = WatchList;

    while (w && !ok)
    {
        if (w->Sel == Sel && w->Offset == Offset)
            ok = TRUE;
        else
            w = w->Next;
    }

    FSection.Leave();

    return ok;
}

/*##########################################################################
#
#   Name       : TDebug::AddBreak
#
#   Purpose....: Add breakpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::AddBreak(int Sel, long Offset, int Hw)
{
    TDebugBreak *newbr = new TDebugBreak(Sel, Offset, Hw);
    TDebugBreak *b;
    int found = FALSE;

    char str[128];

    sprintf(str, "Break: %04hX:%08lX", Sel, Offset);
    LogMsg(str);
    
    FSection.Enter();

    newbr->Next = 0;

    b = BreakList;
    if (b)
    {
        while (b->Next)
        {
            if (b->Sel == Sel && b->Offset == Offset)
                found = TRUE;
            b = b->Next;
        }

        if (!found)
            b->Next = newbr;            
    }
    else
        BreakList = newbr;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TDebug::ClearBreak
#
#   Purpose....: Clear breakpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::ClearBreak(int Sel, long Offset)
{
    TDebugBreak *b;
    TDebugBreak *delbr;
    
    FSection.Enter();

    b = BreakList;

    if (b)
    {
        if (b->Offset == Offset && b->Sel == Sel)
        {
            BreakList = b->Next;
            delete b;
        }
        else
        {
            while (b->Next)
            {
                delbr = b->Next;
                
                if (delbr->Offset == Offset && delbr->Sel == Sel)
                {
                    b->Next = delbr->Next;
                    delete delbr;
                }
                else
                    b = b->Next;                    
            }
        }
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TDebug::AddWatch
#
#   Purpose....: Add watchpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::AddWatch(int Sel, long Offset, int Size)
{
    TDebugWatch *neww = new TDebugWatch(Sel, Offset, Size);
    TDebugWatch *w;
    int found = FALSE;

    char str[128];

    sprintf(str, "Watch: %04hX:%08lX, %d byte(s)", Sel, Offset, Size);
    LogMsg(str);
    
    FSection.Enter();

    neww->Next = 0;

    w = WatchList;
    if (w)
    {
        while (w->Next)
        {
            if (w->Sel == Sel && w->Offset == Offset)
                found = TRUE;
            w = w->Next;
        }

        if (!found)
            w->Next = neww;            
    }
    else
        WatchList = neww;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TDebug::ClearWatch
#
#   Purpose....: Clear watchpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::ClearWatch(int Sel, long Offset, int Size)
{
    TDebugWatch *w;
    TDebugWatch *delw;
    
    FSection.Enter();

    w = WatchList;

    if (w)
    {
        if (w->Offset == Offset && w->Sel == Sel)
        {
            WatchList = w->Next;
            delete w;
        }
        else
        {
            while (w->Next)
            {
                delw = w->Next;
                
                if (delw->Offset == Offset && delw->Sel == Sel)
                {
                    w->Next = delw->Next;
                    delete delw;
                }
                else
                    w = w->Next;                    
            }
        }
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TDebug::DoTrace
#
#   Purpose....: Do a trace operation
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::DoTrace()
{
    if ((CurrentThread->Cs & 0x3) == 0x3)
    {
        CurrentThread->SetupTrace();
        RdosContinueDebugEvent(FHandle, CurrentThread->ThreadID);
    }
    else
    {
        while (RdosGetDebugThread() != CurrentThread->ThreadID)
            RdosDebugNext();
        RdosDebugTrace();
    }
}

/*##########################################################################
#
#   Name       : TDebug::DoGo
#
#   Purpose....: Do a go operation
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::DoGo()
{
    if ((CurrentThread->Cs & 0x3) == 0x3)
    {
        CurrentThread->SetupGo();
        CurrentThread->ActivateBreaks(BreakList, WatchList);
        RdosContinueDebugEvent(FHandle, CurrentThread->ThreadID);
    }
    else
    {
        while (RdosGetDebugThread() != CurrentThread->ThreadID)
            RdosDebugNext();
        CurrentThread->ActivateBreaks(BreakList, WatchList);
        RdosDebugRun();
    }
}

/*##########################################################################
#
#   Name       : TDebug::Go
#
#   Purpose....: Continue active thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::Go()
{
    LogMsg("Go");

    if (CurrentThread)
    {
        UserSignal.Clear();
        DoGo();
        UserSignal.WaitForever();
    }
}

/*##########################################################################
#
#   Name       : TDebug::Trace
#
#   Purpose....: Trace active thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::Trace()
{
    char Instr[2] = {0, 0};
    int Sel;
    long Offset;

    LogMsg("Trace");

    if (CurrentThread)
    {
        Sel = CurrentThread->Cs;
        Offset = CurrentThread->Eip;
            
        CurrentThread->ReadMem(Sel, Offset, Instr, 2);

        if (Instr[0] == 0xF && Instr[1] == 0xB)
        {
            Offset += 7;
            AddBreak(Sel, Offset, TRUE);
            Go();
            ClearBreak(Sel, Offset);
        }
        else
        {
            UserSignal.Clear();
            DoTrace();
            UserSignal.WaitForever();
        }
    }
}

/*##########################################################################
#
#   Name       : TDebug::AsyncGo
#
#   Purpose....: Continue active thread, with timeout
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebug::AsyncGo(int Timeout)
{
    TWaitDevice *wait;

    LogMsg("Async go");
    
    if (CurrentThread)
    {
        UserSignal.Clear();
        DoGo();

        wait = UserSignal.WaitTimeout(Timeout);

        if (wait)
            return TRUE;
        else
            return FALSE;
    }
    return TRUE;
}

/*##########################################################################
#
#   Name       : TDebug::AsyncTrace
#
#   Purpose....: Trace active thread, with timeout
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebug::AsyncTrace(int Timeout)
{
    int ok;
    TWaitDevice *wait;
    char Instr[2] = {0, 0};

    LogMsg("Async trace");

    if (CurrentThread)
    {
        FAsyncSel = CurrentThread->Cs;
        FAsyncOffset = CurrentThread->Eip;
            
        CurrentThread->ReadMem(FAsyncSel, FAsyncOffset, Instr, 2);

        if (Instr[0] == 0xF && Instr[1] == 0xB)
        {
            FAsyncOffset += 7;
            AddBreak(FAsyncSel, FAsyncOffset, TRUE);
            ok = AsyncGo(Timeout);
            if (ok)
                ClearBreak(FAsyncSel, FAsyncOffset);
            else
                FAsyncBreak = TRUE;
            return ok;
        }
        else
        {
            UserSignal.Clear();
            DoTrace();    

            wait = UserSignal.WaitTimeout(Timeout);

            if (wait)
                return TRUE;
            else
                return FALSE;
        }
    }
    return TRUE;
}

/*##########################################################################
#
#   Name       : TDebug::AsyncPoll
#
#   Purpose....: Poll running thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDebug::AsyncPoll(int Timeout)
{
    TWaitDevice *wait;
    
    wait = UserSignal.WaitTimeout(Timeout);

    if (wait)
    {
        if (FAsyncBreak)
        {
            ClearBreak(FAsyncSel, FAsyncOffset);
            FAsyncBreak = FALSE;
        }
        return TRUE;
    }
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TDebug::ExitAsync
#
#   Purpose....: Exit async, and let process continue
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::ExitAsync()
{
    if (FAsyncBreak)
    {
        ClearBreak(FAsyncSel, FAsyncOffset);
        FAsyncBreak = FALSE;
    }
}

/*##########################################################################
#
#   Name       : TDebug::HandleCreateProcess
#
#   Purpose....: Handle create process event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::HandleCreateProcess(TCreateProcessEvent *event)
{
    InsertThread(new TDebugThread(event));
    InsertModule(new TDebugModule(event));       
}

/*##########################################################################
#
#   Name       : TDebug::HandleTerminateProcess
#
#   Purpose....: Handle terminate process event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::HandleTerminateProcess(int exitcode)
{
    TDebugThread *t;
    TDebugModule *m;

    FSection.Enter();

    while (ThreadList)
    {
        t = ThreadList->Next;
        delete ThreadList;
        ThreadList = t;
    }

    while (ModuleList)    
    {
        m = ModuleList->Next;
        delete ModuleList;
        ModuleList = m;
    }

    CurrentThread = 0;
    NewThread = 0;
    FThreadChanged = TRUE;
    FModuleChanged = TRUE;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TDebug::HandleCreateThread
#
#   Purpose....: Handle create thread event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::HandleCreateThread(TCreateThreadEvent *event)
{
         InsertThread(new TDebugThread(event));
}

/*##########################################################################
#
#   Name       : TDebug::HandleTerminateThread
#
#   Purpose....: Handle terminate thread event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::HandleTerminateThread(int thread)
{
    RemoveThread(thread);
}

/*##########################################################################
#
#   Name       : TDebug::HandleException
#
#   Purpose....: Handle exception event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::HandleException(TExceptionEvent *event, int thread)
{
    TDebugThread *Thread;
    char str[128];

    FSection.Enter();

    Thread = ThreadList;

    while (Thread && Thread->ThreadID != thread)
        Thread = Thread->Next;

    if (Thread)
    {
        Thread->SetException(event);

        if (FWaitLoad)
            Thread->ClearBreak();
        FWaitLoad = FALSE;

        sprintf(str, "Exception: %04hX:%08lX", Thread->Cs, Thread->Eip);
        LogMsg(str);
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TDebug::HandleLoadDll
#
#   Purpose....: Handle load DLL event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::HandleLoadDll(TLoadDllEvent *event)
{
         InsertModule(new TDebugModule(event));
}

/*##########################################################################
#
#   Name       : TDebug::HandleFreeDll
#
#   Purpose....: Handle free DLL event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::HandleFreeDll(int handle)
{
    RemoveModule(handle);
}

/*##########################################################################
#
#   Name       : TDebug::HandleKernelException
#
#   Purpose....: Handle kernel exception event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::HandleKernelException(TKernelExceptionEvent *event, int thread)
{
    TDebugThread *Thread;
    char str[128];

    FSection.Enter();

    Thread = ThreadList;

    while (Thread && Thread->ThreadID != thread)
        Thread = Thread->Next;

    if (Thread)
    {
        Thread->SetException(event);

        if (Thread->HasTraceOccurred())
        {
            sprintf(str, "Trace: %04hX:%08lX", Thread->Cs, Thread->Eip);
            LogMsg(str);
        }
        else
        {
            sprintf(str, "Exception: %04hX:%08lX in %d", Thread->Cs, Thread->Eip, thread);
            LogMsg(str);
        }
    }        

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TDebug::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::SignalNewData()
{
    int thread;
    char debtype;
    TCreateProcessEvent cpe;
    TCreateThreadEvent cte;
    TLoadDllEvent lde;
    TExceptionEvent ee;
    TKernelExceptionEvent kev;
    int ExitCode;
    int handle;
    TDebugThread *newt;

    RdosWaitMilli(5);

    debtype = RdosGetDebugEvent(FHandle, &thread);

    switch (debtype)
    {
        case EVENT_EXCEPTION:
            LogMsg("Exception");
            RdosGetDebugEventData(FHandle, &ee);
            HandleException(&ee, thread);
            break;

        case EVENT_CREATE_THREAD:
            LogMsg("Create thread");
            RdosGetDebugEventData(FHandle, &cte);
            HandleCreateThread(&cte);
            FThreadChanged = TRUE;
            break;

        case EVENT_CREATE_PROCESS:
            LogMsg("Create process");
            RdosGetDebugEventData(FHandle, &cpe);
            HandleCreateProcess(&cpe);
            break;

        case EVENT_TERMINATE_THREAD:
            LogMsg("Terminate thread");
            HandleTerminateThread(thread);
            FThreadChanged = TRUE;
            if (CurrentThread->ThreadID == thread)
                CurrentThread = 0;
            break;

        case EVENT_TERMINATE_PROCESS:
            LogMsg("Terminate process");
            RdosGetDebugEventData(FHandle, &ExitCode);
            HandleTerminateProcess(ExitCode);
            FInstalled = FALSE;
            UserSignal.Signal();
            break;

        case EVENT_LOAD_DLL:
            LogMsg("Load DLL");
            RdosGetDebugEventData(FHandle, &lde);
            HandleLoadDll(&lde);
            FModuleChanged = TRUE;
            break;

        case EVENT_FREE_DLL:
            LogMsg("Free DLL");
            RdosGetDebugEventData(FHandle, &handle);
            HandleFreeDll(handle);
            FModuleChanged = TRUE;
            break;

        case EVENT_KERNEL:
            LogMsg("Kernel exception");
            RdosGetDebugEventData(FHandle, &kev);
            HandleKernelException(&kev, thread);
            break;                    

        case 0:
            LogMsg("Null event");
            break;

        default:
            LogMsg("Unknown event");
            break;
    }

    RdosClearDebugEvent(FHandle);

    if (debtype == EVENT_EXCEPTION || debtype == EVENT_KERNEL)
    {
        if (CurrentThread)
        {
            CurrentThread->DeactivateBreaks(BreakList, WatchList);

            if (thread != CurrentThread->ThreadID)
            {
                newt = LockThread(thread);
                if (newt)
                    NewThread = newt;
                UnlockThread();
            }
            UpdateModules();
        }

        UserSignal.Signal();
    }
    else
        RdosContinueDebugEvent(FHandle, thread);
}

/*##########################################################################
#
#   Name       : TDebug::Execute
#
#   Purpose....: Execute debugger
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/

void TDebug::Execute()
{
    int thread;
        
    RdosWaitMilli(250);

    FHandle = RdosSpawnDebug(FProgram.GetData(), FParam.GetData(), FStartDir.GetData(), 0, 0, &thread);
        
    RdosWaitMilli(250);

    if (!FHandle)
        FInstalled = FALSE;
        
    while (FInstalled)
        WaitForever();
}
