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
# type.cpp
# Type command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "type.h"
#include "rdos.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TTypeFactory::TTypeFactory
#
#   Purpose....: Constructor for TTypeFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTypeFactory::TTypeFactory()
  : TCommandFactory("TYPE")
{
}

/*##########################################################################
#
#   Name       : TTypeFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TTypeFactory::Create(TSession *session, const char *param)
{
    return new TTypeCommand(session, param);
}

/*##########################################################################
#
#   Name       : TTypeCommand::TTypeCommand
#
#   Purpose....: Constructor for TTypeCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTypeCommand::TTypeCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_TYPE);
}

/*##########################################################################
#
#   Name       : TTypeCommand::Show
#
#   Purpose....: Show
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTypeCommand::Show(TPathName &PathName)
{
    TFile file = PathName.OpenFile();
    char buf[0x1001];
    int size;

    if (file.IsOpen())
    {
        for (;;)
        {
            size = file.Read(buf, 0x1000);
            if (size == 0)
                break;
            else
            {
                buf[size] = 0;
                Write(buf); 
            }
        }
    }
    Write("\r\n");
}

/*##########################################################################
#
#   Name       : TTypeCommand::Add
#
#   Purpose....: Add
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTypeCommand::Add(TArg *arg)
{
    TDirEntry entry;
    TPathName path(arg->FName);

    FFileList.SetIgnoredAttributes(FILE_ATTRIBUTE_DIRECTORY | FILE_ATTRIBUTE_SYSTEM | FILE_ATTRIBUTE_HIDDEN);
    FFileList.Add(path);
}

/*##########################################################################
#
#   Name       : TTypeCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTypeCommand::Execute(char *param)
{
    TArg *arg;
    int HasSrc = FALSE;
    int ok;
    TPathName path;

    if (!ScanCmdLine(param, 0))
        return 1;

    arg = FArgList;

    while (arg)
    {
        if (LeadOptions(&arg->ptr, 0) != E_None)
            return 1;
        else
        {
            Add(arg);               
            arg = arg->FList;
        }
    }

    FFileList.RemoveDuplicates();
    
    ok = FFileList.GotoFirst();
    while (ok)
    {
        path = FFileList.Get().GetPathName();
        Show(path);
        ok = FFileList.GotoNext();
    }

    return 0;
}
