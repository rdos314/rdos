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

#define MAX_THREADS             256
#define MAX_PROCESSOR_COUNT     32

#define FALSE 0
#define TRUE !FALSE

struct TThread
{
    int Valid;
    int Handle;
    int ID;
    int Core;
    int Prio;
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

#pragma aux ImplTestGate "*" rdosdev parm routine [es edi]

void __far ImplTestGate(const char *msg)
{
    int handle = ThreadArr[0].Handle;
    long long Tics;
    
    Tics = GetThreadTics(handle);
    Tics++;
}
    
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
#   Name       : ThreadCreated
#
##########################################################################*/
#pragma aux ThreadCreated "*" rdosdev parm routine [eax edx ecx]
void ThreadCreated(int handle, int ID, int Prio)
{
    int i;

    RdosEnterKernelSection(&ThreadSection);    

    for (i = 0; i < MAX_THREADS; i++)
    {
        if (!ThreadArr[i].Valid)
        {
            ThreadArr[i].Valid = TRUE;
            ThreadArr[i].Handle = handle;
            ThreadArr[i].ID = ID;
            ThreadArr[i].Core = 0;
            ThreadArr[i].Prio = Prio;
            ThreadArr[i].BaseTics = 0;
            break;
        }
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

    for (i = 0; i < MAX_THREADS; i++)
    {
        if (ThreadArr[i].Valid && ThreadArr[i].Handle == handle) 
        {
            ThreadArr[i].Valid = FALSE;
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

    for (i = 0; i < MAX_THREADS; i++)
    {
        if (ThreadArr[i].Valid && ThreadArr[i].ID == ID) 
        {
            handle = ThreadArr[i].Handle;
            break;
        }
    }

    RdosLeaveKernelSection(&ThreadSection);    

    return handle;
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

        for (i = 0; i < MAX_THREADS; i++)
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

        for (i = 0; i < MAX_THREADS; i++)
        {
            if (ThreadArr[i].Valid)
            {
                Tics = GetThreadTics(ThreadArr[i].Handle);
                Diff = (int)(Tics - ThreadArr[i].BaseTics);
                ThreadArr[i].BaseTics = Tics;

                Core = ThreadArr[i].Core;

                Load = 0;
                
                if (Core < ProcessorCount)
                {
                    CoreStatArr[Core].ThreadCount++;        

                    if (ThreadArr[i].Prio)
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
                    ThreadStatArr[StatCount].Load = Load;
                    StatCount++;
                }
            }
        } 

        RdosLeaveKernelSection(&ThreadSection); 

        RdosEnterKernelSection(&CoreSection); 

        RdosUpdateFreq(0);

        RdosLeaveKernelSection(&CoreSection); 
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
    InitScheduler();
    InitThreadList();
    RdosHookInitTasking(&InitTasking);

    RdosRegisterBimodalUserGate(usergate_get_active_cores, (__rdos_gate_callback *)&ImplGetActiveCores, "Get Active Cores");

    RdosRegisterBimodalUserGate(usergate_test_gate, (__rdos_gate_callback *)&ImplTestGate, "Test Gate"); 
}
