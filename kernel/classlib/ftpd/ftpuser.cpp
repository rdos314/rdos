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
# path.cpp
# Path command class
#
########################################################################*/

#include <string.h>

#include "ftpserv.h"
#include "ftpuser.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TUserFactory::TUserFactory
#
#   Purpose....: Constructor for TUserFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUserFactory::TUserFactory()
  : TCommandFactory("USER")
{
}

/*##########################################################################
#
#   Name       : TUserFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TUserFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TUserCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TUserCommand::TUserCommand
#
#   Purpose....: Constructor for TUserCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUserCommand::TUserCommand(TFtpSocketServer *Server, const char *param)
  : TCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TUserCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUserCommand::Execute(char *param)
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
	{
		FServer->User = FArgList->FName;
		msg.Load(331);
	}
	else
		msg.Load(501);

    FServer->Reply(&msg);    
}
