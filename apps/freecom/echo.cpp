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
# echo.cpp
# Echo command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "echo.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TEchoFactory::TEchoFactory
#
#   Purpose....: Constructor for TEchoFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TEchoFactory::TEchoFactory()
  : TCommandFactory("ECHO")
{
}

/*##########################################################################
#
#   Name       : TEchoFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TEchoFactory::Create(TSession *session, const char *param)
{
	return new TEchoCommand(session, param);
}

/*##########################################################################
#
#   Name       : TEchoCommand::TEchoCommand
#
#   Purpose....: Constructor for TEchoCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TEchoCommand::TEchoCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_ECHO);
}

/*##########################################################################
#
#   Name       : TEchoCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TEchoCommand::Execute(char *param)
{
    TString str;

    str = param;
    str.Upper();
    
    if (*param)
    {
        if (!strcmp(str.GetData(), "ON"))
        {
            FSession->SetEchoOn();
            return 0;
        }

        if (!strcmp(str.GetData(), "OFF"))
        {
            FSession->SetEchoOff();
            return 0;
        }

        Write(param);
        Write("\r\n");
        return 0;
    }
    else
    {
        if (FSession->IsEchoOn())
            FMsg.printf(TEXT_MSG_ECHO_STATE, "ON");
        else
            FMsg.printf(TEXT_MSG_ECHO_STATE, "OFF");
    	Write(FMsg.GetData());
        return 0;    
    }
}
