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
# rmpart.cpp
# Remove partition command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "rmpart.h"
#include "part.h"

#define PROMPT_BUFFER_SIZE  256

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TRemovePartitionFactory::TRemovePartitionFactory
#
#   Purpose....: Constructor for TRemovePartitionFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRemovePartitionFactory::TRemovePartitionFactory()
  : TCommandFactory("RMPART")
{
}

/*##########################################################################
#
#   Name       : TRemovePartitionFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TRemovePartitionFactory::Create(TSession *session, const char *param)
{
    return new TRemovePartitionCommand(session, param);
}

/*##########################################################################
#
#   Name       : TRemovePartitionCommand::TRemovePartitionCommand
#
#   Purpose....: Constructor for TRemovePartitionCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRemovePartitionCommand::TRemovePartitionCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_RMPART);
}

/*##########################################################################
#
#   Name       : TRemovePartitionCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRemovePartitionCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
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
#   Name       : TRemovePartitionCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRemovePartitionCommand::InitOptions()
{
    FOptY = FALSE;
}

/*##########################################################################
#
#   Name       : TRemovePartitionCommand::Confirm
#
#   Purpose....: Confirm removing partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRemovePartitionCommand::Confirm(TIdeFsPartition *Part)
{
    char DriveStr[4];
    char str[40];

    if (Part->GetDrive())
    {
        DriveStr[0] = 'A' + Part->GetDrive()->GetDriveNr();
        DriveStr[1] = ':';
        DriveStr[2] = 0;

        sprintf(str, "%3.3f MB", Part->GetTotalSpace());

        FMsg.printf(TEXT_RMPART_DRIVE_HEAD, DriveStr, str);
        Write(FMsg.GetData());
    }
    else
    {
        sprintf(str, "%3.3f MB", Part->GetTotalSpace());

        FMsg.printf(TEXT_RMPART_PART_HEAD, FPartNr, FDisc->GetDiscNr(), str);
        Write(FMsg.GetData());
    }

    if (FMsg.UserPrompt(PROMPT_RMPART) == 1)
        return TRUE;

    return FALSE;
}

/*##########################################################################
#
#   Name       : TRemovePartitionCommand::Remove
#
#   Purpose....: Remove a partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRemovePartitionCommand::Remove(TIdeFsPartition *Part)
{
    if (!FOptY)
        if (!Confirm(Part))
            return 1;

    if (Part->GetDrive())
        RdosRemoveDrive(Part->GetDrive()->GetDriveNr());

    FDiscPart->Delete(FPartNr);
    return 0;
}

/*##########################################################################
#
#   Name       : TRemovePartitionCommand::RemovePart
#
#   Purpose....: Remove a partition on selected disc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRemovePartitionCommand::RemovePart()
{
    TPartition *Part = 0;

    if (FPartNr < FDiscPart->PartCount)
        Part = FDiscPart->PartArr[FPartNr];

    if (Part)
        if (Part->IsFs())
            return Remove((TIdeFsPartition *)Part);

    FMsg.printf(TEXT_RMPART_PART_ERROR, FPartNr);
    Write(FMsg.GetData());
    return 1;
}

/*##########################################################################
#
#   Name       : TRemovePartitionCommand::Confirm
#
#   Purpose....: Confirm removing partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRemovePartitionCommand::Confirm(TGptPartition *Part)
{
    char DriveStr[4];
    char str[40];
    int DriveNr;

    DriveNr = FDisc->GetDrive(Part->Start, Part->Size);

    if (DriveNr)
    {
        DriveStr[0] = 'A' + DriveNr;
        DriveStr[1] = ':';
        DriveStr[2] = 0;

        sprintf(str, "%3.3f MB", Part->GetTotalSpace());

        FMsg.printf(TEXT_RMPART_DRIVE_HEAD, DriveStr, str);
        Write(FMsg.GetData());
    }
    else
    {
        sprintf(str, "%3.3f MB", Part->GetTotalSpace());

        FMsg.printf(TEXT_RMPART_PART_HEAD, FPartNr, FDisc->GetDiscNr(), str);
        Write(FMsg.GetData());
    }

    if (FMsg.UserPrompt(PROMPT_RMPART) == 1)
        return TRUE;

    return FALSE;
}

/*##########################################################################
#
#   Name       : TRemovePartitionCommand::Remove
#
#   Purpose....: Remove a partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRemovePartitionCommand::Remove(TGptPartition *Part)
{
    if (!FOptY)
        if (!Confirm(Part))
            return 1;

    return 0;
}

/*##########################################################################
#
#   Name       : TRemovePartitionCommand::RemoveDisc
#
#   Purpose....: Remove a partition on selected disc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRemovePartitionCommand::RemoveDisc()
{
    TGptDiscPartition *GptDisc;

    if (FDisc->IsValid())
    {
        if (FDisc->IsGpt())
        {
            GptDisc = new TGptDiscPartition(FDisc);
            GptDisc->Read();

            if (FPartNr >= 0 && FPartNr < GptDisc->PartCount)
            {
                if (GptDisc->PartArr[FPartNr])
                {
                    if (Remove(GptDisc->PartArr[FPartNr]) == 0)
                    {
                        GptDisc->Remove(GptDisc->PartArr[FPartNr]->Start);
                        GptDisc->Write();
                        delete GptDisc;
                        return 0;
                    }
                }
            }

            delete GptDisc;
        }
        else
        {
            FDiscPart = new TIdeDiscPartition(FDisc);
            if (RemovePart() == 0)
            {
                delete FDiscPart;
                return 0;
            }
            delete FDiscPart;
        }
    }

    FMsg.printf(TEXT_SHOWPART_DISC_ERROR, FDisc->GetDiscNr());
    Write(FMsg.GetData());
    return 1;
}

/*##########################################################################
#
#   Name       : TRemovePartitionCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRemovePartitionCommand::Execute(char *param)
{
    int ret;
    int DiscNr;
    int d;
    InitOptions();

    if (!ScanCmdLine(param, 0))
        return 1;

    if (FArgCount != 2)
    {
        FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
        Write(FMsg.GetData());
        return E_Useage;
    }

    if (sscanf(FArgList->FName.GetData(), "%d", &DiscNr) != 1)
    {
        ErrorSyntax(0);
        return 1;
    }

    if (sscanf(FArgList->FList->FName.GetData(), "%d", &FPartNr) != 1)
    {
        ErrorSyntax(0);
        return 1;
    }

    for (d = 0; d < 16; d++)
    {
        FDisc = new TDisc(d);
        if (FDisc->IsValid())
            if (FDisc->GetDiscNr() == DiscNr)
                break;
        delete FDisc;
        FDisc = 0;
    }

    if (FDisc)
    {
        ret = RemoveDisc();
        delete FDisc;
    }

    return ret;
}

