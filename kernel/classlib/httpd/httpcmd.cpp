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
# httpcmd.cpp
# HTTP Command base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "httpcmd.h"
#include "httpserv.h"

#define FALSE 0
#define TRUE !FALSE

int THttpCommand::ErrorLevel = 0;

/*##########################################################################
#
#   Name       : THttpArg::THttpArg
#
#   Purpose....: Constructor for THttpArg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpArg::THttpArg(const char *name)
  : FName(name)
{
    ptr = (char *)FName.GetData();
    
    FList = 0;
}

/*##########################################################################
#
#   Name       : THttpArg::~THttpArg
#
#   Purpose....: Destructor for THttpArg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpArg::~THttpArg()
{
}

/*##########################################################################
#
#   Name       : THttpCommand::THttpCommand
#
#   Purpose....: Constructor for command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCommand::THttpCommand(THttpSocketServer *Server)
{
    FServer = Server;
    FArgList = 0;
}

/*##########################################################################
#
#   Name       : THttpCommand::THttpCommand
#
#   Purpose....: Constructor for command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCommand::THttpCommand(THttpSocketServer *Server, const char *param)
  : FCmdLine(param)
{
    FServer = Server;
    FArgList = 0;
	FOptCount = 0;
	FOptList = 0;
}

/*##########################################################################
#
#   Name       : THttpCommand::~THttpCommand
#
#   Purpose....: Destructor for command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCommand::~THttpCommand()
{
    THttpArg *arg;
    THttpOption *opt;

    arg = FArgList;
    while (arg)
    {
        FArgList = arg->FList;
        delete arg;
        arg = FArgList;
	}

    opt = FOptList;
    while (opt)
    {
        FOptList = opt->FList;
        delete opt;
        opt = FOptList;
	}
}

/*##########################################################################
#
#   Name       : THttpParser::SkipOptDelim
#
#   Purpose....: Skip to next option delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *THttpCommand::SkipOptDelim(char *p)
{
	int ch, quote;
	int more;

	quote = 0;
	for (;;)
	{
		ch = *p;

		if (!ch)
			break;

		more = !(iscntrl(ch) || ch == ':');

		if (!quote && !more)
			break;

		if (quote == ch)
			quote = 0;
		else
			if (strchr("\"", ch))
				quote = ch;
		p++;
	}
	return p;
}


/*##########################################################################
#
#   Name       : THttpCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::Run()
{
	char *param;
	char *ptr;
	int size;
	THttpArg *arg;
	int ArgCount;
	char *start;
	THttpOption *opt;

    ptr = FServer->ReadLine();
	while (ptr && *ptr != 0)
	{
        start = SkipOptDelim(ptr);
        if (*start == ':')
        {
            *start = 0;
            start++;
			start = (char *)THttpSocketServer::LTrim(start);
			THttpSocketServer::RTrim(start);

			ptr = (char *)THttpSocketServer::LTrim(ptr);
			THttpSocketServer::RTrim(ptr);
            
            AddOpt(ptr, start);
        }
            
	    ptr = FServer->ReadLine();
	}

	size = FCmdLine.GetSize();
	param = new char[size + 1];
	memcpy(param, FCmdLine.GetData(), size + 1);

	if (ScanCmdLine(param, 0))
	{
    	ArgCount = 0;
    	arg = FArgList;
    	while (arg)
	    {
    		ArgCount++;
	    	arg = arg->FList;
    	}

    	if (ArgCount == 2)
    	{
            ptr = (char *)FArgList->FList->FName.GetData();

            FMajor = 0;
            FMinor = 0;
            
            if (!strcmp(ptr, "HTTP/1.0"))
            {
                FMajor = 1;
                FMinor = 0;
            }                
            
            if (!strcmp(ptr, "HTTP/1.1"))
            {
                FMajor = 1;
                FMinor = 1;
            }                
    	
    	    ptr = (char *)FArgList->FName.GetData();
    	    while (*ptr == '/')
    	        ptr++;
        	Execute(ptr);
        }
    }

    opt = FindOption("Accept");

	delete param;
}

/*##########################################################################
#
#   Name       : THttpCommand::FindOption
#
#   Purpose....: Find an option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpOption *THttpCommand::FindOption(const char *name)
{
    THttpOption *curr;
    TString Name(name);

    curr = FOptList;

    while (curr)
    {
        if (curr->FName == Name)
            return curr;
        else
            curr = curr->FList;
    }

    return 0;
}

/*##########################################################################
#
#   Name       : THttpCommand::AddArg
#
#   Purpose....: Add an argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::AddArg(const char *name)
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
#   Name       : THttpCommand::AddArg
#
#   Purpose....: Add an argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::AddArg(char *sBeg, char **sEnd)
{ 
    char *arg;

    *sEnd = SkipWord(sBeg);
    arg = THttpSocketServer::Unquote(sBeg, *sEnd);
    AddArg(arg);
    delete arg;
}

/*##########################################################################
#
#   Name       : THttpCommand::AddOpt
#
#   Purpose....: Add an option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::AddOpt(char *name, char *param)
{
	THttpOption *opt = new THttpOption(name, param);
	THttpOption *curr;

    opt->FList = 0;
	curr = FOptList;
   
	if (curr)
	{
		while (curr->FList)
			curr = curr->FList;

		curr->FList = opt;
	}
	else
		FOptList = opt;    
}

/*##########################################################################
#
#   Name       : THttpCommand::Split
#
#   Purpose....: Split line into arguments
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::Split(char *s)
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
#   Name       : THttpCommand::Parse
#
#   Purpose....: Parse arguments
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpCommand::Parse(void *arg)
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
#   Name       : THttpCommand::ScanCmdLine
#
#   Purpose....: Scan cmd line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpCommand::ScanCmdLine(char *line, void *arg)
{
	Split(line);

	if (Parse(arg) != E_None)
		return FALSE;
	else
	    return TRUE;
}

/*##########################################################################
#
#   Name       : THttpCommand::WriteOption
#
#   Purpose....: Write option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::WriteOption(const char *option, const char *val)
{
    FServer->Write(option);
    FServer->Write(": ");
    FServer->Write(val);
    FServer->Write("\r\n");
}

/*##########################################################################
#
#   Name       : THttpCommand::WriteLongOption
#
#   Purpose....: Write number to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::WriteLongOption(const char *option, long value)
{
	char str[40];

    FServer->Write(option);
    FServer->Write(": ");

    sprintf(str, "%ld", value);
	FServer->Write(str);
    FServer->Write("\r\n");
}

/*##########################################################################
#
#   Name       : THttpCommand::WriteTimeOption
#
#   Purpose....: Write a time option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::WriteTimeOption(const char *option, TDateTime &time)
{
	char str[40];

	FServer->Write(option);
	FServer->Write(": ");

	switch (time.GetDayOfWeek())
	{
		case 0:
			FServer->Write("Sun");
			break;

		case 1:
			FServer->Write("Mon");
			break;

		case 2:
			FServer->Write("Tue");
			break;

		case 3:
			FServer->Write("Wed");
			break;

		case 4:
			FServer->Write("Thu");
			break;

		case 5:
			FServer->Write("Fri");
			break;

		case 6:
			FServer->Write("Sat");
			break;
	}

	sprintf(str, ", %d ", time.GetDay());
	FServer->Write(str);

	switch (time.GetMonth())
	{
		case 1:
			FServer->Write("Jan");
			break;

		case 2:
			FServer->Write("Feb");
			break;

		case 3:
			FServer->Write("Mar");
			break;

		case 4:
			FServer->Write("Apr");
			break;

		case 5:
			FServer->Write("May");
			break;

		case 6:
			FServer->Write("Jun");
			break;

		case 7:
			FServer->Write("Jul");
			break;

		case 8:
			FServer->Write("Aug");
			break;

		case 9:
			FServer->Write("Sep");
			break;

		case 10:
			FServer->Write("Oct");
			break;

		case 11:
			FServer->Write("Nov");
			break;

		case 12:
			FServer->Write("Dec");
			break;
	}

	sprintf(str, " %04d %02d:%02d:%02d GMT",
				time.GetYear(),
			    time.GetHour(),
				time.GetMin(),
				time.GetSec());

	FServer->Write(str);
	FServer->Write("\r\n");
}

/*##########################################################################
#
#   Name       : THttpCommand::GetErrorText
#
#   Purpose....: Get error text for error code
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *THttpCommand::GetErrorText(int ErrorCode)
{
    switch (ErrorCode)
    {
        case 200:
            return "OK";

        case 404:
            return "NOT FOUND";

        default:
            return "UNKNOWN ERROR";
    }
}

/*##########################################################################
#
#   Name       : THttpCommand::WriteStartHeader
#
#   Purpose....: Write start of header
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::WriteStartHeader(int ErrorCode)
{
    char str[80];
    TDateTime CurrTime;

    if (FMajor)
    {
        sprintf(str, "HTTP/%d.%d %d ", FMajor, FMinor, ErrorCode);
        FServer->Write(str);
        FServer->Write(GetErrorText(ErrorCode));
        FServer->Write("\r\n");

        WriteTimeOption("Date", CurrTime);
        WriteOption("Server", "RDOS");
        
    }
}

/*##########################################################################
#
#   Name       : THttpCommand::WriteEndHeader
#
#   Purpose....: Write end of header
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::WriteEndHeader()
{
    FServer->Write("\r\n");
}

/*##########################################################################
#
#   Name       : THttpCommand::WriteError
#
#   Purpose....: Write error msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::WriteError(int ErrorCode)
{
    char str[256];

    sprintf(str, "<html><body><h2>RDOS Webserver</h2>%s (%d)</body></html>",
            GetErrorText(ErrorCode), ErrorCode);
    
    WriteStartHeader(ErrorCode);
    WriteOption("Content-Type", "text/html");
    WriteLongOption("Content-Length", strlen(str));
    WriteEndHeader();
    FServer->Write(str);
}
