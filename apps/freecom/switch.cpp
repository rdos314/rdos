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
# switch.cpp
# Switch console command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "switch.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TSwitchFactory::TSwitchFactory
#
#   Purpose....: Constructor for TSwitchFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSwitchFactory::TSwitchFactory()
  : TCommandFactory("SWITCH")
{
}

/*##########################################################################
#
#   Name       : TSwitchFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TSwitchFactory::Create(TSession *session, const char *param)
{
    return new TSwitchCommand(session, param);
}

/*##########################################################################
#
#   Name       : TSwitchCommand::TSwitchCommand
#
#   Purpose....: Constructor for TSwitchCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSwitchCommand::TSwitchCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_SWITCH);
}

/*##########################################################################
#
#   Name       : TSwitchCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSwitchCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
    OptError(optstr);
    return E_Useage;
}

/*##########################################################################
#
#   Name       : TSwitchCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSwitchCommand::InitOptions()
{
}

/*##########################################################################
#
#   Name       : TSwitchCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSwitchCommand::Execute(char *param)
{
    TArg *arg;
    int val;

    InitOptions();

    if (!ScanCmdLine(param, 0))
        return 1;

    arg = FArgList;

    if (arg)
    {
        val = 0x3A + atoi(arg->FName.GetData());
        RdosSetFocus((char)val);
    }

    return 0;
}
