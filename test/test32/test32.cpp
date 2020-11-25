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

    handle = RdosOpenUsbDevice(5, 0);
    size = RdosSendUsbDeviceControlMsg(handle, 0x80, 6, 0x100, 0, buf, 8);
    if (size == 8)
    {
        size = (int)buf[0];
        dev = new char[size];
        size = RdosSendUsbDeviceControlMsg(handle, 0x80, 6, 0x100, 0, dev, size);
    }

    size = RdosSendUsbDeviceControlMsg(handle, 0, 9, 1, 0, buf, 8);
    RdosCloseUsbDevice(handle);

    RdosTestGate("");
}
