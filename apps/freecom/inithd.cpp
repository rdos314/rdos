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
# inithd.cpp
# Init harddrive command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#define BOOT_LOADER_SECTORS	16

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "inithd.h"

#define FALSE 0
#define TRUE !FALSE

struct TBootParam
{
	short int BytesPerSector;
	char Resv1;
	short int MappingSectors;
	char Resv3;
	short int Resv4;
	short int SmallSectors;
	char Media;
	short int Resv6;
	short int SectorsPerCyl;
	short int Heads;
	int HiddenSectors;
	int Sectors;
	char Drive;
	char Resv7;
	char Signature;
	int Serial;
	char Volume[11];
	char Fs[8];
};

/*##########################################################################
#
#   Name       : TInitHdFactory::TInitHdFactory
#
#   Purpose....: Constructor for TInitHdFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInitHdFactory::TInitHdFactory()
  : TCommandFactory("INITHD")
{
}

/*##########################################################################
#
#   Name       : TInitHdFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TInitHdFactory::Create(const char *param)
{
	return new TInitHdCommand(param);
}

/*##########################################################################
#
#   Name       : TInitHdCommand::TInitHdCommand
#
#   Purpose....: Constructor for TInitHdCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInitHdCommand::TInitHdCommand(const char *param)
  : TCommand(param)
{
	FHelpScreen.Load(TEXT_CMDHELP_INITHD);
}

/*##########################################################################
#
#   Name       : TInitHdCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TInitHdCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
	OptError(optstr);
	return E_Useage;
}

/*##########################################################################
#
#   Name       : TInitHdCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitHdCommand::InitOptions()
{
}

/*##########################################################################
#
#   Name       : TInitHdCommand::WriteBootSector
#
#   Purpose....: Write boot sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitHdCommand::WriteBootSector(int Disc)
{
	char *BootSector;
	int BytesPerSector;
	long Sectors;
	int SectorsPerCyl;
	int Heads;
	TBootParam bootp;

	if (RdosGetDiscInfo(Disc, &BytesPerSector, &Sectors, &SectorsPerCyl, &Heads))
	{
		bootp.BytesPerSector = BytesPerSector;
		bootp.Resv1 = 0;
		bootp.MappingSectors = FLoaderSectors;
		bootp.Resv3 = 0;
		bootp.Resv4 = 0;
		bootp.SmallSectors = 0;
		bootp.Media = 0xF0;
		bootp.Resv6 = 0;
		bootp.SectorsPerCyl = SectorsPerCyl;
		bootp.Heads = Heads;
		bootp.HiddenSectors = FLoaderSectors;
		bootp.Sectors = Sectors;
		bootp.Drive = 0x80;
		bootp.Resv7 = 0;
		bootp.Signature = 0;
		bootp.Serial = 0;
		memset(bootp.Volume, 0, 11);
		memcpy(bootp.Fs, "RDOS    ", 8);

		BootSector = new char[512];

		RdosReadDisc(Disc, 0, BootSector, 512);
		memset(BootSector, 0, 0x1BE);
		RdosReadBinaryResource(0, 100, BootSector, 0x1BE);

		memcpy(BootSector + 11, &bootp, sizeof(bootp));

		RdosWriteDisc(Disc, 0, BootSector, 512);

		delete BootSector;
	}
}

/*##########################################################################
#
#   Name       : TInitHdCommand::WriteBootLoader
#
#   Purpose....: Write boot loader
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitHdCommand::WriteBootLoader(int Disc)
{
	char *BootLoader;
	int size;
	int Sector;
	char *ptr;

	BootLoader = new char[512 * BOOT_LOADER_SECTORS];

	memset(BootLoader, 0, 512 * BOOT_LOADER_SECTORS);
	size = RdosReadBinaryResource(0, 101, BootLoader, 512 * BOOT_LOADER_SECTORS);

	ptr = BootLoader;
	FLoaderSectors = 0;
	for (Sector = 1; Sector <= BOOT_LOADER_SECTORS && size >= 0; Sector++)
	{
		RdosWriteDisc(Disc, Sector, ptr, 512);
		FLoaderSectors++;
		ptr += 512;
		size -= 512;
	}

	delete BootLoader;
}

/*##########################################################################
#
#   Name       : TInitHdCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TInitHdCommand::Execute(char *param)
{
	int Disc;
	int BytesPerSector;
	long Sectors;
	int SectorsPerCyl;
	int Heads;

	InitOptions();

	if (LeadOptions(&param, 0) != E_None)
		return 1;

	if (sscanf(param, "%d", &Disc) == 1)
	{
    	if (RdosGetDiscInfo(Disc, &BytesPerSector, &Sectors, &SectorsPerCyl, &Heads))
    	    if (BytesPerSector == 512)
    	    {
    	        WriteBootLoader(Disc);
    	        WriteBootSector(Disc);
    	        return 0;
    	    }
	}

	ErrorSyntax(0);
	return 1;
}

