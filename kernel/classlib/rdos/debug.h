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
# debug.h
# Debug classes
#
########################################################################*/

#ifndef _DEBUG_H
#define _DEBUG_H

#include "thread.h"
#include "str.h"
#include "sigdev.h"

struct TCreateProcessEvent
{
    int FileHandle;
    int Handle;
    int Process;
    int Thread;
    unsigned int ImageBase;
    unsigned int ImageSize;
    unsigned int FsLinear;
    unsigned int StartEip;
    unsigned short StartCs;
};    

struct TCreateThreadEvent
{
    int Thread;
    unsigned int FsLinear;
    unsigned int StartEip;
    unsigned short StartCs;
};

struct TLoadDllEvent
{
    int FileHandle;
    int Handle;
    unsigned int ImageBase;
    unsigned int ImageSize;
};

struct TExceptionEvent
{
    int Code;
    unsigned int Ptr;
    unsigned int Eip;
    unsigned short Cs;
};    

class TDebugBreak
{
public:
	 TDebugBreak(int Sel, long Offset);

	 int Sel;
	 long Offset;
    char Instr;

    TDebugBreak *Next;
};

class TDebugThread
{
public:
    TDebugThread(TCreateProcessEvent *event);
    TDebugThread(TCreateThreadEvent *event);
    ~TDebugThread();

    void SetException(TExceptionEvent *event);
    int IsDebug();

    int ReadMem(int Sel, long Offset, char *Buf, int Size);
    int WriteMem(int Sel, long Offset, char *Buf, int Size);
    void WriteRegs();

    void ActivateBreaks(TDebugBreak *BreakList);
    void DeactivateBreaks(TDebugBreak *BreakList);

    void SetupGo();
    void SetupTrace();
    int WasTrace();

    int HasBreakOccurred();
    int HasTraceOccurred();
    int HasFaultOccurred();

    TString FaultText;
    TString ThreadName;
    TString ThreadList;
    int ListOffset;
    short int ListSel;

    int ThreadID;
    unsigned int FsLinear;
    long Eip;
    short int Cs;

    long Esp0;
    long Ess0;
    long Esp1;
    long Ess1;
    long Esp2;
    long Ess2;
    long Cr3;
    long Eflags;
    long Eax;
    long Ecx;
    long Edx;
    long Ebx;
    long Esp;
    long Ebp;
    long Esi;
    long Edi;
    long Es;
    long Ss;
    long Ds;
    long Fs;
    long Gs;
    long Ldt;

    long Dr[4];
    long Dr7;
    long MathControl;
    long MathStatus;
    long MathTag;
    long MathEip;
    short int MathCs;
    char MathOp[2];
    long MathDataOffs;
    long MathDataSel;
    long double St[8];

    TDebugThread *Next;

protected:
    void ReadState();

    int FDebug;
	int FHasBreak;
	int FHasTrace;
	int FHasException;
    int FWasTrace;        
};

class TDebugModule
{
public:
    TDebugModule(TCreateProcessEvent *event);
    TDebugModule(TLoadDllEvent *event);
    ~TDebugModule();

    void ReadName();
    
    TString ModuleName;
    int FileHandle;
    int Handle;
    unsigned int ImageBase;
    unsigned int ImageSize;

    TDebugModule *Next;
};


class TDebug : public TWaitDevice
{
public:
	TDebug(const char *Program, const char *Param, const char *StartDir);
	~TDebug();

	virtual void DeviceName(char *Name, int MaxLen) const;

    TDebugThread *GetMainThread();
    TDebugModule *GetMainModule();

    int GetNextThread(int ThreadID);
    int GetNextModule(int Module);
    
    TDebugThread *GetCurrentThread();
    void SetCurrentThread(int ThreadID);

    TDebugThread *LockThread(int ThreadID);
    void UnlockThread();

    TDebugModule *LockModule(int Handle);
    void UnlockModule();

	void AddBreak(int Sel, long Offset);
	void ClearBreak(int Sel, long Offset);

    void WaitForLoad(int timeout);
	void Go();
	void Trace();

	int HasThreadChange();
    void ClearThreadChange();

	int HasModuleChange();
	void ClearModuleChange();

	int IsTerminated();

protected:
	virtual void SignalNewData();
	virtual void Add(TWait *Wait);
	virtual void Execute();

	void InsertThread(TDebugThread *thread);
	void InsertModule(TDebugModule *module);

    void HandleCreateProcess(TCreateProcessEvent *event);
    void HandleTerminateProcess(int exitcode);
    void HandleCreateThread(TCreateThreadEvent *event);
    void HandleTerminateThread(int thread);
	void HandleException(TExceptionEvent *event, int thread);
    void HandleLoadDll(TLoadDllEvent *event);

    TString FProgram;
    TString FParam;
	TString FStartDir;
	int FHandle;

	TSection FSection;

    TDebugThread *CurrentThread;
	TDebugThread *ThreadList;
	TDebugModule *ModuleList;

    TDebugBreak *BreakList;

    TSignalDevice UserSignal;

    int FThreadChanged;
    int FModuleChanged;

};

#endif

