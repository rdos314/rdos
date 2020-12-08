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

#define STACK_SIZE 0x4000

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
TUsbEvent::TUsbEvent(const char *ThreadName, int QueueSize)
{
    FHandle = RdosOpenUsbEvent(QueueSize);
    StartHandler(ThreadName, STACK_SIZE);
}

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
#   Name       : TUsbEvent::DeviceName
#
#   Purpose....: Device name                                      
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbEvent::DeviceName(char *Name, int MaxLen) const
{
    strncpy(Name, "USB event", MaxLen);
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
    UsbEvent event;
    int ok;

    ok = RdosGetUsbEvent(FHandle, &event);
}
