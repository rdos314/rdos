/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2011, Leif Ekblad
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
# sched.c
# Scheduler device
#
########################################################################*/

#include "rdos.h"
#include "rdosdev.h"
#include "string.h"

#define MAX_PROCESSES           64
#define MAX_THREADS             512
#define MAX_PROCESSOR_COUNT     32
#define MAX_IRQ_SERVERS         4

#define MOD_FLAG_MSI_BASE       1
#define MOD_FLAG_MSI_SHARED     2

#define FALSE 0
#define TRUE !FALSE

struct TProcess
{
    int Valid;
    int ID;
    int Sel;
};

struct TThread
{
    int Valid;
    int Handle;
    int ID;
    int Core;
    int Prio;
    int IdleCount;
    int Irq;
    long long BaseTics;
};

struct TCore
{
    long long NullBaseTics;
    long long CoreBaseTics;
    int Active;
    int Realtime;
    int IrqCount;
};

struct TIrq
{
    int Core;
    int ModFlags;
    int IntCount;
    int ServerCount;
    int ServerArr[MAX_IRQ_SERVERS];
};

struct TThreadState
{
    int ID;
    int Core;
    int Load;
};

struct TCoreState
{
    int NullTics;
    int CoreTics;
    int ThreadCount;
    int Load;
};

struct TIrqState
{
    int Irq;
    int Core;
    int Load;
};

struct TKernelSection ProcessSection;
struct TKernelSection ThreadSection;
struct TKernelSection CoreSection;

int ActiveProcessors = 1;
int ProcessorCount = 0;
int CurrLoad = 0;
int MaxLoad = 0;
int NextTid = 1;
int NextPid = 1;
int ActiveThreads = 0;
int ActiveProcesses = 0;

struct TProcess ProcessArr[MAX_PROCESSES];
struct TThread ThreadArr[MAX_THREADS];
struct TCore CoreArr[MAX_PROCESSOR_COUNT];
struct TIrq IrqArr[256];

int StatCount = 0;
struct TThreadState ThreadStatArr[MAX_THREADS];
struct TCoreState CoreStatArr[MAX_PROCESSOR_COUNT];

int MinIrqs = 0;
int MaxIrqs = 0;
int MinCore = 0;
int MaxCore = 0;
int MoveIrq = 0;
int IrqStatCount = 0;
struct TIrqState IrqStatArr[256];

extern void InitScheduler();

extern int GetCurrentThread();
#pragma aux GetCurrentThread parm routine value [eax]

extern void SetThreadCore(int Core, int ThreadHandle);
#pragma aux SetThreadCore parm routine [edx eax]

extern long long GetThreadTics(int ThreadHandle);
#pragma aux GetThreadTics parm routine [eax] value [edx eax]

extern void ClearThreadIrqs(int ThreadHandle);
#pragma aux ClearThreadIrqs parm routine [eax]

extern long HasThreadIrq(int ThreadHandle);
#pragma aux HasThreadIrq parm routine [eax] value [eax]

extern void LockThreadIrq(int ThreadHandle);
#pragma aux LockThreadIrq parm routine [eax]

extern long GetThreadIrq();
#pragma aux GetThreadIrq value [eax]

extern void SetThreadIrq(int ThreadHandle, int Irq);
#pragma aux SetThreadIrq parm routine [eax] [edx]

extern long GetCoreInts(int Core, int Irq);
#pragma aux GetCoreInts parm routine [eax] [edx] value [eax]

extern int GetPciMsiBase(int Irq);
#pragma aux GetPciMsiBase parm routine [eax] value [eax]

extern void MovePciMsi(int Core, int Irq);
#pragma aux MovePciMsi parm routine [eax] [edx]

/*##########################################################################
#
#   Name       : StartCore
#
##########################################################################*/
void StartCore()
{
    int Core;
    int CoreId;

    for (Core = 0; Core < ProcessorCount; Core++)
    {
        if (!CoreArr[Core].Realtime && !CoreArr[Core].Active)
        {
            CoreArr[Core].Active = TRUE;
            CoreId = RdosGetCoreNum(Core);
            RdosStartCore(CoreId);
            ActiveProcessors++;
            break;
        }
    }
}

/*##########################################################################
#
#   Name       : StopCore
#
##########################################################################*/
void StopCore()
{
/*
    if (ActiveProcessors > 1 && RdosHasGlobalTimer())
    {
        SwitchAllIrqs(0);
        ActiveProcessors--;
        ReqShutdown(ActiveProcessors);
    }
*/
}

