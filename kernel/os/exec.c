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

#define MAX_MODULES             256
#define MAX_PROCESSES           100
#define MAX_PROCESS_WAITS        10
#define MAX_EXIT_CODES          256

#define FALSE 0
#define TRUE !FALSE

struct TModule
{
    int Valid;
    int ID;
    int Sel;
};

struct TProcess
{
    int Valid;
    int ID;
    int Sel;
    int WaitArr[MAX_PROCESS_WAITS];
};

struct TExit
{
    int ID;
    int ExitCode;
};

struct TKernelSection ModuleSection;
struct TKernelSection ProcessSection;

int ActiveModules = 0;
int NextMid = 1;

int ActiveProcesses = 0;
int NextPid = 1;

int CurrExitInd = 0;

struct TModule ModuleArr[MAX_MODULES];
struct TProcess ProcessArr[MAX_PROCESSES];
struct TExit ExitArr[MAX_EXIT_CODES];

extern void InitExec();
extern void InitTimer();

/*##########################################################################
#
#   Name       : GetModuleCount
#
##########################################################################*/
#pragma aux ImplGetModuleCount "*" rdosdev parm routine
int __far ImplGetModuleCount()
{
    RdosSetSuccess();
    return ActiveModules;
}

/*##########################################################################
#
#   Name       : ModuleLoaded
#
##########################################################################*/
#pragma aux ImplModuleLoaded "*" rdosdev parm routine [ebx] value [eax]
int __far ImplModuleLoaded(int sel)
{
    int i;
    int ok = FALSE;
    int Index;
    int mid;

    RdosEnterKernelSection(&ModuleSection);

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

    RdosLeaveKernelSection(&ModuleSection);

    if (mid)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return mid;
}

/*##########################################################################
#
#   Name       : ModuleUnloaded
#
##########################################################################*/
#pragma aux ImplModuleUnloaded "*" rdosdev parm routine [ebx]
void __far ImplModuleUnloaded(int sel)
{
    int i;

    RdosEnterKernelSection(&ModuleSection);

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

    RdosLeaveKernelSection(&ModuleSection);
    RdosSetSuccess();
}

