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
# disktool.cpp
# Tool for creating bootable disks
#
########################################################################*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "disc.h"
#include "part.h"
#include "idedisc.h"
#include "fatpart.h"

#define BOOT_LOADER_SECTORS     16

#define FALSE   0
#define TRUE    !FALSE

int LoaderSectors;
char *BootCode;
int BootSize;
char *BootLoader;
int LoaderSize;

/*##########################################################################
#
#   Name       : ShowPartEntry
#
#   Purpose....: Show entry table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ShowPartEntry(int Nr, TPartition *Entry)
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
            if (Entry->IsFs() && Entry->GetDrive())
                Drive = Entry->GetDrive()->GetDriveNr();
            else
                Drive = 0;

            if (Drive)
            {
                DriveStr[0] = 'A' + (char)Drive;
                DriveStr[1] = ':';
                DriveStr[2] = 0;
                              
                FreeSpace = Entry->GetFreeSpace();

                printf(
                          "%d: %s %02hX %08lX-%08lX %8s %15.3f MB %15.3f MB\r\n",
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
                printf(
                          "%d: -- %02hX %08lX-%08lX %8s %15.3f MB\r\n",
                          Nr,
                          Typ,
                          Entry->Start,
                          Entry->Start + Entry->Size - 1,
                          Name,
                          TotalSpace);
        }
        else
            printf("%d: -- No entry\r\n", Nr);
    }
}

/*##########################################################################
#
#   Name       : ShowPartTable
#
#   Purpose....: Show partition table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ShowPartTable(TDiscPartition *Part)
{
    int i;
    TDisc *Disc;

    Disc = Part->GetDisc();

    printf(    "Disc %d %08lX BIOS sectors / cyl %04X, heads %04X\r\n",
                Disc->GetDiscNr(), Disc->GetTotalSectors(), 
                Disc->GetSectorsPerCyl(), Disc->GetHeads());

    printf("DRV TYPE    SECTORS       FILESYS         TOTAL SIZE          FREE SIZE\r\n");

    for (i = 0; i < Part->PartCount; i++)
        ShowPartEntry(i, Part->PartArr[i]);
}

/*##########################################################################
#
#   Name       : ShowOnePart
#
#   Purpose....: Show one partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ShowOnePart(TDisc *Disc)
{
    TDiscPartition *DiscPart;

    if (Disc->IsValid())
    {
        DiscPart = new TDiscPartition(Disc);
        ShowPartTable(DiscPart);
        delete DiscPart;
    }
}

/*##########################################################################
#
#   Name       : ShowPart
#
#   Purpose....: Show partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ShowPart()
{
    int DiscNr;
    TDisc *Disc;
    
    for (DiscNr = 0; DiscNr < 16; DiscNr++)
    {
        Disc = new TDisc(DiscNr);
        if (Disc->IsValid())
            ShowOnePart(Disc);
        delete Disc;
    }
}

/*##########################################################################
#
#   Name       : FindCf
#
#   Purpose....: Find possible CF disk
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int FindCf()
{
    int DiscNr;
    TDisc *Disc;
    long Sectors;
    
    for (DiscNr = 0; DiscNr < 16; DiscNr++)
    {
        Disc = new TDisc(DiscNr);
        if (Disc->IsValid())
            Sectors = Disc->GetTotalSectors();
            if (Sectors > 7000000 && Sectors < 8000000)
                return DiscNr;
        delete Disc;
    }
    return -1;
}

/*##########################################################################
#
#   Name       : LoadBootLoader
#
#   Purpose....: Load boot loader into memory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void LoadBootLoader(TDisc *Disc)
{
    BootCode = new char[512];
    BootSize = RdosReadBinaryResource(0, 100, BootCode, 0x1BE);

    BootLoader = new char[512 * BOOT_LOADER_SECTORS];

    memset(BootLoader, 0, 512 * BOOT_LOADER_SECTORS);
    LoaderSize = RdosReadBinaryResource(0, 101, BootLoader, 512 * BOOT_LOADER_SECTORS);

    LoaderSectors = 1 + (LoaderSize - 1) / 512;
}

/*##########################################################################
#
#   Name       : WriteMbrSector
#
#   Purpose....: Write MBR sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void WriteMbrSector(TDisc *Disc, int IdeDisc)
{
    char *BootSector;
    TBootParam bootp;

    bootp.BytesPerSector = Disc->GetBytesPerSector();
    bootp.Resv1 = 0;
    bootp.MappingSectors = LoaderSectors;
    bootp.Resv3 = 0;
    bootp.Resv4 = 0;
    bootp.SmallSectors = 0;
    bootp.Media = 0xF1;
    bootp.Resv6 = 0;
    bootp.SectorsPerCyl = Disc->GetSectorsPerCyl();
    bootp.Heads = Disc->GetHeads();
    bootp.HiddenSectors = LoaderSectors;
    bootp.Sectors = Disc->GetTotalSectors();
    bootp.Drive = 0x80 + IdeDisc;
    bootp.Resv7 = 0;
    bootp.Signature = 0;
    bootp.Serial = 0;
    memset(bootp.Volume, 0, 11);
    memcpy(bootp.Fs, "RDOS    ", 8);

    BootSector = new char[512];

    Disc->Read(0, BootSector, 512);

    memset(BootSector, 0, 0x1FE);
    *(BootSector + 0x1FE) = 0x55;
    *(BootSector + 0x1FF) = 0xAA;

    RdosReadBinaryResource(0, 100, BootSector, 0x1BE);

    memcpy(BootSector + 11, &bootp, sizeof(bootp));

    Disc->Write(0, BootSector, 512);

    delete BootSector;
}

/*##########################################################################
#
#   Name       : WriteBootLoader
#
#   Purpose....: Write boot loader
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void WriteBootLoader(TDisc *Disc)
{
    int Sector;
    char *ptr;
    int size;

    size = LoaderSize;
    ptr = BootLoader;

    for (Sector = 1; Sector <= BOOT_LOADER_SECTORS && size >= 0; Sector++)
    {
        Disc->Write(Sector, ptr, 512);
        ptr += 512;
        size -= 512;
    }
}

/*##########################################################################
#
#   Name       : MakeBootable
#
#   Purpose....: Make disk bootable
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void MakeBootable(int DiscNr)
{
    int ok;
    TDisc *Disc;
    TDiscPartition *DiscPart;
    TPartition *Part;
    
    Disc = new TIdeDisc(DiscNr);
    ok = Disc->IsValid();

    if (ok)
    {
        LoadBootLoader(Disc);

        DiscPart = new TDiscPartition(Disc);
        Part = DiscPart->PartArr[0];
        if (Part)
            if (Part->Start <= LoaderSectors + 1)
                ok = Part->IsFree();

        delete DiscPart;

        if (!ok)
            printf( "Not enough free sectors at the begining of disc %d\r\n", 
                    DiscNr);

    }
    else
        printf(    "Disc %d not found\r\n", DiscNr);

    if (ok)
    {
        WriteBootLoader(Disc);
        WriteMbrSector(Disc, DiscNr);
    }
}

/*##########################################################################
#
#   Name       : MakeBootPart
#
#   Purpose....: Make boot partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int MakeBootPart(int DiscNr)
{
    TDisc *Disc;
    TDiscPartition *DiscPart;
    TFat16PartitionFactory fact;

    Disc = new TIdeDisc(DiscNr);

    if (Disc->IsValid())
    {
        DiscPart = new TDiscPartition(Disc);
        if (DiscPart->Add("FAT16", 120 * 2048, BootCode, BootSize))
            return TRUE;
    }
    return FALSE;
}

int main()
{
    int DiscNr;
    int ok = FALSE;

    printf("Formatting disk...");
    
    RdosWaitMilli(2500);
    DiscNr = FindCf();
    if (DiscNr >= 0)
    {
        MakeBootable(DiscNr);
        ok = MakeBootPart(DiscNr);
    }

    printf("\r\n");

    if (ok)
    {
        RdosWaitMilli(5000);

        printf("Disk ok\r\n");

        for (;;)
            RdosWaitMilli(1000);
    }
    else
    {
        printf("Retrying\r\n");
        RdosWaitMilli(2000);
        RdosSoftReset();
    }
        
    return 0;
}

