/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2011, Leif Ekblad
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
# pci.cpp
# PCI command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "partinfo.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TInfoFactory::TInfoFactory
#
#   Purpose....: Constructor for TInfoFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInfoFactory::TInfoFactory(TDisc *Disc)
  : TCommandFactory("INFO")
{
    FDisc = Disc;
}

/*##########################################################################
#
#   Name       : TInfoFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TInfoFactory::Create(TCommandOutput *out, const char *param)
{
    return new TInfoCommand(FDisc, out, param);
}

/*##########################################################################
#
#   Name       : TInfoCommand::TInfoCommand
#
#   Purpose....: Constructor for TInfoCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInfoCommand::TInfoCommand(TDisc *disc, TCommandOutput *out, const char *param)
  : TCommand(out, param)
{
    FHelpScreen = "Show parttool info";
    FDisc = disc;
}

/*##########################################################################
#
#   Name       : TInfoCommand::ShowHeader
#
#   Purpose....: Show disc header
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInfoCommand::ShowHeader()
{
    char str[256];
    long long CacheSize = FDisc->GetCached();
    long long LockSize = FDisc->GetLocked();
    long double cached;
    long double locked;

    RdosGetDiscVendorInfo(FDisc->GetDiscNr(), str, 256);
    FMsg.printf("Disc %d, %s\r\n", FDisc->GetDiscNr(), str);
    Write(FMsg);

    cached = (long double)CacheSize / 1024.0 / 1024.0;
    locked = (long double)LockSize / 1024.0 / 1024.0;
    FMsg.printf("Cached %5.3f MB, locked %5.3f MB\r\n", cached, locked);
    Write(FMsg);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowPart
#
#   Purpose....: Show part
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInfoCommand::ShowPart(TPartition *part)
{
    long long start = part->GetStartSector();
    long long end = start + part->GetSectorCount() - 1;
    int handle = part->Handle;
    const char *fstype;

    switch (part->GetType())
    {
        case PART_TYPE_FAT12:
            fstype = "FAT12";
            break;

        case PART_TYPE_FAT16:
            fstype = "FAT16";
            break;

        case PART_TYPE_FAT32:
            fstype = "FAT32";
            break;

        default:
            fstype = "UNKNOWN";
            break;
    }

    FMsg.printf("%6d %04lX_%08lX-%04lX_%08lX %s \r\n",
                    handle,
                    (int)(start >> 32), (int)(start & 0xFFFFFFFF),
                    (int)(end >> 32), (int)(end & 0xFFFFFFFF),
                    fstype);
    Write(FMsg);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowDisc
#
#   Purpose....: Show disc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInfoCommand::ShowDisc()
{
    long long TotalSectors = FDisc->FSectorCount;
    const char *parttype;
    int i;

    if (FDisc->IsGpt())
        parttype = "GPT";
    else
        parttype = "MBR";

    FMsg.printf("%s: %04lX_%08lX sectors\r\n", parttype, (int)(TotalSectors >> 32), (int)(TotalSectors & 0xFFFFFFFF));
    Write(FMsg);
    Write("HANDLE SECTORS                     FILESYS\r\n");

    for (i = 0; i < FDisc->FCurrPartCount; i++)
        ShowPart(FDisc->FPartArr[i]);
}

/*##########################################################################
#
#   Name       : TInfoCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TInfoCommand::Execute(char *param)
{
    ShowHeader();
    ShowDisc();

    return 0;
}
