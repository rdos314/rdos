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
# rmdir.cpp
# Rmdir command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "rmdir.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TRmdirFactory::TRmdirFactory
#
#   Purpose....: Constructor for TRmdirFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRmdirFactory::TRmdirFactory()
  : TCommandFactory("RMDIR")
{
}

/*##########################################################################
#
#   Name       : TRmdirFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TRmdirFactory::Create(const char *param)
{
	return new TRmdirCommand(param);
}

/*##########################################################################
#
#   Name       : TMdFactory::TRdFactory
#
#   Purpose....: Constructor for TRdFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdFactory::TRdFactory()
  : TCommandFactory("RD")
{
}

/*##########################################################################
#
#   Name       : TRdFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TRdFactory::Create(const char *param)
{
	return new TRmdirCommand(param);
}

/*##########################################################################
#
#   Name       : TRmdirCommand::TRmdirCommand
#
#   Purpose....: Constructor for TRmdirCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRmdirCommand::TRmdirCommand(const char *param)
  : TCommand(param)
{
	FHelpScreen.Load(TEXT_CMDHELP_RD);
}

/*##########################################################################
#
#   Name       : TRmdirCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRmdirCommand::Execute(char *param)
{
	TArg *arg;

	if (!ScanCmdLine(param, 0))
		return 1;

	arg = FArgList;

	while (arg)
	{
		if (!RdosRemoveDir(arg->FName.GetData()))
		{
			FMsg.printf(TEXT_ERROR_DIRFCT_FAILED, "RD", FArgList->FName.GetData());
			Write(FMsg.GetData());
			return 1;
		}
		arg = arg->FList;
	}
	return 0;
}
