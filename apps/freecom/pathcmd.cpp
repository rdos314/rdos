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
# path.cpp
# Path command class
#
########################################################################*/

#include <string.h>

#include "lang.h"
#include "path.h"
#include "env.h"
#include "rdos.h"

/*##########################################################################
#
#   Name       : TPathFactory::TPathFactory
#
#   Purpose....: Constructor for TPathFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathFactory::TPathFactory()
  : TCommandFactory("PATH")
{
}

/*##########################################################################
#
#   Name       : TPathFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TPathFactory::Create(const char *param)
{
	return new TPathCommand(param);
}

/*##########################################################################
#
#   Name       : TPathCommand::TPathCommand
#
#   Purpose....: Constructor for TPathCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathCommand::TPathCommand(const char *param)
  : TCommand(param)
{
	FHelpScreen.Load(TEXT_CMDHELP_PATH);
}

/*##########################################################################
#
#   Name       : TPathCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathCommand::Execute(char *param)
{
	char *p;
	TEnv *env = TEnv::OpenProcessEnv();
	char path[512];

	p = (char *)LTrim(param);
	if (*p == 0 && !strchr(param, ';'))
	{
		if (env->Find("PATH", path))
			FMsg.printf(TEXT_MSG_PATH, path);
		else
			FMsg.Load(TEXT_MSG_PATH_NONE);
		Write(FMsg.GetData());
	}
	else
	{
		RTrim(p);

		env->Add("PATH", p);
	}
	delete env;
	return 0;
}
