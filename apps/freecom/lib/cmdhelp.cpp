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
# cmdhelp.cpp
# Command help base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "file.h"

#define FALSE 0
#define TRUE !FALSE

TFile *FInputFile = new TFile("CON");
TFile *FOutputFile = new TFile("CON");
TFile *FErrorFile = new TFile("CON");

/*##########################################################################
#
#   Name       : SetInputFile
#
#   Purpose....: Set input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetInputFile(TFile *File)
{
	FInputFile = File;
}

/*##########################################################################
#
#   Name       : SetOutputFile
#
#   Purpose....: Set output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetOutputFile(TFile *File)
{
	FOutputFile = File;
}

/*##########################################################################
#
#   Name       : SetErrorFile
#
#   Purpose....: Set error file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetErrorFile(TFile *File)
{
	FErrorFile = File;
}

/*##########################################################################
#
#   Name       : GetInputFile
#
#   Purpose....: Get input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *GetInputFile()
{
	return FInputFile;
}

/*##########################################################################
#
#   Name       : GetOutputFile
#
#   Purpose....: Get output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *GetOutputFile()
{
	return FOutputFile;
}

/*##########################################################################
#
#   Name       : GetErrorFile
#
#   Purpose....: Get error file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *GetErrorFile()
{
	return FErrorFile;
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
