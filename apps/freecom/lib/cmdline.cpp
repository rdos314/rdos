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
# cmdline.cpp
# Command line class
#
########################################################################*/

#include "cmdline.h"
#include "cmdfact.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TCommandLine::TCommandLine
#
#   Purpose....: Constructor for command line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommandLine::TCommandLine(const char *line)
{	
    FList = TCommandFactory::Parse(line);
    FList->FList = 0;
}

/*##########################################################################
#
#   Name       : TCommandLine::~TCommandLine
#
#   Purpose....: Destructor for command line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommandLine::~TCommandLine()
{	
    TCommand *cmd;
    TCommand *next;

    cmd = FList;

    while (cmd)
    {
        next = cmd->FList;
        delete cmd;
        cmd = next;
    }
}

/*##########################################################################
#
#   Name       : TCommandLine::Run
#
#   Purpose....: Run command line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommandLine::Run()
{	
    TCommand *cmd;
    int result = 0;

    cmd = FList;

    while (cmd && result == 0)
    {
        result = cmd->Run();
        cmd = cmd->FList;
    }
    return result;
}
