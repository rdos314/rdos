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
# exit.cpp
# Exit command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "exit.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TExitFactory::TExitFactory
#
#   Purpose....: Constructor for TExitFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TExitFactory::TExitFactory()
  : TCommandFactory("EXIT")
{
}

/*##########################################################################
#
#   Name       : TExitFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TExitFactory::Create(TSession *session, const char *param)
{
    return new TExitCommand(session, param);
}

/*##########################################################################
#
#   Name       : TExitCommand::TExitCommand
#
#   Purpose....: Constructor for TExitCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TExitCommand::TExitCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_EXIT);
}

/*##########################################################################
#
#   Name       : TExitCommand::IsExit
#
#   Purpose....: Is exit?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TExitCommand::IsExit()
{
	return TRUE;
}

/*##########################################################################
#
#   Name       : TExitCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TExitCommand::Execute(char *param)
{
	if (LeadOptions(&param, 0) != E_None)
		return 1;
		
	return 0;
}
