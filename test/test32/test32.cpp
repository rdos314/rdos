#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "keyboard.h"
#include "modbus.h"

void main()
{
    TModbusDevice dev(0x7701A8C0, 502);
    TModbus unit(&dev, 1);
    int i;
    int val;

    for (;;)
    {
        if (unit.ReqHoldingRegisters(40203, 28))
        {
            unit.GetBufferedHoldingRegister(40214, &val);
            printf("Output power %dW", val);

            unit.GetBufferedHoldingRegister(40224, &val);
            printf(", PV power %dW", val);

            unit.GetBufferedHoldingRegister(40216, &val);
            printf(", Battery voltage %d.%1dV", val / 10, val %10);

            unit.GetBufferedHoldingRegister(40217, &val);
            printf(", current ");
            if (val < 0)
            {
                val = -val;
                printf("-");
            }
            printf("%d.%1dA\r\n", val / 10, val %10);
        }

        for (i = 0; i < 60; i++)
            RdosWaitMilli(1000);
    }

//    RdosTestGate("");
}



