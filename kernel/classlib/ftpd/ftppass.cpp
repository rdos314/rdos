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
# ftppath.cpp
# Ftp Path command class
#
########################################################################*/

#include <string.h>

#include "ftpserv.h"
#include "ftppass.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpPassFactory::TFtpPassFactory
#
#   Purpose....: Constructor for TFtpPassFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpPassFactory::TFtpPassFactory()
  : TFtpCommandFactory("PASS")
{
}

/*##########################################################################
#
#   Name       : TFtpPassFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpPassFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TFtpPassCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpPassCommand::TFtpPassCommand
#
#   Purpose....: Constructor for TFtpPassCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpPassCommand::TFtpPassCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpPassCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpPassCommand::Execute(char *param)
{
	TFtpArg *arg;
	int ArgCount;
	TFtpLangString msg;
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
		FServer->Pass = FArgList->FName;

		if (FServer->VerifyUser())
    		msg.Load(230);
    	else
    	    msg.Load(530);
	}
	else
		msg.Load(501);

    FServer->Reply(&msg);    
}
