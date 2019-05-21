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
