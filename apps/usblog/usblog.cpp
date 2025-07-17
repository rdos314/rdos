/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# usblog.cpp
# USB device problem logger
#
########################################################################*/

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
    virtual void NotifyNoSlots(int Controller);
    virtual void NotifySlotNotEnabled(int Controller);
    virtual void NotifyPipeNotEnabled(int Controller);
    virtual void NotifyBandwidthError(int Controller);
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
    virtual void NotifyTrbError(int Controller, int Port, char Pipe);
    virtual void NotifyNoPing(int Controller, int Port, char Pipe);
    virtual void NotifyUnknown(int Controller, int Port, char Pipe);

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

void TMyUsbEvent::NotifyNoSlots(int Controller)
{
    printf("No slots %02hX\r\n", Controller);
}

void TMyUsbEvent::NotifySlotNotEnabled(int Controller)
{
    printf("Slot not enabled %02hX\r\n", Controller);
}

void TMyUsbEvent::NotifyPipeNotEnabled(int Controller)
{
    printf("Pipe not enabled %02hX\r\n", Controller);
}

void TMyUsbEvent::NotifyBandwidthError(int Controller)
{
    printf("Bandwidth error %02hX\r\n", Controller);
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

void TMyUsbEvent::NotifyTrbError(int Controller, int Port, char Pipe)
{
    printf("TRB error %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyNoPing(int Controller, int Port, char Pipe)
{
    printf("No ping %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
}

void TMyUsbEvent::NotifyUnknown(int Controller, int Port, char Pipe)
{
    printf("Unknown error %02hX:%02hX #%02hX\r\n", Controller, Port, Pipe);
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
    TMyUsbEvent event;
    event.Start();

    for (;;)
        RdosWaitMilli(250);
}
