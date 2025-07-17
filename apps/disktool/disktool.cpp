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
#include "fatpart.h"
#include "idepart.h"
#include "file.h"

#define BOOT_LOADER_SECTORS     16

#define FALSE   0
#define TRUE    !FALSE

int LoaderSectors;
char *BootCode;
int BootSize;
char *BootLoader;
int LoaderSize;

static TIdeFsPartitionFactory *ifat16;

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
void ShowPartEntry(int Nr, TIdePartition *Entry)
{
    const char *Name;
    int Typ;
    double TotalSpace;
    double FreeSpace;
    int DriveNr;
    TDrive *Drive;
    char DriveStr[4];

    if (Entry)
    {
        Name = Entry->GetPartName();
        Typ = Entry->GetType();
        TotalSpace = Entry->GetTotalSpace();

        if (Entry->Size)
        {
            if (Entry->IsFs() && Entry->GetDrive())
            {
                Drive = Entry->GetDrive();
                if (Drive)
                    DriveNr = Drive->GetDriveNr();
                else
                    DriveNr = 0;
            }
            else
                DriveNr = 0;

            if (DriveNr)
            {
                DriveStr[0] = 'A' + (char)DriveNr;
                DriveStr[1] = ':';
                DriveStr[2] = 0;
                              
                FreeSpace = Entry->GetFreeSpace();

                printf(     "%d: %s %02hX %08lX-%08lX %8s %15.3f MB %15.3f MB\r\n",
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
                printf(     "%d: -- %02hX %08lX-%08lX %8s %15.3f MB\r\n",
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
#   Name       : ShowFreeEntry
#
#   Purpose....: Show free entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ShowFreeEntry(int Nr, TPartition *Entry)
{
    const char *Name;
    double TotalSpace;
    double FreeSpace;
    char str[100];

    Name = Entry->GetPartName();
    TotalSpace = Entry->GetTotalSpace();

    sprintf(str,
            "%d: -- -- %08lX-%08lX %8s %15.3f MB\r\n",
             Nr,
             Entry->Start,
             Entry->Start + Entry->Size - 1,
             Name,
             TotalSpace);
    printf(str);
}

/*##########################################################################
#
#   Name       : ShowPartTable
#
#   Purpose....: Show table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ShowPartTable(TIdeDiscPartition *Part)
{
    int i;
    TDisc *Disc;
    long long TotalSectors;
    TPartition *Entry;

    Disc = Part->GetDisc();

    printf(    "Disc %d %08lX BIOS sectors / cyl %04X, heads %04X\r\n",
                Disc->GetDiscNr(), Disc->GetTotalSectors(), 
                Disc->GetSectorsPerCyl(), Disc->GetHeads());

    printf("DRV TYPE    SECTORS       FILESYS         TOTAL SIZE          FREE SIZE\r\n");

    for (i = 0; i < Part->PartCount; i++)
    {
        Entry = Part->PartArr[i];
        if (Entry)
        {
            if (Entry->IsFree())
                ShowFreeEntry(i, Entry);
            else
                ShowPartEntry(i, (TIdePartition *)Entry);
        }
    }
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
    TIdeDiscPartition *DiscPart;

    if (Disc->IsValid())
    {
        DiscPart = new TIdeDiscPartition(Disc);
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
#   Name       : GetDiscCount
#
#   Purpose....: Get number of discs
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetDiscCount()
{
    int DiscNr;
    TDisc *Disc;
    int count = 0;
    
    for (DiscNr = 0; DiscNr < 16; DiscNr++)
    {
        Disc = new TDisc(DiscNr);
        if (Disc->IsValid())
            count++;

        delete Disc;
    }
    return count;
}

/*##########################################################################
#
#   Name       : FindUsb
#
#   Purpose....: Find USB disc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int FindUsb()
{
    int DiscNr;
    TDisc *Disc;
    int i;
    int count = 0;
    TIdeDiscPartition *DiscPart;
    TPartition *Part = 0;
    TDrive *Drive;
    
    for (DiscNr = 1; DiscNr < 16; DiscNr++)
    {
        Disc = new TDisc(DiscNr);
        if (Disc->IsValid())
        {
            DiscPart = new TIdeDiscPartition(Disc);

            for (i = 0; i < DiscPart->PartCount; i++)
            {
                Part = DiscPart->PartArr[i];

                if (Part)
                {
                    Drive = Part->GetDrive();

                    if (Drive)
                    {
                        if (Drive->GetDriveNr() == 'Y' - 'A')
                        {
                            delete DiscPart;
                            delete Disc;
                            return DiscNr;
                        }
                    }
                }
            }
            delete DiscPart;
        }
        delete Disc;
    }
    return -1;
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
        {
            Sectors = Disc->GetTotalSectors();
            if (Sectors > 7000000 && Sectors < 16000000)
            {
                delete Disc;
                return DiscNr;
            }
        }
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
void WriteMbrSector(TDisc *Disc, int DiscNr)
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
    bootp.Drive = 0x80 + DiscNr;
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
    TIdeDiscPartition *DiscPart;
    TIdePartition *Part;
    
    Disc = new TDisc(DiscNr);
    ok = Disc->IsValid();

    if (ok)
    {
        LoadBootLoader(Disc);

        DiscPart = new TIdeDiscPartition(Disc);
        Part = (TIdePartition *)DiscPart->PartArr[0];
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
    int ok;
    TDisc *Disc;
    TIdeDiscPartition *DiscPart;

    Disc = new TDisc(DiscNr);

    if (Disc->IsValid())
    {
        DiscPart = new TIdeDiscPartition(Disc);
        ok = DiscPart->Add("FAT16", 120 * 2048, BootCode, BootSize);

        RdosWaitMilli(1000);
        Disc->WaitForIdle();
        delete DiscPart;
    }
    return ok;
}

/*##########################################################################
#
#   Name       : RemovePart
#
#   Purpose....: Remove partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int RemovePart(TDiscPartition *DiscPart)
{
    int i;
    int ok = FALSE;
    TPartition *Part = 0;

    for (i = 0; i < DiscPart->PartCount; i++)
    {
        Part = DiscPart->PartArr[i];

        if (Part && Part->IsFs())
        {
            DiscPart->Delete(i);
            ok = TRUE;
        }
    }
    return ok;
}

/*##########################################################################
#
#   Name       : RemoveDisc
#
#   Purpose....: Remove all partitions on disc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int RemoveDisc(int DiscNr)
{
    TDisc *Disc;
    TIdeDiscPartition *DiscPart;
    int ok = FALSE;

    Disc = new TDisc(DiscNr);

    if (Disc->IsValid())
    {
        DiscPart = new TIdeDiscPartition(Disc);
        ok = RemovePart(DiscPart);
        delete DiscPart;
    }
    return ok;
}

/*##########################################################################
#
#   Name       : GetPartCount
#
#   Purpose....: Get disc partition count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetPartCount(int DiscNr)
{
    int i;
    int count = 0;
    TDisc *Disc;
    TIdeDiscPartition *DiscPart;
    TPartition *Part = 0;

    Disc = new TDisc(DiscNr);

    if (Disc->IsValid())
    {
        DiscPart = new TIdeDiscPartition(Disc);

        for (i = 0; i < DiscPart->PartCount; i++)
        {
            Part = DiscPart->PartArr[i];

            if (Part && Part->IsFs())
                count++;
        }

        delete DiscPart;
    }

    return count;
}

/*##########################################################################
#
#   Name       : HasBoot
#
#   Purpose....: Check for boot-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int HasBoot()
{
    TFile file("c:\\rdos.bin");

    return file.IsOpen();
}

/*##########################################################################
#
#   Name       : CopyBootFile
#
#   Purpose....: Copy boot-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int CopyBootFile(const char *FileName)
{
    TFile *infile;
    TFile *outfile;
    char *buf;
    int size;
    char str[256];

    strcpy(str, "y:\\boot\\");
    strcat(str, FileName);

    infile = new TFile(str);

    if (infile->IsOpen())
    {
        strcpy(str, "c:\\");
        strcat(str, FileName);
        outfile = new TFile(str, 0);
        
        buf = new char[0x10000];

        size = 1;
        while (size)
        {
            size = infile->Read(buf, 0x10000);
            if (size)
                outfile->Write(buf, size);
        }

        delete infile;
        delete outfile;
        delete buf;

        return TRUE;
    }

    delete infile;
    return FALSE;
            
}

int main()
{
    int DiscNr;
    int UsbDiscNr;
    int ok = FALSE;
    int DiscCount;
    int i;
    
    RdosWaitMilli(2500);

    printf("Waiting for USB disc.");

    ifat16 = new TIdeFat16PartitionFactory;

    for (i = 0; i < 100; i++)
    {
        DiscCount = GetDiscCount();

        if (DiscCount == 2)
        {
            UsbDiscNr = FindUsb();

            if (UsbDiscNr >= 0)
                break;
        }
        printf(".");
        RdosWaitMilli(250);
    }

    printf("\r\n");

    if (DiscCount != 2)
    {
        ShowPart();
        RdosWaitMilli(25000);
        RdosSoftReset();
    }
    
    DiscNr = FindCf();
    if (DiscNr >= 0 && DiscNr != UsbDiscNr)
    {
        switch (GetPartCount(DiscNr))
        {
            case 0:            
                RdosWriteSerialRaw(0, 10, 3);

                printf("Formatting disk...");
                MakeBootable(DiscNr);
                ok = MakeBootPart(DiscNr);
                RdosWaitMilli(5000);
                RdosSoftReset();
                break;

            case 1:
                if (HasBoot())
                {
                    RdosWriteSerialRaw(0, 10, 2);
                
                    RemoveDisc(DiscNr);
                    printf("Removing partitions...");
                    RdosWaitMilli(2000);
                    RdosSoftReset();
                }

                RdosWriteSerialRaw(0, 10, 4);

                RdosWaitMilli(1000);
    
                printf("Copying boot\r\n");

                if (!CopyBootFile("rdos.bin"))
                {
                    printf("Retrying\r\n");
                    RdosWaitMilli(2000);
                    RdosSoftReset();
                }

                CopyBootFile("system.ini");                

                RdosWaitMilli(5000);
    
                printf("Disc ok\r\n");
                printf("Remove USB disc to continue\r\n");

                RdosWriteSerialRaw(0, 10, 5);

                while (GetDiscCount() == 2)
                    RdosWaitMilli(1000);

                printf("Rebooting\r\n");
                RdosWaitMilli(1000);
                RdosSoftReset();
                    
                break;

            default:
                RdosWriteSerialRaw(0, 10, 2);
                
                RemoveDisc(DiscNr);
                printf("Removing partitions...");
                RdosWaitMilli(2000);
                RdosSoftReset();
                break;
        }
    }
    else
    {
        printf("Retrying\r\n");
        RdosWaitMilli(2000);
        RdosSoftReset();
    }
        
    return 0;
}

