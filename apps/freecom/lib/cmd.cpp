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

#include "cmd.h"
#include "lang.h"

#define FALSE 0
#define TRUE !FALSE

TFile *TCommand::FInputFile = new TFile("CON");
TFile *TCommand::FOutputFile = new TFile("CON");

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
TCommand::TCommand(const char *param)
  : FCmdLine(param)
{
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
}

/*##########################################################################
#
#   Name       : TCommand::SetupInputFile
#
#   Purpose....: Setup input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::SetInputFile(TFile *File)
{
	if (FInputFile)
		delete FInputFile;

	FInputFile = File;
}

/*##########################################################################
#
#   Name       : TCommand::SetupOutputFile
#
#   Purpose....: Setup output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::SetOutputFile(TFile *File)
{
	if (FOutputFile)
		delete FOutputFile;

	FOutputFile = File;
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
	int size;
    int result;

	size = FCmdLine.GetSize();
	param = new char[size + 1];
	memcpy(param, FCmdLine.GetData(), size + 1);

	result = Execute(param);

	delete param;
	return result;
}

/*##########################################################################
#
#   Name       : TCommand::IsEmpty
#
#   Purpose....: Return true if string is 0 or contains only spaces
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::IsEmpty(const char *s)
{
	if (s)
	{
		while(*s)
		{
			s++;
			if (!isspace(*s))
				return FALSE;
		}
	}
	return TRUE;
}

/*##########################################################################
#
#   Name       : TCommand::IsArgDelim
#
#   Purpose....: Check for argument delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::IsArgDelim(char ch)
{
	return isspace(ch) || iscntrl(ch) || strchr(",;=", ch);
}

/*##########################################################################
#
#   Name       : TCommand::IsOptDelim
#
#   Purpose....: Check for option delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::IsOptDelim(char ch)
{
	return isspace(ch) || iscntrl(ch);
}

/*##########################################################################
#
#   Name       : TCommand::LTrim
#
#   Purpose....: Remove leading "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TCommand::LTrim(char *str)
{
	while (*str)
	{
		if (IsArgDelim(*str))
			str++;
		else
			break;
	}
	return str;
}

/*##########################################################################
#
#   Name       : TCommand::RTrim
#
#   Purpose....: Remove trailing "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::RTrim(char *str)
{ 
	char *p;

	p = strchr(str, 0);
	p--;

	while (p >= str && IsArgDelim(*p))
		p--;

	p[1] = 0;
}

/*##########################################################################
#
#   Name       : TCommand::Unquote
#
#   Purpose....: Unquote to new string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TCommand::Unquote(const char *str, const char *end)
{
	char *h, *newStr;
	const char *q;
	int len;

	newStr = new char[end - str + 1];
	h = newStr;

	while ((q = strpbrk(str, "\"")) != 0 && q < end)
	{
		memcpy(h, str, len = q++ - str);
		h += len;
		if ((str = strchr(q, q[-1])) == 0 || str >= end)
		{
			str = q;
			break;
		}

		memcpy(h, q, len = str++ - q);
		h += len;
	}

	memcpy(h, str, len = end - str);
	h[len] = 0;
	return newStr;
}

/*##########################################################################
#
#   Name       : TCommand::Write
#
#   Purpose....: Write character to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::Write(char ch)
{
	char str[2];

	str[0] = ch;
	str[1] = 0;

	if (FOutputFile)
		FOutputFile->Write(str, 1);
}

/*##########################################################################
#
#   Name       : TCommand::Write
#
#   Purpose....: Write string to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::Write(const char *str)
{
	int size = strlen(str);

	if (FOutputFile)
		FOutputFile->Write(str, size);
}

/*##########################################################################
#
#   Name       : TCommand::WriteError
#
#   Purpose....: Write character to standard error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::WriteError(char ch)
{
	char str[2];

	str[0] = ch;
	str[1] = 0;

	if (FOutputFile)
		FOutputFile->Write(str, 1);
}

/*##########################################################################
#
#   Name       : TCommand::WriteError
#
#   Purpose....: Write string to standard error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::WriteError(const char *str)
{
	int size = strlen(str);

	if (FOutputFile)
		FOutputFile->Write(str, size);
}

/*##########################################################################
#
#   Name       : TCommand::Read
#
#   Purpose....: Read a character from standard input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TCommand::Read()
{
	char ch = 3;

	if (FInputFile)
		FInputFile->Read(&ch, 1);

	return ch;
}

/*##########################################################################
#
#   Name       : TCommand::Read
#
#   Purpose....: Read a string from standard input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::Read(char *str, int maxsize)
{
	char ch;
	int i;

	if (FInputFile)
	{
		for (i = 0; i < maxsize; i++)
		{
			ch = 0;
			FInputFile->Read(&ch, 1);

			if (ch == 3)
				return FALSE;

			if (ch == 0 || ch == 0xd || ch == 0xa)
			{
				*str = 0;
				break;
			}
			else
			{
				*str = ch;
				str++;
			}
		}
		*str = 0;
		return TRUE;
	}
	return FALSE;
}

/*##########################################################################
#
#   Name       : TCommand::IsOptChar
#
#   Purpose....: Is option char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::IsOptChar(char ch)
{
	return ch == '/';
}

/*##########################################################################
#
#   Name       : TCommand::SkipWord
#
#   Purpose....: Skip to next word
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TCommand::SkipWord(char *p)
{
	int ch, quote;
	int isopt;
	int more;

	isopt = IsOptChar(*p);
	if (isopt)
	{
		p++;
		while (*p && IsOptChar(*p))
			p++;
	}

	quote = 0;
	for (;;)
	{
		ch = *p;
		if (!ch)
			break;

		if (isopt)
			more = !IsOptDelim(ch) || IsOptChar(ch);
		else
			more = !IsArgDelim(ch) || IsOptChar(ch);

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
#   Name       : TCommand::SkipDelim
#
#   Purpose....: Skip to next delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TCommand::SkipDelim(char *p)
{
	int ch, quote;
	int isopt;
	int more;

	isopt = IsOptChar(*p);
	quote = 0;
	for (;;)
	{
		ch = *p;

		if (!ch)
			break;

		if (isopt)
			more = IsOptDelim(ch);
		else
			more = IsArgDelim(ch);

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
