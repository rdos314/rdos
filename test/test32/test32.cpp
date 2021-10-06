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
#include "appini.h"

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


    unsigned long msb, lsb;
    int lyear, lmonth, lday, lhour;
    int year, month, day, hour;
    int min, sec, ms, us;
    TString str;

    count = RdosUsedSections();

    year = 3854;
    month = 12;
    day = 10;
    hour = 11;
    min = 35;
    sec = 26;

    msb = RdosCodeMsbTics(year, month, day, hour);

    year = 2021;
    month = 9;
    day = 18;
    hour = 19;
    min = 35;
    sec = 28;

    msb = RdosCodeMsbTics(year, month, day, hour);

    RdosGetTime(&msb, &lsb);
    RdosDecodeMsbTics(msb, &lyear, &lmonth, &lday, &lhour);

    for (;;)
    {
        RdosGetTime(&msb, &lsb);
        RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
        RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);

        if (lyear != year || lmonth != month || lday != day)
            break;
        str.printf("%04d-%02d-%02d %02d.%02d.%02d,%03d %03d\r\n", year, month, day, hour, min, sec, ms, us);
        printf(str.GetData());
        delay = RdosGetRandom(50) + 1;
        RdosWaitMilli(delay);
    }

    printf("ended\r\n");

    for (;;)
        RdosWaitMilli(500);

    RdosTestGate("");


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
}
