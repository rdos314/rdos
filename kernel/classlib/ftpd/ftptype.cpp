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
# type.cpp
# Type command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "type.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TTypeFactory::TTypeFactory
#
#   Purpose....: Constructor for TTypeFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTypeFactory::TTypeFactory()
  : TCommandFactory("TYPE")
{
}

/*##########################################################################
#
#   Name       : TTypeFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TTypeFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TTypeCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TTypeCommand::TTypeCommand
#
#   Purpose....: Constructor for TTypeCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTypeCommand::TTypeCommand(TFtpSocketServer *Server, const char *param)
  : TCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TTypeCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTypeCommand::Execute(char *param)
{
	TArg *arg;
	int ArgCount;
	TLangString msg;
	int ok;

	ok = ScanCmdLine(param, 0);
	if (ok)
	{
		ArgCount = 0;
		arg = FArgList;
		while (arg)
		{
			ArgCount++;
			arg = arg->FList;
		}

		ok = (FArgCount == 1);
	}

	if (ok)
    	msg.Load(200);
	else
		msg.Load(501);

    FServer->Reply(&msg);    
}
