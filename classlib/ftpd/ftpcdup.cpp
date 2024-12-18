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
# cdup.cpp
# Cdup command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "ftpserv.h"
#include "ftpcdup.h"
#include "rdos.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpCdupFactory::TFtpCdupFactory
#
#   Purpose....: Constructor for TFtpCdupFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCdupFactory::TFtpCdupFactory()
  : TFtpCommandFactory("CDUP")
{
}

/*##########################################################################
#
#   Name       : TFtpCdupFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpCdupFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TFtpCdupCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpCdupCommand::TFtpCdupCommand
#
#   Purpose....: Constructor for TFtpCdupCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCdupCommand::TFtpCdupCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpCdupCommand::~TFtpCdupCommand
#
#   Purpose....: Destructor for TFtpCdupCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCdupCommand::~TFtpCdupCommand()
{
}

/*##########################################################################
#
#   Name       : TFtpCdupCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpCdupCommand::Execute(char *param)
{
	TFtpLangString msg;

	if (FServer->VerifyUser())
	{
		TPathName path = TPathName(FServer->CurrDir);
		TString base = path.GetBaseName();
	
		if (base.GetSize())
			FServer->CurrDir = base;
		else
			FServer->CurrDir = "/";

		msg.Load(250);			
	}
   	else
   	    msg.Load(530);

   	FServer->Reply(&msg);    

}
