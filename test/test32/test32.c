#include <stdio.h>
#include <stdlib.h>

#include <math.h>

#include <rdos.h>

void main()
{
    int ports;
    int handle;

//    RdosTestGate();

    ports = RdosGetMaxComPort();

    handle = RdosOpenCom(ports - 3, 9600, 'N', 8, 1, 0x1000, 0x1000);

    for (;;)
    {
        RdosWaitMilli(5);
        RdosWriteCom(handle, 'A');
    }

//    RdosTestGate();    
}

