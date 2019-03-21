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
#include "sockobj.h"
#include "websock.h"
#include "httpfact.h"
#include "json.h"

#include <math.h>
#include "bignum.h"

#include "section.h"

#include "testlib.h"

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
    RdosTestGate("");
}
