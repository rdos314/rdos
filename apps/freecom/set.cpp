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
# set.cpp
# Set command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "set.h"
#include "env.h"

#define PROMPT_BUFFER_SIZE	256

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TSetFactory::TSetFactory
#
#   Purpose....: Constructor for TSetFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSetFactory::TSetFactory()
  : TCommandFactory("SET")
{
}

/*##########################################################################
#
#   Name       : TSetFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TSetFactory::Create(const char *param)
{
	return new TSetCommand(param);
}

/*##########################################################################
#
#   Name       : TSetCommand::TSetCommand
#
#   Purpose....: Constructor for TSetCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSetCommand::TSetCommand(const char *param)
  : TCommand(param)
{
	FHelpScreen.Load(TEXT_CMDHELP_SET);
}

/*##########################################################################
#
#   Name       : TSetCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSetCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
	switch(ch)
	{
		case 'C':
			return OptScanBool(optstr, bool, strarg, &FOptC);

		case 'P':
			return OptScanBool(optstr, bool, strarg, &FPromptUser);
	}
	OptError(optstr);
	return E_Useage;
}

/*##########################################################################
#
#   Name       : TSetCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSetCommand::InitOptions()
{
	FOptC = 0;
	FPromptUser = 0;
	return TRUE;
}

/*##########################################################################
#
#   Name       : TSetCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSetCommand::Execute(char *param)
{
	TEnv *env;
	TEnvVar *var;
	char *value;
	char *PromptBuf = 0;
	char *p;

	/* if no parameters, show the environment */
	if (*param == 0)
	{
		env = TEnv::OpenProcessEnv();
		var = env->GotoFirst();

		while (var)
		{
			Write(var->GetName());
			Write('=');
			Write(var->GetValue());
			Write("\r\n");

			var = env->GotoNext();
		}

		delete env;
		return 0;
	}

	/* make sure there is an = in the command */
	p = strchr(param, '=');
	if (p == 0 || p == param)
	{
		ErrorSyntax(0);
		return 1;
	}

	*p = 0;			/* separate name and value */
	value = p + 1;

	if (FPromptUser)
	{
		Write(value);

		PromptBuf = new char[PROMPT_BUFFER_SIZE + 1];

		if (!Read(PromptBuf, PROMPT_BUFFER_SIZE))
		{
			delete PromptBuf;
			return E_CBreak;
		}

		value = strchr(PromptBuf, 0);
		while (--value >= PromptBuf && (*value == '\n' || *value == '\r'))
			;

		value[1] = 0;	/* strip trailing newlines */
		value = PromptBuf;
	}

	if (IsEmpty(value))
		value = 0;

	env = TEnv::OpenProcessEnv();
	if (!FOptC)
		strupr(param);
	env->Add(param, value);
	delete env;

	if (PromptBuf)
		delete PromptBuf;

	return 0;
}

