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
TCommand *TInitFdFactory::Create(TSession *session, const char *param)
{
	return new TInitFdCommand(session, param);
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
TInitFdCommand::TInitFdCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_INITFD);

	FFile = 0;
	FDisc = 0;
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

    if (FFile)
        delete FFile;

    if (FDisc)
        delete FDisc;
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
	switch(ch)
	{
		case 'F':
			return OptScanBool(optstr, bool, strarg, &FOptF);

	}
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
    FOptF = FALSE;
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
void TInitFdCommand::LoadBootLoader()
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
void TInitFdCommand::WriteBootSector()
{
	char *BootSector;
	TBootParam bootp;

	bootp.BytesPerSector = 512;
	bootp.Resv1 = 0;
	bootp.MappingSectors = FLoaderSectors + 1;
	bootp.Resv3 = 0;
	bootp.Resv4 = 0;
	bootp.SmallSectors = 2880;
	bootp.Media = 0xF0;
	bootp.Resv6 = 0;
	bootp.SectorsPerCyl = 18;
	bootp.Heads = 2;
	bootp.HiddenSectors = FLoaderSectors + 1;
	bootp.Sectors = 2880;
	bootp.Drive = 0;
	bootp.Resv7 = 0;
	bootp.Signature = 0;
	bootp.Serial = 0;
	memset(bootp.Volume, 0, 11);
	memcpy(bootp.Fs, "RDOS    ", 8);

	BootSector = new char[512];

	memset(BootSector, 0, 0x200);
	RdosReadBinaryResource(0, 100, BootSector, 0x200);

	memcpy(BootSector + 11, &bootp, sizeof(bootp));

	*(BootSector + 0x1FE) = 0x55;
	*(BootSector + 0x1FF) = 0xAA;

	if (FDisc)
		FDisc->Write(0, BootSector, 512);

	if (FFile)
	{
		FFile->SetPos(0);
		FFile->Write(BootSector, 512);
	}

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
void TInitFdCommand::WriteBootLoader()
{
	int Sector;
	char *ptr;
	int size;

	size = FLoaderSize;
	ptr = FBootLoader;

	for (Sector = 1; Sector <= BOOT_LOADER_SECTORS && size >= 0; Sector++)
	{
		if (FDisc)
			FDisc->Write(Sector, ptr, 512);

		if (FFile)
		{
			FFile->SetPos(512 * Sector);
			FFile->Write(ptr, 512);
		}

		ptr += 512;
		size -= 512;
	}
}

/*##########################################################################
#
#   Name       : TInitFdCommand::WriteFloppy
#
#   Purpose....: Write to floppy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TInitFdCommand::WriteFloppy(char *param)
{
	int ok;
	int DiscNr;
	TFloppyDisc *Disc;

	if (sscanf(param, "%d", &DiscNr) == 1)
	{
		Disc = new TFloppyDisc(DiscNr, 512, 2880, 18, 2);
		FDisc = Disc;
		ok = FDisc->IsValid();

		if (ok)
			LoadBootLoader();
		else
		{
			FMsg.printf(TEXT_SHOWPART_DISC_ERROR, DiscNr);
			Write(FMsg.GetData());
			return 1;
		}


		if (ok)
		{
			WriteBootLoader();
			RdosWaitMilli(4000);
			WriteBootSector();
			RdosWaitMilli(2000);
			Disc->Format(2880 - 1 - FLoaderSectors);
			return 0;
		}
	}

	ErrorSyntax(0);
	return 1;
}

/*##########################################################################
#
#   Name       : TInitFdCommand::WriteFile
#
#   Purpose....: Write to file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TInitFdCommand::WriteFile(char *param)
{
	int ok;

	FFile = new TFile(param, 0);

	ok = FFile->IsOpen();

	if (ok)
		LoadBootLoader();
	else
	{
		FMsg.printf(TEXT_ERROR_SFILE_NOT_FOUND, param);
		Write(FMsg.GetData());
		return 1;
	}


	if (ok)
	{
		WriteBootLoader();
		WriteBootSector();
//		Disc->Format(2880 - 1 - FLoaderSectors);
		return 0;
	}

	ErrorSyntax(0);
	return 1;
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
	InitOptions();

	if (LeadOptions(&param, 0) != E_None)
		return 1;

	if (FOptF)
	    return WriteFile(param);
	else
	    return WriteFloppy(param);

}