/*##########################################################################
#
#   Name       : ModuleIdToSel
#
#   Descr      : Convert from module ID to selector
#
##########################################################################*/
#pragma aux ImplModuleIdToSel "*" rdosdev parm routine [ebx] value [ebx]
int __far ImplModuleIdToSel(int ID)
{
    int i;
    int sel = 0;

    RdosEnterKernelSection(&ModuleSection);

    for (i = 0; i < ActiveModules; i++)
    {
        if (ModuleArr[i].Valid && ModuleArr[i].ID == ID)
        {
            sel = ModuleArr[i].Sel;
            break;
        }
    }

    RdosLeaveKernelSection(&ModuleSection);

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
#pragma aux ImplGetModuleId "*" rdosdev parm routine [eax] value [eax]
int __far ImplGetModuleId(int Index)
{
    int ID = 0;

    RdosEnterKernelSection(&ModuleSection);

    if (Index >= 0 && Index < ActiveModules)
        if (ModuleArr[Index].Valid)
            ID = ModuleArr[Index].ID;

    RdosLeaveKernelSection(&ModuleSection);

    if (ID)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return ID;
}


/*##########################################################################
#
#   Name       : GetProcessCount
#
##########################################################################*/
#pragma aux ImplGetProcessCount "*" rdosdev parm routine
int __far ImplGetProcessCount()
{
    RdosSetSuccess();
    return ActiveProcesses;
}

/*##########################################################################
#
#   Name       : ProcessCreated
#
##########################################################################*/
#pragma aux ImplProcessCreated "*" rdosdev parm routine [ebx] value [eax]
int __far ImplProcessCreated(int sel)
{
    int i;
    int j;
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

        for (j = 0; j < MAX_PROCESS_WAITS; j++)
            ProcessArr[Index].WaitArr[j] = 0;
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
#   Name       : ProcessTerminated
#
##########################################################################*/
#pragma aux ImplProcessTerminated "*" rdosdev parm routine [ebx] [eax]
void __far ImplProcessTerminated(int sel, int exit)
{
    int i;
    int j;

    RdosEnterKernelSection(&ProcessSection);

    for (i = 0; i < ActiveProcesses; i++)
    {
        if (ProcessArr[i].Valid && ProcessArr[i].Sel == sel)
        {
            ProcessArr[i].Valid = FALSE;

            ExitArr[CurrExitInd].ID = ProcessArr[i].ID;
            ExitArr[CurrExitInd].ExitCode = exit;

            CurrExitInd++;
            if (CurrExitInd == MAX_EXIT_CODES)
                CurrExitInd = 0;

            for (j = 0; j < MAX_PROCESS_WAITS; j++)
                if (ProcessArr[i].WaitArr[j])
                    RdosSignalWait(ProcessArr[i].WaitArr[j]);

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
#   Name       : ProcessIdToSel
#
#   Descr      : Convert from process ID to selector
#
##########################################################################*/
#pragma aux ImplProcessIdToSel "*" rdosdev parm routine [ebx] value [ebx]
int __far ImplProcessIdToSel(int ID)
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
#   Name       : GetProcessID
#
#   Descr      : Get process ID byte index
#
##########################################################################*/
#pragma aux ImplGetProcessId "*" rdosdev parm routine [eax] value [eax]
int __far ImplGetProcessId(int Index)
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
#   Name       : StartWaitProcess
#
#   Descr      : Start wait for process exit
#
##########################################################################*/
#pragma aux StartWaitProcess "*" rdosdev parm routine [eax] [ebx]
int StartWaitProcess(int WaitObj, int ID)
{
    int i;
    int j;
    int ok = FALSE;

    RdosEnterKernelSection(&ProcessSection);

    for (i = 0; i < ActiveProcesses; i++)
    {
        if (ProcessArr[i].Valid && ProcessArr[i].ID == ID)
        {
            for (j = 0; j < MAX_PROCESS_WAITS; j++)
            {
                if (ProcessArr[i].WaitArr[j] == 0)
                {
                    ProcessArr[i].WaitArr[j] = WaitObj;
                    ok = TRUE;
                    break;
                }
            }
            break;
        }
    }

    RdosLeaveKernelSection(&ProcessSection);

    if (ok)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return i;

}

/*##########################################################################
#
#   Name       : StopWaitProcess
#
#   Descr      : Start wait for process exit
#
##########################################################################*/
#pragma aux StopWaitProcess "*" rdosdev parm routine [eax] [ebx]
void StopWaitProcess(int WaitObj, int ID)
{
    int i;
    int j;

    RdosEnterKernelSection(&ProcessSection);

    for (i = 0; i < ActiveProcesses; i++)
    {
        if (ProcessArr[i].Valid && ProcessArr[i].ID == ID)
        {
            for (j = 0; j < MAX_PROCESS_WAITS; j++)
            {
                if (ProcessArr[i].WaitArr[j] == WaitObj)
                {
                    ProcessArr[i].WaitArr[j] = 0;
                    break;
                }
            }
          
            break;
        }
    }

    RdosLeaveKernelSection(&ProcessSection);
}


/*##########################################################################
#
#   Name       : GetProcExit
#
#   Descr      : Get process exit code
#
##########################################################################*/
#pragma aux GetProcExit "*" rdosdev parm routine [ebx]
int GetProcExit(int ID)
{
    int i;
    int ok = FALSE;
    int code;

    RdosEnterKernelSection(&ProcessSection);

    for (i = CurrExitInd - 1; i >= 0 && !ok; i--)
    {
        if (ExitArr[i].ID == ID)
        {
            code = ExitArr[i].ExitCode;
            ok = TRUE;
        }
    }

    for (i = MAX_EXIT_CODES - 1; i >= CurrExitInd && !ok; i--)
    {
        if (ExitArr[i].ID == ID)
        {
            code = ExitArr[i].ExitCode;
            ok = TRUE;
        }
    }

    RdosLeaveKernelSection(&ProcessSection);

    return code;
}

/*##########################################################################
#
#   Name       : InitGates
#
#   Purpose....: Gate initialization
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InitGates()
{
    int i;

    for (i = 0; i < MAX_EXIT_CODES; i++)
        ExitArr[i].ID = 0;

    RdosRegisterOsGate(osgate_module_loaded, (__rdos_gate_callback *)&ImplModuleLoaded, "Module Loaded");
    RdosRegisterOsGate(osgate_module_unloaded, (__rdos_gate_callback *)&ImplModuleUnloaded, "Module Unloaded");
    RdosRegisterOsGate(osgate_module_id_to_sel, (__rdos_gate_callback *)&ImplModuleIdToSel, "Module ID to Selector");
    RdosRegisterOsGate(osgate_get_module_id, (__rdos_gate_callback *)&ImplGetModuleId, "Get Module ID");

    RdosRegisterOsGate(osgate_process_created, (__rdos_gate_callback *)&ImplProcessCreated, "Process Created");
    RdosRegisterOsGate(osgate_process_terminated, (__rdos_gate_callback *)&ImplProcessTerminated, "Process Terminated");
    RdosRegisterOsGate(osgate_process_id_to_sel, (__rdos_gate_callback *)&ImplProcessIdToSel, "Process ID to Selector");
    RdosRegisterOsGate(osgate_get_process_id, (__rdos_gate_callback *)&ImplGetProcessId, "Get Process ID");

    RdosRegisterBimodalUserGate(usergate_get_module_count, (__rdos_gate_callback *)&ImplGetModuleCount, "Get Module Count");
    RdosRegisterBimodalUserGate(usergate_get_process_count, (__rdos_gate_callback *)&ImplGetProcessCount, "Get Process Count");
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
    InitGates();
    RdosInitKernelSection(&ModuleSection);
    InitExec();
    InitTimer();
}
