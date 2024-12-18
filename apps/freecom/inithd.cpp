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

#define BOOT_LOADER_SECTORS     16

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "inithd.h"
#include "idepart.h"
#include "gptpart.h"

#define FALSE 0
#define TRUE !FALSE

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
TCommand *TInitHdFactory::Create(TSession *session, const char *param)
{
        return new TInitHdCommand(session, param);
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
TInitHdCommand::TInitHdCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_INITHD);
}

/*##########################################################################
#
#   Name       : TInitHdCommand::~TInitHdCommand
#
#   Purpose....: Destructor for TInitHdCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInitHdCommand::~TInitHdCommand()
{
        if (FBootLoader)
        delete FBootLoader;
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
        switch(ch)
        {
                case 'R':
                        return OptScanBool(optstr, bool, strarg, &FOptR);

                case 'I':
                        return OptScanBool(optstr, bool, strarg, &FOptI);

                case 'D':
                        return OptScanBool(optstr, bool, strarg, &FOptD);

                case 'G':
                        return OptScanBool(optstr, bool, strarg, &FOptG);

                case 'U':
                        return OptScanBool(optstr, bool, strarg, &FOptU);
        }
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
        FOptR = 0;
        FOptI = 0;
        FOptD = 0;
        FOptG = 0;
        FOptU = 0;
}

/*##########################################################################
#
#   Name       : TInitHdCommand::LoadBootLoader
#
#   Purpose....: Load boot loader into memory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitHdCommand::LoadBootLoader(TDisc *Disc)
{
        FBootLoader = new char[512 * BOOT_LOADER_SECTORS];

        memset(FBootLoader, 0, 512 * BOOT_LOADER_SECTORS);
        FLoaderSize = RdosReadBinaryResource(0, 101, FBootLoader, 512 * BOOT_LOADER_SECTORS);

        FLoaderSectors = 1 + (FLoaderSize - 1) / 512;
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
void TInitHdCommand::WriteBootSector(TDisc *Disc, int IdeDisc)
{
        char *BootSector;
        TBootParam bootp;

        bootp.BytesPerSector = Disc->GetBytesPerSector();

        if (FOptR)
                bootp.Resv1 = 1;
        else
                bootp.Resv1 = 0;

        bootp.MappingSectors = FLoaderSectors;
        bootp.Resv3 = 0;
        bootp.Resv4 = 0;
        bootp.SmallSectors = 0;

        if (FOptI)
                bootp.Media = 0xF1;
        else
                bootp.Media = 0xF0;

        bootp.Resv6 = 0;
        bootp.SectorsPerCyl = Disc->GetSectorsPerCyl();
        bootp.Heads = Disc->GetHeads();
        bootp.HiddenSectors = FLoaderSectors;
        bootp.Sectors = (int)Disc->GetTotalSectors();
        bootp.Drive = 0x80 + IdeDisc;
        bootp.Resv7 = 0;
        bootp.Signature = 0;
        bootp.Serial = 0;
        memset(bootp.Volume, 0, 11);
        memcpy(bootp.Fs, "RDOS    ", 8);

        BootSector = new char[512];

        Disc->Read(0, BootSector, 512);

        if (FOptI)
        {
                memset(BootSector, 0, 0x1FE);
                *(BootSector + 0x1FE) = 0x55;
                *(BootSector + 0x1FF) = 0xAA;
        }
        else
                memset(BootSector, 0, 0x1BE);

        RdosReadBinaryResource(0, 100, BootSector, 0x1BE);

        memcpy(BootSector + 11, &bootp, sizeof(bootp));

        Disc->Write(0, BootSector, 512);

        delete BootSector;
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
void TInitHdCommand::WriteBootLoader(TDisc *Disc)
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
#   Name       : TInitHdCommand::UpdateBootSector
#
#   Purpose....: Update boot sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitHdCommand::UpdateBootSector(TDisc *Disc, int IdeDisc)
{
    char *BootSector;
    TBootParam bootp;

    BootSector = new char[512];

    Disc->Read(0, BootSector, 512);

    memcpy(&bootp, BootSector + 11, sizeof(bootp));
    bootp.Drive = 0x80 + IdeDisc;
    memcpy(BootSector + 11, &bootp, sizeof(bootp));

    Disc->Write(0, BootSector, 512);

    delete BootSector;
}

/*##########################################################################
#
#   Name       : TInitHdCommand::LoadGptLoader
#
#   Purpose....: Load GPT boot loader into memory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitHdCommand::LoadGptLoader(TDisc *Disc)
{
        FBootLoader = new char[512 * 16];

        memset(FBootLoader, 0, 512 * 16);
        FLoaderSize = RdosReadBinaryResource(0, 104, FBootLoader, 512 * 16);

        FLoaderSectors = 16;
}

/*##########################################################################
#
#   Name       : TInitHdCommand::WriteGptSector
#
#   Purpose....: Write GPT boot sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitHdCommand::WriteGptSector(TDisc *Disc, int IdeDisc)
{
    char *BootSector;
    long long Total;
    TBootParam bootp;

    Total = Disc->GetTotalSectors();

    bootp.BytesPerSector = Disc->GetBytesPerSector();
    if (Total > 0xFFFFFFFF)
        Total = 0xFFFFFFFF;

    bootp.BytesPerSector = Disc->GetBytesPerSector();
    bootp.Resv1 = 0;
    bootp.MappingSectors = 0;
    bootp.Resv3 = 0;
    bootp.Resv4 = 0;
    bootp.SmallSectors = 0;
    bootp.Media = 0xF1;
    bootp.Resv6 = 0;
    bootp.SectorsPerCyl = Disc->GetSectorsPerCyl();
    bootp.Heads = Disc->GetHeads();
    bootp.HiddenSectors = 0;
    bootp.Sectors = (int)Total;
    bootp.Drive = 0x80 + IdeDisc;
    bootp.Resv7 = 0;
    bootp.Signature = 0;
    bootp.Serial = 0;
    memset(bootp.Volume, 0, 11);
    memcpy(bootp.Fs, "RDOS    ", 8);

    BootSector = new char[512];

    Disc->Read(0, BootSector, 512);

    memset(BootSector, 0, 0x1FE);

    RdosReadBinaryResource(0, 103, BootSector, 0x1BE);
    *(BootSector + 0x1FE) = 0x55;
    *(BootSector + 0x1FF) = 0xAA;

    *(BootSector + 0x1BE + 4) = 0xEE;
    *(long *)(BootSector + 0x1BE + 8) = 1;
    if (Total > 0xFFFFFFFF)
        *(long *)(BootSector + 0x1BE + 0xC) = 0xFFFFFFFF;
    else
        *(long *)(BootSector + 0x1BE + 0xC) = (int)Total - 1;

    memcpy(BootSector + 11, &bootp, sizeof(bootp));

    Disc->Write(0, BootSector, 512);

    delete BootSector;
}

/*##########################################################################
#
#   Name       : TInitHdCommand::WriteGptLoader
#
#   Purpose....: Write GPT boot loader
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitHdCommand::WriteGptLoader(TDisc *Disc)
{
        int Sector;
        char *ptr;

        ptr = FBootLoader;

        for (Sector = 0x22; Sector < 0x32; Sector++)
        {
            Disc->Write(Sector, ptr, 512);
            ptr += 512;
        }
}

/*##########################################################################
#
#   Name       : TInitHdCommand::InitGpt
#
#   Purpose....: Init GPT
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitHdCommand::InitGpt(TDisc *Disc, int DiscNr)
{
    TGptDiscPartition Part(Disc);

    Disc->Reset();

    LoadGptLoader(Disc);
    WriteGptLoader(Disc);
    WriteGptSector(Disc, DiscNr);
    Part.Write(FLoaderSectors);
}

/*##########################################################################
#
#   Name       : TInitHdCommand::InitUefi
#
#   Purpose....: Init UEFI
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitHdCommand::InitUefi(TDisc *Disc, int IdeDisc)
{
    char *BootSector;
    long long Total;
    TGptDiscPartition Part(Disc);

    Total = Disc->GetTotalSectors();

    BootSector = new char[512];

    memset(BootSector, 0, 0x1FE);

    *(BootSector + 0x1FE) = 0x55;
    *(BootSector + 0x1FF) = 0xAA;

    *(BootSector + 0x1BE + 2) = 2;
    *(BootSector + 0x1BE + 4) = 0xEE;
    *(BootSector + 0x1BE + 5) = 0xFF;
    *(BootSector + 0x1BE + 6) = 0xFF;
    *(BootSector + 0x1BE + 7) = 0xFF;
    *(long *)(BootSector + 0x1BE + 8) = 1;
    if (Total > 0xFFFFFFFF)
        *(long *)(BootSector + 0x1BE + 0xC) = 0xFFFFFFFF;
    else
        *(long *)(BootSector + 0x1BE + 0xC) = (int)Total - 1;

    Disc->Write(0, BootSector, 512);

    delete BootSector;

    Part.Write();
}

/*##########################################################################
#
#   Name       : TInitHd::InitVfs
#
#   Purpose....: Init VFS disc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInitHdCommand::InitVfs(int DiscNr, const char *Cmd)
{
    TWait Wait;
    TVfsDiscCmdWrapper cmd(this, DiscNr, Cmd);

    Wait.Add(&cmd);

    while (!cmd.IsDone())
        Wait.WaitForever();
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
    int CurrDisc;
    int NewDisc;
    int DiscNr;
    TDisc *Disc;
    TDiscPartition *DiscPart;
    TPartition *Part;
    int ok;

    InitOptions();

    if (LeadOptions(&param, 0) != E_None)
        return 1;

    if (FOptI)
        FOptR = 0;

    if (FOptD)
    {
        if (sscanf(param, "%d %d", &CurrDisc, &NewDisc) == 2)
        {
            Disc = new TDisc(CurrDisc);
            ok = Disc->IsValid();

            if (ok)
            {
                UpdateBootSector(Disc, NewDisc);
                return 0;
            }
            ErrorSyntax(0);
            return 1;
        }
    }

    if (sscanf(param, "%d", &DiscNr) == 1)
    {
        if (RdosIsVfsDisc(DiscNr))
        {
            if (FOptG || FOptU)
                InitVfs(DiscNr, "init gpt");
            else
                InitVfs(DiscNr, "init mbr");

            return 0;
        }

        Disc = new TDisc(DiscNr);
        ok = Disc->IsValid();

        if (ok && FOptG)
        {
            InitGpt(Disc, DiscNr);
            return 0;
        }

        if (ok && FOptU)
        {
            InitUefi(Disc, DiscNr);
            return 0;
        }

        if (ok)
        {

            LoadBootLoader(Disc);

            if (FOptI)
                ok = TRUE;
            else
            {
                DiscPart = new TIdeDiscPartition(Disc);
                Part = DiscPart->PartArr[0];
                if (Part)
                    if (Part->Start <= FLoaderSectors + 1)
                        ok = Part->IsFree();

                delete DiscPart;
            }

            if (!ok)
            {
                FMsg.printf(TEXT_INITHD_AVAIL_ERROR, DiscNr);
                Write(FMsg.GetData());
                return 0;
            }

        }
        else
        {
            FMsg.printf(TEXT_SHOWPART_DISC_ERROR, DiscNr);
            Write(FMsg.GetData());
            return 0;
        }


        if (ok)
        {
            Disc->Reset();
            WriteBootLoader(Disc);
            WriteBootSector(Disc, DiscNr);
            return 0;
        }
    }

    ErrorSyntax(0);
    return 1;
}

