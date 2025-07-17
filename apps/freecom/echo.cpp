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
# echo.cpp
# Echo command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "echo.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TEchoFactory::TEchoFactory
#
#   Purpose....: Constructor for TEchoFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TEchoFactory::TEchoFactory()
  : TCommandFactory("ECHO")
{
}

/*##########################################################################
#
#   Name       : TEchoFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TEchoFactory::Create(TSession *session, const char *param)
{
	return new TEchoCommand(session, param);
}

/*##########################################################################
#
#   Name       : TEchoCommand::TEchoCommand
#
#   Purpose....: Constructor for TEchoCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TEchoCommand::TEchoCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_ECHO);
}

/*##########################################################################
#
#   Name       : TEchoCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TEchoCommand::Execute(char *param)
{
    TString str;

	if (LeadOptions(&param, 0) != E_None)
		return 1;

    str = param;
    str.Upper();
    
    if (*param)
    {
        if (!strcmp(str.GetData(), "ON"))
        {
            FSession->SetEchoOn();
            return 0;
        }

        if (!strcmp(str.GetData(), "OFF"))
        {
            FSession->SetEchoOff();
            return 0;
        }

        Write(param);
        Write("\r\n");
        return 0;
    }
    else
    {
        if (FSession->IsEchoOn())
            FMsg.printf(TEXT_MSG_ECHO_STATE, "ON");
        else
            FMsg.printf(TEXT_MSG_ECHO_STATE, "OFF");
    	Write(FMsg.GetData());
        return 0;    
    }
}
