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
