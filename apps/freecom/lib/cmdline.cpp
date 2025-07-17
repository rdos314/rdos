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
# cmdline.cpp
# Command line class
#
########################################################################*/

#include <string.h>
#include <unistd.h>
#include <fcntl.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "cmdline.h"
#include "cmdfact.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TCommandLine::TCommandLine
#
#   Purpose....: Constructor for command line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommandLine::TCommandLine(TSession *session, const char *line)
{
    const char *ptr;
    TString str;
    char ch;
    const char *p;

    FSession = session;
    FList = 0;

    ptr = line;

    while (*ptr)
    {
        ch = *ptr;

        switch (ch)
        {
            case '"':
            case '\'':
                p = strchr(ptr, ch);
                if (p == 0)
                {
                    str.Append(ptr);
                    ptr = ptr + strlen(ptr) - 1;
                }
                else
                {
                    while (p >= ptr)
                    {
                        str.Append(*ptr);
                        ptr++;
                    }
                }
                break;

            case '<':
                ptr = RedirInput(ptr + 1);
                break;

            case '>':
                if (*(ptr+1) == '>')
                    ptr = RedirAppend(ptr + 2);
                else
                    ptr = RedirOutput(ptr + 1);
                break;

            case '|':
                Pipe(str);
                ptr++;
                str = "";
                break;

            case 0xa:
            case 0xd:
                ptr++;
                break;

            default:
                str.Append(*ptr);
                ptr++;
                break;
        }
    }

    Add(str);
}

/*##########################################################################
#
#   Name       : TCommandLine::~TCommandLine
#
#   Purpose....: Destructor for command line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommandLine::~TCommandLine()
{
    TCommand *cmd;
    TCommand *next;

    cmd = FList;

    while (cmd)
    {
        next = cmd->FList;
        delete cmd;
        cmd = next;
    }
}

/*##########################################################################
#
#   Name       : TCommandLine::IsRedir
#
#   Purpose....: Is redirection char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommandLine::IsRedir(char ch)
{
    return ch == '>' || ch == '<' || ch == '|';
}

/*##########################################################################
#
#   Name       : TCommandLine::InsertLast
#
#   Purpose....: Insert command last
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommandLine::InsertLast(TCommand *cmd)
{
    TCommand *curr;

    cmd->FList = 0;
    curr = FList;
   
    if (curr)
    {
        while (curr->FList)
            curr = curr->FList;

        curr->FList = cmd;
    }
    else
        FList = cmd;
}

/*##########################################################################
#
#   Name       : TCommandLine::RedirInput
#
#   Purpose....: Redirect input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TCommandLine::RedirInput(const char *line)
{
    const char *ptr;

    FInputFile = "";

    ptr = LTrim(line);
    while (*ptr && !IsRedir(*ptr) && !IsArgDelim(*ptr))
    {
        FInputFile.Append(*ptr);
        ptr++;
    }
    return ptr;
}

/*##########################################################################
#
#   Name       : TCommandLine::RedirOutput
#
#   Purpose....: Redirect output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TCommandLine::RedirOutput(const char *line)
{
    const char *ptr;

    FOutputFile = "";
    FAppendFile = "";

    ptr = LTrim(line);
    while (*ptr && !IsRedir(*ptr) && !IsArgDelim(*ptr))
    {
        FOutputFile.Append(*ptr);
        ptr++;
    }
    return ptr;
}

/*##########################################################################
#
#   Name       : TCommandLine::RedirAppend
#
#   Purpose....: Redirect append
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TCommandLine::RedirAppend(const char *line)
{
    const char *ptr;

    FOutputFile = "";
    FAppendFile = "";

    ptr = LTrim(line);
    while (*ptr && !IsRedir(*ptr) && !IsArgDelim(*ptr))
    {
        FAppendFile.Append(*ptr);
        ptr++;
    }
    return ptr;
}

/*##########################################################################
#
#   Name       : TCommandLine::Pipe
#
#   Purpose....: Pipe
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommandLine::Pipe(TString &str)
{
}

/*##########################################################################
#
#   Name       : TCommandLine::Add
#
#   Purpose....: Add rest of command line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommandLine::Add(TString &str)
{
    const char *ptr;
    TCommand *cmd;

    ptr = LTrim(str.GetData());
    if (*ptr)
    {
        cmd = TCommandFactory::Parse(FSession, ptr);
        if (cmd)
        {
            if (FInputFile.GetSize())
                cmd->DefineInput(FInputFile);

            if (FOutputFile.GetSize())
                cmd->DefineOutput(FOutputFile);

            if (FAppendFile.GetSize())
                cmd->DefineAppend(FAppendFile);

            InsertLast(cmd);
        }
    }
}

/*##########################################################################
#
#   Name       : TCommandLine::IsExit
#
#   Purpose....: Check if command line contains "exit"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommandLine::IsExit()
{
    if (FList && FList->IsExit())
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TCommandLine::Run
#
#   Purpose....: Run command line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommandLine::Run()
{
    TCommand *cmd;
    int result = 0;
    const char *name;
    int handle;
    int PrevInput = dup(0);
    int PrevOutput = dup(1);

    if (FList)
    {
        cmd = FList;
        while (cmd && result == 0)
        {
            name = cmd->GetInput();
            if (strlen(name))
            {
                handle = open(name, O_RDONLY);
                if (handle >= 0)
                {
                    dup2(handle, 0);
                    close(handle);
                }
            }
                
            name = cmd->GetOutput();
            if (strlen(name))
            {
                handle = open(name, O_CREAT | O_WRONLY | O_TRUNC);
                if (handle >= 0)
                {
                    dup2(handle, 1);
                    close(handle);
                }
            }
                
            name = cmd->GetAppend();
            if (strlen(name))
            {
                handle = open(name, O_CREAT | O_WRONLY | O_APPEND);
                if (handle >= 0)
                {
                    dup2(handle, 1);
                    close(handle);
                }
            }
                            
            result = cmd->Run();
            cmd = cmd->FList;

            dup2(PrevInput, 0);
            dup2(PrevOutput, 1);
        }
        FSession->Write("\r\n");
    }

    close(PrevInput);
    close(PrevOutput);

    return result;
}
