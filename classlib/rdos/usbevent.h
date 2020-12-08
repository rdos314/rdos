/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
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
	
protected:
    virtual void SignalNewData();
    virtual void Add(TWait *Wait);

    int FHandle;
};

#endif

