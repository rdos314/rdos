#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "file.h"

static char buf[0x10000];
static TFile file("y:/test.dat");


char CalcSign(long long pos)
{
    char ch;
    int temp = (int)pos;

    ch = pos & 0xFF;
    pos = pos >> 8;
    ch = ch ^ (pos & 0xFF);
    pos = pos >> 8;
    ch = ch ^ (pos & 0xFF);
    pos = pos >> 8;
    ch = ch ^ (pos & 0xFF);

    return ch;
}

void Check(long long pos, int size)
{
    int j;
    char ch;
    int ret;
    bool logged = true;

    printf("Pos %lld, size %d\r\n", pos, size);

    file.SetPos(pos);
    ret = file.Read(buf, size);   

    if (size == ret)
    {
        for (j = 0; j < size; j++)
        {
            ch = CalcSign(pos+j);
            if (ch != buf[j])
            {
                if (!logged)
                    printf("Error at pos %lld, expect: %c, found %c\r\n", pos+j, ch, buf[j]);
                logged = true;
            }
        }
    }
    else
        printf("Wrong size at pos %lld, expect: %d, found %d\r\n", pos+j, size, ret);
}

void cdecl main()
{
    int i;
    long long pos;
    int size;
    int alt;

    Check(978, 1091);
    Check(2069, 2464);
    Check(700994, 92);
    Check(2753, 31522);

    for (i = 0; i < 1000000; i++)
    {
        alt = RdosGetRandom(5);
        switch (alt)
        {
            case 0:
                pos = file.GetPos();
                break;

            case 1:
                pos = RdosGetRandom(0x1000000);
                break;

            case 2:
                pos = RdosGetRandom(0x100000);
                break;

            case 3:
                pos = RdosGetRandom(0x10000);
                break;

            case 4:
                pos = RdosGetRandom(0x1000);
                break;
        }

        alt = RdosGetRandom(3);
        switch (alt)
        {
            case 0:
                size = RdosGetRandom(0x10000);
                break;
                 
            case 1:
                size = RdosGetRandom(0x1000);
                break;
        
            case 2:
                size = RdosGetRandom(0x100);
                break;
        }

        Check(pos, size);
    }
}