/*##########################################################################
#
#   Name       : GetActiveThreads
#
##########################################################################*/
#pragma aux GetActiveThreads "*" rdosdev parm routine
int GetActiveThreads()
{
    return ActiveThreads;
}

/*##########################################################################
#
#   Name       : ThreadCreated
#
##########################################################################*/
#pragma aux ThreadCreated "*" rdosdev parm routine [eax edx ecx]
void ThreadCreated(int handle, int ID, int Prio)
{
    int i;
    int ok = FALSE;
    int Index;

    RdosEnterKernelSection(&ThreadSection);

    for (i = 0; i < ActiveThreads; i++)
    {
        if (!ThreadArr[i].Valid)
        {
            ok = TRUE;
            Index = i;
            break;
        }
    }

    if (!ok)
    {
        if (ActiveThreads < MAX_THREADS)
        {
            Index = ActiveThreads;
            ActiveThreads++;
            ok = TRUE;
        }
    }

    if (ok)
    {
        ThreadArr[Index].Valid = TRUE;
        ThreadArr[Index].Handle = handle;
        ThreadArr[Index].ID = ID;
        ThreadArr[Index].Core = 0;
        ThreadArr[Index].Prio = Prio;
        ThreadArr[Index].IdleCount = 0;
        ThreadArr[Index].BaseTics = 0;
        ThreadArr[Index].Irq = 0;

        ClearThreadIrqs(handle);
    }

    RdosLeaveKernelSection(&ThreadSection);
}

/*##########################################################################
#
#   Name       : ThreadTerminated
#
##########################################################################*/
#pragma aux ThreadTerminated "*" rdosdev parm routine [eax]
void ThreadTerminated(int handle)
{
    int i;

    RdosEnterKernelSection(&ThreadSection);

    for (i = 0; i < ActiveThreads; i++)
    {
        if (ThreadArr[i].Valid && ThreadArr[i].Handle == handle)
        {
            ThreadArr[i].Valid = FALSE;

            if (i == ActiveThreads - 1)
                ActiveThreads--;

            break;
        }
    }

    RdosLeaveKernelSection(&ThreadSection);
}

/*##########################################################################
#
#   Name       : IdToHandle
#
#   Descr      : Convert from ID to handle
#
##########################################################################*/
#pragma aux IdToHandle "*" rdosdev parm routine [eax]
int IdToHandle(int ID)
{
    int i;
    int handle = 0;

    RdosEnterKernelSection(&ThreadSection);

    for (i = 0; i < ActiveThreads; i++)
    {
        if (ThreadArr[i].Valid && ThreadArr[i].ID == ID)
        {
            handle = ThreadArr[i].Handle;
            break;
        }
    }

    RdosLeaveKernelSection(&ThreadSection);

    if (handle)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return handle;
}

/*##########################################################################
#
#   Name       : IndexToHandle
#
#   Descr      : Convert from index to handle
#
##########################################################################*/
#pragma aux IndexToHandle "*" rdosdev parm routine [eax]
int IndexToHandle(int Index)
{
    int handle = 0;

    RdosEnterKernelSection(&ThreadSection);

    if (Index >= 0 && Index < ActiveThreads)
        if (ThreadArr[Index].Valid)
            handle = ThreadArr[Index].Handle;

    RdosLeaveKernelSection(&ThreadSection);

    if (handle)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return handle;
}

/*##########################################################################
#
#   Name       : CreateTid
#
#   Descr      : Get thread ID
#
##########################################################################*/
#pragma aux CreateTid "*" rdosdev parm routine
int CreateTid()
{
    int i;
    int tid;
    int ok;

    RdosEnterKernelSection(&ThreadSection);

    ok = FALSE;

    while (!ok)
    {
        tid = NextTid;

        if (NextTid == 0x7FFF)
            NextTid = 1;
        else
            NextTid++;

        ok = TRUE;

        for (i = 0; i < ActiveThreads; i++)
        {
            if (ThreadArr[i].Valid && ThreadArr[i].ID == tid)
            {
                ok = FALSE;
                break;
            }
        }
    }

    RdosLeaveKernelSection(&ThreadSection);

    return tid;
}

