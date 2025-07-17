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
# cmd.cpp
# Command base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>

#include "lang.h"
#include "cmd.h"
#include "cmdhelp.h"

#define FALSE 0
#define TRUE !FALSE

int TCommand::ErrorLevel = 0;

/*##########################################################################
#
#   Name       : TArg::TArg
#
#   Purpose....: Constructor for TArg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TArg::TArg(const char *name)
  : FName(name)
{
    ptr = (char *)FName.GetData();
    
    FList = 0;
}

/*##########################################################################
#
#   Name       : TArg::~TArg
#
#   Purpose....: Destructor for TArg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TArg::~TArg()
{
}

/*##########################################################################
#
#   Name       : TVfsDiscCmdWrapper::TVfsDiscCmdWrapper
#
#   Purpose....: Constructor for TVfsDiscCmdWrapper
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVfsDiscCmdWrapper::TVfsDiscCmdWrapper(TCommand *command, int disc, const char *cmd)
 : TVfsDiscCmd(disc, cmd)
{
    FCommand = command;
}

/*##########################################################################
#
#   Name       : TVfsDiscCmdWrapper::~TVfsDiscCmdWrapper
#
#   Purpose....: Destructor for TVfsDiscCmdWrapper
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVfsDiscCmdWrapper::~TVfsDiscCmdWrapper()
{
}

/*##########################################################################
#
#   Name       : TVfsDiscCmdWrapper::NotifyMsg
#
#   Purpose....: Notify message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVfsDiscCmdWrapper::NotifyMsg(const char *msg)
{
    FCommand->Write(msg);
}

/*##########################################################################
#
#   Name       : TCommand::TCommand
#
#   Purpose....: Constructor for command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand::TCommand(TSession *session, const char *param)
  : FCmdLine(param)
{
    FArgList = 0;
    FSession = session;
}

/*##########################################################################
#
#   Name       : TCommand::~TCommand
#
#   Purpose....: Destructor for command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand::~TCommand()
{
    TArg *arg;

    arg = FArgList;
    while (arg)
    {
        FArgList = arg->FList;
        delete arg;
        arg = FArgList;
    }
}

/*##########################################################################
#
#   Name       : TCommand::IsExit
#
#   Purpose....: Is this an exit command?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::IsExit()
{
    return FALSE;
}

/*##########################################################################
#
#   Name       : TCommand::Command
#
#   Purpose....: Spawn command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::Command()
{
    TSession session(*FSession);
    session.Run();
    return 0;
}

/*##########################################################################
#
#   Name       : TCommand::Command
#
#   Purpose....: Spawn command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::Command(const char *param)
{
    TSession session(*FSession);
    session.Run(param);
    return 0;
}

/*##########################################################################
#
#   Name       : TCommand::RunBatch
#
#   Purpose....: Run batch file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::RunBatch(const char *name)
{
    TSession session(*FSession);
    return session.Run(name, FArgList);
}

/*##########################################################################
#
#   Name       : TCommand::Write
#
#   Purpose....: Write to std output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::Write(char ch)
{
    write(1, &ch, 1);
}

/*##########################################################################
#
#   Name       : TCommand::Write
#
#   Purpose....: Write to std output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::Write(const char *str)
{
    write(1, str, strlen(str));
}

/*##########################################################################
#
#   Name       : TCommand::WriteError
#
#   Purpose....: Write to std error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::WriteError(char ch)
{
    write(2, &ch, 1);
}

/*##########################################################################
#
#   Name       : TCommand::WriteError
#
#   Purpose....: Write to std error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::WriteError(const char *str)
{
    write(2, str, strlen(str));
}

/*##########################################################################
#
#   Name       : TCommand::WriteLong
#
#   Purpose....: Write long to std output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::WriteLong(long value)
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
#   Name       : TCommand::WriteLongLong
#
#   Purpose....: Write long long to std output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::WriteLongLong(long long value)
{
    char str[4];
    long long tmp;
    int use = FALSE;

    tmp = value / 1000000000000000000;
    if (tmp)
    {
        use = TRUE;
        sprintf(str, "%1d", tmp);
    }
    else
        strcpy(str, "  ");

    Write(str);
    Write(" ");
    value = value % 1000000000000000000;

    tmp = value / 1000000000000000;
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
    value = value % 1000000000000000;

    tmp = value / 1000000000000;
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
    value = value % 1000000000000;

    tmp = value / 1000000000;
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
#   Name       : TCommand::Read
#
#   Purpose....: Read a line from std input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::Read(char *str, int maxsize)
{
    return read(0, str, maxsize);
}

/*##########################################################################
#
#   Name       : TCommand::DefineInput
#
#   Purpose....: Define input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::DefineInput(TString &name)
{
    FInputName = name;
}

/*##########################################################################
#
#   Name       : TCommand::DefineOutput
#
#   Purpose....: Define output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::DefineOutput(TString &name)
{
    FOutputName = name;
}

/*##########################################################################
#
#   Name       : TCommand::DefineError
#
#   Purpose....: Define error file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::DefineError(TString &name)
{
    FErrorName = name;
}

/*##########################################################################
#
#   Name       : TCommand::DefineAppend
#
#   Purpose....: Define append to output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::DefineAppend(TString &name)
{
    FAppendName = name;
}

/*##########################################################################
#
#   Name       : TCommand::GetInput
#
#   Purpose....: Get input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TCommand::GetInput()
{
    return FInputName.GetData();
}

/*##########################################################################
#
#   Name       : TCommand::GetOutput
#
#   Purpose....: Get output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TCommand::GetOutput()
{
    return FOutputName.GetData();
}

/*##########################################################################
#
#   Name       : TCommand::GetError
#
#   Purpose....: Get error file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TCommand::GetError()
{
    return FErrorName.GetData();
}

/*##########################################################################
#
#   Name       : TCommand::GetAppend
#
#   Purpose....: Get append to output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TCommand::GetAppend()
{
    return FAppendName.GetData();
}

/*##########################################################################
#
#   Name       : TCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::Run()
{
    char *param;
    char *ptr;
    int size;
    int result;

    size = FCmdLine.GetSize();
    param = new char[size + 1];
    memcpy(param, FCmdLine.GetData(), size + 1);

    ptr = param;

    result = Execute(ptr);

    delete param;
    return result;
}

/*##########################################################################
#
#   Name       : TCommand::OptScan
#
#   Purpose....: Default opt-scan method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
        OptError(optstr);
        return 0;
}

/*##########################################################################
#
#   Name       : TCommand::OptError
#
#   Purpose....: Opt error notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::OptError(const char *optstr)
{
        FMsg.printf(TEXT_ERROR_INVALID_LSWITCH, optstr);
        WriteError(FMsg.GetData());
}

/*##########################################################################
#
#   Name       : TCommand::ErrorSyntax
#
#   Purpose....: Syntax error notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::ErrorSyntax(const char *str)
{
        if (str)
                FMsg.printf(TEXT_ERROR_SYNTAX, str);
        else
                FMsg.Load(TEXT_ERROR_SYNTAX);
        WriteError(FMsg.GetData());
}

/*##########################################################################
#
#   Name       : TCommand::OptScanBool
#
#   Purpose....: Opt-scan boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::OptScanBool(const char *optstr, int bool, const char *arg, int *value)
{
        if (arg)
        {
                FMsg.printf(TEXT_ERROR_OPT_ARG, optstr);
                WriteError(FMsg.GetData());
            return E_Useage;
        }

        switch (bool)
        {
                case -1:
                        *value = 0;
                        break;

                case 0:
                        *value = !*value;
                        break;

                case 1:
                        *value = 1;
                        break;
        }
        return 0;
}

/*##########################################################################
#
#   Name       : TCommand::ScanOpt
#
#   Purpose....: Scan option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::ScanOpt(void *ag, char *rest)
{
        char *line, *arg, *optend;
        int ch, bool;

        line = rest;
        if (!IsOptChar(*line))
                return -1;

        line++;
        switch (*line)
        {
                case 0:
                        return E_None;

                case '-':
                        bool = -1;
                        line++;
                        break;

                case '+':
                        bool = 1;
                        line++;
                        break;

                default:
                        bool = 0;
                        break;

        }

        ch = toupper(*line);
        if (!isprint(ch) || strchr("-+=:", ch))
        {
                OptError(rest);
                return E_Useage;
        }

        if (ch == '?')
        {
                Write(FHelpScreen.GetData());
                return E_Help;
        }

        optend = strpbrk(line, "=:");
        if (optend)
                arg = optend + 1;
        else
        {
                arg = 0;
                optend = strchr(line, 0);
        }

        switch (optend[-1])
        {
                case '-':
                        bool = -1;
                optend--;
                        break;

                case '+':
                        bool = 1;
                optend--;
                        break;
        }

        *optend = 0;
        return OptScan(line, line[1] ? 0 : ch, bool, arg, ag);
}

/*##########################################################################
#
#   Name       : TCommand::LeadOptions
#
#   Purpose....: Scan leading options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::LeadOptions(char **Xline, void *arg)
{ 
        int ec = E_None;
        char *p, *q, *line;

        p = *Xline;
        if(!p)
                p = "";

        while (*(line = SkipDelim(p)))
        {
                p = SkipWord(line);
                q = Unquote(line, p);

                if (IsOptChar(*q))
                {
                        ec = ScanOpt(arg, q);
                        if (ec != E_None && ec != E_Ignore)
                        {
                                delete q;
                                break;
                        }
                        else
                                delete q;
                }
                else
                {
                        delete q;
                        break;
                }
        }

        *Xline = line;
        return ec;
}

/*##########################################################################
#
#   Name       : TCommand::ShowCount
#
#   Purpose....: Show count with 3 IDs
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::ShowCount(int BaseId, int count)
{
    switch (count)
    {
        case 0:
            FMsg.Load(BaseId);
            break;
                
            case 1:
                FMsg.Load(BaseId + 1);
                break;
                    
            default:
                FMsg.printf(BaseId + 2, count);
                break;
    }
        Write(FMsg.GetData());        
}

/*##########################################################################
#
#   Name       : TCommand::AddArg
#
#   Purpose....: Add an argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::AddArg(const char *name)
{
    TArg *arg = new TArg(name);
    TArg *curr;

    arg->FList = 0;
        curr = FArgList;
   
        if (curr)
        {
                while (curr->FList)
                        curr = curr->FList;

                curr->FList = arg;
        }
        else
                FArgList = arg;    
}

/*##########################################################################
#
#   Name       : TCommand::AddArg
#
#   Purpose....: Add an argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::AddArg(char *sBeg, char **sEnd)
{ 
    char *arg;

    *sEnd = SkipWord(sBeg);
    arg = Unquote(sBeg, *sEnd);
    AddArg(arg);
    delete arg;
}

/*##########################################################################
#
#   Name       : TCommand::Split
#
#   Purpose....: Split line into arguments
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommand::Split(char *s)
{
        char *start;

    if (s)
    {
        start = SkipDelim(s);
        while (*start)
        {
                        AddArg(start, &s);
                        start = SkipDelim(s);
                }
    }
}

/*##########################################################################
#
#   Name       : TCommand::ParseOptions
#
#   Purpose....: Parse all options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::ParseOptions(void *arg)
{
    TArg *curr;
    TArg *argv;
    char *str;
        int ec;

    FOptCount = 0;
        FArgCount = 0;

    argv = FArgList;    
        while (argv)
        {
            str = (char *)argv->FName.GetData();
                if (IsOptChar(*str))
                {
                        ec = ScanOpt(arg, str);
                        if (ec == E_None)
                        {
                            curr = FArgList;
                            if (curr == argv)
                            {
                                FArgList = argv->FList;
                                delete argv;
                                argv = 0;
                            }
                            else
                            {
                                while (curr && curr->FList != argv)
                                    curr = curr->FList;

                                if (curr)
                                {
                                    curr->FList = argv->FList;
                                    delete argv;
                                argv = 0;
                                }
                            }
                                FOptCount++;
                        }
                        else
                        {
                                if (ec == E_Ignore)
                                    FArgCount++;
                                else
                                        return ec;
                        }
                }
                else
            FArgCount++;

        if (argv)       
                argv = argv->FList;
        }

        return E_None;
}

/*##########################################################################
#
#   Name       : TCommand::ScanCmdLine
#
#   Purpose....: Scan cmd line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommand::ScanCmdLine(char *line, void *arg)
{
        Split(line);

        if (ParseOptions(arg) != E_None)
                return FALSE;
        else
            return TRUE;
}

