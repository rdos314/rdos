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
#include "modbus.h"
#include "openweather.h"
#include "frinv.h"

#include <math.h>
#include "bignum.h"

#include "section.h"

#include "testlib.h"


#define FALSE 0
#define TRUE !FALSE


void main()
{
    TFroniusInverter inv("192.168.1.51");

    for (;;)
    {
        RdosWaitMilli(2500);
    }
}
