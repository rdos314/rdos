#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "keyboard.h"
#include "modbus.h"
#include "datetime.h"


void main()
{
    int handle;
    long long size;

    handle = RdosOpenHandle("e:/safe.bin", O_RDWR);
    size = RdosGetHandleSize(handle);
    RdosSetHandleSize(handle, 0);


//    RdosTestGate("");
}



