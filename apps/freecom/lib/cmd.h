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
# cmd.h
# Command base class
#
########################################################################*/

#ifndef _CMD_H
#define _CMD_H

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

class TCommand
{
public:
    TCommand(const char *param);
	virtual ~TCommand();

	static void SetInputFile(TFile *File);
	static void SetOutputFile(TFile *File);

	int Run();
	virtual int Execute(char *param) = 0;

protected:
	virtual int OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg);
	void OptError(const char *optstr);
	void ErrorSyntax(const char *str);

	char *SkipDelim(char *p);
	char *SkipWord(char *p);
	int IsOptChar(char ch);
	int ScanOpt(void *ag, char *rest);

	int LeadOptions(char **Xline, void *arg);
	int OptScanBool(const char *optstr, int bool, const char *arg, int *value);

	int IsEmpty(const char *s);
	int IsArgDelim(char ch);
	int IsOptDelim(char ch);
	char *LTrim(char *str);
	void RTrim(char *str);
	char *Unquote(const char *str, const char *end);

	static void Write(char ch);
	static void Write(const char *str);

	static void WriteError(char ch);
	static void WriteError(const char *str);

	static char Read();
	static int Read(char *str, int maxsize);

	TLangString FMsg;
	TString FCmdLine;
	TLangString FHelpScreen;

	static TFile *FInputFile;
	static TFile *FOutputFile;
};

class TCommandFactory
{
public:
    TCommandFactory(const char *name);
	virtual ~TCommandFactory();

	virtual TCommand *Create(const char *param) = 0;

protected:
	void InsertCommand();
	void RemoveCommand();

	static TCommandFactory *FCmdList;
	TCommandFactory *FList;
	TString FName;
};

#endif
