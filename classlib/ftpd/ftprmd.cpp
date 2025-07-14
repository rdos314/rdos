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
# ftprmd.cpp
# Rmd command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "ftpserv.h"
#include "ftprmd.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpRmdFactory::TFtpRmdFactory
#
#   Purpose....: Constructor for TFtpRmdFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpRmdFactory::TFtpRmdFactory()
  : TFtpCommandFactory("RMD")
{
}

/*##########################################################################
#
#   Name       : TFtpRmdFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpRmdFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TFtpRmdCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpRmdCommand::TFtpRmdCommand
#
#   Purpose....: Constructor for TFtpRmdCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpRmdCommand::TFtpRmdCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpRmdCommand::~TFtpRmdCommand
#
#   Purpose....: Destructor for TFtpRmdCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpRmdCommand::~TFtpRmdCommand()
{
}

/*##########################################################################
#
#   Name       : TFtpRmdCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpRmdCommand::Execute(char *param)
{
	TFtpArg *arg;
	int ArgCount;
	TFtpLangString msg;
	int ok;

	if (FServer->VerifyUser())
	{
		ok = ScanCmdLine(param, 0);
		if (ok)
		{
			ArgCount = 0;
			arg = FArgList;
			while (arg)
			{
				ArgCount++;
				arg = arg->FList;
			}

			ok = (FArgCount == 1);
		}

		if (ok)
		{
			TPathName relpath = TPathName(FServer->CurrDir) + TString(FArgList->FName);
			TPathName abspath = TPathName(FServer->RootDir) + relpath.Get();
			if (abspath.RemoveDir())
			    msg.Load(250);
			else
				msg.Load(450);
		}
		else
			msg.Load(501);
	}
	else
   	    msg.Load(530);

    FServer->Reply(&msg);    

}
