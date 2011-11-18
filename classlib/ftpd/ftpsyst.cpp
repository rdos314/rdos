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
# syst.cpp
# Syst command class
#
########################################################################*/

#include <string.h>

#include "ftpserv.h"
#include "ftpsyst.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpSystFactory::TFtpSystFactory
#
#   Purpose....: Constructor for TFtpSystFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpSystFactory::TFtpSystFactory()
  : TFtpCommandFactory("SYST")
{
}

/*##########################################################################
#
#   Name       : TFtpSystFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpSystFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TFtpSystCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpSystCommand::TFtpSystCommand
#
#   Purpose....: Constructor for TFtpSystCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpSystCommand::TFtpSystCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpSystCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSystCommand::Execute(char *param)
{
	TFtpLangString msg;

	if (FServer->VerifyUser())
    	msg.Load(215);
   	else
   	    msg.Load(530);

    FServer->Reply(&msg);    
}
