#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"
#include "serial.h"
#include "rdos.h"
#include "file.h"

void main()
{
    int h1;
    int h2;
    int count;
    long long pos;
    char *buf = new char[512];
    
    h1 = RdosOpenHandle("y:/1.txt", O_RDWR);
    count = RdosReadHandle(h1, buf, 512);
    pos = RdosGetHandlePos(h1);
    h2 = 11;
    pos = RdosGetHandlePos(h2);
    count = RdosReadHandle(h2, buf, 512);
    RdosDup2Handle(h1, h2);
    pos = RdosGetHandlePos(h1);
    count = RdosReadHandle(h1, buf, 512);
    pos = RdosGetHandlePos(h1);
    RdosSetHandlePos(h2, 2000);
    count = RdosReadHandle(h2, buf, 512);
    pos = RdosGetHandlePos(h2);

    RdosCloseHandle(h1);
    RdosCloseHandle(h2);

//    RdosTestGate("");
}
