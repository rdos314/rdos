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

#include "str.h"
#include "parser.h"
#include "cmdout.h"

class TArg
{
public:
    TArg(const char *name);
    ~TArg();

    char *ptr;

    TString FName;
    TArg *FList;
};

class TCommand : public TParser
{
public:
    TCommand(TCommandOutput *out, const char *param);
    virtual ~TCommand();

    virtual int IsExit();

    void Write(TString &str);
    void Write(char ch);
    void Write(const char *str);
    void WriteLong(long Value);
        
    int Run();
    virtual int Execute(char *param) = 0;

    static int ErrorLevel;

protected:
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
        
    int OptScanBool(const char *optstr, int bool, const char *arg, int *value);

    TString FMsg;
    TString FCmdLine;
    TString FHelpScreen;
    TCommand *FList;
    TCommandOutput *FOut;
        
    TArg *FArgList;
    int FArgCount;
    int FOptCount;
};

#endif
