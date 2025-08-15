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
# exec.c
# Exec module
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

    RdosRegisterBimodalUserGate(usergate_get_module_count, (__rdos_gate_callback *)&ImplGetModuleCount, "Get Module Count");
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
    return 0;
}
