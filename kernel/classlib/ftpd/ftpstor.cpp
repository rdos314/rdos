/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# stor.cpp
# Stor command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "ftpserv.h"
#include "ftpstor.h"
#include "path.h"
#include "file.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TStorFactory::TStorFactory
#
#   Purpose....: Constructor for TStorFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorFactory::TStorFactory()
  : TCommandFactory("STOR")
{
}

/*##########################################################################
#
#   Name       : TStorFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TStorFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TStorCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TStorCommand::TStorCommand
#
#   Purpose....: Constructor for TStorCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorCommand::TStorCommand(TFtpSocketServer *Server, const char *param)
  : TCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TStorCommand::~TStorCommand
#
#   Purpose....: Destructor for TStorCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorCommand::~TStorCommand()
{
}

/*##########################################################################
#
#   Name       : TStorCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorCommand::Execute(char *param)
{
	TArg *arg;
	int ArgCount;
	TLangString msg;
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

			TFile file = abspath.CreateFile(0);
			int size;

			if (file.IsOpen())
			{
				char *buf = new char[512];

    			msg.Load(150);
	    	    FServer->Reply(&msg);    

				while (FServer->IsOpen())
				{
					size = FServer->Read(buf, 512);
					file.Write(buf, size);
				}

				size = FServer->Read(buf, 512);
				while (size)
				{
					file.Write(buf, size);
					size = FServer->Read(buf, 512);
				}

				delete buf;

				FServer->Push();

		    	msg.Load(226);
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
