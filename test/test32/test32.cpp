#include <rdos.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "serial.h"

#include <math.h>

void main()
{
    int pf;

    while (!RdosPowerFailure())
        RdosWaitMilli(10);
        
    RdosWriteSerialRaw(0, 10, 6);

    

    TSerialDevice serial(1, 19200);


    serial.Open();

    for (;;)
    {
        serial.Write('A');
        RdosWaitMilli(250);
    }
        
    RdosTestGate();
}

