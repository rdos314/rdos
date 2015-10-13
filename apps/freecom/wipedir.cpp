/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# mkdir.cpp
# Mkdir command class
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
