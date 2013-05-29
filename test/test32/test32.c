#include <stdio.h>
#include <stdlib.h>

#include <math.h>

#include <rdos.h>

int Load(int in)
{
    int val;

    val = in;
    val = val / 2;
    return val;
}

TestThread(void *Param)
{
    long long time;
    long diff;
    int i;
    int val;
    int row;
    char str[40];

    row = *(int *)Param;

    for (;;)
    {
        time = RdosGetLongSysTime();
        for (i = 0; i < 10000000; i++)
            val = Load(i);

        diff = (int)(RdosGetLongSysTime() - time);

        RdosSetCursorPosition(row, 0);
        sprintf(str, "Tics: %d", diff);
        RdosWriteString(str);
    }            
}

void main()
{
    int i;
    char *str[50];
    int *param;

    for (i = 0; i < 3; i++)
    {
        param = (int *)malloc(4);
        *param = i;
        sprintf(str, "Test Thread %d", i);
//        RdosCreateThread(TestThread, str, param, 0x5000);
    }

    RdosTestGate();

    for (;;)
        RdosWaitMilli(1000); 

}

