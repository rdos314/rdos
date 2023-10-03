#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"
#include "serial.h"
#include "rdos.h"

void main()
{
    int handle;
    int i;
    int delay;
    long long size;

    handle = RdosOpenFile("y:/ABcd-long-name.txt", 0);

    for (i = 0; i < 1000; i++)
    {
        size = RdosGetRandom(1000000);
        delay = RdosGetRandom(500);

        printf("Delay: %d, Size: %lld\r\n", delay, size);

        RdosWaitMilli(delay);
        RdosSetFileSize64(handle, size);
    }        

    RdosCloseFile(handle);


//    RdosTestGate("");
}
