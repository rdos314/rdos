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
#   Name       : THttpOption::GetArgCount
#
#   Purpose....: Get argument count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpOption::GetArgCount()
{
    return FArgCount;
}

/*##########################################################################
#
#   Name       : THttpOption::GetArg
#
#   Purpose....: Get argument 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString THttpOption::GetArg(int n)
{
    int i;
    THttpArg *arg = FArgList;

    for (i = 0; i < n && arg; i++)
        arg = arg->FList;

    if (arg)
        return arg->FName;
    else
        return "";
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
    char *tempstr;

    *sEnd = SkipWord(sBeg);
    arg = THttpSocketServer::Unquote(sBeg, *sEnd);
    tempstr = (char *)THttpCommand::LTrim(arg);
    THttpCommand::RTrim(tempstr);
    AddArg(tempstr);
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
