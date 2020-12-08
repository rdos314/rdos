#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "usbevent.h"

#define FALSE 0
#define TRUE !FALSE

class TMyUsbEvent : public TUsbEvent
{
public:
    TMyUsbEvent();
    virtual ~TMyUsbEvent();

    void Start();

    virtual void NotifyAttach(int Controller, int Port);
    virtual void NotifyDetach(int Controller, int Port);
    virtual void NotifyControllerError(int Controller);
	
};

TMyUsbEvent::TMyUsbEvent()
 : TUsbEvent(32)
{
}

TMyUsbEvent::~TMyUsbEvent()
{
}

void TMyUsbEvent::Start()
{
    StartHandler("USB Event", 0x4000);
}

void TMyUsbEvent::NotifyAttach(int Controller, int Port)
{
    printf("Attach %02hX.%02hX\r\n", Controller, Port);
}

void TMyUsbEvent::NotifyDetach(int Controller, int Port)
{
    printf("Detach %02hX.%02hX\r\n", Controller, Port);
}

void TMyUsbEvent::NotifyControllerError(int Controller)
{
    printf("Controller error %02hX\r\n", Controller);
}

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

    TMyUsbEvent event;
    event.Start();

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
