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
# session.cpp
# Session class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "session.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TSession::TSession
#
#   Purpose....: Session constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSession::TSession()
{
    FCmdFile = new TFile("CON");
    FInputFile = new TFile("CON");
    FOutputFile = new TFile("CON");
    FErrorFile = new TFile("CON");
}

/*##########################################################################
#
#   Name       : TSession::SetCmdFile
#
#   Purpose....: Set cmd file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::SetCmdFile(TFile *File)
{
	FCmdFile = File;
}

/*##########################################################################
#
#   Name       : TSession::SetInputFile
#
#   Purpose....: Set input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::SetInputFile(TFile *File)
{
	FInputFile = File;
}

/*##########################################################################
#
#   Name       : TSession::SetOutputFile
#
#   Purpose....: Set output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::SetOutputFile(TFile *File)
{
	FOutputFile = File;
}

/*##########################################################################
#
#   Name       : TSession::SetErrorFile
#
#   Purpose....: Set error file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::SetErrorFile(TFile *File)
{
	FErrorFile = File;
}

/*##########################################################################
#
#   Name       : GetCmdFile
#
#   Purpose....: Get cmd file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TSession::GetCmdFile()
{
	return FCmdFile;
}

/*##########################################################################
#
#   Name       : TSession::GetInputFile
#
#   Purpose....: Get input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TSession::GetInputFile()
{
	return FInputFile;
}

/*##########################################################################
#
#   Name       : TSession::GetOutputFile
#
#   Purpose....: Get output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TSession::GetOutputFile()
{
	return FOutputFile;
}

/*##########################################################################
#
#   Name       : TSession::GetErrorFile
#
#   Purpose....: Get error file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TSession::GetErrorFile()
{
	return FErrorFile;
}

/*##########################################################################
#
#   Name       : TSession::Write
#
#   Purpose....: Write character to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::Write(char ch)
{
	char str[2];

	str[0] = ch;
	str[1] = 0;

	if (FOutputFile)
		FOutputFile->Write(str, 1);
}

/*##########################################################################
#
#   Name       : TSession::Write
#
#   Purpose....: Write string to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::Write(const char *str)
{
	int size = strlen(str);

	if (FOutputFile)
		FOutputFile->Write(str, size);
}

/*##########################################################################
#
#   Name       : TSession::WriteError
#
#   Purpose....: Write character to standard error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::WriteError(char ch)
{
	char str[2];

	str[0] = ch;
	str[1] = 0;

	if (FOutputFile)
		FOutputFile->Write(str, 1);
}

/*##########################################################################
#
#   Name       : TSession::WriteError
#
#   Purpose....: Write string to standard error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::WriteError(const char *str)
{
	int size = strlen(str);

	if (FOutputFile)
		FOutputFile->Write(str, size);
}

/*##########################################################################
#
#   Name       : TSession::WriteNumber
#
#   Purpose....: Write number to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::WriteLong(long value)
{
	char str[4];
	int tmp;
	int use = FALSE;

	tmp = value / 1000000000;
	if (tmp)
	{
		use = TRUE;
		sprintf(str, "%2d", tmp);
	}
	else
		strcpy(str, "  ");
	Write(str);
	Write(" ");
	value = value % 1000000000;

	tmp = value / 1000000;
	if (use)
		sprintf(str, "%03d", tmp);
	else
	{
		if (tmp)
		{
			use = TRUE;
			sprintf(str, "%3d", tmp);
		}
		else
			strcpy(str, "   ");
	}
	Write(str);
	Write(" ");
	value = value % 1000000;

	tmp = value / 1000;
	if (use)
		sprintf(str, "%03d", tmp);
	else
	{
		if (tmp)
		{
			use = TRUE;
			sprintf(str, "%3d", tmp);
		}
		else
			strcpy(str, "   ");
	}
	Write(str);
	Write(" ");
	value = value % 1000;

	tmp = value;
	if (use)
		sprintf(str, "%03d", tmp);
	else
		sprintf(str, "%3d", tmp);
	Write(str);
}

/*##########################################################################
#
#   Name       : TSession::Read
#
#   Purpose....: Read a character from standard input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TSession::Read()
{
	char ch = 3;

	if (FInputFile)
		FInputFile->Read(&ch, 1);

	return ch;
}

/*##########################################################################
#
#   Name       : TSession::ReadCmd
#
#   Purpose....: Read a string from cmd input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSession::ReadCmd(char *str, int maxsize)
{
	char ch;
	int i;

	if (FCmdFile->IsDevice())
	    return ReadCon(str, maxsize);
	else
	{
		for (i = 0; i < maxsize; i++)
		{
			ch = 0;
			FCmdFile->Read(&ch, 1);

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
}

/*##########################################################################
#
#   Name       : TSession::Read
#
#   Purpose....: Read a string from standard input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSession::Read(char *str, int maxsize)
{
	char ch;
	int i;

	if (FInputFile->IsDevice())
	    return ReadCon(str, maxsize);
	else
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
}
