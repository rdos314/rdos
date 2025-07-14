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
# ftpcwd.cpp
# Cwd command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "ftpserv.h"
#include "ftpcwd.h"
#include "rdos.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpCwdFactory::TFtpCwdFactory
#
#   Purpose....: Constructor for TFtpCwdFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCwdFactory::TFtpCwdFactory()
  : TFtpCommandFactory("CWD")
{
}

/*##########################################################################
#
#   Name       : TFtpCwdFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpCwdFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TFtpCwdCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpCwdCommand::TFtpCwdCommand
#
#   Purpose....: Constructor for TFtpCwdCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCwdCommand::TFtpCwdCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpCwdCommand::~TFtpCwdCommand
#
#   Purpose....: Destructor for TFtpCwdCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCwdCommand::~TFtpCwdCommand()
{
}

/*##########################################################################
#
#   Name       : TFtpCwdCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpCwdCommand::Execute(char *param)
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
            TPathName abspath;
            TPathName relpath;

            switch (FArgList->FName[0])
		    {
		        case '/':
		        case '\\':
    			    relpath = TString(FArgList->FName);
    			    break;

    			default:
		   			relpath = TPathName(FServer->CurrDir) + TString(FArgList->FName);
			        break;
			}

			abspath = TPathName(FServer->RootDir) + relpath.Get();
			
			if (abspath.IsDir())
			{
				FServer->CurrDir = relpath.Get();
				msg.Load(250);			
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
