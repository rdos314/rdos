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
# ftpport.cpp
# Ftp Port command class
#
########################################################################*/

#include <stdio.h>
#include <string.h>

#include "ftpserv.h"
#include "ftpport.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpPortFactory::TFtpPortFactory
#
#   Purpose....: Constructor for TFtpPortFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpPortFactory::TFtpPortFactory()
  : TFtpCommandFactory("PORT")
{
}

/*##########################################################################
#
#   Name       : TFtpPortFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpPortFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TFtpPortCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpPortCommand::TFtpPortCommand
#
#   Purpose....: Constructor for TFtpPortCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpPortCommand::TFtpPortCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpPortCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpPortCommand::Execute(char *param)
{
	TFtpArg *arg;
	int ArgCount;
	TFtpLangString msg;
	int ok;
	long IP;
	int port;
	int i;
	int val;
	const char *ptr;

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

		ok = (FArgCount == 6);
	}

	if (ok)
	{
    	if (FServer->VerifyUser())
		{
			arg = FArgList;
			IP = 0;
			for (i = 0; i < 4 && ok; i++)
			{
				ptr = arg->FName.GetData();
				if (sscanf(ptr, "%d", &val) == 1)
				{
					IP = (IP << 8) | val;
					arg = arg->FList;
				}
				else
					ok = FALSE;
			}
			IP = RdosSwapLong(IP);

			port = 0;
			for (i = 0; i < 2 && ok; i++)
			{
				ptr = arg->FName.GetData();
				if (sscanf(ptr, "%d", &val) == 1)
				{
					port = (port << 8) | val;
					arg = arg->FList;
				}
				else
					ok = FALSE;
			}

			if (ok)
			{
				if (FServer->OpenDataConnection(IP, port))
					msg.Load(225);
				else
					msg.Load(426);
			}
			else
				msg.Load(501);
		}
		else
			msg.Load(530);
	}
	else
		msg.Load(501);

    FServer->Reply(&msg);    
}

