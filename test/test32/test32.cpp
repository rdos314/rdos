#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "serial.h"
#include "section.h"
#include "file.h"
#include "rdos.h"

#include <math.h>

#define FALSE 0
#define TRUE !FALSE

void main()
{
    int handle;
    int handle1;
    int handle2;
    int powhandle;
    int powexp;
    int size;
    char *buf;

    handle1 = RdosCreateBigNum();
    RdosLoadBigNum64(handle1, 1);

    handle = RdosCreateRandomOddBigNum(512);
    size = RdosGetBigNumSize10(handle);
    buf = new char[size + 1];
    RdosGetBigNumString10(handle, buf, size + 1);
    printf("Random: ");
    printf(buf);
    printf("\r\n");
    delete buf;

    handle2 = RdosSubBigNum(handle, handle1);
    powhandle = RdosFactorPow2BigNum(handle2, &powexp);

    size = RdosGetBigNumSize10(powhandle);
    buf = new char[size + 1];
    RdosGetBigNumString10(powhandle, buf, size + 1);
    printf("Factor: ");
    printf(buf);
    printf(", Exp: %d\r\n", powexp);
    delete buf;

    
}
