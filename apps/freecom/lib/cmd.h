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
# cmd.h
# Command base class
#
########################################################################*/

#ifndef _CMD_H
#define _CMD_H

#include "langstr.h"
#include "file.h"
#include "path.h"
#include "parser.h"
#include "session.h"
#include "disccmd.h"

class TSession;
class TCommand;

class TArg
{
public:
    TArg(const char *name);
    ~TArg();

    char *ptr;

    TString FName;
    TArg *FList;
};

class TVfsDiscCmdWrapper : public TVfsDiscCmd
{
public:
    TVfsDiscCmdWrapper(TCommand *command, int disc, const char *cmd);
    virtual ~TVfsDiscCmdWrapper();

    virtual void NotifyMsg(const char *msg);

protected:
    TCommand *FCommand;
};

class TCommand : public TParser
{
    friend class TCommandLine;
public:
    TCommand(TSession *session, const char *param);
    virtual ~TCommand();

    virtual int IsExit();

    int Command();
    int Command(const char *param);

    void DefineInput(TString &name);
    void DefineOutput(TString &name);
    void DefineAppend(TString &name);
    void DefineError(TString &name);

    const char *GetInput();
    const char *GetOutput();
    const char *GetAppend();
    const char *GetError();

    void Write(char ch);
    void Write(const char *str);

    void WriteError(char ch);
    void WriteError(const char *str);

    void WriteLong(long Value);
    void WriteLongLong(long long Value);

    int Read(char *str, int maxsize);
        
    int Run();
    virtual int Execute(char *param) = 0;

    static int ErrorLevel;

protected:
    int RunBatch(const char *name);
    
    virtual int OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg);
    void OptError(const char *optstr);
    void ErrorSyntax(const char *str);

    int ScanOpt(void *ag, char *rest);
    int LeadOptions(char **Xline, void *arg);

    void AddArg(const char *name);
    void AddArg(char *sBeg, char **sEnd);
    void Split(char *s);
    int ParseOptions(void *arg);
    int ScanCmdLine(char *line, void *arg);

    void ShowCount(int BaseId, int count);
        
    int OptScanBool(const char *optstr, int bool, const char *arg, int *value);

    TSession *FSession;
    TLangString FMsg;
    TString FCmdLine;
    TLangString FHelpScreen;
    TCommand *FList;
        
    TArg *FArgList;
    int FArgCount;
    int FOptCount;

    TString FInputName;
    TString FOutputName;
    TString FAppendName;
    TString FErrorName;
};

#endif
