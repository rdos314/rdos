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
# reboot.cpp
# Reboot command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "reboot.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TRebootFactory::TRebootFactory
#
#   Purpose....: Constructor for TRebootFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRebootFactory::TRebootFactory()
  : TCommandFactory("REBOOT")
{
}

/*##########################################################################
#
#   Name       : TRebootFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TRebootFactory::Create(TSession *session, const char *param)
{
	return new TRebootCommand(session, param);
}

/*##########################################################################
#
#   Name       : TRebootCommand::TRebootCommand
#
#   Purpose....: Constructor for TRebootCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRebootCommand::TRebootCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_REBOOT);
}

/*##########################################################################
#
#   Name       : TRebootCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRebootCommand::Execute(char *param)
{
    int i;

	if (LeadOptions(&param, 0) != E_None)
		return 1;

    RdosCpuReset();
    
	return 0;
}
