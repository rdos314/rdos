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
# lon.cpp
# Lon command class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "lon.h"

#define FALSE 0
#define TRUE !FALSE

TString LonFileName = "z:\\lon.raw";
int LonHandle = 0;

/*##########################################################################
#
#   Name       : TLonFactory::TLonFactory
#
#   Purpose....: Constructor for TLonFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLonFactory::TLonFactory()
  : TCommandFactory("LON")
{
}

/*##########################################################################
#
#   Name       : TLonFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TLonFactory::Create(TSession *session, const char *param)
{
    return new TLonCommand(session, param);
}

/*##########################################################################
#
#   Name       : TLonCommand::TLonCommand
#
#   Purpose....: Constructor for TLonCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLonCommand::TLonCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_LON);
}

/*##########################################################################
#
#   Name       : TLonCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TLonCommand::Execute(char *param)
{
    TString Str;
    const char *str;
    const char *file;

    if (!ScanCmdLine(param, 0))
        return 1;

    if (FArgCount != 1)
    {
         FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
         Write(FMsg.GetData());
         return E_Useage;
    }

    Str = FArgList->FName;
    Str.Lower();
    str = Str.GetData();

    if (!strcmp(str, "off"))
    {
        RdosStopLonCapture();

        if (LonHandle)
        {
            RdosCloseFile(LonHandle);
            LonHandle = 0;
        }

        FMsg.Load(TEXT_LON_OFF);
        Write(FMsg.GetData());
        return 0;
    }

    if (strcmp(str, "on"))
        LonFileName = FArgList->FName;

    if (LonHandle)
    {
        RdosStopLonCapture();
        RdosCloseFile(LonHandle);
        LonHandle = 0;
    }

    file = LonFileName.GetData();
    LonHandle = RdosOpenFile(file, 0);
    if (!LonHandle)
        LonHandle = RdosCreateFile(file, 0);

    if (LonHandle)
    {
        RdosStartLonCapture(LonHandle);
        FMsg.printf(TEXT_LON_ON, file);
        Write(FMsg.GetData());
        return 0;
    }
    else
    {
         FMsg.Load(TEXT_ERROR_FILE_NOT_FOUND);
         Write(FMsg.GetData());
         return E_Useage;
    }
}
