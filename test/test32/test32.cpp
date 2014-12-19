#include <rdos.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "serial.h"

#include <math.h>

void main()
{
    TSerialDevice *serial;
//    RdosTestGate();


    serial = new TSerialDevice(6, 9600);
    serial->Open();

    for (;;)
    {
        serial->Write("test");
        RdosWaitMilli(1000);
    }

}

