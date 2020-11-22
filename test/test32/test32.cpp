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
    int handle;
    int size;
    char buf[8];

    handle = RdosOpenUsbDevice(7, 1);
    size = RdosSendUsbDeviceControlMsg(handle, 0x80, 6, 0x100, 0, buf, 8);
    RdosCloseUsbDevice(handle);

    RdosTestGate("");
}
