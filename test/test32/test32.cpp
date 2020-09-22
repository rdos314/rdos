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
    int x, y;

    for (;;)
    {    
        RdosGetMousePosition(&x, &y);
        printf("x: %d, y: %d\r\n", x, y);
        RdosWaitMilli(250);
    }

    RdosTestGate("");
}
