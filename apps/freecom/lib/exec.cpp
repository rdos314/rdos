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
# exec.cpp
# Execute external command class
#
########################################################################*/

#include <string.h>

#include "rdos.h"
#include "exec.h"
#include "cmdhelp.h"
#include "lang.h"
#include "env.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TExecCommand::TExecCommand
#
#   Purpose....: Constructor for TExecCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TExecCommand::TExecCommand(TSession *session, const char *name, const char *param, int detach)
  : TCommand(session, param)
{
	FDetach = detach;
	FProgName = name;
}

/*##########################################################################
#
#   Name       : TExecCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TExecCommand::Execute(char *param)
{
	TPathName StartupDir;

	if (FDetach)
	{   
		if (RdosSpawn(FProgName.GetData(), param, StartupDir.Get().GetData()))
			return 0;
		else
			 return -1;
	 }
	 else
		  return RdosExec(FProgName.GetData(), param);
}
