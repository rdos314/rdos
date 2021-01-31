#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "modbus.h"

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
    TSocketModbusDevice dev(0x3801A8C0);
    TModbus modbus(&dev, 1);
    int reg;
    int val;

    modbus.ReadHoldingRegister32(42109, &val);

    for (reg = 30001; reg < 32001; reg++)
        modbus.ReadInputRegister32(reg, &val);

    RdosTestGate("");
}
