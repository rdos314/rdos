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
# prompt.cpp
# Prompt command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "prompt.h"
#include "env.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TPromptFactory::TPromptFactory
#
#   Purpose....: Constructor for TPromptFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPromptFactory::TPromptFactory()
  : TCommandFactory("PROMPT")
{
}

/*##########################################################################
#
#   Name       : TPromptFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TPromptFactory::Create(TSession *session, const char *param)
{
	return new TPromptCommand(session, param);
}

/*##########################################################################
#
#   Name       : TPromptCommand::TPromptCommand
#
#   Purpose....: Constructor for TPromptCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPromptCommand::TPromptCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_PROMPT);
}

/*##########################################################################
#
#   Name       : TPromptCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPromptCommand::Execute(char *param)
{
	TEnv *env;

	if (LeadOptions(&param, 0) != E_None)
		return 1;

	if (*param == 0)
	    strcpy(param, "$p$g");

	env = TEnv::OpenSysEnv();
	env->Add("PROMPT", param);
	delete env;
	
	return 0;
}
