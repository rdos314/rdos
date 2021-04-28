#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "discserv.h"
#include "fatfs.h"

/*##########################################################################
#
#   Name       : GetFatSize
#
#   Purpose....: Get FAT size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetFatSize(TDiscServer *Server, const char *FsName, char *BootSector)
{
    char Name[6];
    long long TotalSectors;
    struct TBootSector *boot;
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, 0, 1);
    int FatSize;

    req.WaitForever();

    boot = (struct TBootSector *)e1.Map();

    if (!boot)
    {
        printf("Cannot read boot sector\r\n");
        return 0;
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

    if (!FatSize)
    {
        printf("No FAT size specified\r\n");
        return 0;
    }

    if (boot->BytesPerSector != 512)
    {
        printf("Unexpected bytes per sector: %d\r\n", boot->BytesPerSector);
        return 0;
    }

    memcpy(BootSector, boot, 512);
    return FatSize;
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
    TDiscServer *Server;
    int FatSize;
    char *BootSector = new char[512];

    ServTest();

    if (argc >= 4)
    {
        ptr = argv[1];
        dev = atoi(ptr);

        ptr = argv[2];
        unit = atoi(ptr);

        ptr = argv[3];

        Server = new TDiscServer;
        FatSize = GetFatSize(Server, ptr, BootSector);

//        TFat Fat;
//        Fat.Run(ptr);


    }
}
