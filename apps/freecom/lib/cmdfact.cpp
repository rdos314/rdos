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
#include "cmdhelp.h"
#include "lang.h"
#include "cmd.h"
#include "cmdfact.h"
#include "setdrive.h"
#include "exec.h"
#include "bat.h"
#include "errcmd.h"
#include "env.h"

#define FALSE 0
#define TRUE !FALSE

TCommandFactory *TCommandFactory::FCmdList = 0;
TPathName TCommandFactory::FFullPath;

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

/*##################  TCommandFactory::ExpandEnv  ##########################
*   Purpose....: Parse environment variables in command line                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
TString TCommandFactory::ExpandEnv(TString &line)
{
        char *tp;
        char *ip;
    TString cp;
    int ok;

        ip = (char *)line.GetData();

    while (*ip)
    {
        if (*ip == '%')
        {
            ip++;
            
                        switch (*ip)
            {
                case 0:
                    cp.Append('%');
                                        break;

                                case '%':
                                        cp.Append('%');
                                        ip++;
                                        break;

                                case '0':
                                case '1':
                                case '2':
                                case '3':
                                case '4':
                                case '5':
                                case '6':
                                case '7':
                                case '8':
                                case '9':
                                        tp = (char *)FindArg(*ip - '0');
                            if (tp)
                                        {
                                                cp.Append(*tp);
                                                ip++;
                                        }
                                        else
                                                cp.Append('%');
                                        break;

                                default:
                                        tp = strchr(ip, '%');
                                        if (tp)
                                        {
                                                TEnv *env = TEnv::OpenProcessEnv();
                                                char *eval = new char[256];
                                                *tp = 0;

                                                ok = env->Find(ip, eval);
                                                if (!ok)
                                                {
                                                        strupr(ip);
                                                        ok = env->Find(ip, eval);
                                                }

                                                if (ok)
                                                        cp.Append(eval);
                                                else
                                                {
                                                        if (MatchToken(&ip, "ERRORLEVEL", 10))
                                                        {
                                                                sprintf(eval, "%u", TCommand::ErrorLevel);
                                                                cp.Append(eval);
                                                        }
                                                        else
                                                        {
                                                                if (MatchToken(&ip, "_CWD", 4))
                                                                {
                                                                        cp.Append(RdosGetCurDrive() + 'A');
                                                                        cp.Append(":\\");
                                                                        *eval = 0;
                                                                        RdosGetCurDir(RdosGetCurDrive(), eval);
                                                                        cp.Append(eval);
                                                                }
                                                        }
                                                }
                                                delete eval;
                                                delete env;
                                                ip = tp + 1;
                                        }
                                        break;
                        }
                }
                else
                {
                        cp.Append(*ip);
                        ip++;
                }
        }
        return cp;
}

/*##########################################################################
#
#   Name       : TCommandFactory::CheckFileExt
#
#   Purpose....: Check if path is valid file (with given extension)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommandFactory::CheckFileExt(const char *path, const char *ext)
{
    FFullPath = TString(path);
    FFullPath += ext;

        if (FFullPath.IsFile())
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TCommandFactory::CheckFileExt
#
#   Purpose....: Check if path + name is a valid file (with given extension)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommandFactory::CheckFileExt(const char *path, const char *name, const char *ext)
{
        TPathName pn(path);
        pn += name;

        return CheckFileExt(pn.Get().GetData(), ext);
}

/*##########################################################################
#
#   Name       : TCommandFactory::CheckPathFileExt
#
#   Purpose....: Find file through with path env var
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommandFactory::CheckPathFileExt(char *path, const char *name, const char *ext)
{
        char *ptr;

        if (CheckFileExt(name, ext))
            return TRUE;

        while (*path)
        {
                ptr = strchr(path, ';');
                if (ptr)
                {
                        *ptr = 0;
                        if (CheckFileExt(path, name, ext))
                            return TRUE;

                        path = ptr + 1;
                }
                else
                        return CheckFileExt(path, name, ext);
        }
        return FALSE;
}

/*##########################################################################
#
#   Name       : TCommandFactory::CheckFile
#
#   Purpose....: Check if file is executable
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommandFactory::CheckFile(char *name, const char *ext)
{
        char *path;
        TEnv *env;
        int ok;
        
        if (strchr(name, '\\'))
                if (CheckFileExt(name, ext))
                    return TRUE;

        if (strchr(name, '/'))
                if (CheckFileExt(name, ext))
                         return TRUE;

        if (strchr(name, ':'))
                if (CheckFileExt(name, ext))
                         return TRUE;

         path = new char[512];
         env = TEnv::OpenSysEnv();
        if (env->Find("PATH", path))
         {
                 ok = CheckPathFileExt(path, name, ext);
                delete env;
                  delete path;
                  if (ok)
                                return TRUE;
         }
         else
         {
                  delete env;
                  delete path;
         }

         return CheckFileExt(name, ext);
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
TCommand *TCommandFactory::Parse(TSession *session, const char *line)
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
        int detach;
    int ok;

        Line = TString(LTrim(line));

        Line = ExpandEnv(Line);

        rest = Line.GetData();

        if (strlen(rest) == 2)
                if (rest[1] == ':' && isalpha(*rest))
                {
                        cmd = new TSetDriveCommand(session, rest);
                        return cmd;
                }

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

                                if (*com == '@')
                                         factory = 0;
                                else
                                {
                                factory = FCmdList;
                                while (factory)
                                {
                                        if (!strcmp(factory->FName.GetData(), com))
                                                break;

                                        factory = factory->FList;
                                 }
                         }

                        if (!factory)
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

                return factory->Create(session, rest);

        }
        else
        {
                rest = SkipWord((char *)Line.GetData());
                cp = Unquote(Line.GetData(), rest);
                name = cp;

        detach = FALSE;
        if (*name == '@')
        {
            name++;
            detach = TRUE;
        }
        
                ok = CheckFile(name, ".com");
        if (!ok)
            ok = CheckFile(name, ".exe");

        if (ok)
        {
            delete cp;
                return new TExecCommand(session, FFullPath.Get().GetData(), rest, detach);
        }

                ok = CheckFile(name, ".bat");
        if (!ok)
            ok = CheckFile(name, ".cmd");

        if (ok)
        {
            delete cp;
                return new TBatchCommand(session, FFullPath, rest);
        }

        cmd = new TErrorCommand(session, name);
        delete cp;
        return cmd;
        }
}
