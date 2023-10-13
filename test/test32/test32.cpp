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
    h2 = RdosOpenHandle("y:/2.txt", O_CREAT | O_RDWR);

    count = RdosReadHandle(h1, buf, 512);
    pos = RdosGetHandlePos(h1);

    while (count)
    {
        count = RdosWriteHandle(h2, buf, count);
        pos = RdosGetHandlePos(h1);
        pos = RdosGetHandlePos(h2);
        count = RdosReadHandle(h1, buf, 512);
    }

    RdosCloseHandle(h1);
    RdosCloseHandle(h2);

//    RdosTestGate("");
}
