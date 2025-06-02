#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

#include "rdos.h"

void main()
{
    int dev = RdosFindPciProtocol(0, 12, 3, 48);

    while (dev)
    {
        printf("dev %d\r\n", dev);
        dev = RdosFindPciProtocol(dev, 12, 3, 48);
    }

//    RdosTestGate(buf);
}



