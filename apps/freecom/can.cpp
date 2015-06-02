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
# can.cpp
# Can command class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "can.h"

#define FALSE 0
#define TRUE !FALSE

TString CanFileName = "z:\\can.raw";
int CanHandle = 0;

/*##########################################################################
#
#   Name       : TCanFactory::TCanFactory
#
#   Purpose....: Constructor for TCanFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCanFactory::TCanFactory()
  : TCommandFactory("CAN")
{
}

/*##########################################################################
#
#   Name       : TCanFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TCanFactory::Create(TSession *session, const char *param)
{
	return new TCanCommand(session, param);
}

/*##########################################################################
#
#   Name       : TCanCommand::TCanCommand
#
#   Purpose....: Constructor for TCanCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCanCommand::TCanCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_CAN);
}

/*##########################################################################
#
#   Name       : TCanCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCanCommand::Execute(char *param)
{
    TString Str;
	const char *str;
	const char *file;

	if (!ScanCmdLine(param, 0))
		return 1;

	if (FArgCount != 1)
	{
		 FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
		 Write(FMsg.GetData());
		 return E_Useage;
	}

	Str = FArgList->FName;
	Str.Lower();
	str = Str.GetData();

	if (!strcmp(str, "off"))
	{
		RdosStopCanCapture();

		if (CanHandle)
		{
			RdosCloseFile(CanHandle);
			CanHandle = 0;
		}

		FMsg.Load(TEXT_CAN_OFF);
		Write(FMsg.GetData());
		return 0;
	}

	if (strcmp(str, "on"))
		CanFileName = FArgList->FName;

	if (CanHandle)
	{
		RdosStopCanCapture();
		RdosCloseFile(CanHandle);
		CanHandle = 0;
	}

	file = CanFileName.GetData();
	CanHandle = RdosOpenFile(file, 0);
	if (!CanHandle)
		CanHandle = RdosCreateFile(file, 0);

	if (CanHandle)
	{
	    RdosStartCanCapture(CanHandle);
		FMsg.printf(TEXT_CAN_ON, file);
		Write(FMsg.GetData());
		return 0;
	}
	else
	{
		 FMsg.Load(TEXT_ERROR_FILE_NOT_FOUND);
		 Write(FMsg.GetData());
		 return E_Useage;
	}
}
