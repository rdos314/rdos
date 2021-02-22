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
# net.cpp
# Net command class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "net.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TNetFactory::TNetFactory
#
#   Purpose....: Constructor for TNetFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TNetFactory::TNetFactory()
  : TCommandFactory("NET")
{
}

/*##########################################################################
#
#   Name       : TNetFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TNetFactory::Create(TSession *session, const char *param)
{
    return new TNetCommand(session, param);
}

/*##########################################################################
#
#   Name       : TNetCommand::TNetCommand
#
#   Purpose....: Constructor for TNetCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TNetCommand::TNetCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_NET);
}

/*##########################################################################
#
#   Name       : TNetCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TNetCommand::Execute(char *param)
{
    int HwId;

    HwId = RdosGetNetHwId(0);

    if (HwId)
    {
        FMsg.printf(TEXT_NET_HW_ID, 1, HwId);
        Write(FMsg.GetData());
    }

    HwId = RdosGetNetHwId(1);

    if (HwId)
    {
        FMsg.printf(TEXT_NET_HW_ID, 2, HwId);
        Write(FMsg.GetData());
    }

    return 0;
}
