#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

#include "rdos.h"

void main()
{
//    int dev = RdosFindPciDevice(0, 0x8086, 0x0F34);
    int val;
    int dev;

    for (dev = 1; dev < 25; dev++)
    {
        val = RdosGetPciHandleSegment(dev);
        printf("Seg: %d ", val);

        val = RdosGetPciHandleBus(dev);
        printf("Bus: %d ", val);

        val = RdosGetPciHandleDevice(dev);
        printf("Dev: %d ", val);

        val = RdosGetPciHandleFunction(dev);
        printf("Func: %d ", val);

        val = RdosGetPciHandleIrq(dev);
        printf("IRQ: %d ", val);

        val = RdosGetPciHandleCap(dev, 1);
        printf("Cap: %d\r\n", val);
    }

    for (;;)
        RdosWaitMilli(500);


//    RdosTestGate(buf);
}



