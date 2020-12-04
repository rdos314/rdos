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
    char *dev;
    bool ok;
    int wait;

    handle = RdosOpenUsbDevice(1, 2);
    ok = RdosConfigUsbPipe(handle, 0x81, 16);

    wait = RdosCreateWait();
    RdosAddWaitForUsbPipe(wait, handle, 0x81, 0x1234);
    RdosEnableUsbPipe(handle, 0x81);
    RdosWaitForever(wait);
    RdosCloseUsbDevice(handle);
    RdosCloseWait(wait);

    RdosTestGate("");
}
