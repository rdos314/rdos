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
#include "rdos.h"
#include "debug.h"

#define FALSE	0
#define TRUE	!FALSE

#define EVENT_EXCEPTION         1
#define EVENT_CREATE_THREAD     2
#define EVENT_CREATE_PROCESS    3
#define EVENT_TERMINATE_THREAD  4
#define EVENT_TERMINATE_PROCESS 5
#define EVENT_LOAD_DLL          6

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

	FWasTrace = FALSE;

	RdosGetThreadTss(ThreadID, &tss);
	RdosReadThreadMem(ThreadID, tss.cs, tss.eip, &ch, 1);

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

    RdosGetThreadTss(ThreadID, &tss);

	RdosReadThreadMem(ThreadID, tss.cs, tss.eip, &ch, 1);

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
void TDebugThread::ActivateBreaks(TDebugBreak *BreakList)
{
    TDebugBreak *b = BreakList;
    char brinstr = 0xCC;

    while (b)
    {
        RdosReadThreadMem(ThreadID, b->Sel, b->Offset, &b->Instr, 1);
		  RdosWriteThreadMem(ThreadID, b->Sel, b->Offset, &brinstr, 1);

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
void TDebugThread::DeactivateBreaks(TDebugBreak *BreakList)
{
    TDebugBreak *b = BreakList;

	if (!FWasTrace)
    {
        while (b)
        {
            RdosWriteThreadMem(ThreadID, b->Sel, b->Offset, &b->Instr, 1);
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

	FHasBreak = FALSE;
	FHasTrace = FALSE;
	FHasException = FALSE;

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

	Cs = event->Cs;
	Eip = event->Eip;

	ReadState();

	RdosGetThreadTss(ThreadID, &tss);

    Esp0 = tss.esp0;
    Ess0 = tss.ess0;
    Esp1 = tss.esp1;    
    Ess1 = tss.ess1;
    Esp2 = tss.esp2;
    Ess2 = tss.ess2;    
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
	 MathOp[0] = tss.MathOp[0];
	 MathOp[1] = tss.MathOp[1];
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

    FNew = TRUE;

    ReadName();
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

    str[0];
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
TDebugBreak::TDebugBreak(int sel, long offset)
{
	 Sel = sel;
	 Offset = offset;
	 Instr = 0xCC;
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
TDebug::TDebug(const char *Program, const char *Param, const char *StartDir)
 : FProgram(Program),
	FParam(Param),
	FStartDir(StartDir)
{
    ThreadList = 0;
    ModuleList = 0;
    CurrentThread = 0;
    BreakList = 0;

    FThreadChanged = FALSE;
    FModuleChanged = FALSE;

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
    UserSignal.WaitTimeout(timeout);
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
    return FThreadChanged;
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
#   Name       : TDebug::AddBreak
#
#   Purpose....: Add breakpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::AddBreak(int Sel, long Offset)
{
    TDebugBreak *newbr = new TDebugBreak(Sel, Offset);
    TDebugBreak *b;
    int found = FALSE;
    
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
	if (CurrentThread)
	{
		UserSignal.Clear();

		CurrentThread->SetupGo();
		CurrentThread->ActivateBreaks(BreakList);
		RdosContinueDebugEvent(FHandle, CurrentThread->ThreadID);

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

	if (CurrentThread)
	{
	    Sel = CurrentThread->Cs;
	    Offset = CurrentThread->Eip;
	    
        CurrentThread->ReadMem(Sel, Offset, Instr, 2);

        if (Instr[0] == 0xF && Instr[1] == 0xB)
        {
            Offset += 7;
            AddBreak(Sel, Offset);
            Go();
            ClearBreak(Sel, Offset);
        }
        else
        {
    		UserSignal.Clear();
    
            CurrentThread->SetupTrace();
		    RdosContinueDebugEvent(FHandle, CurrentThread->ThreadID);

    		UserSignal.WaitForever();
        }
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

    FSection.Enter();

    Thread = ThreadList;

    while (Thread && Thread->ThreadID != thread)
        Thread = Thread->Next;

    if (Thread)
        Thread->SetException(event);

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
    int ExitCode;
    TDebugThread *newt;

	debtype = RdosGetDebugEvent(FHandle, &thread);

	switch (debtype)
	{
		case EVENT_EXCEPTION:
			RdosGetDebugEventData(FHandle, &ee);
			HandleException(&ee, thread);
			break;

		case EVENT_CREATE_THREAD:
			RdosGetDebugEventData(FHandle, &cte);
			HandleCreateThread(&cte);
			FThreadChanged = TRUE;
			break;

		case EVENT_CREATE_PROCESS:
			RdosGetDebugEventData(FHandle, &cpe);
			HandleCreateProcess(&cpe);
			break;

		case EVENT_TERMINATE_THREAD:
			HandleTerminateThread(thread);
			FThreadChanged = TRUE;
			break;

		case EVENT_TERMINATE_PROCESS:
			RdosGetDebugEventData(FHandle, &ExitCode);
			HandleTerminateProcess(ExitCode);
			FInstalled = FALSE;
			UserSignal.Signal();
			break;

		case EVENT_LOAD_DLL:
			RdosGetDebugEventData(FHandle, &lde);
			HandleLoadDll(&lde);
			FModuleChanged = TRUE;
			break;
	}

	RdosClearDebugEvent(FHandle);

	if (debtype == EVENT_EXCEPTION)
	{
		if (CurrentThread)
		{
			CurrentThread->DeactivateBreaks(BreakList);

			if (thread != CurrentThread->ThreadID)
			{
				newt = LockThread(thread);
				if (newt)
				{
					CurrentThread = newt;
					FThreadChanged = TRUE;
				}
				UnlockThread();
			}
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

	FHandle = RdosSpawnDebug(FProgram.GetData(), FParam.GetData(), FStartDir.GetData(), &thread);

    if (!FHandle)
        FInstalled = FALSE;
        
    while (FInstalled)
        WaitForever();
}
