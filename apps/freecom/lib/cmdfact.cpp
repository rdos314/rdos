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
# cmdfact.cpp
# Command factory base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "cmd.h"
#include "cmdfact.h"
#include "path.h"
#include "env.h"
#include "setdrive.h"
#include "exec.h"

#define FALSE 0
#define TRUE !FALSE

TCommandFactory *TCommandFactory::FCmdList = 0;

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
			Write(*pr);
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
	delete env;
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
						delete env;
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
	TCommand *cmd;

	Line = TString(LTrim(line));

	Line = ExpandEnv(Line);

	rest = Line.GetData();

	if (strlen(rest) == 2)
		if (rest[1] == ':' && isalpha(*rest))
		{
			cmd = new TSetDriveCommand(rest);
			return cmd;
		}

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

            if (*com == '@')
                factory = 0;
            else
            {
    			factory = FCmdList;
	    		while (factory)
		    	{
    				if (!strcmp(factory->FName.GetData(), com))
	    				break;

		    		factory = factory->FList;
			    }
			 }

			if (!factory)
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
		cmd = new TExecCommand(line);
		return cmd;
	}
}
