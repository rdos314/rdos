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

#ifndef _HTTPCUST_H
#define _HTTPCUST_H

#include "file.h"
#include "path.h"

class THttpCommand;
class THttpSocketServer;
class THttpSocketServerFactory;

class THttpCustomPage
{
friend class THttpCustomPageFactory;
friend class THttpCustomDirFactory;
friend class THttpCommand;

public:
	THttpCustomPage(THttpCommand *Cmd, const char *FileName, const char *Param);
	virtual ~THttpCustomPage();

protected:
	virtual void Get(const char *Name);
	virtual void Post(const char *Name);
	virtual void Post(const char *Var, const char *Val);

	void WriteError(int ErrorCode);
	void WriteFile(TPathName &path, const char *ContentType);
	void StartPush();
	int PushFile(TPathName &path, const char *ContentType, int ReloadTimeout);

	THttpCommand *FCmd;
	TString FFileName;
	TString FParam;
};

class THttpCustomPageFactory
{
friend class THttpSocketServer;
friend class THttpSocketServerFactory;

public:
	THttpCustomPageFactory(const char *ReqName);
	virtual ~THttpCustomPageFactory();

	virtual THttpCustomPage *Create(THttpCommand *cmd, const char *Param);

	TString FReqName;

protected:
    TString CreateUniqueFile(THttpCommand *Cmd);

	THttpCustomPageFactory *FList;
	THttpCommand *FCmd;
};

class THttpCustomDirFactory
{
friend class THttpSocketServer;
friend class THttpSocketServerFactory;

public:
	THttpCustomDirFactory(const char *ReqName);
	virtual ~THttpCustomDirFactory();

	virtual THttpCustomPage *Create(THttpCommand *cmd, const char *Param);

	TString FReqName;

protected:
    TString CreateUniqueFile(THttpCommand *Cmd);

	THttpCustomDirFactory *FList;
	THttpCommand *FCmd;
};

#endif

