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

#include "cmd.h"
#include "lang.h"
#include "env.h"
#include "rdos.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

TFile *FInputFile = new TFile("CON");
TFile *FOutputFile = new TFile("CON");
TCommandFactory *TCommandFactory::FCmdList = 0;
int TCommand::ErrorLevel = 0;

/*##########################################################################
#
#   Name       : SetupInputFile
#
#   Purpose....: Setup input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetInputFile(TFile *File)
{
	if (FInputFile)
		delete FInputFile;

	FInputFile = File;
}

/*##########################################################################
#
#   Name       : SetupOutputFile
#
#   Purpose....: Setup output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetOutputFile(TFile *File)
{
	if (FOutputFile)
		delete FOutputFile;

	FOutputFile = File;
}

/*##########################################################################
#
#   Name       : IsEmpty
#
#   Purpose....: Return true if string is 0 or contains only spaces
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsEmpty(const char *s)
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
#   Name       : IsArgDelim
#
#   Purpose....: Check for argument delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsArgDelim(char ch)
{
	return isspace(ch) || iscntrl(ch) || strchr(",;=", ch);
}

/*##########################################################################
#
#   Name       : IsOptDelim
#
#   Purpose....: Check for option delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsOptDelim(char ch)
{
	return isspace(ch) || iscntrl(ch);
}

/*##########################################################################
#
#   Name       : IsOptChar
#
#   Purpose....: Is option char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsOptChar(char ch)
{
	return ch == '/';
}


/*##########################################################################
#
#   Name       : IsFileNameChar
#
#   Purpose....: Is filename char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsFileNameChar(char c)
{
    return !(c <= ' ' || c == 0x7f || strchr(".\"/\\[]:|<>+=;,", c));
}

/*##########################################################################
#
#   Name       : LTrim
#
#   Purpose....: Remove leading "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *LTrim(const char *str)
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
#   Name       : RTrim
#
#   Purpose....: Remove trailing "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void RTrim(char *str)
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
#   Name       : Unquote
#
#   Purpose....: Unquote to new string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *Unquote(const char *str, const char *end)
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
#   Name       : MatchToken
#
#   Purpose....: Match token at begining of line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int MatchToken(char **Xp, const char *word, int len)
{	
    char *p;
    char *q;

    p = *Xp;
	if (strncmpi(p, word, len) == 0)
	{
		p += len;
		if (*p)
		{
			q = (char *)LTrim(p);
			if (q == p)
				return FALSE;
			p = q;
		}
		*Xp = p;
		return TRUE;
	}

	return FALSE;
}

/*##########################################################################
#
#   Name       : Write
#
#   Purpose....: Write character to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void Write(char ch)
{
	char str[2];

	str[0] = ch;
	str[1] = 0;

	if (FOutputFile)
		FOutputFile->Write(str, 1);
}

/*##########################################################################
#
#   Name       : Write
#
#   Purpose....: Write string to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void Write(const char *str)
{
	int size = strlen(str);

	if (FOutputFile)
		FOutputFile->Write(str, size);
}

/*##########################################################################
#
#   Name       : WriteError
#
#   Purpose....: Write character to standard error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void WriteError(char ch)
{
	char str[2];

	str[0] = ch;
	str[1] = 0;

	if (FOutputFile)
		FOutputFile->Write(str, 1);
}

/*##########################################################################
#
#   Name       : WriteError
#
#   Purpose....: Write string to standard error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void WriteError(const char *str)
{
	int size = strlen(str);

	if (FOutputFile)
		FOutputFile->Write(str, size);
}

/*##########################################################################
#
#   Name       : Read
#
#   Purpose....: Read a character from standard input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char Read()
{
	char ch = 3;

	if (FInputFile)
		FInputFile->Read(&ch, 1);

	return ch;
}

/*##########################################################################
#
#   Name       : Read
#
#   Purpose....: Read a string from standard input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int Read(char *str, int maxsize)
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

			if (ch == 0 || ch == 0xa)
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

/*################## FormatTime ##########################
*   Purpose....: Format time			   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
TString FormatTime(TDateTime &time)
{
	char str[40];
	sprintf(str, "%02d.%02d.%02d,%03d", time.GetHour(), time.GetMin(), time.GetSec(), time.GetMilliSec());
	return TString(str);
}

/*################## FormatLongDate ##########################
*   Purpose....: Format long date		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
TString FormatLongDate(TDateTime &date)
{
	char str[40];
	sprintf(str, "%04d-%02d-%02d", date.GetYear(), date.GetMonth(), date.GetDay());
	return TString(str);
}

/*################## DisplayPrompt ##########################
*   Purpose....: Display prompt for user	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void DisplayPrompt()
{
	char promptstr[128];
	char *pr;
	TString str;
	TPathName path("");

	TEnv *env = TEnv::OpenProcessEnv();
	if (!env->Find("PROMPT", promptstr))
		strcpy(promptstr, "$p$g");

	pr = promptstr;

	while (*pr)
	{
		if (*pr != '$')
			WriteChar(*pr);
		else
		{
			switch (toupper(*++pr))
            {
                case 'Q':
                    Write('=');
                    break;
            
                case '$':
                    Write('$');
                    break;

                case 'T':
                    str = FormatTime(TDateTime());            
                    Write(str.GetData());
                    break;

				case 'D':
					str = FormatLongDate(TDateTime());
					Write(str.GetData());
					break;

				case 'P':
					str = path.GetFullPathName();
                    str.Lower();
					Write(str.GetData());
					break;

                case 'V':
                    Write("command");
                    break;
                    
                case 'N':
                    Write(RdosGetCurDrive() + 'A');
                    break;
                    
                case 'G':
                    Write('>');
					break;

                case 'L':
                    Write('<');
                    break;

                case 'B':
                    Write('|');
                    break;
                    
                case '_':
                    Write('\n');
                    break;
                    
                case 'E':
                    Write(27);
                    break;
                    
                case 'H':
                    Write(8);
                    break;

            }
        }
        pr++;
    }
}

/*##########################################################################
#
#   Name       : TCommandFactory::TCommandFactory
#
#   Purpose....: Constructor for command factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommandFactory::TCommandFactory(const char *name)
  : FName(name)
{	
	InsertCommand();
}

/*##########################################################################
#
#   Name       : TCommandFactor::~TCommandFactor
#
#   Purpose....: Destructor for command factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommandFactory::~TCommandFactory()
{	
	RemoveCommand();
}

/*##################  TCommandFactory::InsertCommand  ##########################
*   Purpose....: Insert device into command list                           #
*				 Should only be done in constructor							#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TCommandFactory::InsertCommand()
{
	FList = FCmdList;
	FCmdList = this;
}

/*##################  TCommandFactory::RemoveCommand  ##########################
*   Purpose....: Remove device from command list                           #
*				 Should only done in destructor								#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TCommandFactory::RemoveCommand()
{
	TCommandFactory *ptr;
	TCommandFactory *prev;
	prev = 0;

	ptr = FCmdList;
	while ((ptr != 0) && (ptr != this))
    {
		prev = ptr;
		ptr = ptr->FList;
    }
	if (prev == 0)
		FCmdList = FCmdList->FList;
	else
		prev->FList = ptr->FList;
}

/*##################  TCommandFactory::PassAll  ##########################
*   Purpose....: Pass all characters to commandline                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
int TCommandFactory::PassAll()
{
    return FALSE;
}

/*##################  TCommandFactory::PassDir  ##########################
*   Purpose....: Pass dir characters to commandline                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
int TCommandFactory::PassDir()
{
    return FALSE;
}

/*##################  TCommandFactory::FindArg  ##########################
*   Purpose....: Find argument to batch-file                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
const char *TCommandFactory::FindArg(int no)
{
    return 0;
}

/*##################  TCommandFactory::ExpandEnv  ##########################
*   Purpose....: Parse environment variables in command line                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
TString TCommandFactory::ExpandEnv(TString &line)
{
	char *tp;
	char *ip;
    TString cp;
    int ok;

	ip = (char *)line.GetData();

    while (*ip)
    {
        if (*ip == '%')
        {
            ip++;
            
            switch (*ip)
            {
                case 0:
                    cp.Append('%');
					break;

				case '%':
					cp.Append('%');
					ip++;
					break;

				case '0':
				case '1':
				case '2':
				case '3':
				case '4':
				case '5':
				case '6':
				case '7':
				case '8':
				case '9':
					tp = (char *)FindArg(*ip - '0');
		            if (tp)
					{
						cp.Append(*tp);
						ip++;
			        }
			        else
			            cp.Append('%');
                    break;

                default:
                    tp = strchr(ip, '%');
					if (tp)
        			{
        			    TEnv *env = TEnv::OpenProcessEnv();
        				char *eval = new char[256];
			            *tp = 0;

                        ok = env->Find(ip, eval);
                        if (!ok)
                        {
                            strupr(ip);
                            ok = env->Find(ip, eval);                        
                        }

                        if (ok)
                            cp.Append(eval);
			            else
			            {
							if (MatchToken(&ip, "ERRORLEVEL", 10))
							{
								sprintf(eval, "%u", TCommand::ErrorLevel);
								cp.Append(eval);
							}
							else
			                {
								if (MatchToken(&ip, "_CWD", 4))
			                    {
			                        cp.Append(RdosGetCurDrive() + 'A');
			                        cp.Append(":\\");
			                        *eval = 0;
			                        RdosGetCurDir(RdosGetCurDrive(), eval); 
                    				cp.Append(eval);
			                    }
			                }
			            }
			            delete eval;
                        ip = tp + 1;
			        }
			        break;
		    }
        }
        else
        {
            cp.Append(*ip);
            ip++;
        }
	}
	return cp;
}

/*##################  TCommandFactory::Parse  ##########################
*   Purpose....: Parse a command line and return a command class	    	#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
TCommand *TCommandFactory::Parse(const char *line)
{
	const char *rest;
	int size;
    int i;
	char *com;
	char *ptr;
    int done;
    TString Line;
    TCommandFactory *factory = 0;

	Line = TString(LTrim(line));

	Line = ExpandEnv(Line);
	
	rest = Line.GetData();

	if (*rest)
	{
    	size = 0;
		while (*rest && IsFileNameChar(*rest) && !strchr("\"", *rest))
		{
			size++;
			rest++;
		}

		if (*rest && strchr("\"", *rest))
			size = 0;

		if (size)
		{

	    	com = new char[size + 1];

            rest = Line.GetData();
            ptr = com;
            
	    	for (i = 0; i < size; i++)
	    	{
                *ptr = toupper(*rest);
                ptr++;
                rest++;
            }
            *ptr = 0;
    		
        	factory = FCmdList;
        	while (factory)
        	{
                if (!strcmp(factory->FName.GetData(), com))
                    break;
                
        		factory = factory->FList;
        	}

            delete com;
        }    
    }

    if (factory) 
    {
        done = factory->PassAll();

        if (!done && factory->PassDir())
            done = *rest == '\\' || *rest == '.' || *rest == ':';

        if (!done)
            done = (!*rest || *rest == '/');

        if (!done)
            if (IsArgDelim(*rest))
			    rest = LTrim(rest);

	    return factory->Create(rest);
	    
	}
	else
	{
        TLangString msg;

        msg.printf(TEXT_ERROR_SYNTAX, line);
    	WriteError(msg.GetData());
    	
        return 0;
    }
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
