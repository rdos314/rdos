#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"
#include "serial.h"
#include "rdos.h"

void main()
{
    unsigned long msb;
    int year, month, day, hour;

    msb = 0x010EACFF;
    RdosDecodeMsbTics(msb, &year, &month, &day, &hour);

    printf("%04d-%02d-%02d %02d\r\n", year, month, day, hour);

    msb = 0x010EAD00;
    RdosDecodeMsbTics(msb, &year, &month, &day, &hour);

    printf("%04d-%02d-%02d %02d\r\n", year, month, day, hour);
    


//    RdosTestGate("");
}
