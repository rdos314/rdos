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
    virtual void NotifyCrcError(int Controller, int Port, char Pipe);
    virtual void NotifyBitStuffingError(int Controller, int Port, char Pipe);
    virtual void NotifyDataToggleError(int Controller, int Port, char Pipe);
    virtual void NotifyStall(int Controller, int Port, char Pipe);
    virtual void NotifyNotResponding(int Controller, int Port, char Pipe);
    virtual void NotifyPidFailure(int Controller, int Port, char Pipe);
    virtual void NotifyUnexpectedPid(int Controller, int Port, char Pipe);
    virtual void NotifyDataOverrun(int Controller, int Port, char Pipe);
    virtual void NotifyDataUnderrun(int Controller, int Port, char Pipe);
    virtual void NotifyBufferOverrun(int Controller, int Port, char Pipe);
    virtual void NotifyBufferUnderrun(int Controller, int Port, char Pipe);
    virtual void NotifyDataBufferError(int Controller, int Port, char Pipe);
    virtual void NotifyBabble(int Controller, int Port, char Pipe);
    virtual void NotifyTransError(int Controller, int Port, char Pipe);
    virtual void NotifyMissedMicroframe(int Controller, int Port, char Pipe);
    virtual void NotifyHalted(int Controller, int Port, char Pipe);

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

void TMyUsbEvent::NotifyCrcError(int Controller, int Port, char Pipe)
{
    printf("CRC error %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyBitStuffingError(int Controller, int Port, char Pipe)
{
    printf("Bit stuffing error %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyDataToggleError(int Controller, int Port, char Pipe)
{
    printf("Data toggle error %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyStall(int Controller, int Port, char Pipe)
{
    printf("Stall %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyNotResponding(int Controller, int Port, char Pipe)
{
    printf("Not responding %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyPidFailure(int Controller, int Port, char Pipe)
{
    printf("PID failure %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyUnexpectedPid(int Controller, int Port, char Pipe)
{
    printf("Unexpected PID %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyDataOverrun(int Controller, int Port, char Pipe)
{
    printf("Data overrun %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyDataUnderrun(int Controller, int Port, char Pipe)
{
    printf("Data underrun %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyBufferOverrun(int Controller, int Port, char Pipe)
{
    printf("Buffer overrun %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyBufferUnderrun(int Controller, int Port, char Pipe)
{
    printf("Buffer underrun %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyDataBufferError(int Controller, int Port, char Pipe)
{
    printf("Data buffer error %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyBabble(int Controller, int Port, char Pipe)
{
    printf("Babble %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyTransError(int Controller, int Port, char Pipe)
{
    printf("Transaction error %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyMissedMicroframe(int Controller, int Port, char Pipe)
{
    printf("Missed microframe %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyHalted(int Controller, int Port, char Pipe)
{
    printf("Halted %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
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

    for (;;)
    {
        handle = RdosOpenUsbDevice(7, 0);
        ok = RdosConfigUsbPipe(handle, 0x81, 16);

        wait = RdosCreateWait();
        RdosAddWaitForUsbPipe(wait, handle, 0x81, 0x1234);
        RdosEnableUsbPipe(handle, 0x81);
        count = RdosGetUsedUsbBuffers(handle, 0x81);
        size = RdosGetUsbBufferSize(handle, 0x81);
        buf = new char[size + 1];

        while (RdosGetUsbBufferSize(handle, 0x81))
        {
            RdosWaitForever(wait);
            count = RdosReadUsbPipe(handle, 0x81, buf);

            for (i = 0; i < count; i++)
                printf("%02hX ", buf[i]);
            printf("\r\n");
        }

        RdosCloseUsbDevice(handle);
        RdosCloseWait(wait);
    }

    RdosTestGate("");
}
