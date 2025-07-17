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
# newsess.cpp
# New session command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "newsess.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TNewSessionFactory::TNewSessionFactory
#
#   Purpose....: Constructor for TNewSessionFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TNewSessionFactory::TNewSessionFactory()
  : TCommandFactory("COMMAND")
{
}

/*##########################################################################
#
#   Name       : TNewSessionFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TNewSessionFactory::Create(TSession *session, const char *param)
{
	return new TNewSessionCommand(session, param);
}

/*##########################################################################
#
#   Name       : TNewSessionCommand::TNewSessionCommand
#
#   Purpose....: Constructor for TNewSessionCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TNewSessionCommand::TNewSessionCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_COMMAND);
}

/*##########################################################################
#
#   Name       : TNewSessionCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TNewSessionCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
	switch(ch)
	{
		case 'C':
			return OptScanBool(optstr, bool, strarg, &FOptC);
	}
	OptError(optstr);
	return E_Useage;
}

/*##########################################################################
#
#   Name       : TNewSessionCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TNewSessionCommand::InitOptions()
{
    FOptC = 0;
}

/*##########################################################################
#
#   Name       : TNewSessionCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TNewSessionCommand::Execute(char *param)
{
	InitOptions();

	if (LeadOptions(&param, 0) != E_None)
		return 1;

    if (FOptC)
        return Command(param);
    else
        return Command();      
}
