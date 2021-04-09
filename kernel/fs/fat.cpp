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
#   Name       : test
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void Test(TDiscServer *server)
{
    char *data;

    TDiscReq req(server);

    TDiscReqEntry e1(&req, 121, 16);
    TDiscReqEntry e2(&req, 131, 8);

    req.WaitForever();

    data = e1.Map();
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

    TDiscServer server(dev, unit);

    sectors = server.GetPartSectors();
    printf("Sectors: %lld\r\n", sectors);

    Test(&server);
}
