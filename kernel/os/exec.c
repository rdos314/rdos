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

#define MAX_EXIT_CODES          256

#define FALSE 0
#define TRUE !FALSE

struct TExit
{
    int ID;
    int ExitCode;
};

struct TKernelSection ModuleSection;

int CurrExitInd = 0;

struct TExit ExitArr[MAX_EXIT_CODES];

extern void InitExec();
extern void InitTimer();

/*##########################################################################
#
#   Name       : AddExitCode
#
##########################################################################*/
#pragma aux AddExitCode "*" rdosdev parm routine [ebx] [eax]
void AddExitCode(int id, int exit)
{
    RdosEnterKernelSection(&ModuleSection);

    ExitArr[CurrExitInd].ID = id;
    ExitArr[CurrExitInd].ExitCode = exit;

    CurrExitInd++;
    if (CurrExitInd == MAX_EXIT_CODES)
        CurrExitInd = 0;

    RdosLeaveKernelSection(&ModuleSection);
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

    RdosEnterKernelSection(&ModuleSection);

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

    RdosLeaveKernelSection(&ModuleSection);

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
