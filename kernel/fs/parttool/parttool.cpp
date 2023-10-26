#include <rdos.h>
#include <serv.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "discpart.h"
#include "mbrdisc.h"
#include "gptdisc.h"

#include "partinfo.h"
#include "discinit.h"
#include "partadd.h"

static TCommandFactory *info;
static TCommandFactory *init;
static TCommandFactory *addp;

static TDisc *Disc = 0;

/*##########################################################################
#
#   Name       : InitDisc
#
#   Purpose....: Init disc object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool InitDisc(TDiscServer *Server, const char *PartType)
{
    Disc = 0;

    if (!strcmp(PartType, "mbr"))
        Disc = new TMbrDisc(Server);

    if (!strcmp(PartType, "gpt"))
        Disc = new TGptDisc(Server);

    if (Disc)
        if (Disc->InitPart())
            return true;

    return false;
}

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
    bool wait = true;

    while (wait)
        RdosWaitMilli(100);

    if (argc >= 2)
    {
   

        ptr = argv[1];
        dev = atoi(ptr);

        Server = new TDiscServer;
        Server->OnInit = InitDisc;

        init = new TInitFactory(Server);
        info = new TInfoFactory(Server);
        addp = new TAddPartitionFactory(Server);

        Disc = CreateDisc(Server);
        if (Disc)
            if (Disc->LoadPart())
                while (Server->IsActive())
                    Server->Run(Disc);
    }
}
