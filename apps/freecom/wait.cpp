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
# wait.cpp
# Wait command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "lang.h"
#include "wait.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TWaitFactory::TWaitFactory
#
#   Purpose....: Constructor for TWaitFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitFactory::TWaitFactory()
  : TCommandFactory("WAIT")
{
}

/*##########################################################################
#
#   Name       : TWaitFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TWaitFactory::Create(TSession *session, const char *param)
{
	return new TWaitCommand(session, param);
}

/*##########################################################################
#
#   Name       : TWaitCommand::TWaitCommand
#
#   Purpose....: Constructor for TWaitCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitCommand::TWaitCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_WAIT);
}

/*##########################################################################
#
#   Name       : TWaitCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWaitCommand::Execute(char *param)
{
    int time;
    
	if (sscanf(param, "%d", &time) == 1)
	{
	    RdosWaitMilli(time);
	    return 0;
	}
	
	ErrorSyntax(0);
	return 1;
}