/*##########################################################################
#
#   Name       : MoveThread
#
#   Descr      : Move thread to another core
#
##########################################################################*/
#pragma aux MoveThread "*" rdosdev parm routine [eax ebx]
void MoveThread(int Core, int ThreadId)
{
    int i;
    int ok = FALSE;

    if (Core < RdosGetCoreCount())
        ok = TRUE;

    if (ok)
        ok = CoreArr[Core].Active && !CoreArr[Core].Realtime;

    if (ok)
    {
        RdosEnterKernelSection(&ThreadSection);

        for (i = 0; i < ActiveThreads; i++)
        {
            if (ThreadArr[i].Valid && ThreadArr[i].ID == ThreadId)
            {
                if (Core != ThreadArr[i].Core)
                {
                    ThreadArr[i].Core = Core;
                    SetThreadCore(Core, ThreadArr[i].Handle);
                }
                break;
            }
        }

        RdosLeaveKernelSection(&ThreadSection);
    }
}

/*##########################################################################
#
#   Name       : ImplMoveToNewCore
#
#   Descr      : Move thread to new core
#
##########################################################################*/
#pragma aux ImplMoveToNewCore "*" rdosdev parm routine
void ImplMoveToNewCore()
{
    int ThreadId = GetCurrentThread();
    int Core;
    int CoreId = 0;
    int i;

    for (Core = 0; Core < ProcessorCount; Core++)
    {
        if (!CoreArr[Core].Realtime && !CoreArr[Core].Active)
        {
            CoreArr[Core].Active = TRUE;
            CoreId = RdosGetCoreNum(Core);
            RdosStartCore(CoreId);
            ActiveProcessors++;
            break;
        }
    }

    if (CoreId)
    {
        RdosEnterKernelSection(&ThreadSection);

        for (i = 0; i < ActiveThreads; i++)
        {
            if (ThreadArr[i].Valid && ThreadArr[i].ID == ThreadId)
            {
                if (Core != ThreadArr[i].Core)
                {
                    ThreadArr[i].Core = Core;
                    SetThreadCore(Core, ThreadArr[i].Handle);
                }
                break;
            }
        }

        RdosLeaveKernelSection(&ThreadSection);
    }
}

/*##########################################################################
#
#   Name       : GetActiveCores
#
##########################################################################*/
#pragma aux ImplGetActiveCores "*" rdosdev parm routine value [eax]
int __far ImplGetActiveCores()
{
    return ActiveProcessors;
}

/*##########################################################################
#
#   Name       : GetProgramCount
#
##########################################################################*/
#pragma aux ImplGetProgramCount "*" rdosdev parm routine
int __far ImplGetProgramCount()
{
    RdosSetSuccess();
    return ActiveProcesses;
}

/*##########################################################################
#
#   Name       : ProcessCreated
#
##########################################################################*/
#pragma aux ImplProgramCreated "*" rdosdev parm routine [ebx] value [eax]
int __far ImplProgramCreated(int sel)
{
    int i;
    int ok = FALSE;
    int Index;
    int pid;

    RdosEnterKernelSection(&ProcessSection);

    ok = FALSE;

    while (!ok)
    {
        pid = NextPid;

        if (NextPid == 0x7FFF)
            NextPid = 1;
        else
            NextPid++;

        ok = TRUE;

        for (i = 0; i < ActiveProcesses; i++)
        {
            if (ProcessArr[i].Valid && ProcessArr[i].ID == pid)
            {
                ok = FALSE;
                break;
            }
        }
    }

    ok = FALSE;

    for (i = 0; i < ActiveProcesses; i++)
    {
        if (!ProcessArr[i].Valid)
        {
            ok = TRUE;
            Index = i;
            break;
        }
    }

    if (!ok)
    {
        if (ActiveProcesses < MAX_PROCESSES)
        {
            Index = ActiveProcesses;
            ActiveProcesses++;
            ok = TRUE;
        }
    }

    if (ok)
    {
        ProcessArr[Index].Valid = TRUE;
        ProcessArr[Index].Sel = sel;
        ProcessArr[Index].ID = pid;
    }

    RdosLeaveKernelSection(&ProcessSection);

    if (pid)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return pid;
}

/*##########################################################################
#
#   Name       : ProgramTerminated
#
##########################################################################*/
#pragma aux ImplProgramTerminated "*" rdosdev parm routine [ebx]
void __far ImplProgramTerminated(int sel)
{
    int i;

    RdosEnterKernelSection(&ProcessSection);

    for (i = 0; i < ActiveProcesses; i++)
    {
        if (ProcessArr[i].Valid && ProcessArr[i].Sel == sel)
        {
            ProcessArr[i].Valid = FALSE;

            if (i == ActiveProcesses - 1)
                ActiveProcesses--;

            break;
        }
    }

    RdosLeaveKernelSection(&ProcessSection);

    RdosSetSuccess();
}

