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
# rem.cpp
# Rem command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "rem.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TRemFactory::TRemFactory
#
#   Purpose....: Constructor for TRemFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRemFactory::TRemFactory()
  : TCommandFactory("REM")
{
}

/*##########################################################################
#
#   Name       : TRemFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TRemFactory::Create(TSession *session, const char *param)
{
	return new TRemCommand(session, param);
}

/*##########################################################################
#
#   Name       : TRemCommand::TRemCommand
#
#   Purpose....: Constructor for TRemCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRemCommand::TRemCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_REM);
}

/*##########################################################################
#
#   Name       : TRemCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRemCommand::Execute(char *param)
{
	if (LeadOptions(&param, 0) != E_None)
		return 1;

	return 0;
}
