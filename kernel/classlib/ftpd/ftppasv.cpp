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
# pasv.cpp
# Pasv command class
#
########################################################################*/

#include <string.h>

#include "ftpserv.h"
#include "ftppasv.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpPasvFactory::TFtpPasvFactory
#
#   Purpose....: Constructor for TFtpPasvFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpPasvFactory::TFtpPasvFactory()
  : TFtpCommandFactory("PASV")
{
}

/*##########################################################################
#
#   Name       : TFtpPasvFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpPasvFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TFtpPasvCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpPasvCommand::TFtpPasvCommand
#
#   Purpose....: Constructor for TFtpPasvCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpPasvCommand::TFtpPasvCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpPasvCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpPasvCommand::Execute(char *param)
{
	TFtpLangString msg;
	long IP;
	int port;
	int i;
	int arr[6];

	FServer->ListenForDataConnection(&IP, &port);

	for (i = 0; i < 4; i++)
	    arr[i] = (IP >> (8 * i)) & 0xff;

	arr[4] = (port >> 8) & 0xff;
	arr[5] = port & 0xff;

	msg.printf(227, arr[0], arr[1], arr[2], arr[3], arr[4], arr[5]);
	
    FServer->Reply(&msg);    
}

