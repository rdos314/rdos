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
# showpart.cpp
# Show partition command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "showpart.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TShowPartitionFactory::TShowPartitionFactory
#
#   Purpose....: Constructor for TShowPartitionFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShowPartitionFactory::TShowPartitionFactory()
  : TCommandFactory("SHOWPART")
{
}

/*##########################################################################
#
#   Name       : TShowPartitionFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TShowPartitionFactory::Create(const char *param)
{
	return new TShowPartitionCommand(param);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::TShowPartitionCommand
#
#   Purpose....: Constructor for TShowPartitionCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShowPartitionCommand::TShowPartitionCommand(const char *param)
  : TCommand(param)
{
	FHelpScreen.Load(TEXT_CMDHELP_SHOWPART);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShowPartitionCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
	switch(ch)
	{
		case 'D':
			return OptScanBool(optstr, bool, strarg, &FOptD);
	}
	OptError(optstr);
	return E_Useage;
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::InitOptions()
{
	FOptD = 0;
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowEntry
#
#   Purpose....: Show entry table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowEntry(int Nr, TPartition *Entry)
{
	const char *Name;
	int Typ;
	double TotalSpace;
	double FreeSpace;
	int Drive;
	char DriveStr[4];
	
	if (Entry)
	{
		Name = Entry->GetPartName();
		Typ = Entry->GetType();
		TotalSpace = Entry->GetTotalSpace();

		if (Entry->Size)
		{
		    if (Entry->IsFs())
		        Drive = Entry->GetDrive();
		    else
		        Drive = 0;

			if (Drive)
			{
			    DriveStr[0] = 'A' + (char)Drive;
			    DriveStr[1] = ':';
			    DriveStr[2] = 0;
			      
			    FreeSpace = Entry->GetFreeSpace();

                FMsg.printf(TEXT_SHOWPART_DRIVE_ENTRY,
	    				Nr,
						DriveStr,
    					Typ,
	    				Entry->Start,
		    			Entry->Start + Entry->Size - 1,
			    		Name,
				    	TotalSpace,
				    	FreeSpace);
			}
			else
                FMsg.printf(TEXT_SHOWPART_UNKNOWN_ENTRY,
					    Nr,
						Typ,
						Entry->Start,
    					Entry->Start + Entry->Size - 1,
	    				Name,
		    			TotalSpace);
		}
		else
            FMsg.printf(TEXT_SHOWPART_FREE_ENTRY, Nr);

    	Write(FMsg.GetData());
	}
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowTreeTable
#
#   Purpose....: Show tree table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowTreeTable(TPartitionTable *Part)
{
	int i;
	TPartition *Entry;
    double TotalSpace;

	TotalSpace = Part->GetTotalSpace();

    FMsg.printf(TEXT_SHOWPART_PART_RANGE,
    			Part->Start,
	    		Part->Start + Part->Size - 1,
		    	TotalSpace);
		    	
	Write(FMsg.GetData());

	for (i = 0; i < 4; i++)
	    ShowEntry(i, Part->PartArr[i]);

	for (i = 0; i < 4; i++)
	{
		Entry = Part->PartArr[i];
		if (Entry)
			if (Entry->IsTable())
				ShowTreeTable((TPartitionTable *)Entry);
	}
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowTree
#
#   Purpose....: Show tree
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowTree(TDiscPartition *Part)
{
    FMsg.printf(TEXT_SHOWPART_DISC_SHORT, Part->GetDisc());
	Write(FMsg.GetData());

	 FMsg.Load(TEXT_SHOWPART_HEADER);
	Write(FMsg.GetData());
	
	if (Part->PartRoot)
		ShowTreeTable(Part->PartRoot);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowTable
#
#   Purpose....: Show table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowTable(TDiscPartition *Part)
{
	int i;
	TPartition *Entry;
	int BytesPerSector;
	long Sectors;
	int SectorsPerCyl;
	int Heads;

	RdosGetDiscInfo(Part->GetDisc(), &BytesPerSector, &Sectors, &SectorsPerCyl, &Heads);

    FMsg.printf(TEXT_SHOWPART_DISC_LONG, Part->GetDisc(), Sectors, SectorsPerCyl, Heads);
	Write(FMsg.GetData());

	 FMsg.Load(TEXT_SHOWPART_HEADER);
	Write(FMsg.GetData());
	
	for (i = 0; i < Part->PartCount; i++)
	    ShowEntry(i, Part->PartArr[i]);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::Show
#
#   Purpose....: Show result
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::Show(TDiscPartition *Part)
{
    if (FOptD)
        ShowTree(Part);
    else
        ShowTable(Part);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShowPartitionCommand::Execute(char *param)
{
    TDiscPartition *DiscPart;
    int Disc;

	InitOptions();

	if (LeadOptions(&param, 0) != E_None)
		return 1;

	/* if no parameters, show all */
	if (*param == 0)
	{
        for (Disc = 0; Disc < 25; Disc++)
        {
            DiscPart = new TDiscPartition(Disc);
            if (DiscPart->BytesPerSector)
                Show(DiscPart);
            delete DiscPart;
        }
        return 0;
	}

    if (sscanf(param, "%d", &Disc) == 1)
    {
        DiscPart = new TDiscPartition(Disc);
        if (DiscPart->BytesPerSector)
            Show(DiscPart);              
        else
        {
        	FMsg.printf(TEXT_SHOWPART_DISC_ERROR, Disc);
		    Write(FMsg.GetData());
		}
        delete DiscPart;
    }
    else
    {
		ErrorSyntax(0);
		return 1;
    }
    
	return 0;
}

