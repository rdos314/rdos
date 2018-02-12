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
#define MAX_MODULES             256
#define MAX_THREADS             512
#define MAX_PROCESSOR_COUNT     32

#define FALSE 0
#define TRUE !FALSE

struct TProcess
{
    int Valid;
    int ID;
    int Sel;
};

struct TModule
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
    int IntCount;
    long long BaseTics;
};

struct TCore
{
    long long NullBaseTics;
    long long CoreBaseTics;
};

struct TThreadState
{
    int ID;
    int Core;
    int IntCount;
    int Load;
};

struct TCoreState
{
    int NullTics;
    int CoreTics;
    int ThreadCount;
    int Load;
};

struct TKernelSection ThreadSection;
struct TKernelSection CoreSection;

int ActiveProcessors = 1;
int ProcessorCount = 0;
int CurrLoad = 0;
int MaxLoad = 0;
int NextTid = 1;
int NextMid = 1;
int NextPid = 1;
int ActiveThreads = 0;
int ActiveProcesses = 0;
int ActiveModules = 0;

struct TProcess ProcessArr[MAX_PROCESSES];
struct TModule ModuleArr[MAX_MODULES];
struct TThread ThreadArr[MAX_THREADS];
struct TCore CoreArr[MAX_PROCESSOR_COUNT];

int StatCount = 0;
struct TThreadState ThreadStatArr[MAX_THREADS];
struct TCoreState CoreStatArr[MAX_PROCESSOR_COUNT];

extern void InitScheduler();

extern void SetThreadCore(int Core, int ThreadHandle);
#pragma aux SetThreadCore parm routine [edx eax]

extern long long GetThreadTics(int ThreadHandle);
#pragma aux GetThreadTics parm routine [eax] value [edx eax]

extern int GetThreadIntCount(int ThreadHandle);
#pragma aux GetThreadIntCount parm routine [eax] value [eax]

