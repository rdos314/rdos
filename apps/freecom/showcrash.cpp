/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# showcrash.cpp
# Show crash command class
#
########################################################################*/

#include <stdio.h>
#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "showcrash.h"
#include "crash.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TShowCrashFactory::TShowCrashFactory
#
#   Purpose....: Constructor for TShowCrashFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShowCrashFactory::TShowCrashFactory()
  : TCommandFactory("CRASH")
{
}

/*##########################################################################
#
#   Name       : TShowCrashFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TShowCrashFactory::Create(TSession *session, const char *param)
{
    return new TShowCrashCommand(session, param);
}

/*##########################################################################
#
#   Name       : TShowCrashCommand::TShowCrashCommand
#
#   Purpose....: Constructor for TShowCrashCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShowCrashCommand::TShowCrashCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_SHOWCRASH);
}

/*##########################################################################
#
#   Name       : TShowCrashCommand::WriteSel
#
#   Purpose....: Write a single selector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowCrashCommand::WriteSelector(const char *Name, TCrashSelectorInfo *info)
{
    char str[81];

    Write(Name);
    Write("=");

    sprintf(str,"%04hX", info->Selector);
    Write(str);

    if (info->Valid)
    {
        sprintf(str," %08lX (%08lX) ", info->Base, info->Limit);
        Write(str);

        Write(info->InfoText);
    }
    Write("\r\n");
}

/*##########################################################################
#
#   Name       : TShowCrashCommand::WriteDt
#
#   Purpose....: Write descriptor table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowCrashCommand::WriteDt(const char *Name, TCrashSelectorInfo *info)
{
    char str[81];

    Write(Name);
    Write("=");

    sprintf(str,"%08lX (%08lX) ", info->Base, info->Limit);
    Write(str);
    Write("\r\n");
}

/*##########################################################################
#
#   Name       : TShowCrashCommand::WriteFlags
#
#   Purpose....: Write flags
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowCrashCommand::WriteFlags(long long flags)
{
    int iopl = (((int)flags) >> 12) & 0x3;
    char str[10];

    if (flags & 0x1)
        Write("CY ");
    else
        Write("NC ");

    if (flags & 0x40)
        Write("ZR ");
    else
        Write("NZ ");

    if (flags & 0x200)
        Write("EI ");
    else
        Write("DI ");

    if (flags & 0x4000)
        Write("NT ");
     else
        Write("PR ");

    if (flags & 0x20000)
        Write("VM ");
    else
        Write("PM ");

    sprintf(str, "IOPL=%d\r\n", iopl);
    Write(str);
}

/*##########################################################################
#
#   Name       : TShowCrashCommand::WriteThread
#
#   Purpose....: Write thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowCrashCommand::WriteThread(TCrashThreadInfo *info)
{
    char str[81];

    sprintf(str,"%04hX ", info->Selector);
    Write(str);

    sprintf(str,"PRIO=%d ", info->Prio);
    Write(str);

    if (info->Core)
    {
        sprintf(str,"CORE=%04hX ", info->Core);
        Write(str);
    }

    if (info->WantedCore)
    {
        sprintf(str,"WCORE=%04hX ", info->WantedCore);
        Write(str);
    }

    Write(info->NameText);
    Write(" ");
    Write(info->StateText);
    Write("\r\n");
}

/*##########################################################################
#
#   Name       : TShowCrashCommand::WriteStack
#
#   Purpose....: Write stack
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowCrashCommand::WriteStack(char *data, int sel, int base, int size)
{
    int ads;
    char *ptr;
    char str[10];
    int i;
    short int sval;

    while (size >= 16)
    {
        ads = base + size - 16;
        ptr = data + size - 16;

        sprintf(str,"%04hX:%04hX ", sel, ads);
        Write(str);

        for (i = 0; i < 8; i++)
        {
            sval = *((short int *)(ptr + 2 * i));
            sprintf(str,"%04hX", sval);
            Write(str);

            if (i == 7)
                Write("\r\n");
            else
                Write(" ");
        }
        size -= 16;
    }

    if (size)
    {
        ads = base + size - 16;
        ptr = data + size - 16;

        sprintf(str,"%04hX:%04hX ", sel, ads);
        Write(str);

        size = size / 2;

       for (i = 0; i < 8 - size; i++)
            Write("     ");

        for (i = 8 - size; i < 8; i++)
        {
            sval = *((short int *)(ptr + 2 * i));
            sprintf(str,"%04hX", sval);
            Write(str);

            if (i == 7)
                Write("\r\n");
            else
                Write(" ");
        }
    }
}

/*##########################################################################
#
#   Name       : TShowCrashCommand::WriteCore
#
#   Purpose....: Write a single core
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowCrashCommand::WriteCore(int core, TCrashCoreInfo *info)
{
    int i;
    char str[81];

    sprintf(str, "Core=%d (%04hX)\r\n", core, info->Core);
    Write(str);

    sprintf(str, "CS:EIP=%04hX:%08lX\r\n", info->Cs.Selector, (int)info->Rip);
    Write(str);

    sprintf(str, "SS:ESP=%04hX:%08lX\r\n", info->Ss.Selector, (int)info->Rsp);
    Write(str);

    sprintf(str,"EAX=%08lX ", (int)info->Rax);
    Write(str);

    sprintf(str, "EBX=%08lX ", (int)info->Rbx);
    Write(str);

    sprintf(str, "ECX=%08lX ", (int)info->Rcx);
    Write(str);

    sprintf(str, "EDX=%08lX\r\n", (int)info->Rdx);
    Write(str);

    sprintf(str, "ESI=%08lX ", (int)info->Rsi);
    Write(str);

    sprintf(str, "EDI=%08lX ", (int)info->Rdi);
    Write(str);

    sprintf(str, "EBP=%08lX\r\n", (int)info->Rbp);
    Write(str);

    WriteFlags(info->Rflags);

    WriteSelector("CS", &info->Cs);
    WriteSelector("DS", &info->Ds);
    WriteSelector("ES", &info->Es);
    WriteSelector("FS", &info->Fs);
    WriteSelector("GS", &info->Gs);
    WriteSelector("SS", &info->Ss);
    WriteSelector("LDT", &info->Ldt);
    WriteDt("GDT", &info->Gdt);
    WriteDt("IDT", &info->Idt);

    sprintf(str, "CR0=%08lX ", info->Cr0);
    Write(str);

    sprintf(str, "CR2=%08lX ", info->Cr2);
    Write(str);

    sprintf(str, "CR3=%08lX ", info->Cr3);
    Write(str);

    sprintf(str, "CR4=%08lX\r\n", info->Cr4);
    Write(str);

    sprintf(str, "NEST=%d\r\n", (int)info->Nesting);
    Write(str);

    WriteSelector("TR", &info->Tr);

    for (i = 0; i < info->ThreadCount; i++)
        WriteThread(info->ThreadArr[i]);

    if (info->StackData)
        WriteStack(info->StackData, info->Ss.Selector, (int)info->Rsp, info->StackSize);

    Write("\r\n");
}

/*##########################################################################
#
#   Name       : TShowCrashCommand::WriteLog
#
#   Purpose....: Write log entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowCrashCommand::WriteLog(TCrashLogInfo *info)
{
    char str[81];

    sprintf(str, "%04d-%02d-%02d %02d.%02d.%02d,%03d %03d ",
                    info->Time.GetYear(),
                    info->Time.GetMonth(),
                    info->Time.GetDay(),
                    info->Time.GetHour(),
                    info->Time.GetMin(),
                    info->Time.GetSec(),
                    info->Time.GetMilliSec(),
                    info->Time.GetMicroSec());
    Write(str);

    sprintf(str, "CORE=%d ", info->Core);
    Write(str);

    sprintf(str, "TYPE=%d ", info->Type);
    Write(str);

    sprintf(str, "PROC=%04hX ", info->Proc);
    Write(str);

    sprintf(str, "DATA=%08hX\r\n", info->Data);
    Write(str);
}


/*##########################################################################
#
#   Name       : TShowCrashCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShowCrashCommand::Execute(char *param)
{
    int core;
    TCrashInfo info;
    int i;

    for (core = 0; core < MAX_CRASH_INFO_CORES; core++)
        if (info.CrashInfo[core])
            WriteCore(core, info.CrashInfo[core]);

    for (i = 0; i < info.LogCount; i++)
        WriteLog(info.LogArr[i]);

    Write("\r\n");

    return 0;
}
