#include <stdio.h>
#include <stdlib.h>

#include <math.h>

#include <rdos.h>

void main()
{
    int ports;
    int handle;

    ports = RdosGetMaxComPort();

    handle = RdosOpenCom(0, 9600, 'N', 8, 1, 0x1000, 0x1000);

    RdosTestGate();    
}

