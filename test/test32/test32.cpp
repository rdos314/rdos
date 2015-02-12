#include <rdos.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "serial.h"

#include <math.h>

void main()
{
    TSerialDevice serial(1, 19200);

    serial.Open();

    for (;;)
    {
        serial.Write('A');
        RdosWaitMilli(250);
    }
        
    RdosTestGate();
}

