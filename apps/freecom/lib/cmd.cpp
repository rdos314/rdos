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
# cmd.cpp
# Command base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "lang.h"
#include "cmd.h"
#include "cmdhelp.h"

#define FALSE 0
#define TRUE !FALSE

int TCommand::ErrorLevel = 0;

/*##########################################################################
#
#   Name       : TArg::TArg
#
#   Purpose....: Constructor for TArg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TArg::TArg(const char *name)
  : FName(name)
{
    ptr = (char *)FName.GetData();
    
    FList = 0;
}

/*##########################################################################
#
#   Name       : TArg::~TArg
#
#   Purpose....: Destructor for TArg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TArg::~TArg()
{
}

/*##########################################################################
#
#   Name       : TCommand::TCommand
#
#   Purpose....: Constructor for command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand::TCommand(TSession *session, const char *param)
  : FCmdLine(param)
{
    FArgList = 0;
    FSession = session;
    FInputFile = 0;
    FOutputFile = 0;
    FErrorFile = 0;

    FRemovePath = 0;
}

/*##########################################################################
#
#   Name       : TCommand::~TCommand
#
#   Purpose....: Destructor for command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand::~TCommand()
{
    TArg *arg;

    arg = FArgList;
    while (arg)
    {
        FArgList = arg->FList;
        delete arg;
        arg = FArgList;
    }
    
    if (FInputFile)
        delete FInputFile;

	if (FOutputFile)
		delete FOutputFile;

	if (FErrorFile)
		delete FErrorFile;

	if (FRemovePath)
	{
		FRemovePath->DeleteFile();
		delete FRemovePath;
	}
}

/*##########################################################################
#
#   Name       : TCommand::IsExit
#
#   Purpose....: Is this an exit command?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::IsExit()
{
    return FALSE;
}

/*##########################################################################
#
#   Name       : TCommand::Command
#
#   Purpose....: Spawn command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::Command()
{
	TSession session(*FSession);
	session.Run();
	return 0;
}

/*##########################################################################
#
#   Name       : TCommand::Command
#
#   Purpose....: Spawn command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::Command(const char *param)
{
	TSession session(*FSession);
	session.Run(param);
	return 0;
}

/*##########################################################################
#
#   Name       : TCommand::RunBatch
#
#   Purpose....: Run batch file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::RunBatch(const char *name)
{
	TSession session(*FSession);
	return session.Run(name, FArgList);
}

/*##########################################################################
#
#   Name       : TCommand::Write
#
#   Purpose....: Write to std output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::Write(char ch)
{
    FSession->Write(ch);
}

/*##########################################################################
#
#   Name       : TCommand::Write
#
#   Purpose....: Write to std output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::Write(const char *str)
{
    FSession->Write(str);
}

/*##########################################################################
#
#   Name       : TCommand::WriteError
#
#   Purpose....: Write to std error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::WriteError(char ch)
{
    FSession->WriteError(ch);
}

/*##########################################################################
#
#   Name       : TCommand::WriteError
#
#   Purpose....: Write to std error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::WriteError(const char *str)
{
    FSession->WriteError(str);
}

/*##########################################################################
#
#   Name       : TCommand::WriteLong
#
#   Purpose....: Write long to std error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::WriteLong(long Value)
{
    FSession->WriteLong(Value);
}

/*##########################################################################
#
#   Name       : TCommand::Read
#
#   Purpose....: Read a single character from std input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TCommand::Read()
{
    return FSession->Read();
}

/*##########################################################################
#
#   Name       : TCommand::Read
#
#   Purpose....: Read a line from std input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::Read(char *str, int maxsize)
{
    return FSession->Read(str, maxsize);
}

/*##########################################################################
#
#   Name       : TCommand::DefineInput
#
#   Purpose....: Define input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::DefineInput(TString &name, int remove)
{
	FInputName = name;
	if (remove)
		FRemovePath = new TPathName(name);
}

/*##########################################################################
#
#   Name       : TCommand::DefineOutput
#
#   Purpose....: Define output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::DefineOutput(TString &name)
{
	FOutputName = name;
}

/*##########################################################################
#
#   Name       : TCommand::DefineError
#
#   Purpose....: Define error file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::DefineError(TString &name)
{
	FErrorName = name;
}

/*##########################################################################
#
#   Name       : TCommand::DefineAppend
#
#   Purpose....: Define append to output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::DefineAppend(TString &name)
{
	FAppendName = name;
}

/*##########################################################################
#
#   Name       : TCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::Run()
{
	char *param;
	char *ptr;
	int size;
	int result;

	size = FCmdLine.GetSize();
	param = new char[size + 1];
	memcpy(param, FCmdLine.GetData(), size + 1);

	ptr = param;

	if (FInputName.GetSize())
	{
		FInputFile = new TFile(FInputName.GetData());
		if (FInputFile->IsOpen())
			FSession->SetInputFile(FInputFile);
	}

	if (FOutputName.GetSize())
	{
		FOutputFile = new TFile(FOutputName.GetData(), 0);
		if (FOutputFile->IsOpen())
			FSession->SetOutputFile(FOutputFile);
	}
	else
	{
		if (FAppendName.GetSize())
		{
			FOutputFile = new TFile(FAppendName.GetData());
			if (FOutputFile->IsOpen())
				FOutputFile->SetPos(FOutputFile->GetSize());
			else
			{
				delete FOutputFile;
				FOutputFile = new TFile(FAppendName.GetData(), 0);
			}

			if (FOutputFile->IsOpen())
				FSession->SetOutputFile(FOutputFile);
		}
	}

	if (FErrorName.GetSize())
	{
		FErrorFile = new TFile(FErrorName.GetData(), 0);
		if (FErrorFile->IsOpen())
			FSession->SetErrorFile(FErrorFile);
	}

	result = Execute(ptr);

	delete param;
	return result;
}

/*##########################################################################
#
#   Name       : TCommand::OptScan
#
#   Purpose....: Default opt-scan method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
	OptError(optstr);
	return 0;
}

/*##########################################################################
#
#   Name       : TCommand::OptError
#
#   Purpose....: Opt error notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::OptError(const char *optstr)
{
	FMsg.printf(TEXT_ERROR_INVALID_LSWITCH, optstr);
	WriteError(FMsg.GetData());
}

/*##########################################################################
#
#   Name       : TCommand::ErrorSyntax
#
#   Purpose....: Syntax error notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::ErrorSyntax(const char *str)
{
	if (str)
		FMsg.printf(TEXT_ERROR_SYNTAX, str);
	else
		FMsg.Load(TEXT_ERROR_SYNTAX);
	WriteError(FMsg.GetData());
}

/*##########################################################################
#
#   Name       : TCommand::OptScanBool
#
#   Purpose....: Opt-scan boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::OptScanBool(const char *optstr, int bool, const char *arg, int *value)
{
	if (arg)
	{
		FMsg.printf(TEXT_ERROR_OPT_ARG, optstr);
		WriteError(FMsg.GetData());
	    return E_Useage;
  	}

	switch (bool)
	{
		case -1:
			*value = 0;
			break;

		case 0:
			*value = !*value;
			break;

		case 1:
			*value = 1;
			break;
	}
  	return 0;
}

/*##########################################################################
#
#   Name       : TCommand::ScanOpt
#
#   Purpose....: Scan option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::ScanOpt(void *ag, char *rest)
{
	char *line, *arg, *optend;
	int ch, bool;

	line = rest;
	if (!IsOptChar(*line))
		return -1;

	line++;
	switch (*line)
	{
		case 0:
			return E_None;

		case '-':
			bool = -1;
			line++;
			break;

  		case '+':
			bool = 1;
			line++;
			break;

		default:
			bool = 0;
			break;

	}

	ch = toupper(*line);
	if (!isprint(ch) || strchr("-+=:", ch))
	{
		OptError(rest);
   		return E_Useage;
	}

	if (ch == '?')
	{
		Write(FHelpScreen.GetData());
  		return E_Help;
	}

	optend = strpbrk(line, "=:");
	if (optend)
		arg = optend + 1;
	else
	{
 		arg = 0;
		optend = strchr(line, 0);
	}

	switch (optend[-1])
	{
		case '-':
			bool = -1;
        	optend--;
 			break;

		case '+':
			bool = 1;
        	optend--;
 			break;
	}

	*optend = 0;
	return OptScan(line, line[1] ? 0 : ch, bool, arg, ag);
}

/*##########################################################################
#
#   Name       : TCommand::LeadOptions
#
#   Purpose....: Scan leading options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::LeadOptions(char **Xline, void *arg)
{ 
	int ec = E_None;
	char *p, *q, *line;

	p = *Xline;
	if(!p)
		p = "";

	while (*(line = SkipDelim(p)))
	{
		p = SkipWord(line);
		q = Unquote(line, p);

		if (IsOptChar(*q))
		{
			ec = ScanOpt(arg, q);
			if (ec != E_None && ec != E_Ignore)
			{
				delete q;
				break;
			}
			else
				delete q;
		}
		else
		{
			delete q;
			break;
		}
	}

	*Xline = line;
	return ec;
}

/*##########################################################################
#
#   Name       : TCommand::ShowCount
#
#   Purpose....: Show count with 3 IDs
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::ShowCount(int BaseId, int count)
{
    switch (count)
    {
        case 0:
            FMsg.Load(BaseId);
            break;
                
	    case 1:
	        FMsg.Load(BaseId + 1);
	        break;
	            
	    default:
	        FMsg.printf(BaseId + 2, count);
	        break;
    }
	Write(FMsg.GetData());        
}

/*##########################################################################
#
#   Name       : TCommand::AddArg
#
#   Purpose....: Add an argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::AddArg(const char *name)
{
    TArg *arg = new TArg(name);
    TArg *curr;

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
#   Name       : TCommand::AddArg
#
#   Purpose....: Add an argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::AddArg(char *sBeg, char **sEnd)
{ 
    char *arg;

    *sEnd = SkipWord(sBeg);
    arg = Unquote(sBeg, *sEnd);
    AddArg(arg);
    delete arg;
}

/*##########################################################################
#
#   Name       : TCommand::Split
#
#   Purpose....: Split line into arguments
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::Split(char *s)
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
#   Name       : TCommand::ParseOptions
#
#   Purpose....: Parse all options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::ParseOptions(void *arg)
{
    TArg *curr;
    TArg *argv;
    char *str;
   	int ec;

    FOptCount = 0;
	FArgCount = 0;

    argv = FArgList;	
	while (argv)
	{
	    str = (char *)argv->FName.GetData();
		if (IsOptChar(*str))
		{
			ec = ScanOpt(arg, str);
			if (ec == E_None)
			{
			    curr = FArgList;
			    if (curr == argv)
			    {
			        FArgList = argv->FList;
			        delete argv;
			    }
			    else
			    {
			        while (curr && curr->FList != argv)
			            curr = curr->FList;

			        if (curr)
			        {
			            curr->FList = argv->FList;
			            delete argv;
			        }
			    }
				FOptCount++;
			}
			else
			{
				if (ec == E_Ignore)
				    FArgCount++;
				else
					return ec;
			}
		}
		else
    	    FArgCount++;
	
		argv = argv->FList;
	}

	return E_None;
}

/*##########################################################################
#
#   Name       : TCommand::ScanCmdLine
#
#   Purpose....: Scan cmd line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::ScanCmdLine(char *line, void *arg)
{
	Split(line);

	if (ParseOptions(arg) != E_None)
		return FALSE;
	else
	    return TRUE;
}

