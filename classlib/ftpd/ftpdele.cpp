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
# ftpdele.cpp
# Ftp Dele command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "ftpserv.h"
#include "ftpdele.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpDeleFactory::TFtpDeleFactory
#
#   Purpose....: Constructor for TFtpDeleFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpDeleFactory::TFtpDeleFactory()
  : TFtpCommandFactory("DELE")
{
}

/*##########################################################################
#
#   Name       : TFtpDeleFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpDeleFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TFtpDeleCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpDeleCommand::TFtpDeleCommand
#
#   Purpose....: Constructor for TFtpDeleCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpDeleCommand::TFtpDeleCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpDeleCommand::~TFtpDeleCommand
#
#   Purpose....: Destructor for TFtpDeleCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpDeleCommand::~TFtpDeleCommand()
{
}

/*##########################################################################
#
#   Name       : TFtpDeleCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpDeleCommand::Execute(char *param)
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
			if (abspath.IsFile())
			{
				if (abspath.DeleteFile())
			    	msg.Load(250);
				else
					msg.Load(450);
			}
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
