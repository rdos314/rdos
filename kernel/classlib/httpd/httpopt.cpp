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
# httpopt.cpp
# HTTP Option base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "httpopt.h"
#include "httpcmd.h"

#define FALSE 0
#define TRUE !FALSE

int THttpOption::ErrorLevel = 0;

/*##########################################################################
#
#   Name       : THttpOption::THttpOption
#
#   Purpose....: Constructor for command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpOption::THttpOption(const char *Name, char *Param)
  : FName(Name)
{
    FArgList = 0;

	ScanCmdLine(Param, 0);
}

/*##########################################################################
#
#   Name       : THttpOption::~THttpOption
#
#   Purpose....: Destructor for command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpOption::~THttpOption()
{
    THttpArg *arg;

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
#   Name       : THttpOption::IsArgDelim
#
#   Purpose....: Check for argument delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpOption::IsArgDelim(char ch)
{
	return iscntrl(ch) || ch == ',';
}

/*##########################################################################
#
#   Name       : THttpOption::AddArg
#
#   Purpose....: Add an argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpOption::AddArg(const char *name)
{
    THttpArg *arg = new THttpArg(name);
    THttpArg *curr;

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
#   Name       : THttpOption::AddArg
#
#   Purpose....: Add an argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpOption::AddArg(char *sBeg, char **sEnd)
{ 
    char *arg;

    *sEnd = SkipWord(sBeg);
    arg = THttpSocketServer::Unquote(sBeg, *sEnd);
    AddArg(arg);
    delete arg;
}

/*##########################################################################
#
#   Name       : THttpOption::Split
#
#   Purpose....: Split line into arguments
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpOption::Split(char *s)
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
#   Name       : THttpOption::Parse
#
#   Purpose....: Parse arguments
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpOption::Parse(void *arg)
{
    THttpArg *argv;

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
#   Name       : THttpOption::ScanCmdLine
#
#   Purpose....: Scan cmd line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpOption::ScanCmdLine(char *line, void *arg)
{
	Split(line);

	if (Parse(arg) != E_None)
		return FALSE;
	else
	    return TRUE;
}

