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
        }
    }
}
