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

#include "langstr.h"
#include "file.h"
#include "path.h"

class TCommand
{
    friend class TCommandLine;
public:
    TCommand(const char *param);
	virtual ~TCommand();

	int DefineInput(const char *name, int remove);
	int DefineOutput(const char *name);
	int DefineAppend(const char *name);
	int DefineError(const char *name);
	
	int Run();
	virtual void InitOptions();
	virtual int Execute(char *param) = 0;

	static int ErrorLevel;

protected:
	virtual int OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg);
	void OptError(const char *optstr);
	void ErrorSyntax(const char *str);

	char *SkipDelim(char *p);
	char *SkipWord(char *p);
	int ScanOpt(void *ag, char *rest);

	int LeadOptions(char **Xline, void *arg);
	int OptScanBool(const char *optstr, int bool, const char *arg, int *value);

	TLangString FMsg;
	TString FCmdLine;
	TLangString FHelpScreen;
	TCommand *FList;

	TFile *FInputFile;
	TFile *FOutputFile;
	TFile *FErrorFile;

    TPathName *FRemovePath;
};

#endif
