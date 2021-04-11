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
    char Jmp[3];
    char Name[8];
    short int BytesPerSector;
    char SectorsPerCluster;
    short int ResvSectors;
    char FatCount;
    short int RootDirEntries;
    unsigned short int SectorCount16;
    char Media;
    short int FatSectors16;
    short int SectorsPerCyl;
    short int Heads;
    int HiddenSectors;
    unsigned int Sectors;
    int FatSectors;
    short int ExtFlags;
    short int FsVersion;
    int RootCluster;
    short int InfoSector;
    short int BackupSector;
};

static TDiscServer *Server;
static int FatSize = 0;
static int PartSectors;
static int FatSectors;

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
bool ProcessBootSector()
{
    long long TotalSectors;
    struct TBootSector *boot;
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, 0, 1);

    req.WaitForever();

    boot = (struct TBootSector *)e1.Map();

    if (boot->BytesPerSector != 512)
    {
        printf("Unexpected bytes per sector: %d", boot->BytesPerSector);
        return false;
    }

    TotalSectors = Server->GetPartSectors();

    if (FatSize == 32)
    {
        PartSectors = (long long)boot->Sectors;
        FatSectors = boot->FatSectors;
    }
    else
    {
        PartSectors = (long long)boot->SectorCount16;
        FatSectors = boot->FatSectors16;
    }

    if (TotalSectors < PartSectors)
    {
        printf("Partition size mismatch: Part: %lld, Boot: %lld", TotalSectors, PartSectors);
        return false;
    }

    if (FatSectors == 0)
    {
        printf("No FAT sectors");
        return false;
    }

    return true;
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
    bool ok;

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

    if (argc >= 4)
    {
        ptr = argv[3];

        if (strstr(ptr, "FAT12"))
            FatSize = 12;

        if (strstr(ptr, "FAT16"))
            FatSize = 16;

        if (strstr(ptr, "FAT32"))
            FatSize = 32;
    }

    Server = new TDiscServer(dev, unit);

    ok = ProcessBootSector();
}
