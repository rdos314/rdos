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
# usbevent.cpp
# USB event class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include "usbevent.h"

#include <rdos.h>

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TUsbEvent::TUsbEvent
#
#   Purpose....: Constructor for TUsbEvent                                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUsbEvent::TUsbEvent(int QueueSize)
 : TWaitDevice("USB event")
{
    FHandle = RdosOpenUsbEvent(QueueSize);
}

/*##########################################################################
#
#   Name       : TUsbEvent::~TUsbEvent
#
#   Purpose....: Destructor for TUsbEvent                                   
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUsbEvent::~TUsbEvent()
{
    RdosCloseUsbEvent(FHandle);
}

/*##########################################################################
#
#   Name       : TUsbEvent::Add
#
#   Purpose....: Add this object to wait list
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::Add(TWait *Wait)
{
    RdosAddWaitForUsbEvent(Wait->GetHandle(), FHandle, (int)this);
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyAttach
#
#   Purpose....: Notify attach
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyAttach(int Controller, int Port)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyDetach
#
#   Purpose....: Notify detach
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyDetach(int Controller, int Port)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyControllerError
#
#   Purpose....: Notify controller error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyControllerError(int Controller)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyNoSlots
#
#   Purpose....: Notify no slots
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyNoSlots(int Controller)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifySlotNotEnabled
#
#   Purpose....: Notify slot not enabled
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifySlotNotEnabled(int Controller)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyPipeNotEnabled
#
#   Purpose....: Notify pipe not enabled
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyPipeNotEnabled(int Controller)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyBandwidthError
#
#   Purpose....: Notify bandwidth error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyBandwidthError(int Controller)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyCrcError
#
#   Purpose....: Notify CRC error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyCrcError(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyBitStuffingError
#
#   Purpose....: Notify bit stuffing error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyBitStuffingError(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyDataToggleError
#
#   Purpose....: Notify data toggle error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyDataToggleError(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyStall
#
#   Purpose....: Notify stall
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyStall(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyNotResponding
#
#   Purpose....: Notify not responding
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyNotResponding(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyPidFailure
#
#   Purpose....: Notify PID failure
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyPidFailure(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyUnexpectedPid
#
#   Purpose....: Notify unexpected PID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyUnexpectedPid(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyDataOverrun
#
#   Purpose....: Notify data overrun
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyDataOverrun(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyDataUnderrun
#
#   Purpose....: Notify data underrun
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyDataUnderrun(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyBufferOverrun
#
#   Purpose....: Notify buffer overrun
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyBufferOverrun(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyBufferUnderrun
#
#   Purpose....: Notify buffer underrun
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyBufferUnderrun(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyDataBufferError
#
#   Purpose....: Notify data buffer error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyDataBufferError(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyBabble
#
#   Purpose....: Notify babble
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyBabble(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyTransError
#
#   Purpose....: Notify transaction error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyTransError(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyMissedMicroframe
#
#   Purpose....: Notify missed microframe
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyMissedMicroframe(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyHalted
#
#   Purpose....: Notify halted
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyHalted(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyTrbError
#
#   Purpose....: Notify TRB error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyTrbError(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyNoPing
#
#   Purpose....: Notify missing ping
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyNoPing(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyUnknown
#
#   Purpose....: Notify unknown error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyUnknown(int Controller, int Port, char Pipe)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyReset
#
#   Purpose....: Notify reset
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyReset(int Controller, int Port)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::NotifyOverCurrent
#
#   Purpose....: Notify overcurrent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::NotifyOverCurrent(int Controller, int Port)
{
}

/*##########################################################################
#
#   Name       : TUsbEvent::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::SignalNewData()
{
    RdosUsbEvent event;
    int ok;

    ok = RdosGetUsbEvent(FHandle, &event);
    if (ok)
    {
        switch (event.Event)
        {
            case USB_EVENT_ATTACH:
                NotifyAttach(event.Controller, event.Port);
                break;

            case USB_EVENT_DETACH:
                NotifyDetach(event.Controller, event.Port);
                break;

            case USB_EVENT_CONTROLLER_ERROR:
                NotifyControllerError(event.Controller);
                break;

            case USB_EVENT_NO_SLOTS:
                NotifyNoSlots(event.Controller);
                break;

            case USB_EVENT_SLOT_NOT_ENABLED:
                NotifySlotNotEnabled(event.Controller);
                break;

            case USB_EVENT_PIPE_NOT_ENABLED:
                NotifyPipeNotEnabled(event.Controller);
                break;

            case USB_EVENT_BANDWIDTH_ERROR:
                NotifyBandwidthError(event.Controller);
                break;

            case USB_EVENT_CRC_ERROR:
                NotifyCrcError(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_BIT_STUFFING_ERROR:
                NotifyBitStuffingError(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_DATA_TOGGLE_ERROR:
                NotifyDataToggleError(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_STALL:
                NotifyStall(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_NOT_RESPONDING:
                NotifyNotResponding(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_PID_FAILURE:
                NotifyPidFailure(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_UNEXPECTED_PID:
                NotifyUnexpectedPid(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_DATA_OVERRUN:
                NotifyDataOverrun(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_DATA_UNDERRUN:
                NotifyDataUnderrun(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_BUFFER_OVERRUN:
                NotifyBufferOverrun(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_BUFFER_UNDERRUN:
                NotifyBufferUnderrun(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_DATA_BUFFER_ERROR:
                NotifyDataBufferError(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_BABBLE:
                NotifyBabble(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_TRANS_ERROR:
                NotifyTransError(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_MISSED_MICROFRAME:
                NotifyMissedMicroframe(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_HALTED:
                NotifyHalted(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_TRB_ERROR:
                NotifyTrbError(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_NO_PING:
                NotifyNoPing(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_UNKNOWN:
                NotifyUnknown(event.Controller, event.Port, event.Pipe);
                break;

            case USB_EVENT_RESET:
                NotifyReset(event.Controller, event.Port);
                break;

            case USB_EVENT_OVER_CURRENT:
                NotifyOverCurrent(event.Controller, event.Port);
                break;
        }
    }
}
