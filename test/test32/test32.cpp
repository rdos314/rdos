#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"
#include "serial.h"

void main()
{
    int handle;

    handle = RdosCreateFile("y:/1.txt", 0);
    RdosCloseFile(handle);

//    RdosTestGate("");
}
