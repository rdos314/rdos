#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"

void main()
{
    char *buf;
    TDisc disc(1);

    buf = new char[8192];
    disc.Read(0xFA010, buf, 8192);
    memset(buf, 0xDA, 1024);
    disc.Write(0xFA012, buf, 1024);
    delete buf;
}
