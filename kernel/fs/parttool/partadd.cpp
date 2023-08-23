/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2011, Leif Ekblad
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
# partadd.cpp
# Add partition command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "partadd.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TAddPartitionFactory::TAddPartitionFactory
#
#   Purpose....: Constructor for TAddPartitionFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAddPartitionFactory::TAddPartitionFactory(TDiscServer *Server)
  : TCommandFactory("ADD")
{
    FServer = Server;
}

/*##########################################################################
#
#   Name       : TAddPartitionFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TAddPartitionFactory::Create(TCommandOutput *out, const char *param)
{
    return new TAddPartitionCommand(FServer, out, param);
}

/*##########################################################################
#
#   Name       : TAddPartitionCommand::TAddPartitionCommand
#
#   Purpose....: Constructor for TAddPartitionCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAddPartitionCommand::TAddPartitionCommand(TDiscServer *server, TCommandOutput *out, const char *param)
  : TCommand(out, param)
{
    FHelpScreen = "Add (partition) type size (MB)";
    FServer = server;
}

/*##########################################################################
#
#   Name       : TAddPartitionCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAddPartitionCommand::Execute(char *param)
{
    TString str;

    str.printf("Add partition %s\r\n", param);
    Write(str.GetData());

//    FServer->InitDisc(param);

    return 0;
}
