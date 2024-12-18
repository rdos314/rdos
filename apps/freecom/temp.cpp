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
# temp.cpp
# Temperature command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "temp.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TTempFactory::TTempFactory
#
#   Purpose....: Constructor for TTempFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTempFactory::TTempFactory()
  : TCommandFactory("TEMP")
{
}

/*##########################################################################
#
#   Name       : TTempFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TTempFactory::Create(TSession *session, const char *param)
{
    return new TTempCommand(session, param);
}

/*##########################################################################
#
#   Name       : TTempCommand::TTempCommand
#
#   Purpose....: Constructor for TTempCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTempCommand::TTempCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_TEMP);
}

/*##########################################################################
#
#   Name       : TTempCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTempCommand::Execute(char *param)
{
    int val = RdosGetCpuTemperature();

    if (val)
    {
         FMsg.printf(TEXT_CPU_TEMP, val / 10, val % 10);
         Write(FMsg.GetData());

    }
    else
    {
        FMsg.Load(TEXT_NO_CPU_TEMP);
        Write(FMsg.GetData());
    }

    return 0;
}
