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

    unsigned long Linear;
    unsigned long mb;
    unsigned long kb;

    Check(0, 2511);
    Check(2555, 498);
    Check(3053, 42142);
    Check(790, 26122);
    Check(709942, 88);
    Check(710030, 30);
    Check(8537956, 3960);
    Check(9516104, 3807);
    Check(869728, 1846);
    Check(871574, 46001);
    Check(553148, 2091);
    Check(3885, 62);
    Check(2832, 36773);
    Check(39605, 3832);
    Check(75781, 133);
    Check(2586, 50493);
    Check(40329, 21972);
    Check(45163, 32039);
    Check(13348002, 2667);
    Check(63514, 2804);
    Check(52668, 47457);
    Check(100125, 46);
    Check(37154, 144);
    Check(940574, 200);
    Check(940774, 148);
    Check(940922, 34807);
    Check(3843, 59560);
    Check(301335, 899);
    Check(23575, 233);
    Check(41154, 25314);
    Check(43653, 98);
    Check(440357, 1601);
    Check(1391, 25258);
    Check(62641, 36316);
    Check(98957, 39604);
    Check(52125, 32);
    Check(15569872, 22831);
    Check(316940, 163);
    Check(807550, 59158);
    Check(2505870, 189);
    Check(13974633, 32765);
    Check(41594, 60714);
    Check(47716, 3760);
    Check(4038, 2818);
    Check(39416, 54565);
    Check(614945, 48);
    Check(1632, 54022);
    Check(41560, 59);
    Check(41619, 34209);
    Check(7057241, 2610);
    Check(6138294, 66);
    Check(872074, 20114);
    Check(1964, 193);
    Check(778, 3690);
    Check(55745, 237);
    Check(25258, 2255);
    Check(24824, 3222);
    Check(35120, 169);
    Check(1645, 193);
    Check(764518, 18394);

    for (i = 0; i < 1000000; i++)
    {
/*
        Linear = (unsigned long)RdosGetFreeBigLocalLinear();
        mb = Linear / 1024 / 1024;
        kb = Linear - mb * 1024 * 1024;
        kb = kb * 1000 / 1024;
        kb = kb * 100 / 1024;
        printf("Gdt: %d Mem: %d.%05d MB\r\n", RdosGetFreeGdt(), mb, kb); 
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

        Check(pos, size);
    }
}
