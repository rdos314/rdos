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
    int val;

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
    printf("Cap: %d ", val);

//    RdosTestGate(buf);
}



