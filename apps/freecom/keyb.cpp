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
# keyb.cpp
# Keyboard mapping command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "keyb.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TKeybFactory::TKeybFactory
#
#   Purpose....: Constructor for TKeybFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TKeybFactory::TKeybFactory()
  : TCommandFactory("KEYB")
{
}

/*##########################################################################
#
#   Name       : TKeybFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TKeybFactory::Create(TSession *session, const char *param)
{
        return new TKeybCommand(session, param);
}

/*##########################################################################
#
#   Name       : TKeybCommand::TKeybCommand
#
#   Purpose....: Constructor for TKeybCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TKeybCommand::TKeybCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_KEYB);
}

/*##########################################################################
#
#   Name       : TKeybCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TKeybCommand::Execute(char *param)
{
    char MapStr[10];

    if (LeadOptions(&param, 0) != E_None)
        return 1;

    if (*param == 0)
    {
        RdosGetKeyMap(MapStr);
        FMsg.printf(TEXT_MSG_CURRENT_KEYB, MapStr);
        Write(FMsg.GetData());
        param = 0;
    }
    else
    {
        if (!RdosSetKeyMap(param))
        {
             FMsg.Load(TEXT_ERROR_INVALID_KEYB);
            Write(FMsg.GetData());
        }
    }

    return 0;
}
