#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "discserv.h"
#include "fatboot.h"
#include "tab16.h"

struct TFatInfo
{
    int ExtSign;
    char Resv[480];
    int InfoSign;
    int FreeClusters;
    int NextCluster;
};

TDiscServer *Server;
TFatBoot *Boot;

static int FreeClusters;
static TFatTable *Tab1;
static TFatTable *Tab2;

/*##########################################################################
#
#   Name       : ReadInfo
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool ReadInfo(long long sector)
{
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, sector, 1);
    struct TFatInfo *info;
    bool ok;

    req.WaitForever();

    info = (struct TFatInfo *)e1.Map();

    if (info)
        ok = true;
    else
        ok = false;

    if (ok)
        if (info->ExtSign != 0x41615252)
            ok = false;

    if (ok)
        if (info->InfoSign != 0x61417272)
            ok = false;

    if (ok)
        FreeClusters = info->FreeClusters;
    else
        FreeClusters = 0;

    return ok;
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
    int Free1;
    int Free2;

    ServTest();

    if (argc >= 4)
    {
        ptr = argv[1];
        dev = atoi(ptr);

        ptr = argv[2];
        unit = atoi(ptr);

        ptr = argv[3];

        Server = new TDiscServer(dev, unit);
        Boot = new TFatBoot(Server, ptr);

        if (Boot->IsValid())
        {
            switch (Boot->FatSize)
            {
                case 16:
                    Tab1 = new TFatTable16(Server, Boot->SectorsPerCluster, Boot->Fat1Sector, Boot->Clusters);
                    Tab2 = new TFatTable16(Server, Boot->SectorsPerCluster, Boot->Fat2Sector, Boot->Clusters);
                    break;

                default:
                    Tab1 = 0;
                    Tab2 = 0;
                    break;
            }

            if (Tab1)
                Free1 = Tab1->GetFreeClusters();

            if (Tab2)
                Free2 = Tab2->GetFreeClusters();

            if (Boot->InfoSector)
                ReadInfo(Boot->InfoSector);
        }
    }
}
