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
# pwd.cpp
# Pwd command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "pwd.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TPwdFactory::TPwdFactory
#
#   Purpose....: Constructor for TPwdFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPwdFactory::TPwdFactory()
  : TCommandFactory("PWD")
{
}

/*##########################################################################
#
#   Name       : TPwdFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TPwdFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TPwdCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TPwdCommand::TPwdCommand
#
#   Purpose....: Constructor for TPwdCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPwdCommand::TPwdCommand(TFtpSocketServer *Server, const char *param)
  : TCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TPwdCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPwdCommand::Execute(char *param)
{
	TLangString msg;
    TString str;

    str = "\"" + FServer->CurrDir + "\"" + " is current directory";

    msg.printf(257, str.GetData());
    FServer->Reply(&msg);    
}
