#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"
#include "serial.h"
#include "rdos.h"

void main()
{
    int handle;

    RdosDeleteFile("y:/1.txt");

    RdosSetCurDrive('y' - 'a');
    RdosMakeDir("y:/test");
    RdosSetCurDir("y:/test");

    handle = RdosCreateFile("1.txt", 0);
    RdosCloseFile(handle);


//    RdosTestGate("");
}
