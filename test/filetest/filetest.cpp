#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "file.h"

static int run = 0;

struct TPosEntry
{
    long long pos;
    int size;
};

static TPosEntry PosArr[] =
{
  {959342, 164},
  {2506, 230},
  {3367, 38817},
  {2585, 188},
  {2773, 43497},
  {46270, 253},
  {32634, 58},
  {47791, 143},
  {10895637, 15},
  {10895652, 2872},
  {2306, 1653},
  {104773, 51462},
  {338770, 33970},
  {10361287, 26477},
  {743790, 159},
  {743949, 1376},
  {24730, 2970},
  {197667, 2213},
  {519, 15524},
  {100, 1145},
  {26523, 37928},
  {64451, 1354},
  {25174, 1213},
  {1646, 43},
  {1689, 351},
  {2040, 4087},
  {125466, 2720},
  {15179815, 53515},
  {34891, 4015},
  {438217, 13},
  {915226, 1248},
  {916474, 64787},
  {0, -1}
};

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

void Check(TFile &file, char *buf, long long pos, int size)
{
    int j;
    char ch;
    int ret;
    bool logged = false;

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
    {
        if (pos + ret != 0x1000000)
            printf("Wrong size at pos %lld, expect: %d, found %d\r\n", pos+j, size, ret);
    }
}

extern "C" void TestThread(void *Data)
{
    int count = *(int *)Data;
    int i;
    long long pos;
    int size;
    int alt;
    TFile file("y:/test.dat");
    char *buf = new char[0x10000];

    run++;

    unsigned long Linear;
    unsigned long mb;
    unsigned long kb;

    for (i = 0; i < 1000; i++)
    {
        pos = PosArr[i].pos;
        size = PosArr[i].size;

        if (size > 0)
            Check(file, buf, pos, size);
        else
            break;
    }

    for (i = 0; i < count; i++)
    {
/*
        {
            Linear = (unsigned long)RdosGetFreeBigLocalLinear();
            mb = Linear / 1024 / 1024;
            kb = Linear - mb * 1024 * 1024;
            kb = kb * 1000 / 1024;
            kb = kb * 100 / 1024;
            printf("Id: %d Gdt: %d Mem: %d.%05d MB\r\n", i, RdosGetFreeGdt(), mb, kb);
        }
*/

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

//        sprintf(str, "  {%lld, %d}, \r\n", pos, size);
//        logfile.Write(str);

        Check(file, buf, pos, size);
    }

    delete buf;

    run--;
}

void cdecl main()
{
    int count;
    TFile file("y:/rdos.bin");

    count = 25000000;
    RdosCreateThread(TestThread, "Test 1", &count, 0x2000);
    RdosCreateThread(TestThread, "Test 2", &count, 0x2000);

    RdosWaitMilli(50);

    while (run)
        RdosWaitMilli(50);

}
