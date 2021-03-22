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
    int i;
    char *buf;
    TDisc disc(0);

    buf = new char[512];

    for (i = 0; i < 16; i++)
        disc.Read(0xFA000 + i, buf, 0x200);

    RdosTestGate("");
}
