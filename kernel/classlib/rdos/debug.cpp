/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2009, Leif Ekblad
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
# debug.cpp
# Debug class
#
########################################################################*/

#include <string.h>
#include "rdos.h"
#include "debug.h"

#define FALSE	0
#define TRUE	!FALSE

#define EVENT_EXCEPTION         1
#define EVENT_CREATE_THREAD     2
#define EVENT_CREATE_PROCESS    3
#define EVENT_TERMINATE_THREAD  4
#define EVENT_TERMINATE_PROCESS 5
#define EVENT_LOAD_DLL          6

/*##########################################################################
#
#   Name       : TDebug::TDebug
#
#   Purpose....: Debugger constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebug::TDebug(const char *Program, const char *Param, const char *StartDir)
 : FProgram(Program),
	FParam(Param),
	FStartDir(StartDir)
{
    Start("Debug device", 0x4000);
}

/*##########################################################################
#
#   Name       : TDebug::~TDebug
#
#   Purpose....: Debugger destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebug::~TDebug()
{
}

/*##########################################################################
#
#   Name       : TDebug::DeviceName
#
#   Purpose....: Returns device-name
#
#   In params..: MaxLen max size of name
#   Out params.: Name   device name
#   Returns....: *
#
##########################################################################*/
void TDebug::DeviceName(char *Name, int MaxLen) const
{
	strncpy(Name,"Debug device",MaxLen);
}

/*##########################################################################
#
#   Name       : TDebug::Add
#
#   Purpose....: Add object to wait
#
#   In params..: wait
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::Add(TWait *Wait)
{
    if (FHandle)
        RdosAddWaitForDebugEvent(Wait->GetHandle(), FHandle, this);
}

/*##########################################################################
#
#   Name       : TDebug::HandleCreateProcess
#
#   Purpose....: Handle create process event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::HandleCreateProcess(TCreateProcessEvent *event)
{
}

/*##########################################################################
#
#   Name       : TDebug::HandleTerminateProcess
#
#   Purpose....: Handle terminate process event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::HandleTerminateProcess(int exitcode)
{
}

/*##########################################################################
#
#   Name       : TDebug::HandleCreateThread
#
#   Purpose....: Handle create thread event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::HandleCreateThread(TCreateThreadEvent *event)
{
}

/*##########################################################################
#
#   Name       : TDebug::HandleTerminateThread
#
#   Purpose....: Handle terminate thread event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::HandleTerminateThread(int thread)
{
}

/*##########################################################################
#
#   Name       : TDebug::HandleException
#
#   Purpose....: Handle exception event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::HandleException(TExceptionEvent *event, int thread)
{
}

/*##########################################################################
#
#   Name       : TDebug::HandleLoadDll
#
#   Purpose....: Handle load DLL event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::HandleLoadDll(TLoadDllEvent *event)
{
}

/*##########################################################################
#
#   Name       : TDebug::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::SignalNewData()
{
	 short int thread;
    char debtype;
    TCreateProcessEvent cpe;
    TCreateThreadEvent cte;
    TLoadDllEvent lde;
    TExceptionEvent ee;
    int ExitCode;

	 debtype = RdosGetDebugEvent(FHandle, &thread);

	 switch (debtype)
	 {
		case EVENT_EXCEPTION:
			RdosGetDebugEventData(FHandle, &ee);
			HandleException(&ee, thread);
			break;

		case EVENT_CREATE_THREAD:
			RdosGetDebugEventData(FHandle, &cte);
			HandleCreateThread(&cte);
			break;

		case EVENT_CREATE_PROCESS:
			RdosGetDebugEventData(FHandle, &cpe);
			HandleCreateProcess(&cpe);
			break;

		case EVENT_TERMINATE_THREAD:
			HandleTerminateThread(thread);
			break;

		case EVENT_TERMINATE_PROCESS:
			RdosGetDebugEventData(FHandle, &ExitCode);
			HandleTerminateProcess(ExitCode);
			FInstalled = FALSE;
			break;

		case EVENT_LOAD_DLL:
			RdosGetDebugEventData(FHandle, &lde);
			HandleLoadDll(&lde);
			break;
	 }

	 RdosClearDebugEvent(FHandle);

	 if (debtype != EVENT_EXCEPTION)
		  RdosContinueDebugEvent(FHandle, thread);
}

/*##########################################################################
#
#   Name       : TDebug::Execute
#
#   Purpose....: Execute debugger
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDebug::Execute()
{
	short int thread;

	RdosWaitMilli(250);

	FHandle = RdosSpawnDebug(FProgram.GetData(), FParam.GetData(), FStartDir.GetData(), &thread);

    if (!FHandle)
        FInstalled = FALSE;
        
    while (FInstalled)
        FWait->WaitForever();
}
