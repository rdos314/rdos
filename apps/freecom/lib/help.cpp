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
# help.cpp
# Help command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "help.h"
#include "cmdhelp.h"
#include "lang.h"

/*##########################################################################
#
#   Name       : THelpFactory::THelpFactory
#
#   Purpose....: Constructor for THelpFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THelpFactory::THelpFactory()
  : TCommandFactory("?")
{
}

/*##########################################################################
#
#   Name       : THelpFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *THelpFactory::Create(const char *param)
{
	return new THelpCommand(param);
}

/*##########################################################################
#
#   Name       : THelpCommand::THelpCommand
#
#   Purpose....: Constructor for THelpCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THelpCommand::THelpCommand(const char *param)
  : TCommand(param)
{
}

/*##########################################################################
#
#   Name       : THelpCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THelpCommand::Execute(char *param)
{
    TCommandFactory *cmd;
    int y = 0;
    char str[16];

	FMsg.Load(TEXT_MSG_SHOWCMD_INTERNAL_COMMANDS);
	Write(FMsg.GetData());

    cmd = TCommandFactory::FCmdList;

    while (cmd)
    {
        y++;
        if (y == 8)
        {
			Write(cmd->FName.GetData());
			y = 0;
		}
		else
		{
            sprintf(str, "%-10s", cmd->FName.GetData());
            Write(str);
        }
        cmd = cmd->FList;            
    }

    if (y != 0)
        Write("\r\n");

	return 0;
}
