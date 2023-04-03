#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "discpart.h"
#include "gptdisc.h"


/*##########################################################################
#
#   Name       : CreateGpt
#
#   Purpose....: Create GPT object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGptDisc *CreateGpt(TDiscServer *Server)
{
    return new TGptDisc(Server);
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
    TGptDisc *Gpt;
    bool cont = false;

    while (!cont)
        RdosWaitMilli(50);

    if (argc >= 2)
    {
        ptr = argv[1];
        dev = atoi(ptr);

        Server = new TDiscServer;
        Gpt = CreateGpt(Server);

        if (Gpt)
            Gpt->Run();
    }
}
