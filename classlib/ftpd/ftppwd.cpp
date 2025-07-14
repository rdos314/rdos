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
# ftppwd.cpp
# FTP Pwd command class
#
########################################################################*/

#include <string.h>

#include "ftpserv.h"
#include "ftppwd.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpPwdFactory::TFtpPwdFactory
#
#   Purpose....: Constructor for TFtpPwdFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpPwdFactory::TFtpPwdFactory()
  : TFtpCommandFactory("PWD")
{
}

/*##########################################################################
#
#   Name       : TFtpPwdFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpPwdFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TFtpPwdCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpPwdCommand::TFtpPwdCommand
#
#   Purpose....: Constructor for TFtpPwdCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpPwdCommand::TFtpPwdCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpPwdCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpPwdCommand::Execute(char *param)
{
	TFtpLangString msg;
    TString str;
	const char *ptr;

	if (FServer->VerifyUser())
	{
		str = "\"";
		ptr = FServer->CurrDir.GetData();
		while (*ptr)
		{
			if (*ptr == '\\')
				str += '/';
			else
				str += *ptr;
			ptr++;
		}
		str += "\"";
		str += " is current directory";
        msg.printf(257, str.GetData());
    }
   	else
   	    msg.Load(530);

    FServer->Reply(&msg);    
}
