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
# move.cpp
# Move command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "move.h"
#include "rdos.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TMoveFactory::TMoveFactory
#
#   Purpose....: Constructor for TMoveFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMoveFactory::TMoveFactory()
  : TCommandFactory("MOVE")
{
}

/*##########################################################################
#
#   Name       : TMoveFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TMoveFactory::Create(TSession *session, const char *param)
{
        return new TMoveCommand(session, param);
}

/*##########################################################################
#
#   Name       : TMoveCommand::TMoveCommand
#
#   Purpose....: Constructor for TMoveCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMoveCommand::TMoveCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_MOVE);
}

/*##########################################################################
#
#   Name       : TMoveCommand::MoveFile
#
#   Purpose....: Move file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMoveCommand::MoveFile(TString &Src, TString &Dest)
{
        TPathName src(Src);
        TPathName dest(Dest);
        TString fullsrc(src.GetFullPathName());
        TString fulldest(dest.GetFullPathName());

        fullsrc.Upper();
        fulldest.Upper();

        if (!strcmp(fullsrc.GetData(), fulldest.GetData()))
                return 0;

        if (dest.IsFile())
        {
                FMsg.printf(TEXT_ERROR_OVERWRITE, dest.Get().GetData());
                Write(FMsg.GetData());
            return 1;
    }

        Write(Src.GetData());
        Write(" => ");
        Write(Dest.GetData());
        Write("\r\n");

        if (src.MoveFile(dest))
                return 0;
        else
        {
                FMsg.Load(TEXT_ERROR_MOVE);
                Write(FMsg.GetData());
                return 1;
        }
}

/*##########################################################################
#
#   Name       : TMoveCommand::MoveFiles
#
#   Purpose....: Move files
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMoveCommand::MoveFiles()
{
    int ok;
    int result;
    TString src;
    TString dst;
        
    ok = FSrcFiles.GotoFirst();
    while (ok)
    {
        TPathName path(*FDest);
        path += FSrcFiles.Get().GetEntryName();
        src = FSrcFiles.Get().GetPathName().Get();
        dst = FDest->Get();
        result = MoveFile(src, dst);
        if (result)
            return result;
        else
            ok = FSrcFiles.GotoNext();
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TMoveCommand::MoveSingleFile
#
#   Purpose....: Move a single file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMoveCommand::MoveSingleFile()
{
    TString src;
    TString dst;
    
    FSrcFiles.GotoFirst();
    src = FSrcFiles.Get().GetPathName().Get();
    dst = FDest->Get();
    MoveFile(src, dst);            
    return 0;
}

/*##########################################################################
#
#   Name       : TMoveCommand::AddSrc
#
#   Purpose....: Add source files
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMoveCommand::AddSrc(TArg *arg)
{
        TPathName path(arg->FName);
        FSrcFiles.SetIgnoredAttributes(FILE_ATTRIBUTE_DIRECTORY | FILE_ATTRIBUTE_SYSTEM | FILE_ATTRIBUTE_HIDDEN);
        FSrcFiles.Add(path);
        return TRUE;    
}

/*##########################################################################
#
#   Name       : TMoveCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMoveCommand::Execute(char *param)
{
        TArg *arg;
        int HasSrc = FALSE;
        const char *ptr;

        FDest = 0;

        if (!ScanCmdLine(param, 0))
                return 1;

        arg = FArgList;

        while (arg)
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

    FSrcFiles.RemoveDuplicates();

        if (FDest)
        {
                if (FDest->IsDir())
                        return MoveFiles();
                else
                {
                    if (FSrcFiles.GetSize() == 1)
                        return MoveSingleFile();
            else
            {
                        FMsg.Load(TEXT_ERROR_MOVE_MULTIPLE);
                        Write(FMsg.GetData());
                        return 1;
            }
        }
        }

        return 0;
}
