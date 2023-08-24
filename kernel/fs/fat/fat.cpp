#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "sigdev.h"
#include "parttype.h"
#include "part.h"
#include "fat12.h"
#include "fat16.h"
#include "fat32.h"

bool Started = false;
TFat *Fs = 0;
const char *FsName = 0;

/*##########################################################################
#
#   Name       : LogError
#
#   Purpose....: Log bad FAT contents
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void LogError(TPartServer *Server, TFat *Fat)
{
    long long TotalSectors;

    TotalSectors = Server->GetPartSectors();

    if (TotalSectors < Fat->PartSectors)
        printf("Partition size mismatch: Part: %lld, Boot: %lld\r\n", TotalSectors, Fat->PartSectors);

    if (Fat->FatSectors == 0)
        printf("No FAT sectors\r\n");

    if (Fat->FatCount != 2)
        printf("Must have 2 FAT tables\r\n");

    if (Fat->SectorsPerCluster <= 0)
        printf("Invalid sectors per cluster: %d\r\n", Fat->SectorsPerCluster);
}

/*##########################################################################
#
#   Name       : StartFs
#
#   Purpose....: Start filesystem
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void StartFs(TPartServer *Server)
{
    char Name[6];
    long long TotalSectors;
    struct TBootSector *boot;
    TPartReq req(Server);
    TPartReqEntry e1(&req, 0, 1);
    int FatSize;

    Started = true;
    Fs = 0;

    req.WaitForever();

    boot = (struct TBootSector *)e1.Map();

    if (!boot)
    {
        printf("Cannot read boot sector\r\n");
        return;
    }

    if (boot->BytesPerSector != 512)
    {
        printf("Unexpected bytes per sector: %d\r\n", boot->BytesPerSector);
        return;
    }

    FatSize = 0;

    memcpy(Name, boot->FsName, 5);
    Name[5] = 0;

    if (!strcmp(Name, "FAT12"))
        FatSize = 12;

    if (!strcmp(Name, "FAT16"))
        FatSize = 16;

    if (!strcmp(Name, "FAT32"))
        FatSize = 32;

    if (!FatSize)
    {
        memcpy(Name, FsName, 5);
        Name[5] = 0;

        if (!strcmp(Name, "FAT12"))
            FatSize = 12;

        if (!strcmp(Name, "FAT16"))
            FatSize = 16;

        if (!strcmp(Name, "FAT32"))
            FatSize = 32;
    }

    if (FatSize == 32)
    {
        if (!boot->RootCluster)
            FatSize = 16;
    }
    else
    {
        if (!boot->RootDirEntries)
            FatSize = 32;
    }

    switch (FatSize)
    {
        case 12:
            Fs = new TFat12(Server, boot);
            break;

        case 16:
            Fs = new TFat16(Server, boot);
            break;

        case 32:
            Fs = new TFat32(Server, boot);
            break;

        default:
            printf("No FAT size specified\r\n");
            break;
    }

    if (Fs)
    {
        if (!Fs->Validate())
        {
            LogError(Server, Fs);
            delete Fs;
            Fs = 0;
        }
    }
}

/*##########################################################################
#
#   Name       : FormatFs
#
#   Purpose....: Format filesystem
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int FormatFs(TPartServer *Server, int PartType, long long *Start, long long *Size)
{
    char *BootSector;
    struct TBootSector *boot;
    bool ok;

    BootSector = new char[512];

    memset(BootSector, 0, 0x1FE);
    *(BootSector + 0x1FE) = 0x55;
    *(BootSector + 0x1FF) = 0xAA;

    RdosReadBinaryResource(0, 100, BootSector, 0x1BE);

    switch (PartType)
    {
        case PART_TYPE_FAT12:
            ok = TFat12::ValidateFs(boot, Start, Size);
            break;

        case PART_TYPE_FAT16:
            ok = TFat16::ValidateFs(boot, Start, Size);
            break;

        case PART_TYPE_FAT32:
            ok = TFat32::ValidateFs(boot, Start, Size);
            break;

        default:
            ok = false;
            break;
    }

    delete BootSector;


/*

    TPartReq req(Server);
    TPartReqEntry e1(&req, *Start, 1, false);
    char *BootSector;
    struct TBootSector *boot;

    req.WaitForever();

    BootSector = (char *)e1.Map();

    memset(BootSector, 0, 0x1FE);
    *(BootSector + 0x1FE) = 0x55;
    *(BootSector + 0x1FF) = 0xAA;

    RdosReadBinaryResource(0, 100, BootSector, 0x1BE);
    
    boot = (struct TBootSector *)(BootSector + 11);

    boot->BytesPerSector = Server->GetBytesPerSector();
    boot->Resv1 = 0;
    boot->MappingSectors = 0;
    boot->Resv3 = 0;
    boot->Resv4 = 0;
    boot->SmallSectors = 0;
    boot->Media = 0xF8;
    boot->Resv6 = 0;
    boot->SectorsPerCyl = 0xFFFF;
    boot->Heads = 0xFF;
    boot->HiddenSectors = 0;
    boot->Sectors = *Size - 1;
    boot->Drive = 0x80;
    boot->Resv7 = 0;
    boot->Signature = 0;
    boot->Serial = 0;
    memset(boot->Volume, 0, 11);
    memcpy(boot->Fs, "RDOS    ", 8);

    e1.Write();

*/

    return 1;
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main(int argc, char **argv)
{
    int dev;
    int unit;
    char *ptr;
    TPartServer *Server;

    if (argc >= 4)
    {
        ptr = argv[1];
        dev = atoi(ptr);

        ptr = argv[2];
        unit = atoi(ptr);

        FsName = argv[3];

        Server = new TPartServer;
        Server->OnStart = StartFs;
        Server->OnFormat = FormatFs;

        while (!Started)
            if (!Server->WaitForMsg())
                break;

        if (Fs)
            Fs->Run();

        Server->Disable();

        if (Fs)
            delete Fs;

        delete Server;
    }
}
