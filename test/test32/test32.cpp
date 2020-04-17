#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "realtime.h"

#define FALSE 0
#define TRUE !FALSE

int count = 0;

struct AdcBuf
{
    short int chA;
    short int chB;
};


/*##########################################################################
#
#   Name       : NotifySignal
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifySignal(TRealtimeDevice *Dev, int ID, int Signal)
{
    if (Signal == 1023)
    {
        printf("Count %d\r\n", count);
        count++;
    }
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void main()
{
    TRealtimeDevice dev;
    char state;
    int i;
    char *buf = (char *)RdosAllocateMem(0x200000);
    
    RdosSetupAdc(0x5, 0, 5000);
    state = RdosStartAdc();

    printf("State: %02hX\r\n", state);

    if (state & 0x40)
    {
        for (i = 0; i < 5000; i++)
        {
            RdosMapAdcBlock(i, buf);
        }
    }    

    RdosTestGate("");

    dev.OnSignal = NotifySignal;
    dev.AddCore(1, "realtest.bin");

    for (;;)
        RdosWaitMilli(250);


}
