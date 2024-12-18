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
# syncpart.cpp
# Sync partition command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "syncpart.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TSyncPartitionFactory::TSyncPartitionFactory
#
#   Purpose....: Constructor for TSyncPartitionFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSyncPartitionFactory::TSyncPartitionFactory()
  : TCommandFactory("SYNCPART")
{
}

/*##########################################################################
#
#   Name       : TSyncPartitionFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TSyncPartitionFactory::Create(TSession *session, const char *param)
{
    return new TSyncPartitionCommand(session, param);
}

/*##########################################################################
#
#   Name       : TSyncPartitionCommand::TSyncPartitionCommand
#
#   Purpose....: Constructor for TSyncPartitionCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSyncPartitionCommand::TSyncPartitionCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_SYNCPART);
}

/*##########################################################################
#
#   Name       : TSyncPartitionCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSyncPartitionCommand::Execute(char *param)
{
    int DiscNr;

    if (!ScanCmdLine(param, 0))
        return 1;

    if (FArgCount != 1)
    {
        FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
        Write(FMsg.GetData());
        return E_Useage;
    }

    if (sscanf(FArgList->FName.GetData(), "%d", &DiscNr) != 1)
    {
        ErrorSyntax(0);
        return 1;
    }

    RdosSyncDiscPart(DiscNr);

    return 0;
}

