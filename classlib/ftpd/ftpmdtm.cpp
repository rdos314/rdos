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
# ftpmdtm.cpp
# Ftp Mdtm command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "ftpserv.h"
#include "ftpmdtm.h"
#include "path.h"
#include "file.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpMdtmFactory::TFtpMdtmFactory
#
#   Purpose....: Constructor for TFtpMdtmFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpMdtmFactory::TFtpMdtmFactory()
  : TFtpCommandFactory("MDTM")
{
}

/*##########################################################################
#
#   Name       : TFtpMdtmFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpMdtmFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TFtpMdtmCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpMdtmCommand::TFtpMdtmCommand
#
#   Purpose....: Constructor for TFtpMdtmCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpMdtmCommand::TFtpMdtmCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpMdtmCommand::~TFtpMdtmCommand
#
#   Purpose....: Destructor for TFtpMdtmCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpMdtmCommand::~TFtpMdtmCommand()
{
}

/*##########################################################################
#
#   Name       : TFtpMdtmCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpMdtmCommand::Execute(char *param)
{
	TFtpArg *arg;
	int ArgCount;
	TFtpLangString msg;
	int ok;
	int year, month, day;
	int hour, min, sec;

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

			ok = (FArgCount == 2);
		}

		if (ok)
		{
			arg = FArgList;

			ok = (sscanf(arg->FName.GetData(), 
					"%04d%02d%02d%02d%02d%02d",
					&year, &month, &day,
					&hour, &min, &sec) == 6);
		}

		if (ok)
		{
			TDateTime filetime(year, month, day, hour, min, sec);

			arg = FArgList->FList;
				
			TPathName relpath = TPathName(FServer->CurrDir) + TString(arg->FName);
			TPathName abspath = TPathName(FServer->RootDir) + relpath.Get();
			if (abspath.IsFile())
			{
				TFile file = abspath.OpenFile();
				file.SetTime(filetime);
			}

	    	msg.Load(250);
		}
		else
			msg.Load(501);
	}
	else
   	    msg.Load(530);

    FServer->Reply(&msg);    

}
