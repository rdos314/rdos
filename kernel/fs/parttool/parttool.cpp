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
    char *Buf;
    unsigned char Type;
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, 0, 1);
    TDisc *Disc = 0;

    req.WaitForever();

    Buf = (char *)e1.Map();
    if (Buf)
    {
        Type = Buf[0x1BE + 4];
        if (Type == 0xEE)
            Disc = new TGptDisc(Server);
        else
            Disc = new TMbrDisc(Server);
    }
    return Disc;
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

    if (argc >= 2)
    {
        ptr = argv[1];
        dev = atoi(ptr);

        Server = new TDiscServer;
        Disc = CreateDisc(Server);
        Disc->LoadPart();

        for (;;)
            RdosWaitMilli(50);

//        if (Mbr)
//            Mbr->Run();
    }
}
