#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "discpart.h"
#include "mbrdisc.h"
#include "gptdisc.h"


/*##########################################################################
#
#   Name       : CreateDisc
#
#   Purpose....: Create disc object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDisc *CreateDisc(TDiscServer *Server)
{
    struct TBootSector *boot;
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, 0, 1);

    req.WaitForever();

    boot = (struct TBootSector *)e1.Map();

    return 0;
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
    char *ptr;
    TDiscServer *Server;
    TDisc *Disc;
    bool cont = false;

    while (!cont)
        RdosWaitMilli(50);

    if (argc >= 2)
    {
        ptr = argv[1];
        dev = atoi(ptr);

        Server = new TDiscServer;
        Disc = CreateDisc(Server);

//        if (Mbr)
//            Mbr->Run();
    }
}
