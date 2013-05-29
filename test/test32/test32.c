#include <stdio.h>
#include <stdlib.h>

#include <math.h>

#include <rdos.h>

void main()
{
    int ports;
    int handle;
    int wait;
    char str[2] = {0, 0};
    int id;

//    RdosTestGate();

    ports = RdosGetMaxComPort();

    wait = RdosCreateWait();

    handle = RdosOpenCom(ports - 3, 9600, 'N', 8, 1, 0x1000, 0x1000);
    RdosAddWaitForCom(wait, handle, 1);

    for (;;)
    {
        RdosWriteCom(handle, 'A');
        RdosWriteCom(handle, 0xd);
        RdosWriteCom(handle, 0xa);

        id = RdosWaitTimeout(wait, 20000);
        while (id)
        {
            str[0] = RdosReadCom(handle);
            printf(str);
            id = RdosWaitTimeout(wait, 1000);
        }
    }

}

