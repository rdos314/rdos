#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "discserv.h"

#define FALSE 0
#define TRUE !FALSE

struct TBootSector
{
    char Jmp[2];
    char Name[8];
    short int BytesPerSector;
    char SectorsPerCluster;
    short int ResvSectors;
    char FatCount;
    short int RootDirEntries;
    short int SectorCount16;
    char Media;
    short int FatSectors16;
    short int SectorsPerCyl;
    short int Heads;
    int HiddenSectors;
    int Sectors;
    int FatSectors;
    short int ExtFlags;
    short int FsVersion;
    int RootCluster;
    short int InfoSector;
    short int BackupSector;
};

static TDiscServer *server;

/*##########################################################################
#
#   Name       : test
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ProcessBootSector()
{
    struct TBootSector *boot;
    TDiscReq req(server);

    TDiscReqEntry e1(&req, 0, 1);

    req.WaitForever();

    boot = (struct TBootSector *)e1.Map();
    printf(boot->Name);
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
    long long sectors;

    ServTest();

    if (argc >= 3)
    {
        ptr = argv[1];
        dev = atoi(ptr);

        ptr = argv[2];
        unit = atoi(ptr);
    }
    else
    {
        dev = 0;
        unit = 0;
    }

    server = new TDiscServer(dev, unit);

    sectors = server->GetPartSectors();
    printf("Sectors: %lld\r\n", sectors);

    ProcessBootSector();
}
