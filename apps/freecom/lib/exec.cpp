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
# exec.cpp
# Execute external command class
#
########################################################################*/

#include <string.h>
#include <unistd.h>

#include "rdos.h"
#include "exec.h"
#include "cmdhelp.h"
#include "lang.h"
#include "env.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TExecCommand::TExecCommand
#
#   Purpose....: Constructor for TExecCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TExecCommand::TExecCommand(TSession *session, const char *name, const char *param, int detach)
  : TCommand(session, param)
{
    FDetach = detach;
    FProgName = name;
}

/*##########################################################################
#
#   Name       : TExecCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TExecCommand::Execute(char *param)
{
    TPathName StartupDir;
    int ThreadId;
    int Handle;
    int pid;
    int WaitHandle;
    char *arg[] = {0, param, 0};

    arg[0] = (char *)FProgName.GetData();

    if (FDetach)
    {
        Handle = RdosSpawn(FProgName.GetData(), param, StartupDir.Get().GetData(), 0, &ThreadId);
        if (Handle)
            return 0;
        else
            return -1;
     }
     else
     {
          pid = fork();
          if (pid == 0)
          {
              execv(arg[0], (char **)&arg);
              exit(-1);
          }

          WaitHandle = RdosCreateWait();
          RdosAddWaitForProcessEnd(WaitHandle, pid, 0);

          while (RdosIsProcessRunning(pid))
              RdosWaitForever(WaitHandle);

          RdosCloseWait(WaitHandle);
          return RdosGetProcessExitCode(pid);
     }
}

