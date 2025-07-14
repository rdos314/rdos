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
# partinfo.cpp
# Partition info class
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
TInfoFactory::TInfoFactory(TDiscServer *Server)
  : TCommandFactory("INFO")
{
    FServer = Server;
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
    return new TInfoCommand(FServer, out, param);
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
TInfoCommand::TInfoCommand(TDiscServer *server, TCommandOutput *out, const char *param)
  : TCommand(out, param)
{
    FHelpScreen = "Show parttool info";
    FServer = server;
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
    int DiscNr = FServer->GetDiscNr();
    char str[256];
    long long CacheSize = RdosGetDiscCache(DiscNr);
    long long LockSize = RdosGetDiscLocked(DiscNr);
    long double cached;
    long double locked;

    RdosGetDiscVendorInfo(DiscNr, str, 256);
    FMsg.printf("Disc %d, %s\r\n", DiscNr, str);
    Write(FMsg);

    cached = (long double)CacheSize / 1024.0 / 1024.0;
    locked = (long double)LockSize / 1024.0 / 1024.0;
    FMsg.printf("Cached %5.3f MB, locked %5.3f MB\r\n", cached, locked);
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
void TInfoCommand::ShowDisc(TDisc *disc)
{
    long long TotalSectors = 0;
    long long CurrSector = 0;
    long long start;
    long long end;
    long double Space;
    TPartition *part;
    const char *parttype;
    const char *fstype;
    char drive;
    int i;

    if (disc)
    {
        TotalSectors = disc->FSectorCount;

        if (disc->IsGpt())
            parttype = "GPT";
        else
            parttype = "MBR";
    }
    else
    {
        TotalSectors = FServer->GetDiscSectors();
        parttype = "NONE";
    }

    FMsg.printf("%s: %04lX_%08lX sectors\r\n", parttype, (int)(TotalSectors >> 32), (int)(TotalSectors & 0xFFFFFFFF));
    Write(FMsg);

    if (disc)
    {
        Write("  DRV           SECTORS            FILESYS        SIZE\r\n");

        for (i = 0; i < disc->FCurrPartCount; i++)
        {
            part = disc->FPartArr[i];

            start = part->GetStartSector();
            end = start + part->GetSectorCount() - 1;
           
            if (CurrSector + 64 < start) 
            {
                Space = (double)(start - CurrSector) * (double)512 / (double)0x100000;
                start--;
                FMsg.printf("-: -- %04lX_%08lX-%04lX_%08lX     Free %8ld MB \r\n",
                    (int)(CurrSector >> 32), (int)(CurrSector & 0xFFFFFFFF),
                    (int)(start >> 32), (int)(start & 0xFFFFFFFF),
                    (int)Space);
                Write(FMsg);
                start++;
            }

            switch (part->GetType())
            {
                case PART_TYPE_FAT12:
                    fstype = "    FAT12";
                    break;

                case PART_TYPE_FAT16:
                    fstype = "    FAT16";
                    break;

                case PART_TYPE_FAT32:
                    fstype = "    FAT32";
                    break;

                case PART_TYPE_FAT:
                    fstype = "     FAT";
                    break;

                case PART_TYPE_EFI:
                    fstype = "     EFI";
                    break;

                default:
                    fstype = "UNKNOWN";
                    break;
            }

            Space = (double)(end - start) * (double)512 / (double)0x100000;
            drive = part->GetDrive();

            if (drive)
                FMsg.printf("%d: %c: %04lX_%08lX-%04lX_%08lX %s %8ld MB \r\n",
                        i,
                        drive + 'A',
                        (int)(start >> 32), (int)(start & 0xFFFFFFFF),
                        (int)(end >> 32), (int)(end & 0xFFFFFFFF),
                        fstype,
                        (int)Space);
            else
                FMsg.printf("%d: -- %04lX_%08lX-%04lX_%08lX %s %8ld MB \r\n",
                        i,
                        (int)(start >> 32), (int)(start & 0xFFFFFFFF),
                        (int)(end >> 32), (int)(end & 0xFFFFFFFF),
                        fstype,
                        (int)Space);
            Write(FMsg);

            CurrSector = end;
        }

        end = TotalSectors - 34;

        if (CurrSector < end) 
        {
            Space = (double)(TotalSectors - CurrSector) * (double)512 / (double)0x100000;
            FMsg.printf("-: -- %04lX_%08lX-%04lX_%08lX     Free %8ld MB \r\n",
                (int)(CurrSector >> 32), (int)(CurrSector & 0xFFFFFFFF),
                (int)(end >> 32), (int)(end & 0xFFFFFFFF),
                (int)Space);
            Write(FMsg);
        }
    }
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
    TDisc *disc = FServer->GetDisc();

    ShowHeader();
    ShowDisc(disc);

    return 0;
}
