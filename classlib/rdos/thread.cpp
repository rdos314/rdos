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
#include "sigdev.h"

#include <rdos.h>

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
static void ThreadStartup(void *ptr)
{
    ((TThread *)ptr)->Run();
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
  : FStopSection("Thread.Stop")
{
    FInstalled = true;
    FThreadRunning = false;
    FStopSignal = 0;
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
  : FStopSection("Thread.Stop")
{
    FInstalled = true;
    FThreadRunning = false;
    FStopSignal = 0;
    
    Start(ThreadName, StackSize);
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
TThread::TThread(const char *ThreadName, int StackSize, bool Run)
  : FStopSection("Thread.Stop")
{
    FInstalled = true;
    FThreadRunning = false;

    if (Run)
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
#   Name       : TThread::Terminated
#
#   Purpose....: Thread terminated
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TThread::Terminated()
{
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
    if (FThreadRunning)
    {
        TSignalDevice FSignal;

        FStopSection.Enter();

        FStopSignal = &FSignal;
        FInstalled = false;

        while (FThreadRunning)
        {
            FStopSection.Leave();
            FSignal.WaitForever();
            FStopSection.Enter();
        }

        FStopSignal = 0;

        FStopSection.Leave();
    }
}

/*##########################################################################
#
#   Name       : TThread::IsStopping
#
#   Purpose....: Is thread stopping?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TThread::IsStopping()
{
    return !FInstalled;
}

/*##########################################################################
#
#   Name       : TThread::IsRunning
#
#   Purpose....: Is thread running?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TThread::IsRunning()
{
    return FThreadRunning;
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
    RdosCreateThread(ThreadStartup, ThreadName, this, StackSize);
}

/*##########################################################################
#
#   Name       : TThread::Start
#
#   Purpose....: Start thread
#
#   In params..: ThreadName     name of thread
#                Prio           priority
#                StackSize      size of stack
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TThread::Start(const char *ThreadName, int Prio, int StackSize)
{
    RdosCreatePrioThread(ThreadStartup, Prio, ThreadName, this, StackSize);
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
    FInstalled = true;
    if (!FThreadRunning)
    {
        FThreadRunning = true;
        Execute();

        FStopSection.Enter();

        FThreadRunning = false;

        if (FStopSignal)
            FStopSignal->Signal();

        FStopSection.Leave();

        Terminated();
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
