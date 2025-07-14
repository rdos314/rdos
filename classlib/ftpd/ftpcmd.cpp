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
# ftpcmd.cpp
# Command base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "ftpcmd.h"
#include "ftpserv.h"

#define FALSE 0
#define TRUE !FALSE

int TFtpCommand::ErrorLevel = 0;

/*##########################################################################
#
#   Name       : TFtpArg::TFtpArg
#
#   Purpose....: Constructor for TFtpArg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpArg::TFtpArg(const char *name)
  : FName(name)
{
    ptr = (char *)FName.GetData();
    
    FList = 0;
}

/*##########################################################################
#
#   Name       : TFtpArg::~TFtpArg
#
#   Purpose....: Destructor for TFtpArg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpArg::~TFtpArg()
{
}

/*##########################################################################
#
#   Name       : TFtpCommand::TFtpCommand
#
#   Purpose....: Constructor for command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand::TFtpCommand(TFtpSocketServer *Server)
{
    FServer = Server;
    FArgList = 0;
}

/*##########################################################################
#
#   Name       : TFtpCommand::TFtpCommand
#
#   Purpose....: Constructor for command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand::TFtpCommand(TFtpSocketServer *Server, const char *param)
  : FCmdLine(param)
{
    FServer = Server;
    FArgList = 0;
}

/*##########################################################################
#
#   Name       : TFtpCommand::~TFtpCommand
#
#   Purpose....: Destructor for command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand::~TFtpCommand()
{
    TFtpArg *arg;

    arg = FArgList;
    while (arg)
    {
        FArgList = arg->FList;
        delete arg;
        arg = FArgList;
	}
}

/*##########################################################################
#
#   Name       : TFtpCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpCommand::Run()
{
	char *param;
	char *ptr;
	int size;

	size = FCmdLine.GetSize();
	param = new char[size + 1];
	memcpy(param, FCmdLine.GetData(), size + 1);

	ptr = param;

	Execute(ptr);

	delete param;
}

/*##########################################################################
#
#   Name       : TFtpCommand::AddArg
#
#   Purpose....: Add an argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpCommand::AddArg(const char *name)
{
    TFtpArg *arg = new TFtpArg(name);
    TFtpArg *curr;

    arg->FList = 0;
	curr = FArgList;
   
	if (curr)
	{
		while (curr->FList)
			curr = curr->FList;

		curr->FList = arg;
	}
	else
		FArgList = arg;    
}

/*##########################################################################
#
#   Name       : TFtpCommand::AddArg
#
#   Purpose....: Add an argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpCommand::AddArg(char *sBeg, char **sEnd)
{ 
    char *arg;

    *sEnd = SkipWord(sBeg);
    arg = TFtpSocketServer::Unquote(sBeg, *sEnd);
    AddArg(arg);
    delete arg;
}

/*##########################################################################
#
#   Name       : TFtpCommand::Split
#
#   Purpose....: Split line into arguments
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpCommand::Split(char *s)
{
	char *start;

    if (s)
    {
        start = SkipDelim(s);
        while (*start)
        {
			AddArg(start, &s);
			start = SkipDelim(s);
		}
	}
}

/*##########################################################################
#
#   Name       : TFtpCommand::Parse
#
#   Purpose....: Parse arguments
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpCommand::Parse(void *arg)
{
    TFtpArg *argv;

	FArgCount = 0;

    argv = FArgList;	
	while (argv)
	{
    	FArgCount++;	
		argv = argv->FList;
	}

	return E_None;
}

/*##########################################################################
#
#   Name       : TFtpCommand::ScanCmdLine
#
#   Purpose....: Scan cmd line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpCommand::ScanCmdLine(char *line, void *arg)
{
	Split(line);

	if (Parse(arg) != E_None)
		return FALSE;
	else
	    return TRUE;
}

