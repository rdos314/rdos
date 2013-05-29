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
    int i;

//    RdosTestGate();

    ports = RdosGetMaxComPort();

    wait = RdosCreateWait();

    handle = RdosOpenCom(ports - 3, 9600, 'N', 8, 1, 0x1000, 0x1000);
    RdosAddWaitForCom(wait, handle, 1);

    for (i = 0; i < 10; i++)
    {
        RdosWriteCom(handle, 'A');
        RdosWriteCom(handle, 0xd);
        RdosWriteCom(handle, 0xa);

        id = RdosWaitTimeout(wait, 200);
        while (id)
        {
            str[0] = RdosReadCom(handle);
            printf(str);
            id = RdosWaitTimeout(wait, 1000);
        }
    }

    RdosCloseCom(handle);
}

