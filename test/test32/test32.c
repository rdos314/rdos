#include <rdos.h>
#include <stdio.h>
#include <stdlib.h>

#include <math.h>

void main()
{
    int handle;
    int count = RdosGetMaxComPort();

    handle = RdosOpenCom(count - 6, 9600, 'N', 8, 1, 0x1000, 0x1000);
    

    for (;;)
        RdosWaitMilli(1000); 

}

