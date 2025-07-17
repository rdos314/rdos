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
# rmdir.cpp
# Rmdir command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "rmdir.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TRmdirFactory::TRmdirFactory
#
#   Purpose....: Constructor for TRmdirFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRmdirFactory::TRmdirFactory()
  : TCommandFactory("RMDIR")
{
}

/*##########################################################################
#
#   Name       : TRmdirFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TRmdirFactory::Create(TSession *session, const char *param)
{
	return new TRmdirCommand(session, param);
}

/*##########################################################################
#
#   Name       : TMdFactory::TRdFactory
#
#   Purpose....: Constructor for TRdFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdFactory::TRdFactory()
  : TCommandFactory("RD")
{
}

/*##########################################################################
#
#   Name       : TRdFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TRdFactory::Create(TSession *session, const char *param)
{
	return new TRmdirCommand(session, param);
}

/*##########################################################################
#
#   Name       : TRmdirCommand::TRmdirCommand
#
#   Purpose....: Constructor for TRmdirCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRmdirCommand::TRmdirCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_RD);
}

/*##########################################################################
#
#   Name       : TRmdirCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRmdirCommand::Execute(char *param)
{
	TArg *arg;

	if (!ScanCmdLine(param, 0))
		return 1;

	arg = FArgList;

	while (arg)
	{
		if (!RdosRemoveDir(arg->FName.GetData()))
		{
			FMsg.printf(TEXT_ERROR_DIRFCT_FAILED, "RD", FArgList->FName.GetData());
			Write(FMsg.GetData());
			return 1;
		}
		arg = arg->FList;
	}
	return 0;
}
