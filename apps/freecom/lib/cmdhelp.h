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
# cmdhelp.h
# Command base class
#
########################################################################*/

#ifndef _CMDHELP_H
#define _CMDHELP_H

#include "file.h"
#include "langstr.h"

enum InternalErrorCodes
{
	E_None = 0,
	E_Useage = 1,
	E_Other = 2,
	E_CBreak = 3,
	E_NoMem,
	E_CorruptMemory,
	E_NoOption,
	E_Exit,
	E_Ignore,			/* Error that can be ignored */
	E_Empty,
	E_Syntax,
	E_Range,				/* Numbers out of range */
	E_NoItems,
	E_Help,		/* Help screen */
	E_User		/* MUST be the last one */
};

void SetInputFile(TFile *File);
void SetOutputFile(TFile *File);
void SetErrorFile(TFile *File);

TFile *GetInputFile();
TFile *GetOutputFile();
TFile *GetErrorFile();

int IsEmpty(const char *s);
int IsArgDelim(char ch);
int IsOptDelim(char ch);
int IsOptChar(char ch);
int IsFileNameChar(char c);
const char *LTrimsp(const char *str);
const char *LTrim(const char *str);
void RTrim(char *str);
char *Unquote(const char *str, const char *end);
int MatchToken(char **Xp, const char *word, int len);

void Write(char ch);
void Write(const char *str);

void WriteError(char ch);
void WriteError(const char *str);

void WriteLong(long Value);

char Read();
int Read(char *str, int maxsize);
int ReadCmd(char *str, int maxsize);

void DisplayPrompt();

#endif
