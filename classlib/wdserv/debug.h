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
# debug.h
# Debug classes
#
########################################################################*/

#ifndef _DEBUG_H
#define _DEBUG_H

#include "thread.h"
#include "str.h"
#include "sigdev.h"
#include "rdos.h"

#define DEBUG_MEMORY_MODEL_FLAT     1
#define DEBUG_MEMORY_MODEL_16       2
#define DEBUG_MEMORY_MODEL_32       3

struct TCreateProcessEvent
{
    int FileHandle;
    int Handle;
    int Process;
    int Thread;
    unsigned int ImageBase;
    unsigned int ImageSize;
    unsigned int ObjectRva;
    unsigned int FsLinear;
    unsigned int StartEip;
    unsigned short StartCs;};

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
    unsigned int ObjectRva;
};

struct TExceptionEvent
{
    int Code;
    unsigned int Ptr;
    unsigned int Eip;
    unsigned short Cs;
};    

struct TKernelExceptionEvent
{
    unsigned short Vector;
};    

class TDebugBreak
{
public:
    TDebugBreak(int Sel, long Offset, int Hw);

    int Sel;
    long Offset;
    char Instr;

    int UseHw;
    int IsActive;

    TDebugBreak *Next;
};

class TDebugWatch
{
public:
    TDebugWatch(int Sel, long Offset, int Size);

    int Sel;
    long Offset;
    int Size;

    TDebugWatch *Next;
};

class TDebug;

class TDebugThread
{
public:
    TDebugThread(TDebug *deb, TCreateProcessEvent *event);
    TDebugThread(TDebug *deb, TCreateThreadEvent *event);
    ~TDebugThread();

    void SetException(TExceptionEvent *event);
    void SetException(TKernelExceptionEvent *event);
    int IsDebug();

    void WriteRegs();

    void ActivateBreaks(TDebugBreak *BreakList, TDebugWatch *WatchList);

    void SetupGo(TDebugBreak *bp);
    void SetupTrace(TDebugBreak *bp);
    int WasTrace();

    int HasBreakOccurred();
    int HasTraceOccurred();
    int HasFaultOccurred();

    void ClearBreak();

    int GetMemoryModel();

    TString FaultText;
    TString ThreadName;
    TString ThreadList;
    int ListOffset;
    short int ListSel;

    int ThreadID;
    unsigned int FsLinear;
    long Eip;
    short int Cs;

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
    long MathDataOffs;
    short int MathDataSel;
    real_math St[8];

    TDebugThread *Next;

protected:
    void ReadState();
    void RecalcBreak();

    TDebug *FDebDev;
    int FHasTempBp;
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
    TDebugModule(int Cs);
    ~TDebugModule();

    void ReadName();
    
    TString ModuleName;
    int FileHandle;
    int Handle;
    unsigned int ImageBase;
    unsigned int ImageSize;
    unsigned int ObjectRva;
    unsigned short int CodeSel;
    unsigned short int DataSel;
    unsigned int DataSize;

    int FNew;

    TDebugModule *Next;
};


class TDebug : public TWaitDevice
{
public:
    TDebug(const char *Program, const char *Param, const char *StartDir);
    ~TDebug();

    virtual void DeviceName(char *Name, int MaxLen) const;

    void Stop();
    int IsDone();

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

    void AddBreak(int Sel, long Offset, int Hw);
    void ClearBreak(int Sel, long Offset);
    TDebugBreak *GetHwBreak(int Sel, long Offset);
    TDebugBreak *GetSwBreak(int Sel, long Offset);

    void AddWatch(int Sel, long Offset, int Size);
    void ClearWatch(int Sel, long Offset, int Size);
    int IsWatch(int Sel, long Offset);

    int ReadMem(int Sel, long Offset, char *Buf, int Size);
    int WriteMem(int Sel, long Offset, char *Buf, int Size);

    void WaitForLoad(int timeout);
    void Go();
    void Trace();

    int AsyncGo(int Timeout);
    int AsyncTrace(int Timeout);
    int AsyncPoll(int Timeout);
    void ExitAsync();

    int HasThreadChange();
    void ClearThreadChange();

    int HasModuleChange();

    int IsTerminated();

    int HasConfigChange();
    void ClearConfigChange();

    int GetMemoryModel();

    void LogMsg(const char *Msg);

    void (*OnMsg)(TDebug *Deb, const char *Msg);

protected:
    virtual void SignalNewData();
    virtual void Add(TWait *Wait);
    virtual void Execute();

    int AttachRunning(const char *FileName);

    void InsertThread(TDebugThread *thread);

    TDebugModule *FindModule(int Cs);
    void InsertModule(TDebugModule *module);

    int HasModule(const char *Name);
    void UpdateModules();

    void RemoveThread(int thread);
    void RemoveModule(int handle);

    int PickNewThread();
    void FixupAfterTimeout(TDebugBreak *b);
    
    TDebugBreak *DoGo();
    TDebugBreak *DoTrace();
    TDebugBreak *PrepareToRun();

    void LogBreaks();

    void AddBreak(TDebugBreak *b);
    void RemoveBreak(TDebugBreak *b);

    void HandleCreateProcess(TCreateProcessEvent *event);
    void HandleTerminateProcess(int exitcode);
    void HandleCreateThread(TCreateThreadEvent *event);
    void HandleTerminateThread(int thread);
    void HandleException(TExceptionEvent *event, int thread);
    void HandleKernelException(TKernelExceptionEvent *event, int thread);
    void HandleLoadDll(TLoadDllEvent *event);
    void HandleFreeDll(int handle);

    TString FProgram;
    TString FParam;
    TString FStartDir;
    int FHandle;

    TSection FSection;

    TDebugThread *CurrentThread;
    TDebugThread *ThreadList;
    TDebugModule *ModuleList;

    TDebugBreak *HwBreakList;
    TDebugBreak *SwBreakList;
    TDebugWatch *WatchList;

    TSignalDevice UserSignal;

    int FThreadChanged;

    int FWaitLoad;
    int FDone;

    int FConfigChange;
    int FMemoryModel;
};

#endif

