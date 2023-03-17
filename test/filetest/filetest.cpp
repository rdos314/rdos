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

    Check(185, 799);
    Check(984, 24);
    Check(769133, 17030);
    Check(786163, 1789);
    Check(62896, 65);
    Check(54631, 18658);
    Check(7877701, 189);
    Check(2703, 117);
    Check(14566288, 14841);
    Check(620055, 83);
    Check(620138, 2777);

    for (i = 0; i < 1000000; i++)
    {
/*        Linear = (unsigned long)RdosGetFreeBigLocalLinear();
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