/*##########################################################################
#
#   Name       : GetProgramSel
#
#   Descr      : Convert from process ID to selector
#
##########################################################################*/
#pragma aux ImplGetProgramSel "*" rdosdev parm routine [ebx] value [eax]
int __far ImplGetProgramSel(int ID)
{
    int i;
    int sel = 0;

    RdosEnterKernelSection(&ProcessSection);

    for (i = 0; i < ActiveProcesses; i++)
    {
        if (ProcessArr[i].Valid && ProcessArr[i].ID == ID)
        {
            sel = ProcessArr[i].Sel;
            break;
        }
    }

    RdosLeaveKernelSection(&ProcessSection);

    if (sel)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return sel;
}

/*##########################################################################
#
#   Name       : GetProgramID
#
#   Descr      : Get program ID byte index
#
##########################################################################*/
#pragma aux ImplGetProgramID "*" rdosdev parm routine [eax] value [eax]
int __far ImplGetProgramID(int Index)
{
    int ID = 0;

    RdosEnterKernelSection(&ProcessSection);

    if (Index >= 0 && Index < ActiveProcesses)
        if (ProcessArr[Index].Valid)
            ID = ProcessArr[Index].ID;

    RdosLeaveKernelSection(&ProcessSection);

    if (ID)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return ID;
}

/*##########################################################################
#
#   Name       : AllocateRealTimeCore
#
##########################################################################*/
#pragma aux ImplAllocateRealTimeCore "*" rdosdev parm routine value [eax]
int __far ImplAllocateRealTimeCore()
{
    int ok = FALSE;
    int Core;

    for (Core = 0; Core < ProcessorCount; Core++)
    {
        if (!CoreArr[Core].Realtime && !CoreArr[Core].Active)
        {
            CoreArr[Core].Realtime = TRUE;
            ok = TRUE;
            break;
        }
    }

    if (ok)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return Core;
}

/*##########################################################################
#
#   Name       : FreeRealTimeCore
#
##########################################################################*/
#pragma aux ImplFreeRealTimeCore "*" rdosdev parm routine [eax]
void __far ImplFreeRealTimeCore(int Core)
{
    if (Core >= 0 && Core < ProcessorCount)
        if (CoreArr[Core].Realtime)
            CoreArr[Core].Realtime = FALSE;

    RdosSetSuccess();
}

