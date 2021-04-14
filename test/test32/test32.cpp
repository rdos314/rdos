#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "modbus.h"
#include "disc.h"
#include "md5.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : FillSector
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void FillSector(int id, char *buf)
{
    TMd5Hash hash;

    memcpy(buf + 16, &id, 4);
    hash.Add(buf + 16, 512 - 16);
    hash.GetHashData(buf);
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
void main()
{
    TDisc disc(2);
    char *buf;
    int id;
    long long sector;

    buf = new char[512];

    memset(buf, 0x55, 512);

    for (id = 0; id < 900000; id++)
    {
        FillSector(id, buf);
        sector = 100000;
        disc.Write(sector, buf, 512);
    }

    RdosTestGate("");
}
