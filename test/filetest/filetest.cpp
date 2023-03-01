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
    long long pos;
    char ch;
    TFile file("test.dat", 0);

    for (pos = 0; pos < 0x1000000; pos++)
    {
        ch = CalcSign(pos);
        file.Write(&ch, 1);
    }    
}