/*##########################################################################
#
#   Name       : Scheduler thread
#
##########################################################################*/
#pragma aux SchedulerThread "*" rdosdev parm routine [es edi]
void __far SchedulerThread(void *param)
{
    long long Tics;
    int Diff;
    int i;
    int j;
    int k;
    int irq;
    int found;
    int handle;
    int count;
    int IrqChanged;
    int id;
    int ints;
    int base;
    int Core;
    int Load;
    long long NullTics;
    long long CoreTics;
    int NullTime;
    int CoreTime;
    int NullSum;
    int CoreSum;
    int HighestCore;
    int HighestLoad;
    int LowestCore;
    int LowestLoad;
    int OptLoad;
    int BestLoad;
    int BestThread;

    ProcessorCount = RdosGetCoreCount();

    RdosInitFreq();

    for (Core = 0; Core < ProcessorCount; Core++)
    {
        RdosGetCoreLoad(Core, &NullTics, &CoreTics);
        CoreArr[Core].CoreBaseTics = CoreTics;
        CoreArr[Core].NullBaseTics = NullTics;
        CoreArr[Core].Realtime = FALSE;
        if (Core == 0)
            CoreArr[Core].Active = TRUE;
        else
            CoreArr[Core].Active = FALSE;
    }

    for (;;)
    {
        RdosWaitMilli(250);

        RdosEnterKernelSection(&ThreadSection);

        IrqChanged = 0;

        for (i = 0; i < ActiveThreads; i++)
        {
            if (ThreadArr[i].Valid)
            {
                handle = ThreadArr[i].Handle;
                if (HasThreadIrq(handle))
                {
                    id = ThreadArr[i].ID;
                    LockThreadIrq(handle);
                    irq = GetThreadIrq();
                    while (irq != -1)
                    {
                        if (IrqArr[irq].ServerCount != -1)
                        {
                            if (IrqArr[irq].ServerCount < MAX_IRQ_SERVERS)
                            {
                                found = 0;
                                for (j = 0; j < IrqArr[irq].ServerCount && !found; j++)
                                    found = IrqArr[irq].ServerArr[j] == id;

                                if (!found)
                                {
                                    IrqChanged = 1;
                                    IrqArr[irq].ServerArr[IrqArr[irq].ServerCount] = id;
                                    IrqArr[irq].ServerCount++;
                                }
                            }
                            else
                                IrqArr[irq].ServerCount = -1;
                        }
                        irq = GetThreadIrq();
                    }
                }
            }
        }

        if (IrqChanged)
        {
            for (i = 0; i < 256; i++)
            {
                base = GetPciMsiBase(i);

                if (base)
                {
                    if (base == i)
                        IrqArr[i].ModFlags = MOD_FLAG_MSI_BASE;
                    else
                        IrqArr[i].ModFlags = MOD_FLAG_MSI_SHARED;
                }
                else
                    IrqArr[i].ModFlags = 0;
            }

            for (i = 0; i < ActiveThreads; i++)
            {
                if (ThreadArr[i].Valid)
                {
                    id = ThreadArr[i].ID;
                    count = 0;

                    for (j = 0; j < 256; j++)
                    {
                        for (k = 0; k < IrqArr[j].ServerCount; j++)
                        {
                            if (IrqArr[j].ServerArr[k] == id)
                            {
                                count++;
                                irq = j;
                            }
                        }
                    }

                    switch (count)
                    {
                        case 0:
                            ThreadArr[i].Irq = 0;
                            SetThreadIrq(ThreadArr[i].Handle, 0);
                            break;

                        case 1:
                            SetThreadIrq(ThreadArr[i].Handle, irq);
                            ThreadArr[i].Irq = irq;
                            break;

                        default:
                            ThreadArr[i].Irq = -1;
                            SetThreadIrq(ThreadArr[i].Handle, 0);
                            break;
                    }
                }
            }
        }

        RdosLeaveKernelSection(&ThreadSection);

        StatCount = 0;
        MaxLoad = 0;

        RdosEnterKernelSection(&ThreadSection);

        for (Core = 0; Core < ProcessorCount; Core++)
        {
            CoreStatArr[Core].ThreadCount = 0;
            RdosGetCoreLoad(Core, &NullTics, &CoreTics);
            CoreStatArr[Core].CoreTics = (int)(CoreTics - CoreArr[Core].CoreBaseTics);
            CoreArr[Core].CoreBaseTics = CoreTics;
            CoreStatArr[Core].NullTics = (int)(NullTics - CoreArr[Core].NullBaseTics);
            CoreArr[Core].NullBaseTics = NullTics;
        }

        NullSum = 0;
        CoreSum = 0;

        for (Core = 0; Core < ProcessorCount; Core++)
        {
            if (CoreArr[Core].Active)
            {
                NullTime = CoreStatArr[Core].NullTics;
                CoreTime = CoreStatArr[Core].CoreTics;

                NullSum += NullTime;
                CoreSum += CoreTime;

                if (CoreTime)
                    Load = 1000 - 1000 * NullTime / CoreTime;
                else
                    Load = 0;

                if (Load < 0)
                    Load = 0;

                if (Load > 1000)
                    Load = 1000;

                if (Load > MaxLoad)
                    MaxLoad = Load;

                CoreStatArr[Core].Load = Load;
            }
        }

        if (CoreSum)
            CurrLoad = 1000 - 1000 * NullSum / CoreSum;
        else
            CurrLoad = 0;

        if (CurrLoad < 0)
            CurrLoad = 0;

        if (CurrLoad > 1000)
            CurrLoad = 1000;


        for (i = 0; i < ActiveThreads; i++)
        {
            if (ThreadArr[i].Valid)
            {
                irq = ThreadArr[i].Irq;
                if (irq > 0)
                {
/* disable since MSI-X is not supported!

                    if (ThreadArr[i].Core != IrqArr[irq].Core)
                    {
                        ThreadArr[i].Core = IrqArr[irq].Core;
                        SetThreadCore(IrqArr[irq].Core, ThreadArr[i].Handle);
                    }
*/
                }

                Tics = GetThreadTics(ThreadArr[i].Handle);
                Diff = (int)(Tics - ThreadArr[i].BaseTics);
                ThreadArr[i].BaseTics = Tics;

                Core = ThreadArr[i].Core;

                Load = 0;

                if (Core < ProcessorCount)
                {
                    CoreStatArr[Core].ThreadCount++;

                    if (ThreadArr[i].Prio && ThreadArr[i].Prio < 10)
                    {
                        if (CoreStatArr[Core].CoreTics)
                            Load = 1000 * Diff / CoreStatArr[Core].CoreTics;
                        else
                            Load = 0;
                    }
                }

                if (Load && (ThreadArr[i].Irq <= 0))
                {
                    ThreadStatArr[StatCount].ID = ThreadArr[i].ID;
                    ThreadStatArr[StatCount].Core = ThreadArr[i].Core;
                    ThreadStatArr[StatCount].Load = Load;
                    StatCount++;

                    ThreadArr[i].IdleCount = 0;
                }
                else
                    ThreadArr[i].IdleCount++;
            }
        }

        RdosLeaveKernelSection(&ThreadSection);

        IrqStatCount = 0;

        if (ActiveProcessors > 1)
        {
            for (i = 0; i < 256; i++)
            {
                base = i;

                switch (IrqArr[i].ModFlags)
                {
                    case MOD_FLAG_MSI_BASE:
                    ints = GetCoreInts(IrqArr[i].Core, i);
                    break;

                    case MOD_FLAG_MSI_SHARED:
                        base--;
                        while (IrqArr[base].ModFlags == MOD_FLAG_MSI_SHARED)
                            base--;

                        ints = GetCoreInts(IrqArr[i].Core, i);
                        break;

                    default:
                        ints = 0;
                        break;
                }

                if (ints)
                {
                    if (IrqStatCount && IrqStatArr[IrqStatCount - 1].Irq == base)
                        IrqStatArr[IrqStatCount - 1].Load += ints;
                    else
                    {
                        if (IrqArr[i].ServerCount == 1)
                        {
                            IrqStatArr[IrqStatCount].Irq = base;
                            IrqStatArr[IrqStatCount].Core = IrqArr[i].Core;
                            IrqStatArr[IrqStatCount].Load = ints;
                            IrqStatCount++;
                        }
                    }
                }
            }
        }

        if (IrqStatCount)
        {
            for (Core = 0; Core < ProcessorCount; Core++)
                CoreArr[Core].IrqCount = 0;

            for (i = 0; i < IrqStatCount; i++)
            {
                Core = IrqStatArr[i].Core;
                CoreArr[Core].IrqCount++;
            }

            MinIrqs = 1000;
            MaxIrqs = 0;

            for (Core = 0; Core < ProcessorCount; Core++)
            {
                if (CoreArr[Core].Active && !CoreArr[Core].Realtime)
                {
                    if (MinIrqs > CoreArr[Core].IrqCount)
                    {
                        MinIrqs = CoreArr[Core].IrqCount;
                        MinCore = Core;
                    }

                    if (MaxIrqs < CoreArr[Core].IrqCount)
                    {
                        MaxIrqs = CoreArr[Core].IrqCount;
                        MaxCore = Core;
                    }
                }
            }

            if (MaxIrqs > 1 && MinIrqs == 0)
            {
                Load = 0;

                for (i = 0; i < IrqStatCount; i++)
                {
                    if (IrqStatArr[i].Core == MaxCore)
                    {
                        if (Load < IrqStatArr[i].Load)
                        {
                            Load = IrqStatArr[i].Load;
                            MoveIrq = IrqStatArr[i].Irq;
                        }
                    }
                }
                MovePciMsi(MinCore, MoveIrq);

                IrqArr[MoveIrq].Core = MinCore;
                MoveIrq++;
                while (IrqArr[MoveIrq].ModFlags == MOD_FLAG_MSI_SHARED)
                {
                    IrqArr[MoveIrq].Core = MinCore;
                    MoveIrq++;
                }
            }
        }

        RdosEnterKernelSection(&CoreSection);

        if (MaxLoad > 600)
            RdosUpdateFreq(-1);
        else
        {
            if (MaxLoad < 300)
                RdosUpdateFreq(1);
            else
                RdosUpdateFreq(0);
        }

        RdosLeaveKernelSection(&CoreSection);

        if (CurrLoad > 400)
            StartCore();

        if (ActiveProcessors > 1)
        {
            HighestLoad = -1;
            LowestLoad = 1100;

            for (Core = 0; Core < ProcessorCount; Core++)
            {
                if (CoreArr[Core].Active && !CoreArr[Core].Realtime)
                {
                    Load = CoreStatArr[Core].Load;

                    if (Load > HighestLoad)
                    {
                        HighestCore = Core;
                        HighestLoad = Load;
                    }

                    if (Load < LowestLoad)
                    {
                        LowestCore = Core;
                        LowestLoad =  Load;
                    }
                }
            }

            OptLoad = (HighestLoad - LowestLoad) / 2;

            if (OptLoad > 100)
            {
                BestLoad = 2000;

                for (i = 0; i < StatCount; i++)
                {
                    if (ThreadStatArr[i].Core == HighestCore)
                    {
                        Load = ThreadStatArr[i].Load;

                        if (Load > OptLoad)
                            Load = Load - OptLoad;
                        else
                            Load = OptLoad - Load;

                        if (Load < BestLoad)
                        {
                            BestLoad = Load;
                            BestThread = i;
                        }
                    }
                }

                RdosEnterKernelSection(&ThreadSection);

                for (i = 0; i < ActiveThreads; i++)
                {
                    if (ThreadArr[i].Valid && ThreadArr[i].ID == ThreadStatArr[BestThread].ID)
                    {
                        if (LowestCore != ThreadArr[i].Core)
                        {
                            ThreadArr[i].Core = LowestCore;
                            SetThreadCore(LowestCore, ThreadArr[i].Handle);
                        }
                        break;
                    }
                }

                for (i = 0; i < ActiveThreads; i++)
                {
                    if (ThreadArr[i].Valid && ThreadArr[i].Core != 0 && ThreadArr[i].Prio && ThreadArr[i].IdleCount > 16 && ThreadArr[i].Irq == 0)
                    {
                        ThreadArr[i].Core = 0;
                        ThreadArr[i].IdleCount = 0;
                        SetThreadCore(0, ThreadArr[i].Handle);
                    }
                }

                RdosLeaveKernelSection(&ThreadSection);
            }
        }
    }
}

