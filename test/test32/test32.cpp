#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "modbus.h"
#include "disc.h"

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
void main()
{
    TDisc disc(1);
    char *buf;
    int count;
    long long sector;

    buf = new char[16 * 512];

    for (;;)
    {
        sector = RdosGetRandom(5000);
        count = 1 + RdosGetRandom(15);

        printf("Start: %lld, Count: %d\r\n", sector, count);

        disc.Read(sector, buf, 512 * count);

        RdosWaitMilli(1000);
    }

    RdosTestGate("");
}
