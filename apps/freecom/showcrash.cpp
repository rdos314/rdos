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
    char str[81];

    sprintf(str, "Core=%d\r\n", core);
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

    sprintf(str, "EBP=%08lX ", (int)info->Rbp);    
    Write(str);

    sprintf(str, "EFL=%08lX\r\n", (int)info->Rflags);        
    Write(str);

    WriteSelector("CS", &info->Cs);
    WriteSelector("DS", &info->Ds);
    WriteSelector("ES", &info->Es);
    WriteSelector("FS", &info->Fs);
    WriteSelector("GS", &info->Gs);
    WriteSelector("SS", &info->Ss);

    Write("\r\n");
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

    for (core = 0; core < MAX_CRASH_INFO_CORES; core++)
        if (info.CrashInfo[core])
            WriteCore(core, info.CrashInfo[core]);

    return 0;
}
