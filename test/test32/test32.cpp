#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "realtime.h"

#define FALSE 0
#define TRUE !FALSE

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
    printf("ID %d, signal %d\r\n", ID, Signal);
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

    dev.OnSignal = NotifySignal;
    dev.AddCore(1, "realtest.bin");

    for (;;)
        RdosWaitMilli(250);


//    RdosTestGate("");
}
