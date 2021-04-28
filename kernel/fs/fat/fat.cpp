#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "discserv.h"
#include "fat12.h"
#include "fat16.h"
#include "fat32.h"

/*##########################################################################
#
#   Name       : CreateFat
#
#   Purpose....: Create FAT object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat *CreateFat(TDiscServer *Server, const char *FsName)
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

    if (boot->BytesPerSector != 512)
    {
        printf("Unexpected bytes per sector: %d\r\n", boot->BytesPerSector);
        return 0;
    }

    switch (FatSize)
    {
        case 12:
            return new TFat12(Server, boot);

        case 16:
            return new TFat16(Server, boot);

        case 32:
            return new TFat32(Server, boot);

        default:
            printf("No FAT size specified\r\n");
            return 0;
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
    TDiscServer *Server;
    TFat *Fat;

    ServTest();

    if (argc >= 4)
    {
        ptr = argv[1];
        dev = atoi(ptr);

        ptr = argv[2];
        unit = atoi(ptr);

        ptr = argv[3];

        Server = new TDiscServer;
        Fat = CreateFat(Server, ptr);

//        TFat Fat;
//        Fat.Run(ptr);


    }
}
