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

#include <string.h>

#include "rdos.h"
#include "cmdhelp.h"
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
	TCommand *cmd;
	const char *ptr;
	TString str;
	char ch;
	const char *p;

	FList = 0;
	FRemoveInput = FALSE;

	ptr = line;

	while (*ptr)
	{
		ch = *ptr;

		switch (ch)
		{
			case '"':
            case '\'':
				p = strchr(ptr, ch);
                if (p == 0)
                {
                    str.Append(ptr);
                    ptr = ptr + strlen(ptr) - 1;
                }
                else
                {
                    while (p >= ptr)
					{
						str.Append(*ptr);
						ptr++;
					}
				}
				break;

			case '<':
				ptr = RedirInput(ptr + 1);
				break;

			case '>':
				if (*(ptr+1) == '>')
					ptr = RedirAppend(ptr + 2);
				else
					ptr = RedirOutput(ptr + 1);
				break;

			case '|':
				Pipe(str);
				ptr++;
				str = "";
				break;

			case 0xa:
			case 0xd:
				ptr++;
				break;

			default:
				str.Append(*ptr);
				ptr++;
				break;
		}
	}

	Add(str);
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
#   Name       : TCommandLine::IsRedir
#
#   Purpose....: Is redirection char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommandLine::IsRedir(char ch)
{
	return ch == '>' || ch == '<' || ch == '|';
}

/*##########################################################################
#
#   Name       : TCommandLine::InsertLast
#
#   Purpose....: Insert command last
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommandLine::InsertLast(TCommand *cmd)
{
    TCommand *curr;

    cmd->FList = 0;
	curr = FList;
   
	if (curr)
	{
		while (curr->FList)
			curr = curr->FList;

		curr->FList = cmd;
	}
	else
		FList = cmd;
}

/*##########################################################################
#
#   Name       : TCommandLine::RedirInput
#
#   Purpose....: Redirect input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TCommandLine::RedirInput(const char *line)
{
	const char *ptr;

	FInputFile = "";

	ptr = LTrim(line);
	while (*ptr && !IsRedir(*ptr) && !IsArgDelim(*ptr))
	{
		FInputFile.Append(*ptr);
		ptr++;
	}
	return ptr;
}

/*##########################################################################
#
#   Name       : TCommandLine::RedirOutput
#
#   Purpose....: Redirect output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TCommandLine::RedirOutput(const char *line)
{
	const char *ptr;

	FOutputFile = "";
	FAppendFile = "";

	ptr = LTrim(line);
	while (*ptr && !IsRedir(*ptr) && !IsArgDelim(*ptr))
	{
		FOutputFile.Append(*ptr);
		ptr++;
	}
	return ptr;
}

/*##########################################################################
#
#   Name       : TCommandLine::RedirAppend
#
#   Purpose....: Redirect append
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TCommandLine::RedirAppend(const char *line)
{
	const char *ptr;

	FOutputFile = "";
	FAppendFile = "";

	ptr = LTrim(line);
	while (*ptr && !IsRedir(*ptr) && !IsArgDelim(*ptr))
	{
		FAppendFile.Append(*ptr);
		ptr++;
	}
	return ptr;
}

/*##########################################################################
#
#   Name       : TCommandLine::Pipe
#
#   Purpose....: Pipe
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommandLine::Pipe(TString &str)
{
	FOutputFile.printf("z:\\%04hX.tmp", RdosGetThreadHandle());
	Add(str);
	FInputFile = FOutputFile;
	FRemoveInput = TRUE;
	FOutputFile = "";
	FAppendFile = "";
}

/*##########################################################################
#
#   Name       : TCommandLine::Add
#
#   Purpose....: Add rest of command line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommandLine::Add(TString &str)
{
	const char *ptr;
	TCommand *cmd;

	ptr = LTrim(str.GetData());
	if (*ptr)
	{
		cmd = TCommandFactory::Parse(ptr);
		if (cmd)
		{
			if (FInputFile.GetSize())
				cmd->DefineInput(FInputFile, FRemoveInput);

			if (FOutputFile.GetSize())
				cmd->DefineOutput(FOutputFile);

			if (FAppendFile.GetSize())
				cmd->DefineAppend(FAppendFile);

			InsertLast(cmd);
		}
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
    TFile *PrevInput = GetInputFile();
    TFile *PrevOutput = GetOutputFile();
    TFile *PrevError = GetErrorFile();

	if (FList)
	{
		cmd = FList;
		while (cmd && result == 0)
		{
			result = cmd->Run();
			cmd = cmd->FList;

			SetInputFile(PrevInput);
			SetOutputFile(PrevOutput);
			SetErrorFile(PrevError);
		}
		Write("\r\n");
	}
	return result;
}
