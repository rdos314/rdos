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
# unzipc.cpp
# Unzip command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "lang.h"
#include "unzip.h"
#include "unzipc.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : InfoCallback
#
#   Purpose....: Unzip info callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void InfoCallback(TUnzip *unzip, int code, const char *msg)
{
    ((TUnzipCommand *)(unzip->Owner))->InfoCallback(msg);
}

/*##########################################################################
#
#   Name       : TUnzipFactory::TUnzipFactory
#
#   Purpose....: Constructor for TUnzipFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipFactory::TUnzipFactory()
  : TCommandFactory("UNZIP")
{
}

/*##########################################################################
#
#   Name       : TUnzipFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TUnzipFactory::Create(TSession *session, const char *param)
{
    return new TUnzipCommand(session, param);
}

/*##########################################################################
#
#   Name       : TUnzipCommand::TUnzipCommand
#
#   Purpose....: Constructor for TUnzipCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipCommand::TUnzipCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_UNZIP);
}

/*##########################################################################
#
#   Name       : TUnzipCommand::InfoCallback
#
#   Purpose....: Info callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipCommand::InfoCallback(const char *msg)
{
    switch (strlen(msg))
    {
        case 0:
            break;
            
        case 1:
            if (*msg == 0xa)
            {
                Write("\r\n");
                break;
            }

        default:
            Write(msg);
            break;
    }
}

/*##########################################################################
#
#   Name       : TUnzipCommand::Unzip
#
#   Purpose....: Unzip file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipCommand::Unzip(TPathName &ZipFile, TPathName &DestPath)
{
    TUnzip unzip(ZipFile.Get().GetData());
    TUnzipFile *file;
    int ok;
    int i;
    const char *filename;

    unzip.Owner = this;
    unzip.OnInfo = ::InfoCallback;

    for (i = 0; i < unzip.GetFileCount(); i++)
    {
        file = unzip.GetFile(i);
        filename = file->GetFileName();

        TPathName path(DestPath);
        path += filename;
        filename = path.Get().GetData();
        
        ok = file->IsOk();

        if (ok)
            if (file->NeedUpdate(filename))
                ok = file->Extract(filename);

        if (!ok)
        {    
            Write("Unpack failed: ");
            Write(filename);
            Write("\r\n");
        }
    }
}

/*##########################################################################
#
#   Name       : TUnzipCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipCommand::Execute(char *param)
{
    TArg *arg;

    if (LeadOptions(&param, 0) != E_None)
        return 1;

    if (!ScanCmdLine(param, 0))
        return 1;

    arg = FArgList;

    if (arg)
    {
        TPathName zip(arg->FName);
        if (zip.IsFile())
        {
            TPathName dest;

            arg = arg->FList;
            if (arg)
                dest = arg->FName;

            if (!dest.MakeDir())
            {
                FMsg.printf(TEXT_ERROR_DIRFCT_FAILED, "UNZIP", dest.Get().GetData());
                Write(FMsg.GetData());
                return 1;
            }
                
            Unzip(zip, dest);
        }
        else
        {
            FMsg.printf(TEXT_ERROR_DIRFCT_FAILED, "UNZIP", zip.Get().GetData());
            Write(FMsg.GetData());
            return 1;
        }        
    }
    else
    {    
        ErrorSyntax(0);
        return 1;
    }

    return 0;
}
