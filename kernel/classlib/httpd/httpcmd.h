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
# httpcmd.h
# Http command base class
#
########################################################################*/

#ifndef _HTTPCMD_H
#define _HTTPCMD_H

#include "file.h"
#include "path.h"
#include "httppars.h"
#include "httpserv.h"
#include "httpopt.h"

class THttpArg
{
public:
    THttpArg(const char *name);
    ~THttpArg();

    char *ptr;

    TString FName;
	THttpArg *FList;
};

class THttpCommand : public THttpParser
{
friend class THttpCustomPage;
friend class THttpCustomPageFactory;

public:
	THttpCommand(THttpSocketServer *Server, TString Method, TString Param);
	virtual ~THttpCommand();

	void Run();
	int IsOpen();
	int IsEmpty();
	int IsMSIE();

	static int ErrorLevel;

protected:
    void HandlePost(THttpCustomPage *page, const char *name);
	void GetFile(const char *Name);
	void Get(const char *Name);
    void Post(const char *Name);
	void Execute(const char *Name);

	void AddArg(const char *name);
	void AddArg(char *sBeg, char **sEnd);
	void Split(char *s);
	int Parse(void *arg);
	int ScanCmdLine(char *line, void *arg);

	TDateTime DecodeTime(THttpOption *opt);
	THttpOption *FindOption(const char *name);
	TDateTime GetModifiedSince();

	const char *GetErrorText(int ErrorCode);

	void WriteStartHeader(int ErrorCode);
	void WriteEndHeader();
	void WriteOption(const char *option, const char *val);
	void WriteLongOption(const char *option, long value);
	void WriteTimeOption(const char *option, TDateTime &time);

	void WriteFile(TPathName &path, const char *ContentType);
	void WriteError(int ErrorCode);

	void StartPush();
	int PushFile(TPathName &path, const char *ContentType);

	char *SkipOptDelim(char *p);
	void AddOpt(char *name, char *param);

	THttpCommand *FList;

	THttpArg *FArgList;
	int FArgCount;

	THttpOption *FOptList;
	int FOptCount;

	int FMajor;
	int FMinor;

    TString FUserAgent;
    int FContentSize;
    char *FContentData;

	TString FMethod;
	TString FCmdLine;
	THttpSocketServer *FServer;
};

#endif
