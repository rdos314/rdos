#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "file.h"

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

void cdecl main()
{
    int i;
    int j;
    long long pos;
    int size;
    int ret;
    char ch;
    TFile file("y:/test.dat");
    char *buf = new char[0x10000];

    size = 0x2000;
    ret = file.Read(buf, size);

    file.SetPos(0x567788);
    size = 0x2000;
    ret = file.Read(buf, size);

    for (i = 0; i < 1000000; i++)
    {
        pos = RdosGetRandom(0x1000000);
        file.SetPos(pos);
        size = RdosGetRandom(0x10000);
        ret = file.Read(buf, size);   
        if (size == ret)
        {
            for (j = 0; j < size; j++)
            {
                ch = CalcSign(pos+j);
                if (ch != buf[j])
                    printf("Error at pos %lld, expect: %c, found %c\r\n", pos+j, ch, buf[j]);
            }
        }
        else
            printf("Wrong size at pos %lld, expect: %d, found %d\r\n", pos+j, size, ret);
    }
    delete buf;
}
