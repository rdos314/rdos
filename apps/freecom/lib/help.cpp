/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# help.cpp
# Help command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "help.h"
#include "cmdhelp.h"
#include "lang.h"

/*##########################################################################
#
#   Name       : THelpFactory::THelpFactory
#
#   Purpose....: Constructor for THelpFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THelpFactory::THelpFactory()
  : TCommandFactory("?")
{
}

/*##########################################################################
#
#   Name       : THelpFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *THelpFactory::Create(TSession *session, const char *param)
{
	return new THelpCommand(session, param);
}

/*##########################################################################
#
#   Name       : THelpCommand::THelpCommand
#
#   Purpose....: Constructor for THelpCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THelpCommand::THelpCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
}

/*##########################################################################
#
#   Name       : THelpCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THelpCommand::Execute(char *param)
{
    TCommandFactory *cmd;
    int y = 0;
    char str[16];

	FMsg.Load(TEXT_MSG_SHOWCMD_INTERNAL_COMMANDS);
	Write(FMsg.GetData());

    cmd = TCommandFactory::FCmdList;

    while (cmd)
    {
        sprintf(str, "%-10s", cmd->FName.GetData());
        Write(str);

        y++;
        if (y == 8)
			y = 0;

        cmd = cmd->FList;            
    }

    if (y != 0)
        Write("\r\n");

	return 0;
}
