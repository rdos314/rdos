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
    char *ptr;
    long long sectors;
    int dev;
    int unit;

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

    TDiscServer server(dev, unit);

    sectors = server.GetPartSectors();
    printf("Sectors: %lld\r\n", sectors);

    TDiscReq req(&server);

    req.Add(121, 16);
    req.Add(131, 8);
    req.Start();
    req.WaitForever();
}
