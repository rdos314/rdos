#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"

void main()
{
    char *buf;
    TDisc disc(1);

    buf = new char[1024];
    disc.Read(0xE00000, buf, 1024);
    delete buf;
}
