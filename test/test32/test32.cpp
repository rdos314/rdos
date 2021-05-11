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

int handle;

/*##########################################################################
#
#   Name       : VerifySector
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void VerifySector(int id, char *buf)
{
    TMd5Hash hash;
    char hbuf[16];
    int cid;

    hash.Add(buf + 16, 512 - 16);
    hash.GetHashData(hbuf);

    if (memcmp(hbuf, buf, 16))
        printf("Wrong hash\r\n");
    else
    {
        memcpy(&cid, buf + 16, 4);
        if (id != cid)
            printf("Wrong sector\r\n");
    }
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
    TDisc disc(1);
    char *buf;
    int count;
    long long sector;
    int delay;
    int i;
    char *ptr;
    int id;
    int h;

    int handle;

    handle = RdosOpenVfsFile("y:/rdos/menu/style.ini");


    buf = new char[512 * 128];

    for (;;)
    {
        count = 1 + RdosGetRandom(127);
        sector = 400000 + RdosGetRandom(600000 - count);
        delay = RdosGetRandom(100);
        disc.Read(sector, buf, 512 * count);

        id = (int)(sector - 100000);

        ptr = buf;
        for (i = 0; i < count; i++)
        {
            VerifySector(id + i, ptr);
            ptr += 512;
        }
        RdosWaitMilli(delay);

    }

    RdosTestGate("");
}
