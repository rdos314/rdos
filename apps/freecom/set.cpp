/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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
TCommand *TSetFactory::Create(TSession *session, const char *param)
{
	return new TSetCommand(session, param);
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
TSetCommand::TSetCommand(TSession *session, const char *param)
  : TCommand(session, param)
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
void TSetCommand::InitOptions()
{
	FOptC = 0;
	FPromptUser = 0;
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

	InitOptions();

	if (LeadOptions(&param, 0) != E_None)
		return 1;

	/* if no parameters, show the environment */
	if (*param == 0)
	{
		env = TEnv::OpenSysEnv();
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

	env = TEnv::OpenSysEnv();
	if (!FOptC)
		strupr(param);
	env->Add(param, value);
	delete env;

	if (PromptBuf)
		delete PromptBuf;

	return 0;
}

