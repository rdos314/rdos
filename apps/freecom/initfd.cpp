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
# initfd.cpp
# Init floppy command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#define BOOT_LOADER_SECTORS	16

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "part.h"
#include "fddisc.h"
#include "initfd.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TInitFdFactory::TInitFdFactory
#
#   Purpose....: Constructor for TInitFdFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInitFdFactory::TInitFdFactory()
  : TCommandFactory("INITFD")
{
}

/*##########################################################################
#
#   Name       : TInitFdFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TInitFdFactory::Create(const char *param)
{
	return new TInitFdCommand(param);
}

/*##########################################################################
#
#   Name       : TInitFdCommand::TInitFdCommand
#
#   Purpose....: Constructor for TInitFdCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInitFdCommand::TInitFdCommand(const char *param)
  : TCommand(param)
{
	FHelpScreen.Load(TEXT_CMDHELP_INITFD);
}

/*##########################################################################
#
#   Name       : TInitFdCommand::~TInitFdCommand
#
#   Purpose....: Destructor for TInitFdCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInitFdCommand::~TInitFdCommand()
{
    if (FBootLoader)
        delete FBootLoader;
}

/*##########################################################################
#
#   Name       : TInitFdCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TInitFdCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
	OptError(optstr);
	return E_Useage;
}

/*##########################################################################
#
#   Name       : TInitFdCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitFdCommand::InitOptions()
{
}

/*##########################################################################
#
#   Name       : TInitFdCommand::LoadBootLoader
#
#   Purpose....: Load boot loader into memory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitFdCommand::LoadBootLoader(TDisc *Disc)
{
	FBootLoader = new char[512 * BOOT_LOADER_SECTORS];

	memset(FBootLoader, 0, 512 * BOOT_LOADER_SECTORS);
	FLoaderSize = RdosReadBinaryResource(0, 102, FBootLoader, 512 * BOOT_LOADER_SECTORS);

	FLoaderSectors = 1 + (FLoaderSize - 1) / 512;
}

/*##########################################################################
#
#   Name       : TInitFdCommand::WriteBootSector
#
#   Purpose....: Write boot sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitFdCommand::WriteBootSector(TDisc *Disc)
{
	char *BootSector;
	TBootParam bootp;

	bootp.BytesPerSector = 512;
	bootp.Resv1 = 0;	    
	bootp.MappingSectors = FLoaderSectors;
	bootp.Resv3 = 0;
	bootp.Resv4 = 0;
	bootp.SmallSectors = 2880;
	bootp.Media = 0xF0;
	bootp.Resv6 = 0;
	bootp.SectorsPerCyl = 18;
	bootp.Heads = 2;
	bootp.HiddenSectors = 0;
	bootp.Sectors = 2880;
	bootp.Drive = 0;
	bootp.Resv7 = 0;
	bootp.Signature = 0;
	bootp.Serial = 0;
	memset(bootp.Volume, 0, 11);
	memcpy(bootp.Fs, "RDOS    ", 8);

	BootSector = new char[512];

	Disc->Read(0, BootSector, 512);
	memset(BootSector, 0, 0x200);
	RdosReadBinaryResource(0, 100, BootSector, 0x200);

	memcpy(BootSector + 11, &bootp, sizeof(bootp));

	Disc->Write(0, BootSector, 512);

	delete BootSector;
}

/*##########################################################################
#
#   Name       : TInitFdCommand::WriteBootLoader
#
#   Purpose....: Write boot loader
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitFdCommand::WriteBootLoader(TDisc *Disc)
{
	int Sector;
	char *ptr;
	int size;

	size = FLoaderSize;
	ptr = FBootLoader;

	for (Sector = 1; Sector <= BOOT_LOADER_SECTORS && size >= 0; Sector++)
	{
		Disc->Write(Sector, ptr, 512);
		ptr += 512;
		size -= 512;
	}
}

/*##########################################################################
#
#   Name       : TInitFdCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TInitFdCommand::Execute(char *param)
{
	int DiscNr;
	int BytesPerSector;
	long Sectors;
	int SectorsPerCyl;
	int Heads;
	TFloppyDisc *Disc;
	TDiscPartition *DiscPart;
	TPartition *Part;
	int ok;

	InitOptions();

	if (LeadOptions(&param, 0) != E_None)
		return 1;

	if (sscanf(param, "%d", &DiscNr) == 1)
	{
		Disc = new TFloppyDisc(DiscNr, 512, 2880, 18, 2);
		ok = Disc->IsValid();

		if (ok)
			LoadBootLoader(Disc);
		else
		{
			FMsg.printf(TEXT_SHOWPART_DISC_ERROR, DiscNr);
			Write(FMsg.GetData());
			return 0;
		}
            

        if (ok)
        {            		
    	    WriteBootLoader(Disc);
			WriteBootSector(Disc);
			Disc->Format(2880 - 1 - FLoaderSectors);
    	}
	}

	ErrorSyntax(0);
	return 1;
}

