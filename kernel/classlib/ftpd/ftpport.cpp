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

#include <stdio.h>
#include <string.h>

#include "ftpserv.h"
#include "ftpport.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TPortFactory::TPortFactory
#
#   Purpose....: Constructor for TPortFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPortFactory::TPortFactory()
  : TCommandFactory("PORT")
{
}

/*##########################################################################
#
#   Name       : TPortFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TPortFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TPortCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TPortCommand::TPortCommand
#
#   Purpose....: Constructor for TPortCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPortCommand::TPortCommand(TFtpSocketServer *Server, const char *param)
  : TCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TPortCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPortCommand::Execute(char *param)
{
	TArg *arg;
	int ArgCount;
	TLangString msg;
	int ok;
	long IP;
	int port;
	int i;
	int val;
	const char *ptr;

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

		ok = (FArgCount == 6);
	}

	if (ok)
	{
    	if (FServer->VerifyUser())
		{
			arg = FArgList;
			IP = 0;
			for (i = 0; i < 4 && ok; i++)
			{
				ptr = arg->FName.GetData();
				if (sscanf(ptr, "%d", &val) == 1)
				{
					IP = (IP << 8) | val;
					arg = arg->FList;
				}
				else
					ok = FALSE;
			}
			IP = RdosSwapLong(IP);

			port = 0;
			for (i = 0; i < 2 && ok; i++)
			{
				ptr = arg->FName.GetData();
				if (sscanf(ptr, "%d", &val) == 1)
				{
					port = (port << 8) | val;
					arg = arg->FList;
				}
				else
					ok = FALSE;
			}

			if (ok)
			{
				if (FServer->OpenDataConnection(IP, port))
					msg.Load(225);
				else
					msg.Load(426);
			}
			else
				msg.Load(501);
		}
		else
			msg.Load(530);
	}
	else
		msg.Load(501);

    FServer->Reply(&msg);    
}

