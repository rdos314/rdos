#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"

void main()
{
    char *buf;
    TDisc disc(1);

    buf = new char[1024];
    memset(buf, 0x55, 1024);
    disc.Write(0xFA010, buf, 1024);
    delete buf;
}
