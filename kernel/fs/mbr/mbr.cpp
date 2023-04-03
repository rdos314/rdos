#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "discpart.h"
#include "mbrdisc.h"


/*##########################################################################
#
#   Name       : CreateMbr
#
#   Purpose....: Create MBR object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMbrDisc *CreateMbr(TDiscServer *Server)
{
    return new TMbrDisc(Server);
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
    TMbrDisc *Mbr;
    bool cont = false;

    while (!cont)
        RdosWaitMilli(50);

    if (argc >= 2)
    {
        ptr = argv[1];
        dev = atoi(ptr);

        ptr = argv[2];
        unit = atoi(ptr);

        Server = new TDiscServer;
        Mbr = CreateMbr(Server);

        if (Mbr)
            Mbr->Run();
    }
}
