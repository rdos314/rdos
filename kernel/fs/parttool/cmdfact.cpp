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
# cmdfact.cpp
# Command factory base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmd.h"
#include "cmdhelp.h"
#include "cmdfact.h"
#include "errcmd.h"

#define FALSE 0
#define TRUE !FALSE

TCommandFactory *TCommandFactory::FCmdList = 0;

/*##########################################################################
#
#   Name       : TCommandFactory::TCommandFactory
#
#   Purpose....: Constructor for command factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommandFactory::TCommandFactory(const char *name)
  : FName(name)
{       
    InsertCommand();
}

/*##########################################################################
#
#   Name       : TCommandFactor::~TCommandFactor
#
#   Purpose....: Destructor for command factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommandFactory::~TCommandFactory()
{       
    RemoveCommand();
}

/*##################  TCommandFactory::InsertCommand  ##########################
*   Purpose....: Insert device into command list                           #
*                                Should only be done in constructor                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TCommandFactory::InsertCommand()
{
    FList = FCmdList;
    FCmdList = this;
}

/*##################  TCommandFactory::RemoveCommand  ##########################
*   Purpose....: Remove device from command list                           #
*                                Should only done in destructor                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TCommandFactory::RemoveCommand()
{
    TCommandFactory *ptr;
    TCommandFactory *prev;
    prev = 0;

    ptr = FCmdList;
    while ((ptr != 0) && (ptr != this))
    {
        prev = ptr;
        ptr = ptr->FList;
    }

    if (prev == 0)
        FCmdList = FCmdList->FList;
    else
        prev->FList = ptr->FList;
}

/*##################  TCommandFactory::PassAll  ##########################
*   Purpose....: Pass all characters to commandline                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
int TCommandFactory::PassAll()
{
    return FALSE;
}

/*##################  TCommandFactory::PassDir  ##########################
*   Purpose....: Pass dir characters to commandline                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
int TCommandFactory::PassDir()
{
    return FALSE;
}

/*##################  TCommandFactory::FindArg  ##########################
*   Purpose....: Find argument to batch-file                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
const char *TCommandFactory::FindArg(int no)
{
    return 0;
}

/*##########################################################################
#
#   Name       : TCommandFactory::SkipWord
#
#   Purpose....: Skip to next word
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TCommandFactory::SkipWord(char *p)
{
    int ch, quote;
    int isopt;
    int more;

    isopt = IsOptChar(*p);
    if (isopt)
    {
        p++;
        while (*p && IsOptChar(*p))
        p++;
    }

    quote = 0;
    for (;;)
    {
        ch = *p;
        if (!ch)
            break;

        if (isopt)
            more = !IsOptDelim(ch) || IsOptChar(ch);
        else
            more = !IsArgDelim(ch) || IsOptChar(ch);

        if (!quote && !more)
            break;

        if (quote == ch)
            quote = 0;
        else
            if (strchr("\"", ch))
                quote = ch;

        p++;
    }
    return p;
}

/*##################  TCommandFactory::Parse  ##########################
*   Purpose....: Parse a command line and return a command class                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
TCommand *TCommandFactory::Parse(TCommandOutput *out, const char *line)
{
    const char *rest;
    int size;
    int i;
    char *com;
    char *ptr;
    int done;
    char *cp;
    char *name;
    TString Line;
    TCommandFactory *factory = 0;
    TCommand *cmd;

    Line = TString(LTrim(line));

    rest = Line.GetData();

    if (*rest)
    {
        size = 0;
        while (*rest && IsFileNameChar(*rest) && !strchr("\"", *rest))
        {
            size++;
            rest++;
        }

        if (*rest && strchr("\"", *rest))
            size = 0;

        if (size)
        {
            com = new char[size + 1];

            rest = Line.GetData();
            ptr = com;

            for (i = 0; i < size; i++)
            {
                *ptr = toupper(*rest);
                ptr++;
                rest++;
            }
            *ptr = 0;

            factory = FCmdList;
            while (factory)
            {
                if (!strcmp(factory->FName.GetData(), com))
                    break;

                factory = factory->FList;
            }
            delete com;
        }

    }

    if (factory)
    {
        done = factory->PassAll();

        if (!done && factory->PassDir())
            done = *rest == '\\' || *rest == '.' || *rest == ':';

        if (!done)
            done = (!*rest || *rest == '/');

        if (!done)
            if (IsArgDelim(*rest))
                rest = LTrim(rest);

        return factory->Create(out, rest);
    }
    else
    {
        rest = SkipWord((char *)Line.GetData());
        cp = Unquote(Line.GetData(), rest);
        name = cp;

        cmd = new TErrorCommand(out, name);
        delete cp;
        return cmd;
    }
}

/*##################  TCommandFactory::Run  ##########################
*   Purpose....: Run command                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TCommandFactory::Run(TCommandOutput *out, const char *line)
{
    TCommand *cmd = Parse(out, line);
    if (cmd)
    {
        cmd->Run();
        delete cmd;
    }        
}
