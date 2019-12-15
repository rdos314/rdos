#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "serial.h"
#include "ech200.h"

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
    TSerialDevice serial(2, 9600, 'E', 8, 1);
    TModbusDevice moddev(&serial);
    TEch200 ech(&moddev, 1);

    for (;;)
    {
        RdosWaitMilli(1000);

        printf("Heat inlet=%d\r\n", ech.GetHeatInlet());
        printf("Heat outlet=%d\r\n", ech.GetHeatOutlet());
        printf("Cold intlet=%d\r\n", ech.GetColdInlet());
        printf("Hours=%d\r\n", ech.GetOperTime());

        if (ech.IsOn())
            printf("on\r\n");
        else
            printf("off\r\n");

        printf("Auto alarms=%06hX\r\n", ech.GetAutoAlarms());
        printf("Manual alarms=%06hX\r\n", ech.GetManualAlarms());

    }

//    RdosTestGate("");
}
