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
# chdir.cpp
# Chdir command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "chdir.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

TString PrevDir;

/*##########################################################################
#
#   Name       : TChdirFactory::TChdirFactory
#
#   Purpose....: Constructor for TChdirFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChdirFactory::TChdirFactory()
  : TCommandFactory("CHDIR")
{
}

/*##########################################################################
#
#   Name       : TChdirFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TChdirFactory::Create(TSession *session, const char *param)
{
	return new TChdirCommand(session, param);
}

/*##########################################################################
#
#   Name       : TCdFactory::TCdFactory
#
#   Purpose....: Constructor for TCdFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCdFactory::TCdFactory()
  : TCommandFactory("CD")
{
}

/*##########################################################################
#
#   Name       : TCdFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TCdFactory::Create(TSession *session, const char *param)
{
	return new TChdirCommand(session, param);
}

/*##########################################################################
#
#   Name       : TChdirCommand::TChdirCommand
#
#   Purpose....: Constructor for TChdirCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChdirCommand::TChdirCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_CD);
}

/*##########################################################################
#
#   Name       : TChdirCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChdirCommand::Execute(char *param)
{
	TPathName Path;

	if (!ScanCmdLine(param, 0))
		return 1;

	if (FArgList)
	{
		if (!strcmp(FArgList->FName.GetData(), "-"))
		{
			if (RdosSetCurDir(PrevDir.GetData()))
			{
				PrevDir = Path.GetFullPathName();
				return 0;
			}
			else
			{
				FMsg.printf(TEXT_ERROR_DIRFCT_FAILED, "CD", PrevDir.GetData());
				Write(FMsg.GetData());
				return 1;
			}
		}
		else
		{	
			if (RdosSetCurDir(FArgList->FName.GetData()))
			{
				PrevDir = Path.GetFullPathName();
				return 0;			
			}
			else
			{
				FMsg.printf(TEXT_ERROR_DIRFCT_FAILED, "CD", FArgList->FName.GetData());
				Write(FMsg.GetData());
				return 1;
			}
		}
	}
	else
	{
		Write(Path.GetFullPathName().GetData());
		Write("\r\n");
		return 0;
	}
}
