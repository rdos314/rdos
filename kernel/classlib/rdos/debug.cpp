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

    FSection.Enter();

    m = ModuleList;
    while (m)
    {
        if (m->Handle > ModuleHandle && m->Handle < Handle)
            Handle = m->Handle;

        m = m->Next;            
    }

    FSection.Leave();

    if (Handle != 0xFFFF)
        return Handle;
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
	 short int thread;
    char debtype;
    TCreateProcessEvent cpe;
    TCreateThreadEvent cte;
    TLoadDllEvent lde;
    TExceptionEvent ee;
    int ExitCode;

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
			break;

		case EVENT_CREATE_PROCESS:
			RdosGetDebugEventData(FHandle, &cpe);
			HandleCreateProcess(&cpe);
			break;

		case EVENT_TERMINATE_THREAD:
			HandleTerminateThread(thread);
			break;

		case EVENT_TERMINATE_PROCESS:
			RdosGetDebugEventData(FHandle, &ExitCode);
			HandleTerminateProcess(ExitCode);
			FInstalled = FALSE;
			break;

		case EVENT_LOAD_DLL:
			RdosGetDebugEventData(FHandle, &lde);
			HandleLoadDll(&lde);
			break;
	 }

	 RdosClearDebugEvent(FHandle);

	 if (debtype != EVENT_EXCEPTION)
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
	short int thread;

	RdosWaitMilli(250);

	FHandle = RdosSpawnDebug(FProgram.GetData(), FParam.GetData(), FStartDir.GetData(), &thread);

    if (!FHandle)
        FInstalled = FALSE;
        
    while (FInstalled)
        WaitForever();
}
