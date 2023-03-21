#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "file.h"

struct TPosEntry
{
    long long pos;
    int size;
};

static TPosEntry PosArr[] =
{
  {176122, 53160}, 
  {10640399, 100}, 
  {11615698, 75}, 
  {3022, 237}, 
  {39610, 60234}, 
  {2674, 29451}, 
  {32125, 75}, 
  {5065808, 181}, 
  {5065989, 2039}, 
  {5068028, 45020}, 
  {60263, 3880}, 
  {1061, 56855}, 
  {60306, 17255}, 
  {2019, 33537}, 
  {1175918, 32569}, 
  {33769, 3616}, 
  {2256, 2252}, 
  {14261960, 1791}, 
  {12368641, 1181}, 
  {10295, 20}, 
  {1823, 161}, 
  {1984, 3484}, 
  {1782, 133}, 
  {940000, 39065}, 
  {979065, 11460}, 
  {661189, 74}, 
  {14474, 91}, 
  {52004, 37584}, 
  {603780, 25703}, 
  {555671, 2820}, 
  {1805, 1184}, 
  {3488, 45989}, 
  {2125, 942}, 
  {3067, 3980}, 
  {10222437, 14901}, 
  {10237338, 13618}, 
  {10250956, 5407}, 
  {67406, 15992}, 
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


void DoTest(int count)
{
    int i;
    long long pos;
    int size;
    int alt;
    TFile file("y:/test.dat");
    char *buf = new char[0x10000];

    unsigned long Linear;
    unsigned long mb;
    unsigned long kb;

/*
    for (i = 0; i < 1000; i++)
    {
        pos = PosArr[i].pos;
        size = PosArr[i].size;

        if (size > 0)
            Check(file, buf, pos, size);
        else
            break;
    }

*/

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
}

void cdecl main()
{
    TFile file("y:/rdos.bin");

    DoTest(1000000);
}
