#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "sigdev.h"
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
