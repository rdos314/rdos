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

    handle = RdosOpenHandle("y:/ABcd-long-name.txt", O_RDWR);
    RdosCloseHandle(handle);


//    RdosTestGate("");
}
