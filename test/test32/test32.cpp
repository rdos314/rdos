#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"
#include "serial.h"
#include "rdos.h"

void main()
{
    int handle;

    handle = RdosOpenFile("y:/1.txt", 0);
    RdosSetFileSize64(handle, 18000);
    RdosCloseFile(handle);


//    RdosTestGate("");
}
