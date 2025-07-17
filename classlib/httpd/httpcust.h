/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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
#include "strlist.h"

class THttpParam;
class THttpCommand;
class THttpSocketServer;
class THttpSocketServerFactory;

class THttpCustomPage
{
friend class THttpCustomPageFactory;
friend class THttpCustomDirFactory;
friend class THttpCommand;

public:
	THttpCustomPage(THttpCommand *Cmd);
	virtual ~THttpCustomPage();

protected:
    const char *GetUser();

	virtual void Get(const char *MatchName, const char *UrlName, THttpParam *Param);
	virtual void Post(const char *MatchName, const char *UrlName, THttpParam *Param);
	virtual void Post(const char *Var, const char *Val);

	void WriteError(int ErrorCode);
	void WriteFile(TPathName &path, const char *ContentType);
	void StartPush();
	int PushFile(TPathName &path, const char *ContentType, int ReloadTimeout);

    void Write(const char *str);
    void SendData(const char *ContentType);

	THttpCommand *FCmd;

	TString FData;
};

class THttpCustomPageFactory
{
friend class THttpSocketServer;
friend class THttpServerFactory;

public:
	THttpCustomPageFactory(const char *ReqName);
	virtual ~THttpCustomPageFactory();
	
	virtual THttpCustomPage *Create(THttpCommand *cmd);

    void AddName(const char *ReqName);

	TStringList FReqNameList;

protected:
	THttpCustomPageFactory *FList;
	THttpCommand *FCmd;
};

class THttpCustomDirFactory
{
friend class THttpSocketServer;
friend class THttpServerFactory;

public:
	THttpCustomDirFactory(const char *ReqName);
	virtual ~THttpCustomDirFactory();

	virtual THttpCustomPage *Create(THttpCommand *cmd);

    void AddName(const char *ReqName);

	TStringList FReqNameList;

protected:
	THttpCustomDirFactory *FList;
	THttpCommand *FCmd;
};

#endif

