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