/*##########################################################################
#
#   Name       : InitThreadList
#
#   Purpose....: Init thread lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InitThreadList()
{
    int i;

    for (i = 0; i < MAX_THREADS; i++)
        ThreadArr[i].Valid = FALSE;

    for (i = 0; i < MAX_PROCESSES; i++)
        ProcessArr[i].Valid = FALSE;

    for (i = 0; i < 256; i++)
    {
        IrqArr[i].ServerCount = 0;
        IrqArr[i].Core = 0;
    }

    RdosInitKernelSection(&ThreadSection);
    RdosInitKernelSection(&CoreSection);
    RdosInitKernelSection(&ProcessSection);
}

/*##########################################################################
#
#   Name       : InitTasking
#
#   Purpose....: Init tasking callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux InitTasking "*" rdosdev parm routine
void __far InitTasking()
{
    RdosCreateKernelThread(5, 0x1000, &SchedulerThread, "Scheduler", 0);
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Initialization
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main()
{
    InitThreadList();
    InitScheduler();
    RdosHookInitTasking(&InitTasking);

    RdosRegisterOsGate(osgate_program_created, (__rdos_gate_callback *)&ImplProgramCreated, "Program Created");
    RdosRegisterOsGate(osgate_program_terminated, (__rdos_gate_callback *)&ImplProgramTerminated, "Program Terminated");
    RdosRegisterOsGate(osgate_get_program_sel, (__rdos_gate_callback *)&ImplGetProgramSel, "Get Program Selector");
    RdosRegisterOsGate(osgate_get_program_id, (__rdos_gate_callback *)&ImplGetProgramID, "Get Program ID");
    RdosRegisterOsGate(osgate_allocate_realtime_core, (__rdos_gate_callback *)&ImplAllocateRealTimeCore, "Allocate Realtime Core");
    RdosRegisterOsGate(osgate_free_realtime_core, (__rdos_gate_callback *)&ImplFreeRealTimeCore, "Free Realtime Core");

    RdosRegisterBimodalUserGate(usergate_get_active_cores, (__rdos_gate_callback *)&ImplGetActiveCores, "Get Active Cores");
    RdosRegisterBimodalUserGate(usergate_get_program_count, (__rdos_gate_callback *)&ImplGetProgramCount, "Get Program Count");
    return 0;
}
