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
# mkpart.cpp
# Make partition command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "mkpart.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TMakePartitionFactory::TMakePartitionFactory
#
#   Purpose....: Constructor for TMakePartitionFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMakePartitionFactory::TMakePartitionFactory()
  : TCommandFactory("MKPART")
{
}

/*##########################################################################
#
#   Name       : TMakePartitionFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TMakePartitionFactory::Create(const char *param)
{
	return new TMakePartitionCommand(param);
}

/*##########################################################################
#
#   Name       : TMakePartitionCommand::TMakePartitionCommand
#
#   Purpose....: Constructor for TMakePartitionCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMakePartitionCommand::TMakePartitionCommand(const char *param)
  : TCommand(param)
{
	FHelpScreen.Load(TEXT_CMDHELP_MKPART);
}

/*##########################################################################
#
#   Name       : TMakePartitionCommand::Make
#
#   Purpose....: Make partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMakePartitionCommand::Make(int Disc, const char *FsName, int Size)
{
	TDiscPartition *DiscPart;
	int SectorSize;
	long Sectors;
	int BiosSectorsPerCyl;
	int BiosHeads;

	if (RdosGetDiscInfo(Disc, &SectorSize, &Sectors, &BiosSectorsPerCyl, &BiosHeads))
	{
		if (SectorSize)
		{
			DiscPart = new TDiscPartition(Disc);
			if (DiscPart->Add(FsName, Size))
			{
				delete DiscPart;
				return 0;
			}
			else
			{
				FMsg.Load(TEXT_MKPART_ERROR);
				Write(FMsg.GetData());
        		delete DiscPart;
        		return 1;
            }
		}
	}

	FMsg.printf(TEXT_SHOWPART_DISC_ERROR, Disc);
	Write(FMsg.GetData());
	return 1;
}

/*##########################################################################
#
#   Name       : TMakePartitionCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMakePartitionCommand::Execute(char *param)
{
    int Disc;
    long Size;
    const char *FsName;

	if (!ScanCmdLine(param, 0))
		return 1;

	if (FArgCount != 3)
	{
		FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
		Write(FMsg.GetData());
		return E_Useage;
	}

	if (sscanf(FArgList->FName.GetData(), "%d", &Disc) != 1)
	{
		ErrorSyntax(0);
		return 1;
	}

	FsName = FArgList->FList->FName.GetData();

	if (sscanf(FArgList->FList->FList->FName.GetData(), "%d", &Size) != 1)
    {
		ErrorSyntax(0);
		return 1;
	}
    
    return Make(Disc, FsName, Size * 0x800);

}

