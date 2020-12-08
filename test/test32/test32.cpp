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
    char *buf;
    char *dev;
    bool ok;
    int wait;
    int count;
    int i;
    int controller;
    int port;
    UsbEvent event;

    handle = RdosOpenUsbEvent(16);
    wait = RdosCreateWait();
    RdosAddWaitForUsbEvent(wait, handle, 0x1234);
    for (;;)
    {
        RdosWaitForever(wait);
        ok = RdosGetUsbEvent(handle, &event);
        if (ok)
            printf("Event %d device %02hX.%02hX pipe %02hX\r\n", event.Event, event.Controller, event.Port, event.Pipe);
    }


    handle = RdosOpenUsbDevice(7, 1);
    ok = RdosConfigUsbPipe(handle, 0x81, 16);

    wait = RdosCreateWait();
    RdosAddWaitForUsbPipe(wait, handle, 0x81, 0x1234);
    RdosEnableUsbPipe(handle, 0x81);
    count = RdosGetUsedUsbBuffers(handle, 0x81);
    size = RdosGetUsbBufferSize(handle, 0x81);
    buf = new char[size + 1];

    for (;;)
    {
        RdosWaitForever(wait);
        count = RdosReadUsbPipe(handle, 0x81, buf);

        for (i = 0; i < count; i++)
            printf("%02hX ", buf[i]);
        printf("\r\n");
    }

    RdosCloseUsbDevice(handle);
    RdosCloseWait(wait);

    RdosTestGate("");
}
