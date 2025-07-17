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
# usbevent.h
# USB event class
#
########################################################################*/

#ifndef _USBEVENT_H
#define _USBEVENT_H

#include "waitdev.h"

class TUsbEvent : public TWaitDevice
{
public:
    TUsbEvent(int QueueSize);
    virtual ~TUsbEvent();

    virtual void DeviceName(char *Name, int MaxLen) const;

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
    virtual void NotifyReset(int Controller, int Port);
    virtual void NotifyOverCurrent(int Controller, int Port);

	
protected:
    virtual void SignalNewData();
    virtual void Add(TWait *Wait);

    int FHandle;
};

#endif

