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

#define PROMPT_BUFFER_SIZE	256

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
TCommand *TRemovePartitionFactory::Create(const char *param)
{
	return new TRemovePartitionCommand(param);
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
TRemovePartitionCommand::TRemovePartitionCommand(const char *param)
  : TCommand(param)
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
int TRemovePartitionCommand::Confirm(TFsPartition *Part)
{
    char DriveStr[4];
    char str[40];

    if (Part->GetDrive())
    {
        DriveStr[0] = 'A' + Part->GetDrive();
        DriveStr[1] = ':';
        DriveStr[2] = 0;   

		sprintf(str, "%3.3f MB", Part->GetTotalSpace());

		FMsg.printf(TEXT_RMPART_DRIVE_HEAD, DriveStr, str);
		Write(FMsg.GetData());
	}
	else
	{
		sprintf(str, "%3.3f MB", Part->GetTotalSpace());

    	FMsg.printf(TEXT_RMPART_PART_HEAD, FPartNr, FDisc);    
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
int TRemovePartitionCommand::Remove(TFsPartition *Part)
{
    if (!FOptY)
        if (!Confirm(Part))
            return 1;

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
			return Remove((TFsPartition *)Part);

	FMsg.printf(TEXT_RMPART_PART_ERROR, FPartNr);
	Write(FMsg.GetData());
	return 1;
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
	int SectorSize;
	long Sectors;
	int BiosSectorsPerCyl;
	int BiosHeads;

	if (RdosGetDiscInfo(FDisc, &SectorSize, &Sectors, &BiosSectorsPerCyl, &BiosHeads))
	{
		if (SectorSize)
		{
			FDiscPart = new TDiscPartition(FDisc);
			if (RemovePart() == 0)
			{
				delete FDiscPart;
				return 0;
    	    }
    		delete FDiscPart;
		}
	}

	FMsg.printf(TEXT_SHOWPART_DISC_ERROR, FDisc);
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
	InitOptions();

	if (!ScanCmdLine(param, 0))
		return 1;

	if (FArgCount != 2)
	{
		FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
		Write(FMsg.GetData());
		return E_Useage;
	}

	if (sscanf(FArgList->FName.GetData(), "%d", &FDisc) != 1)
	{
		ErrorSyntax(0);
		return 1;
	}

	if (sscanf(FArgList->FList->FName.GetData(), "%d", &FPartNr) != 1)
    {
		ErrorSyntax(0);
		return 1;
	}

	return RemoveDisc();
}

