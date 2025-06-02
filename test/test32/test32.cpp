#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

#include "rdos.h"

void main()
{
    int dev = RdosFindPciClass(0, 6, 4);

    while (dev)
    {
        printf("dev %d\r\n", dev);
        dev = RdosFindPciClass(dev, 6, 4);
    }

//    RdosTestGate(buf);
}



