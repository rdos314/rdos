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
# mkdir.cpp
# Mkdir command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "mkdir.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TMkdirFactory::TMkdirFactory
#
#   Purpose....: Constructor for TMkdirFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMkdirFactory::TMkdirFactory()
  : TCommandFactory("MKDIR")
{
}

/*##########################################################################
#
#   Name       : TMkdirFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TMkdirFactory::Create(TSession *session, const char *param)
{
	return new TMkdirCommand(session, param);
}

/*##########################################################################
#
#   Name       : TMdFactory::TMdFactory
#
#   Purpose....: Constructor for TMdFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMdFactory::TMdFactory()
  : TCommandFactory("MD")
{
}

/*##########################################################################
#
#   Name       : TMdFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TMdFactory::Create(TSession *session, const char *param)
{
	return new TMkdirCommand(session, param);
}

/*##########################################################################
#
#   Name       : TMkdirCommand::TMkdirCommand
#
#   Purpose....: Constructor for TMkdirCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMkdirCommand::TMkdirCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_MD);
}

/*##########################################################################
#
#   Name       : TMkdirCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMkdirCommand::Execute(char *param)
{
	TArg *arg;

	if (!ScanCmdLine(param, 0))
		return 1;

	arg = FArgList;

	while (arg)
	{
        TPathName path(arg->FName);
        if (!path.MakeDir())
		{
			FMsg.printf(TEXT_ERROR_DIRFCT_FAILED, "MD", FArgList->FName.GetData());
			Write(FMsg.GetData());
			return 1;
		}
		arg = arg->FList;
	}
	return 0;
}
