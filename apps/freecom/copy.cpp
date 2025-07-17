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
# copy.cpp
# Copy command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "copy.h"
#include "rdos.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TCopyFactory::TCopyFactory
#
#   Purpose....: Constructor for TCopyFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCopyFactory::TCopyFactory()
  : TCommandFactory("COPY")
{
}

/*##########################################################################
#
#   Name       : TCopyFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TCopyFactory::Create(TSession *session, const char *param)
{
        return new TCopyCommand(session, param);
}

/*##########################################################################
#
#   Name       : TCopyCommand::TCopyCommand
#
#   Purpose....: Constructor for TCopyCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCopyCommand::TCopyCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_COPY);
}

/*##########################################################################
#
#   Name       : TCopyCommand::IsArgDelim
#
#   Purpose....: Check for argument delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::IsArgDelim(char ch)
{
        if (ch == '+')
                return TRUE;
        else
                return TCommand::IsArgDelim(ch);
}

/*##########################################################################
#
#   Name       : TCopyCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
        switch(ch)
        {
                case 'Y':
                        return OptScanBool(optstr, bool, strarg, &FOptY);
        }
        OptError(optstr);
        return E_Useage;
}

/*##########################################################################
#
#   Name       : TCopyCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCopyCommand::InitOptions()
{
        FOptY = FALSE;
}

/*##########################################################################
#
#   Name       : TCopyCommand::CopyFile
#
#   Purpose....: Copy file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::CopyFile(TString &Src, TString &Dest)
{
        char ch;
        TPathName src(Src);
        TPathName dest(Dest);
        TString fullsrc(src.GetFullPathName());
        TString fulldest(dest.GetFullPathName());

        fullsrc.Upper();
        fulldest.Upper();

        if (!strcmp(fullsrc.GetData(), fulldest.GetData()))
        {
                FMsg.printf(TEXT_ERROR_SELFCOPY, Dest.GetData());
                Write(FMsg.GetData());
                return 1;
        }

        if (dest.IsFile() && !FOptY)
        {
                ch = FMsg.UserPrompt(PROMPT_OVERWRITE_FILE, Dest.GetData());
                switch (ch)
                {
                        case 3: /* All */
                                FOptY = TRUE;

                        case 1: /* Yes */
                                break;

                        case 2: /* No */
                                return 0;

                        default:        /* Quit */
                                return 1;
                }               
        }


        Write(Src.GetData());
        Write(" => ");
        Write(Dest.GetData());
        Write("\r\n");

        if (src.CopyFile(dest))
                return 0;
        else
        {
                FMsg.Load(TEXT_ERROR_COPY);
                Write(FMsg.GetData());
                return 1;
        }
}

/*##########################################################################
#
#   Name       : TCopyCommand::AppendFile
#
#   Purpose....: Append file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::AppendFile(TString &Src, TString &Dest)
{
        TPathName src(Src);
        TPathName dest(Dest);
        TString fullsrc(src.GetFullPathName());
        TString fulldest(dest.GetFullPathName());

        fullsrc.Upper();
        fulldest.Upper();

        if (!strcmp(fullsrc.GetData(), fulldest.GetData()))
                return 0;

        Write(Src.GetData());
        Write(" =>> ");
        Write(Dest.GetData());
        Write("\r\n");

        if (src.AppendFile(dest))
                return 0;
        else
        {
                FMsg.Load(TEXT_ERROR_COPY);
                Write(FMsg.GetData());
                return 1;
        }
}

/*##########################################################################
#
#   Name       : TCopyCommand::CopyFiles
#
#   Purpose....: Copy files
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::CopyFiles()
{
    TString src;
    TString dst;
    int ok;
    int result;
        
        ok = FSrcFiles.GotoFirst();
        while (ok)
        {
            TPathName path(*FDest);
            path += FSrcFiles.Get().GetEntryName();
            src = FSrcFiles.Get().GetPathName().Get();
            dst = path.Get();
            result = CopyFile(src, dst);
            if (result)
                return result;
            else
                ok = FSrcFiles.GotoNext();
        }
        return 0;
}

/*##########################################################################
#
#   Name       : TCopyCommand::AppendFiles
#
#   Purpose....: Append files
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::AppendFiles()
{
    int ok;
    TString src;
    TString dst;
        
    ok = FSrcFiles.GotoFirst();
    if (ok)
    {
        src = FSrcFiles.Get().GetPathName().Get();
        dst = FDest->Get();
        CopyFile(src, dst);

        while (ok)
        {
            ok = FSrcFiles.GotoNext();
            if (ok)
            {
                src = FSrcFiles.Get().GetPathName().Get();
                dst = FDest->Get();
                AppendFile(src, dst);
            }
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TCopyCommand::AddSrc
#
#   Purpose....: Add source files
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::AddSrc(TArg *arg)
{
        TPathName path(arg->FName);
        FSrcFiles.SetIgnoredAttributes(FILE_ATTRIBUTE_DIRECTORY | FILE_ATTRIBUTE_SYSTEM | FILE_ATTRIBUTE_HIDDEN);
        FSrcFiles.Add(path);
        return TRUE;    
}

/*##########################################################################
#
#   Name       : TCopyCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::Execute(char *param)
{
        TArg *arg;
        int HasSrc = FALSE;
        const char *ptr;

        FDest = 0;

        InitOptions();

        if (!ScanCmdLine(param, 0))
                return 1;

        arg = FArgList;

        while (arg)
        {
                if (LeadOptions(&arg->ptr, 0) != E_None)
                        return 1;
                else
                {
                        if (arg->FList)
                        {
                                if (AddSrc(arg))
                                        HasSrc = TRUE;
                                else
                                        return 1;
                        }
                        else
                        {
                                if (HasSrc)
                                {
                                        ptr = arg->FName.GetData();
                                        if (strlen(ptr) == 2 && *(ptr+1) == ':')
                                                FDest = new TPathName(arg->FName + ".");
                                        else
                                                FDest = new TPathName(arg->FName);
                                }
                                else
                                {
                                        if (AddSrc(arg))
                                                FDest = new TPathName(".");
                                        else
                                                return 1;
                                }
                        }

                        arg = arg->FList;
                }
        }

    FSrcFiles.RemoveDuplicates();

        if (FDest)
        {
                if (FDest->IsDir())
                        return CopyFiles();
                else
                        return AppendFiles();
        }

        return 0;
}
