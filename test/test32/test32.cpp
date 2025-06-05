#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

#include "rdos.h"

void main()
{
    int val;
    int dev;

    dev = RdosGetPciHandle(0, 3, 0, 6);

    RdosLockPciHandle(dev, "Test lock");
    RdosUnlockPciHandle(dev);

    for (;;)
        RdosWaitMilli(500);


//    RdosTestGate(buf);
}



