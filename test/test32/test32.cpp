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
    char p;
    int ival;
    long long lval;
    double val;

    for (;;)
    {
        printf("Volt: ");
        for (p = 1; p <=3; p++)
        {
            if (p != 1)
                printf(", ");

            ival = RdosGetAcVoltage(p);
            val = (double)ival;
            val = val / 1000.0;
            printf("%05.3Lf V", val);
        }
        printf("\r\n");

        printf("Current: ");
        for (p = 1; p <=3; p++)
        {
            if (p != 1)
                printf(", ");

            ival = RdosGetAcCurrent(p);
            val = (double)ival;
            val = val / 1000.0;
            printf("%05.3Lf A", val);
        }
        printf("\r\n");

        printf("Power: ");
        for (p = 0; p <=3; p++)
        {
            if (p != 0)
                printf(", ");

            ival = RdosGetAcPower(p);
            val = (double)ival;
            val = val / 10.0;
            printf("%05.1Lf W", val);
        }
        printf("\r\n");

        printf("Energy: ");
        for (p = 0; p <=3; p++)
        {
            if (p != 0)
                printf(", ");

            lval = RdosGetAcEnergy(p);
            val = (double)lval;
            val = val / 1000.0;
            val = val / 3600.0;
            printf("%05.3Lf kWh", val);
        }
        printf("\r\n");

        RdosWaitMilli(1000);
    }

    RdosTestGate("");
}