/*##########################################################################
#
#   Name       : StartCore
#
##########################################################################*/
void StartCore()
{
    int CoreId;

    if (ActiveProcessors < ProcessorCount)
    {
        CoreId = RdosGetCoreNum(ActiveProcessors);
        RdosStartCore(CoreId);
        ActiveProcessors++;
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
#   Descr      : Move thread to new core
#
##########################################################################*/
#pragma aux MoveThread "*" rdosdev parm routine [eax ebx]
void MoveThread(int Core, int ThreadId)
{
    int i;
    
    if (Core < RdosGetCoreCount())
    {
        RdosEnterKernelSection(&CoreSection); 

        while (ActiveProcessors <= Core)
            StartCore();

        RdosLeaveKernelSection(&CoreSection); 

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

    RdosEnterKernelSection(&ThreadSection);    

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
    
    RdosLeaveKernelSection(&ThreadSection);

    if (pid)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return pid;
}
    
/*##########################################################################
#
#   Name       : ProcessTerminated
#
##########################################################################*/
#pragma aux ProcessTerminated "*" rdosdev parm routine [eax]
void ProcessTerminated(int sel)
{
    int i;

    RdosEnterKernelSection(&ThreadSection);    

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

    RdosLeaveKernelSection(&ThreadSection);    
}
    
/*##########################################################################
#
#   Name       : GetProcessSel
#
#   Descr      : Convert from process ID to selector
#
##########################################################################*/
#pragma aux GetProcessSel "*" rdosdev parm routine [ebx] value [eax]
int GetProcessSel(int ID)
{
    int i;
    int sel = 0;

    RdosEnterKernelSection(&ThreadSection);    

    for (i = 0; i < ActiveProcesses; i++)
    {
        if (ProcessArr[i].Valid && ProcessArr[i].ID == ID) 
        {
            sel = ProcessArr[i].Sel;
            break;
        }
    }

    RdosLeaveKernelSection(&ThreadSection);    

    if (sel)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return sel;
}
    
/*##########################################################################
#
#   Name       : GetProcessID
#
#   Descr      : Get process ID byte index
#
##########################################################################*/
#pragma aux GetProcessID "*" rdosdev parm routine [eax] value [eax]
int GetProcessID(int Index)
{
    int ID = 0;

    RdosEnterKernelSection(&ThreadSection);

    if (Index >= 0 && Index < ActiveProcesses)
        if (ProcessArr[Index].Valid)
            ID = ProcessArr[Index].ID;

    RdosLeaveKernelSection(&ThreadSection);    

    if (ID)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return ID;
}

    
/*##########################################################################
#
#   Name       : GetActiveModules
#
##########################################################################*/
#pragma aux GetActiveModules "*" rdosdev parm routine
int GetActiveModules()
{
    return ActiveModules;
}
        
/*##########################################################################
#
#   Name       : ModuleLoaded
#
##########################################################################*/
#pragma aux ModuleLoaded "*" rdosdev parm routine [ebx] value [eax]
int ModuleLoaded(int sel)
{
    int i;
    int ok = FALSE;
    int Index;
    int mid;

    RdosEnterKernelSection(&ThreadSection);    

    ok = FALSE;

    while (!ok)
    {
        mid = NextMid;

        if (NextMid == 0x7FFF)
            NextMid = 1;
        else
            NextMid++;

        ok = TRUE;

        for (i = 0; i < ActiveModules; i++)
        {
            if (ModuleArr[i].Valid && ModuleArr[i].ID == mid) 
            {
                ok = FALSE;
                break;
            }
        }
    }

    ok = FALSE;

    for (i = 0; i < ActiveModules; i++)
    {
        if (!ModuleArr[i].Valid)
        {
            ok = TRUE;
            Index = i;
            break;
        }
    }

    if (!ok)
    {
        if (ActiveModules < MAX_MODULES)
        {
            Index = ActiveModules;
            ActiveModules++;
            ok = TRUE;
        }
    }

    if (ok)
    {
        ModuleArr[Index].Valid = TRUE;
        ModuleArr[Index].Sel = sel;
        ModuleArr[Index].ID = mid;
    }
    
    RdosLeaveKernelSection(&ThreadSection);

    return mid;
}
    
/*##########################################################################
#
#   Name       : ModuleUnloaded
#
##########################################################################*/
#pragma aux ModuleUnloaded "*" rdosdev parm routine [eax]
void ModuleUnloaded(int sel)
{
    int i;

    RdosEnterKernelSection(&ThreadSection);    

    for (i = 0; i < ActiveModules; i++)
    {
        if (ModuleArr[i].Valid && ModuleArr[i].Sel == sel) 
        {
            ModuleArr[i].Valid = FALSE;

            if (i == ActiveModules - 1)
                ActiveModules--;

            break;
        }
    }

    RdosLeaveKernelSection(&ThreadSection);    
}
    
/*##########################################################################
#
#   Name       : GetModuleSel
#
#   Descr      : Convert from module ID to selector
#
##########################################################################*/
#pragma aux GetModuleSel "*" rdosdev parm routine [ebx] value [eax]
int GetModuleSel(int ID)
{
    int i;
    int sel = 0;

    RdosEnterKernelSection(&ThreadSection);    

    for (i = 0; i < ActiveModules; i++)
    {
        if (ModuleArr[i].Valid && ModuleArr[i].ID == ID) 
        {
            sel = ModuleArr[i].Sel;
            break;
        }
    }

    RdosLeaveKernelSection(&ThreadSection);    

    if (sel)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return sel;
}
    
/*##########################################################################
#
#   Name       : GetModuleID
#
#   Descr      : Get module ID byte index
#
##########################################################################*/
#pragma aux GetModuleID "*" rdosdev parm routine [eax] value [eax]
int GetModuleID(int Index)
{
    int ID = 0;

    RdosEnterKernelSection(&ThreadSection);

    if (Index >= 0 && Index < ActiveModules)
        if (ModuleArr[Index].Valid)
            ID = ModuleArr[Index].ID;

    RdosLeaveKernelSection(&ThreadSection);    

    if (ID)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return ID;
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
    }

    for (;;)
    {
        RdosWaitMilli(250);

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
        
        for (Core = 0; Core < ActiveProcessors; Core++)
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
                Tics = GetThreadTics(ThreadArr[i].Handle);
                Diff = (int)(Tics - ThreadArr[i].BaseTics);
                ThreadArr[i].BaseTics = Tics;
                ThreadArr[i].IntCount = GetThreadIntCount(ThreadArr[i].Handle);

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

                if (Load)
                {
                    ThreadStatArr[StatCount].ID = ThreadArr[i].ID;
                    ThreadStatArr[StatCount].Core = ThreadArr[i].Core;
                    ThreadStatArr[StatCount].IntCount = ThreadArr[i].IntCount;
                    ThreadStatArr[StatCount].Load = Load;
                    StatCount++;

                    ThreadArr[i].IdleCount = 0;
                }
                else
                    ThreadArr[i].IdleCount++;
            }
        } 

        RdosLeaveKernelSection(&ThreadSection); 

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
        
            for (Core = 0; Core < ActiveProcessors; Core++)
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

            OptLoad = (HighestLoad - LowestLoad) / 2;

            if (OptLoad > 100)
            {
                BestLoad = 2000;

                for (i = 0; i < StatCount; i++)
                {
                    if (ThreadStatArr[i].Core == HighestCore && ThreadStatArr[i].IntCount == 0)
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
                    if (ThreadArr[i].Valid && ThreadArr[i].Core != 0 && ThreadArr[i].Prio && ThreadArr[i].IdleCount > 16)
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
        
    RdosInitKernelSection(&ThreadSection);
    RdosInitKernelSection(&CoreSection);
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

    RdosRegisterBimodalUserGate(usergate_get_active_cores, (__rdos_gate_callback *)&ImplGetActiveCores, "Get Active Cores");
    RdosRegisterBimodalUserGate(usergate_get_program_count, (__rdos_gate_callback *)&ImplGetProgramCount, "Get Program Count");
}
