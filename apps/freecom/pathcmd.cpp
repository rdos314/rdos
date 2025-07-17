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
# pathcmd.cpp
# Pathcmd command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "pathcmd.h"
#include "path.h"
#include "env.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

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
TCommand *TPathFactory::Create(TSession *session, const char *param)
{
	return new TPathCommand(session, param);
}

/*##########################################################################
#
#   Name       : TPathFactory::PassAll
#
#   Purpose....: Pass all chars
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathFactory::PassAll()
{
	return TRUE;
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
TPathCommand::TPathCommand(TSession *session, const char *param)
  : TCommand(session, param)
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
	TEnv *env = TEnv::OpenSysEnv();
	char path[512];

	if (LeadOptions(&param, 0) != E_None)
		return 1;

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
