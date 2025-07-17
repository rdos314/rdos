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

class THttpParam
{
public:
    THttpParam(const char *name, const char *value);
    ~THttpParam();

    const char *GetParam(const char *Name);

    TString FName;
    TString FValue;
    THttpParam *FList;
};

class THttpCommand : public THttpParser
{
friend class THttpCustomPage;
friend class THttpCustomPageFactory;
friend class THttpCustomDirFactory;

public:
    THttpCommand(THttpSocketServer *Server, TString Method, TString Param);
    virtual ~THttpCommand();

    void Run();
    int IsOpen();
    int IsEmpty();
    int IsMSIE();

    THttpOption *FindOption(const char *name);
    void WriteError(int ErrorCode);

    void WriteStartHeader(int ErrorCode);
    void WriteEndHeader();
    void WriteOption(const char *option, const char *val);
    void WriteLongOption(const char *option, long value);
    void WriteTimeOption(const char *option, TDateTime &time);

    static int IsOptDelim(char ch);
    static const char *LTrim(const char *str);
    static void RTrim(char *str);

    static int ErrorLevel;

protected:
    void HandlePost(THttpCustomPage *page, const char *name);
    void GetFile(const char *Name);
    void Get(const char *Name);
    void Post(const char *Name);
    void Execute(const char *Name);

    void CheckAuthorization(const char *param);
    void AddArg(const char *name);
    void AddArg(char *sBeg, char **sEnd);
    void Split(char *s);
    int Parse(void *arg);
    int ScanCmdLine(char *line, void *arg);


    TDateTime DecodeTime(THttpOption *opt);
    TDateTime GetModifiedSince();

    const char *GetErrorText(int ErrorCode);

    void WriteFile(TPathName &path, const char *ContentType);

    void SendData(const char *Data, const char *ContentType);

    void StartPush();
    int PushFile(TPathName &path, const char *ContentType, int ReloadTimeout);

    char *SkipOptDelim(char *p);
    void AddOpt(char *name, char *param);
    char *AddParam(char *p);

    THttpCommand *FList;
    THttpParam *FParamList;

    THttpArg *FArgList;
    int FArgCount;

    THttpOption *FOptList;
    int FOptCount;

    int FAuthOk;

    int FMajor;
    int FMinor;

    TString FUserAgent;
    int FContentSize;
    char *FContentData;

    TString FMethod;
    TString FCmdLine;
    TString FUser;
    THttpSocketServer *FServer;
};

#endif
