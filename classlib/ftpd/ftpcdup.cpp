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
# ftpcdup.cpp
# Cdup command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "ftpserv.h"
#include "ftpcdup.h"
#include "rdos.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpCdupFactory::TFtpCdupFactory
#
#   Purpose....: Constructor for TFtpCdupFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCdupFactory::TFtpCdupFactory()
  : TFtpCommandFactory("CDUP")
{
}

/*##########################################################################
#
#   Name       : TFtpCdupFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpCdupFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TFtpCdupCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpCdupCommand::TFtpCdupCommand
#
#   Purpose....: Constructor for TFtpCdupCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCdupCommand::TFtpCdupCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpCdupCommand::~TFtpCdupCommand
#
#   Purpose....: Destructor for TFtpCdupCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCdupCommand::~TFtpCdupCommand()
{
}

/*##########################################################################
#
#   Name       : TFtpCdupCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpCdupCommand::Execute(char *param)
{
	TFtpLangString msg;

	if (FServer->VerifyUser())
	{
		TPathName path = TPathName(FServer->CurrDir);
		TString base = path.GetBaseName();
	
		if (base.GetSize())
			FServer->CurrDir = base;
		else
			FServer->CurrDir = "/";

		msg.Load(250);			
	}
   	else
   	    msg.Load(530);

   	FServer->Reply(&msg);    

}
