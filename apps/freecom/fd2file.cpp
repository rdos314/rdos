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
