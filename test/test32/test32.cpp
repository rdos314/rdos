#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "keyboard.h"
#include "modbus.h"

void main()
{
    TModbusDevice dev(0x7701A8C0, 502);
    TModbus unit(&dev, 5);
    int val;

    val = unit.ReadInputRegister(44501);
    val = unit.ReadInputRegister(44502);
    val = unit.ReadInputRegister(44503);
    val = unit.ReadInputRegister(44504);

    val = unit.ReadInputRegister(40001);
    val = unit.ReadInputRegister(40002);


//    RdosTestGate("");
}



