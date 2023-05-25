#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"
#include "file.h"

void main()
{
    TFile file("lf.txt", 0);
    int i;
    int low;
    int hi;
    int count;
    unsigned char ch;
    unsigned char mask;
    char str[40];

    sprintf(str, "t00000000 DB 00h\r\n");
    file.Write(str);
    
    for (i = 1; i < 256; i++)
    {
        ch = (unsigned char)i;

        mask = 0x1;
        low = 0;
        while (low != 8 && (mask & ch) == 0)
        {
            mask = mask << 1;
            low++;
        }

        mask = 0x80;
        hi = 7;
        while (hi && (mask & ch) == 0)
        {
            mask = mask >> 1;
            hi--;
        }

        count = hi - low + 1;
        ch = (unsigned char)count | (unsigned char)low << 4;
        sprintf(str, "t%08b DB %02hXh\r\n", i, ch);
        file.Write(str);
    }


    char *buf;
    TDisc disc(1);

    buf = new char[4096];
    disc.Read(0xFA010, buf, 4096);
    memset(buf, 0xAC, 4096);
    disc.Write(0xFA010, buf, 4096);
    delete buf;
}
