#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"

void main()
{
    char *buf;
    TDisc disc(1);

    buf = new char[4096];
    disc.Read(0xFA010, buf, 4096);
    memset(buf, 0xAC, 4096);
    disc.Write(0xFA010, buf, 4096);
    delete buf;
}
