#include <stdio.h>
#include <stdlib.h>

#include <rdos.h>


int sync_val = 0;

void sync_thread(void *param)
{
    sync_val = 1;
    RdosWaitMilli(1000);
    sync_val = 2;
    RdosWaitMilli(1000);
    sync_val = 3;    
}

void NullProc()
{
}

void main()
{
    int near_count = 0;
    int gate_count = 0;

    RdosWaitMilli(2500);

    RdosCreateThread(sync_thread, "Sync", 0, 0x02000);

    while (sync_val != 1)
        ;

    while (sync_val != 2)
    {
        NullProc();
        near_count++;
    }

    while (sync_val != 3)
    {
        NullProc();
        gate_count++;
    }

    printf("Near: %d, Gate: %d\r\n", near_count, gate_count);        
}

