#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "serial.h"

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
    bool On = true;
    RdosWaitMilli(1000);

    TSerialDevice Port2(2, 9600, 'N', 8, 1);

    Port2.Open();

    for (;;)
    {
        RdosWaitMilli(100);

        if (On)
        {
            On = false;
            Port2.SetDtr();
        }
        else
        {
            On = true;
            Port2.ResetDtr();
        }

        Port2.Write("hello ");
    }
}
