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
# ftppwd.cpp
# FTP Pwd command class
#
########################################################################*/

#include <string.h>

#include "ftpserv.h"
#include "ftppwd.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpPwdFactory::TFtpPwdFactory
#
#   Purpose....: Constructor for TFtpPwdFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpPwdFactory::TFtpPwdFactory()
  : TFtpCommandFactory("PWD")
{
}

/*##########################################################################
#
#   Name       : TFtpPwdFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpPwdFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TFtpPwdCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpPwdCommand::TFtpPwdCommand
#
#   Purpose....: Constructor for TFtpPwdCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpPwdCommand::TFtpPwdCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpPwdCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpPwdCommand::Execute(char *param)
{
	TFtpLangString msg;
    TString str;
	const char *ptr;

	if (FServer->VerifyUser())
	{
		str = "\"";
		ptr = FServer->CurrDir.GetData();
		while (*ptr)
		{
			if (*ptr == '\\')
				str += '/';
			else
				str += *ptr;
			ptr++;
		}
		str += "\"";
		str += " is current directory";
        msg.printf(257, str.GetData());
    }
   	else
   	    msg.Load(530);

    FServer->Reply(&msg);    
}
