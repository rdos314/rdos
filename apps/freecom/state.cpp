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
# state.cpp
# State command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "state.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TStateFactory::TStateFactory
#
#   Purpose....: Constructor for TStateFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStateFactory::TStateFactory()
  : TCommandFactory("STATE")
{
}

/*##########################################################################
#
#   Name       : TStateFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TStateFactory::Create(TSession *session, const char *param)
{
    return new TStateCommand(session, param);
}

/*##########################################################################
#
#   Name       : TStateCommand::TStateCommand
#
#   Purpose....: Constructor for TStateCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStateCommand::TStateCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_STATE);
}

/*##########################################################################
#
#   Name       : TStateCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStateCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
    switch(ch)
    {
        case 'T':
            return OptScanBool(optstr, bool, strarg, &FOptT);

        case 'M':
            return OptScanBool(optstr, bool, strarg, &FOptM);

        case 'S':
            return OptScanBool(optstr, bool, strarg, &FOptS);

        case 'F':
            return OptScanBool(optstr, bool, strarg, &FOptF);

        case 'U':
            return OptScanBool(optstr, bool, strarg, &FOptU);

    }
    OptError(optstr);
    return E_Useage;
}

/*##########################################################################
#
#   Name       : TStateCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::InitOptions()
{
    FOptT = FALSE;
    FOptM = FALSE;
    FOptS = FALSE;
    FOptF = FALSE;
    FOptU = FALSE;
}

/*##########################################################################
#
#   Name       : TStateCommand::WriteOne
#
#   Purpose....: Write one
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::WriteOne(struct RdosThreadActionState *State)
{
    char str[40];
    int len;
    int day;
    int hour;
    int min;
    int sec;
    int milli;
    int micro;
    int started;
    int i;

    sprintf(str, "%04hX ", State->ID);
    Write(str);

    memcpy(str, State->Name, 20);
    str[20] = 0;
    len = strlen(str);

    for (i = len; i < 20; i++)
        str[i] = ' ';

    Write(str);

    day = State->MsbTime / 24;
    hour = State->MsbTime % 24;
    RdosDecodeLsbTics(State->LsbTime, &min, &sec, &milli, &micro);

    started = FALSE;
    if (day)
    {
        sprintf(str, "%3d ", day);
        Write(str);
        started = TRUE;
    }
    else
        Write("    ");

    if (hour || started)
    {
        if (started)
            sprintf(str, "%02d.", hour);
        else
            sprintf(str, "%2d.", hour);
        Write(str);
        started = TRUE;
    }
    else
        Write("   ");

        if (min || started)
        {
            if (started)
                sprintf(str, "%02d.", min);
            else
                sprintf(str, "%2d.", min);
            Write(str);
            started = TRUE;
        }
        else
            Write("   ");

    if (sec || started)
    {
        if (started)
            sprintf(str, "%02d,", sec);
        else
            sprintf(str, "%2d,", sec);
        Write(str);
        started = TRUE;
    }
    else
        Write("   ");

    if (milli || started)
    {
        if (started)
            sprintf(str, "%03d ", milli);
        else
            sprintf(str, "%3d ", milli);
        Write(str);
        started = TRUE;
    }
    else
        Write("    ");

    if (started)
        sprintf(str, "%03d ", micro);
    else
        sprintf(str, "%3d ", micro);
    Write(str);

    if (State->Action[0])
    {
        for (len = 0; len < 20 && State->Action[len]; len++)
            str[len] = State->Action[len];

        str[len] = ' ';
        len++;

        str[len] = '(';
        len++;

        i = 0;
        while (len < 20 + 12 && State->List[i])
        {
            str[len] = State->List[i];
            len++;
            i++;
        }

        str[len] = ')';
        len++;

        for (i = len; i < 20 + 13; i++)
            str[i] = ' ';

        str[20+13] = 0;
        Write(str);
    }
    else
    {
        memcpy(str, State->List, 20);
        str[20] = 0;
        len = strlen(str);

        for (i = len; i < 20; i++)
            str[i] = ' ';

        Write(str);

        if (State->Pos.Sel)
        {
            sprintf(str, "%04hX:", State->Pos.Sel);
            Write(str);

            sprintf(str, "%08lX", State->Pos.Offset);
            Write(str);
        }
        else
            Write("             ");

        if (FOptU)
        {
            for (i = 0; i < State->UserCount; i++)
            {
                Write(" ");
                if (State->UserCall[i].Sel != 0x1B3 && State->UserCall[i].Sel != 0x2E3)
                {
                    sprintf(str, "%04hX:", State->UserCall[i].Sel);
                    Write(str);
                }

                sprintf(str, "%08lX", State->UserCall[i].Offset);
                Write(str);
            }
        }
    }

    Write("\r\n");
}

/*##########################################################################
#
#   Name       : TStateCommand::WriteThreads
#
#   Purpose....: Write threads
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::WriteThreads()
{
    int i;
    int ThreadCount = RdosGetThreadCount();
    struct RdosThreadActionState state;

    for (i = 0; i < ThreadCount; i++)
        if (RdosGetThreadActionState(i, &state))
            WriteOne(&state);
}

/*##########################################################################
#
#   Name       : TStateCommand::WriteOneModule
#
#   Purpose....: Write one module
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::WriteOneModule(int mid, const char *Name)
{
    char str[50];
    int iStart;
    int iSize;
    int iLow;
    int iHigh;
    int Sel = RdosGetModuleSel(mid);
    long long Start = RdosGetModuleBase(mid);
    long long Size = RdosGetModuleSize(mid);

    sprintf(str, "%04hX ", mid);
    Write(str);

    strncpy(str, Name, 45);
    str[42] = 0;
    while (strlen(str) < 41)
        strcat(str, " ");

    Write(str);

    if (Sel)
    {
        iStart = (int)Start;
        iSize = (int)Size;
        sprintf(str, "%04hX:%08lX (%08lX) ", Sel, iStart, iSize);
        Write(str);
    }
    else
    {
        iHigh = (int)(Start >> 32);
        iLow = (int)Start;
        sprintf(str, "%04hX_%08lX ", iHigh, iLow);
        Write(str);

        iHigh = (int)(Size >> 32);
        iLow = (int)Size;
        sprintf(str, "(%04hX_%08lX) ", iHigh, iLow);
        Write(str);
    }
    Write("\r\n");
}

/*##########################################################################
#
#   Name       : TStateCommand::WriteOneModule
#
#   Purpose....: Write one module
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::WriteOneModule(int pid, int mid, const char *Name)
{
    char str[50];
    int iStart;
    int iSize;
    int iLow;
    int iHigh;
    int Sel = RdosGetModuleSel(mid);
    long long Start = RdosGetModuleBase(mid);
    long long Size = RdosGetModuleSize(mid);
    int Usage = RdosGetProcessModuleUsage(pid, mid);

    sprintf(str, "%04hX %04hX ", mid, Usage);
    Write(str);

    strncpy(str, Name, 36);
    str[36] = 0;
    while (strlen(str) < 36)
        strcat(str, " ");

    Write(str);

    if (Sel)
    {
        iStart = (int)Start;
        iSize = (int)Size;
        sprintf(str, "%04hX:%08lX (%08lX) ", Sel, iStart, iSize);
        Write(str);
    }
    else
    {
        iHigh = (int)(Start >> 32);
        iLow = (int)Start;
        sprintf(str, "%04hX_%08lX ", iHigh, iLow);
        Write(str);

        iHigh = (int)(Size >> 32);
        iLow = (int)Size;
        sprintf(str, "(%04hX_%08lX) ", iHigh, iLow);
        Write(str);
    }
    Write("\r\n");
}

/*##########################################################################
#
#   Name       : TStateCommand::WriteModuleById
#
#   Purpose....: Write module by ID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::WriteModuleById(int mid)
{
    char buf[256];
    int ok = FALSE;
    int i;
    int id;
    int ModuleCount = RdosGetModuleCount();

    for (i = 0; i < ModuleCount && !ok; i++)
    {
        if (RdosGetModuleInfo(i, &id, buf, 256))
        {
            if (id == mid)
            {
                Write("  ");
                WriteOneModule(mid, buf);
                ok = TRUE;
            }
        }
    }

    if (!ok)
    {
        sprintf(buf, "  %04hX\r\n", mid);
        Write(buf);
    }
}

/*##########################################################################
#
#   Name       : TStateCommand::WriteModuleById
#
#   Purpose....: Write module by ID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::WriteModuleById(int pid, int mid)
{
    char buf[256];
    int ok = FALSE;
    int i;
    int id;
    int ModuleCount = RdosGetModuleCount();

    for (i = 0; i < ModuleCount && !ok; i++)
    {
        if (RdosGetModuleInfo(i, &id, buf, 256))
        {
            if (id == mid)
            {
                Write("  ");
                WriteOneModule(pid, mid, buf);
                ok = TRUE;
            }
        }
    }

    if (!ok)
    {
        sprintf(buf, "  %04hX\r\n", mid);
        Write(buf);
    }
}

/*##########################################################################
#
#   Name       : TStateCommand::WriteModules
#
#   Purpose....: Write modules
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::WriteModules()
{
    int i;
    int id;
    char buf[256];
    int ModuleCount = RdosGetModuleCount();

    for (i = 0; i < ModuleCount; i++)
        if (RdosGetModuleInfo(i, &id, buf, 256))
            WriteOneModule(id, buf);
}

/*##########################################################################
#
#   Name       : TStateCommand::WriteProgramModules
#
#   Purpose....: Write program modules
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::WriteProgramModules(int pid)
{
    int i;
    int ModuleCount = RdosGetProgramModules(pid, IdBuf, 256);

    for (i = 0; i < ModuleCount; i++)
        WriteModuleById(IdBuf[i]);
}

/*##########################################################################
#
#   Name       : TStateCommand::WriteOneProcess
#
#   Purpose....: Write one process
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::WriteOneProcess(int pid, const char *Name)
{
    int i;
    int ThreadCount;
    int ModuleCount;

    Write(Name);
    Write("\r\n");

    ModuleCount = RdosGetProcessModules(pid, TIdBuf, 256);

    for (i = 0; i < ModuleCount; i++)
        WriteModuleById(pid, TIdBuf[i]);

    ThreadCount = RdosGetProcessThreads(pid, TIdBuf, 256);

    for (i = 0; i < ThreadCount; i++)
        WriteThreadById(TIdBuf[i]);
}

/*##########################################################################
#
#   Name       : TStateCommand::WriteProcessById
#
#   Purpose....: Write process by ID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::WriteProcessById(int pid)
{
    char buf[256];
    int ok = FALSE;
    int i;
    int id;
    int ProcessCount = RdosGetProcessCount();

    for (i = 0; i < ProcessCount && !ok; i++)
    {
        if (RdosGetProcessInfo(i, &id, buf, 256))
        {
            if (id == pid)
            {
                Write(" Process: ");
                WriteOneProcess(pid, buf);
                ok = TRUE;
            }
        }
    }

    if (!ok)
    {
        sprintf(buf, " %04hX\r\n", pid);
        Write(buf);
    }
}

/*##########################################################################
#
#   Name       : TStateCommand::WriteProgramProcesses
#
#   Purpose....: Write program processes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::WriteProgramProcesses(int pid)
{
    int i;
    int ProcessCount = RdosGetProgramProcesses(pid, IdBuf, 256);

    for (i = 0; i < ProcessCount; i++)
        WriteProcessById(IdBuf[i]);
}

/*##########################################################################
#
#   Name       : TStateCommand::WriteThreadById
#
#   Purpose....: Write thread by ID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::WriteThreadById(int tid)
{
    char str[40];
    int ok = FALSE;
    int i;
    struct RdosThreadActionState state;
    int ThreadCount = RdosGetThreadCount();

    for (i = 0; i < ThreadCount && !ok; i++)
    {
        if (RdosGetThreadActionState(i, &state))
        {
            if (state.ID == tid)
            {
                Write("  ");
                WriteOne(&state);
                ok = TRUE;
            }
        }
    }

    if (!ok)
    {
        sprintf(str, "  %04hX\r\n", tid);
        Write(str);
    }
}

/*##########################################################################
#
#   Name       : TStateCommand::WritePrograms
#
#   Purpose....: Write threads
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::WritePrograms()
{
    char str[40];
    char NameBuf[100];
    int i;
    int ID;
    int ProgramCount = RdosGetProgramCount();

    for (i = 0; i < ProgramCount; i++)
    {
        if (RdosGetProgramInfo(i, &ID, NameBuf, 100))
        {
            sprintf(str, "%04hX ", ID);
            Write(str);
            Write(NameBuf);
            Write("\r\n");
//            if (i == 0)
                WriteProgramModules(i);
            WriteProgramProcesses(i);
            Write("\r\n");
        }
    }
}

/*##########################################################################
#
#   Name       : TStateCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStateCommand::Execute(char *param)
{
    int i;
    struct RdosThreadActionState state;
    short int ID;
    TArg *arg;

    InitOptions();

    if (LeadOptions(&param, 0) != E_None)
        return 1;

    if (!ScanCmdLine(param, 0))
        return 1;

    if (FArgCount == 0)
    {
        if (FOptT || FOptM)
        {
            if (FOptT)
                WriteThreads();

            if (FOptM)
                WriteModules();
        }
        else
            WritePrograms();

        return 0;
    }
    else
    {
         int ThreadCount = RdosGetThreadCount();

         arg = FArgList;

        while (arg)
        {
            if (sscanf(arg->FName.GetData(), "%4hX", &ID) == 1)
            {
                for (i = 0; i < ThreadCount; i++)
                {
                    if (RdosGetThreadActionState(i, &state))
                    {
                        if (state.ID == ID)
                        {
                            if (FOptF)
                            {
                                RdosSuspendAndSignalThread(ID);
                                RdosWaitMilli(50);
                            }
                            else
                            {
                                if (FOptS)
                                {
                                    RdosSuspendThread(ID);
                                    RdosWaitMilli(50);
                                }
                            }
                            WriteOne(&state);
                        }
                    }
                }
            }
            arg = arg->FList;
        }
        return 0;
    }
}

