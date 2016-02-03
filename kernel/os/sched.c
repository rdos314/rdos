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
};

struct TKernelSection ThreadSection;
struct TKernelSection CoreSection;

int ActiveProcessors = 1;
int ProcessorCount = 0;

long long CoreTicsArr[MAX_PROCESSOR_COUNT];
long long NullTicsArr[MAX_PROCESSOR_COUNT];

int MaxCpuLoad;
int MinCpuLoad;

struct TThread ThreadArr[MAX_THREADS];

extern void InitScheduler();

extern void SetThreadCore(int Core, int ThreadHandle);
#pragma aux SetThreadCore parm routine [edx eax]

#pragma aux ImplTestGate "*" rdosdev parm routine [es edi]

void __far ImplTestGate(const char *msg)
{
    int val;

    val = RdosGetActiveCores();
    val++;
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
#pragma aux ThreadCreated "*" rdosdev parm routine [eax edx]
void ThreadCreated(int handle, int ID)
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
    long long CoreTics;
    long long NullTics;
    long long CoreDiff;
    long long NullDiff;
    int Updated;
    int Core;
    int CpuLoad;
    int MinLoadCore;
    int HighCount;
    int HighArr[MAX_PROCESSOR_COUNT];

    ProcessorCount = RdosGetCoreCount();

    RdosInitFreq();

    for (Core = 0; Core < ProcessorCount; Core++)
        RdosGetCoreLoad(Core, &NullTicsArr[Core], &CoreTicsArr[Core]);

    for (;;)
    {
        RdosWaitMilli(250);

        MinCpuLoad = 110;
        MaxCpuLoad = 0;
        MinLoadCore = 0;
        HighCount = 0;

        Updated = FALSE;

        for (Core = 0; Core < ProcessorCount; Core++)
        {
            RdosGetCoreLoad(Core, &NullTics, &CoreTics);
            CoreDiff = CoreTics - CoreTicsArr[Core];
            NullDiff = NullTics - NullTicsArr[Core];
            CoreTicsArr[Core] = CoreTics;
            NullTicsArr[Core] = NullTics;

            if (CoreDiff)
            {
                CpuLoad = 100 - (int)(100 * NullDiff / CoreDiff);

                if (CpuLoad == MaxCpuLoad)
                {
                    HighArr[HighCount] = Core;
                    HighCount++;
                }
                
                if (CpuLoad > MaxCpuLoad)
                {
                    MaxCpuLoad = CpuLoad;
                    HighArr[0] = Core;
                    HighCount = 1;
                }

                if (CpuLoad < MinCpuLoad)
                {
                    MinCpuLoad = CpuLoad;
                    MinLoadCore = Core;
                }
            }
        }

/*        SwitchOneIrq(MinLoadCore); */

        RdosEnterKernelSection(&CoreSection); 

        if (HighCount > 1)
            Core = HighArr[RdosGetRandom(HighCount)];
        else
            Core = HighArr[0];
            
/*        MoveOneTask(Core); */

        if (MaxCpuLoad > 60)
        {
            if (ActiveProcessors == ProcessorCount)
            {
                Updated = TRUE;
                RdosUpdateFreq(-1);
            }
            else
                StartCore();
        }

        if (MaxCpuLoad < 30)
        {
/*            if (PowerState == PowerStateCount - 1)
                StopCore();
            else         */
            {
                Updated = TRUE;
                RdosUpdateFreq(1);
            }
        }

        if (!Updated)
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
