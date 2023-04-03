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
    bool cont = false;

    while (!cont)
        RdosWaitMilli(50);

    if (argc >= 2)
    {
        ptr = argv[1];
        dev = atoi(ptr);

        Server = new TDiscServer;
//        Mbr = CreateMbr(Server);

//        if (Mbr)
//            Mbr->Run();
    }
}
