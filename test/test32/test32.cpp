#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "smameter.h"

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
    int p;
    double val;
    TSmaMeter sma;

    for (;;)
    {
        sma.WaitForMeassure();

        printf("\r\n");

        printf("Volt: ");
        for (p = 1; p <= 3; p++)
        {
            if (p != 1)
                printf(", ");

            val = sma.GetVolt(p);
            printf("%9.3Lf V", val);
        }
        printf("\r\n");

        printf("Current: ");
        for (p = 1; p <= 3; p++)
        {
            if (p != 1)
                printf(", ");

            val = sma.GetCurrent(p);
            printf("%9.3Lf A", val);
        }
        printf("\r\n");

        printf("Consume power: ");
        val = sma.GetConsumePower();
        printf("%9.1Lf W", val);

        for (p = 1; p <= 3; p++)
        {
            val = sma.GetConsumePower(p);
            printf("%9.1Lf W", val);
        }
        printf("\r\n");

        printf("Produce power: ");
        val = sma.GetProducePower();
        printf("%9.1Lf W", val);

        for (p = 1; p <= 3; p++)
        {
            val = sma.GetProducePower(p);
            printf("%9.1Lf W", val);
        }
        printf("\r\n");

        printf("Consume energy: ");
        val = sma.GetConsumeEnergy();
        printf("%9.3Lf kWh", val);

        for (p = 1; p <= 3; p++)
        {
            val = sma.GetConsumeEnergy(p);
            printf("%9.3Lf kWh", val);
        }
        printf("\r\n");

        printf("Produce energy: ");
        val = sma.GetProduceEnergy();
        printf("%9.3Lf kWh", val);

        for (p = 1; p <=3; p++)
        {
            val = sma.GetProduceEnergy(p);
            printf("%9.3Lf kWh", val);
        }
        printf("\r\n");
    }

    RdosTestGate("");
}
