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
# sysinfo.cpp
# Sysinfo command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "rdosimg.h"
#include "cmdhelp.h"
#include "lang.h"
#include "sysinfo.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TSysinfoFactory::TSysinfoFactory
#
#   Purpose....: Constructor for TSysinfoFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSysinfoFactory::TSysinfoFactory()
  : TCommandFactory("SYSINFO")
{
}

/*##########################################################################
#
#   Name       : TSysinfoFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TSysinfoFactory::Create(TSession *session, const char *param)
{
        return new TSysinfoCommand(session, param);
}

/*##########################################################################
#
#   Name       : TSysinfoCommand::TSysinfoCommand
#
#   Purpose....: Constructor for TSysinfoCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSysinfoCommand::TSysinfoCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_SYSINFO);
}

/*##########################################################################
#
#   Name       : TSysinfoCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSysinfoCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
    OptError(optstr);
    return E_Useage;
}

/*##########################################################################
#
#   Name       : TSysinfoCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSysinfoCommand::InitOptions()
{
}

/*##########################################################################
#
#   Name       : TSysinfoCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSysinfoCommand::Execute(char *param)
{
    TArg *arg;
    TRdosImage img;
    TRdosObject *obj;
    TString info;

    InitOptions();

    if (!ScanCmdLine(param, 0))
        return 1;

    arg = FArgList;

    if (arg)
        img.AddImage(arg->FName.GetData());
    else
        img.AddRunning();

    obj = img.FObjectList;

    while (obj)
    {
        info = obj->GetInfo();
        Write(info.GetData());
        Write("\r\n");

        obj = obj->FLink;            
    }

    return 0;
}
