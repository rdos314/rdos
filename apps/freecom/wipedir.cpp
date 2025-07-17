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
# wipedir.cpp
# wipedir command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "wipedir.h"
#include "direntry.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TWipeDirFactory::TWipeDirFactory
#
#   Purpose....: Constructor for TWipeDirFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWipeDirFactory::TWipeDirFactory()
  : TCommandFactory("WIPEDIR")
{
}

/*##########################################################################
#
#   Name       : TWipeDirFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TWipeDirFactory::Create(TSession *session, const char *param)
{
    return new TWipeDirCommand(session, param);
}

/*##########################################################################
#
#   Name       : TWipeDirCommand::TWipeDirCommand
#
#   Purpose....: Constructor for TWipeDirCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWipeDirCommand::TWipeDirCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_WIPEDIR);
}

/*##########################################################################
#
#   Name       : TWipeDirCommand::WipeDir
#
#   Purpose....: Wipe directory and all its contents
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWipeDirCommand::WipeDir(TPathName &Path)
{
    int ok;

    if (!Path.IsDir())
        return FALSE;

    TDirList DirList = Path.Find();

    if (DirList.GetSize())
    {
        ok = DirList.GotoFirst();

        while (ok)
        {
            TDirEntry DirEntry = DirList.Get();
            TPathName PathName = DirEntry.GetPathName();

            if (PathName.IsFile())
            {
                FMsg.printf(TEXT_DELETE_FILE, PathName.Get().GetData());
                Write(FMsg.GetData());
                PathName.DeleteFile();
            }
            else
            {
                FMsg.printf(TEXT_DELETE_FILE, PathName.Get().GetData());
                Write(FMsg.GetData());

                if (!WipeDir(PathName))
                    return FALSE;
            }
            ok = DirList.GotoNext();
        }
    }

    return Path.RemoveDir();
}

/*##########################################################################
#
#   Name       : TWipeDirCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWipeDirCommand::Execute(char *param)
{
    TArg *arg;

    if (!ScanCmdLine(param, 0))
        return 1;

    arg = FArgList;

    while (arg)
    {
        TPathName path(arg->FName);
        if (!WipeDir(path))
        {
            FMsg.printf(TEXT_ERROR_DIRFCT_FAILED, "WIPEDIR", FArgList->FName.GetData());
            Write(FMsg.GetData());
            return 1;
        }
        arg = arg->FList;
    }
    return 0;
}
