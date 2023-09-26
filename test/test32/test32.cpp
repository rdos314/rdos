#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"
#include "serial.h"
#include "rdos.h"

void main()
{
    unsigned long msb;
    unsigned long lsb;
    int year, month, day, hour;

    msb = RdosCodeMsbTics(2023, 8, 11, 11);
    lsb = RdosCodeLsbTics(22, 33, 0, 0);

    printf("%08lX_%08lX\r\n", msb, lsb);

    msb = RdosCodeMsbTics(2023, 8, 13, 22);
    lsb = RdosCodeLsbTics(33, 44, 0, 0);

    printf("%08lX_%08lX\r\n", msb, lsb);

    RdosDecodeMsbTics(0x010EACD3, &year, &month, &day, &hour);
    printf("%04d-%02d-%02d %02d\r\n", year, month, day, hour);

    RdosDecodeMsbTics(0x010EAD0E, &year, &month, &day, &hour);
    printf("%04d-%02d-%02d %02d\r\n", year, month, day, hour);


//    RdosTestGate("");
}
