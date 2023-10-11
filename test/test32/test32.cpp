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
    char *buf = new char[512];
    
    h1 = RdosOpenHandle("y:/1.txt", O_RDWR);
    count = RdosPollHandle(h1, buf, 512);
    count = RdosReadHandle(h1, buf, 512);
    count = RdosPollHandle(h1, buf, 512);
    count = RdosReadHandle(h1, buf, 512);

    RdosCloseHandle(h1);

//    RdosTestGate("");
}
