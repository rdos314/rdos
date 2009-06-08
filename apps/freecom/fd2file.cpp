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
# fd2file.cpp
# Copy floppy disc to a file command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "lang.h"
#include "fd2file.h"
#include "rdos.h"
#include "path.h"
#include "fddisc.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFloppyToFileFactory::TFloppyToFileFactory
#
#   Purpose....: Constructor for TFloppyToFileFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFloppyToFileFactory::TFloppyToFileFactory()
  : TCommandFactory("FD2FILE")
{
}

/*##########################################################################
#
#   Name       : TFloppyToFileFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TFloppyToFileFactory::Create(TSession *session, const char *param)
{
        return new TFloppyToFileCommand(session, param);
}

/*##########################################################################
#
#   Name       : TFloppyToFileCommand::TFloppyToFileCommand
#
#   Purpose....: Constructor for TFloppyToFileCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFloppyToFileCommand::TFloppyToFileCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_FD2FILE);
}

/*##########################################################################
#
#   Name       : TFloppyToFileCommand::CopyToFile
#
#   Purpose....: Copy to file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFloppyToFileCommand::CopyToFile(TDisc *Disc, TString &Dest)
{
    char *buf;
    int sector;
        TPathName dest(Dest);
        TString fulldest(dest.GetFullPathName());
        TFile file(Dest.GetData(), 0);

        Write("Floppy => ");
        Write(Dest.GetData());
        Write("\r\n");

        buf = new char[0x200];

    for (sector = 0; sector < 2880; sector++)
    {
                Disc->Read(sector, buf, 512);
                file.Write(buf, 512);
        }

        delete buf;

        return 0;
}

/*##########################################################################
#
#   Name       : TFloppyToFileCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFloppyToFileCommand::Execute(char *param)
{
        TArg *arg;
        int HasSrc = FALSE;
        TDisc *Disc;
        int DiscNr;
        int ok;

        if (!ScanCmdLine(param, 0))
                return 1;

    if (FArgCount != 2)
    {
                FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
                Write(FMsg.GetData());
                return E_Useage;
        }

        arg = FArgList;

    ok = FALSE;
    
        if (sscanf(arg->FName.GetData(), "%d", &DiscNr) == 1)
        {
                Disc = new TFloppyDisc(DiscNr, 512, 2880, 18, 2);
                ok = Disc->IsValid();
    }

    if (!ok)
    {
                FMsg.printf(TEXT_SHOWPART_DISC_ERROR, DiscNr);
                Write(FMsg.GetData());
                return 1;
    }

    arg = arg->FList;
        return CopyToFile(Disc, arg->FName);
}
