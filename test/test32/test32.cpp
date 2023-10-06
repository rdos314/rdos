#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"
#include "serial.h"
#include "rdos.h"

void main()
{
    int h1;
    int h2;
    int count;
    char *buf = new char[512];

    h1 = RdosOpenHandle("y:/ABcd-long-name.txt", O_RDWR);
    h2 = RdosOpenHandle("y:/1.txt", O_RDWR);

    count = RdosReadHandle(h2, buf, 512);

    RdosCloseHandle(h1);
    RdosCloseHandle(h2);


//    RdosTestGate("");
}
