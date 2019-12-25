#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define FALSE 0
#define TRUE !FALSE

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
    int handle;
    int core;
    int sig;

    handle = RdosCreateRealtime();
    core = RdosAddRealtimeCore(handle, "realtest.bin");

    for (;;)
    {
        RdosWaitForRealtimeSignal(handle);
        if (RdosGetRealtimeSignal(handle, &core, &sig))
            printf("Signal: core %d, signal %d\r\n", core, sig);
    }

//    RdosTestGate("");
}
