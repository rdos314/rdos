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

#include "cmdhelp.h"
#include "pasv.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TPasvFactory::TPasvFactory
#
#   Purpose....: Constructor for TPasvFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPasvFactory::TPasvFactory()
  : TCommandFactory("PASV")
{
}

/*##########################################################################
#
#   Name       : TPasvFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TPasvFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TPasvCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TPasvCommand::TPasvCommand
#
#   Purpose....: Constructor for TPasvCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPasvCommand::TPasvCommand(TFtpSocketServer *Server, const char *param)
  : TCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TPasvCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPasvCommand::Execute(char *param)
{
	TLangString msg;
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

