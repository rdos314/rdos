/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# thread.cpp
# Basic thread class
#
########################################################################*/

#include "thread.h"

#include <windows.h>

/*##########################################################################
#
#   Name       : ThreadStartup
#
#   Purpose....: Startup procedure for thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
DWORD WINAPI ThreadStartup(void *ptr)
{
    ((TThread *)ptr)->Run();
    return 0;
}

/*##########################################################################
#
#   Name       : TThread::TThread
#
#   Purpose....: Constructor for TThread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TThread::TThread()
{
        FInstalled = TRUE;
        FThreadRunning = FALSE;
}

/*##########################################################################
#
#   Name       : TThread::TThread
#
#   Purpose....: Constructor for TThread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TThread::TThread(const char *ThreadName, int StackSize)
{
        FInstalled = TRUE;
        FThreadRunning = FALSE;

        Start(ThreadName, StackSize);
}

/*##########################################################################
#
#   Name       : TThread::~TThread
#
#   Purpose....: Destructor for TThread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TThread::~TThread()
{
        Stop();
}

/*##########################################################################
#
#   Name       : TThread::Stop
#
#   Purpose....: Stop thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TThread::Stop()
{
        FInstalled = FALSE;
        while (FThreadRunning)
                ;
}

/*##########################################################################
#
#   Name       : TThread::Start
#
#   Purpose....: Start thread
#
#   In params..: ThreadName     name of thread
#                StackSize      size of stack
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TThread::Start(const char *ThreadName, int StackSize)
{
        unsigned long ThreadId;

        CreateThread(NULL, StackSize, ThreadStartup, this, 0, &ThreadId);
}

/*##########################################################################
#
#   Name       : TThread::Run
#
#   Purpose....: Run thread (from internal callback)
#
#   In params..: *
#                *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TThread::Run()
{
    FInstalled = TRUE;
        if (!FThreadRunning)
        {
                FThreadRunning = TRUE;
                Execute();
                FThreadRunning = FALSE;
        }
}

/*##########################################################################
#
#   Name       : TThread::Execute
#
#   Purpose....: Default execute method
#
#   In params..: *
#                *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TThread::Execute()
{
}

