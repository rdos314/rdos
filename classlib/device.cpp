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
# device.cpp
# Basic device class
#
#######################################################################*/

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "device.h"
#include "sigdev.h"

#if !defined(MSVC) && defined(__RDOS__)
#include "rdos.h"
#endif

#define FALSE 0
#define TRUE !FALSE

TSection TDevice::FListSection("Device.List");
TDevice *TDevice::FDeviceList = 0;

/*##########################################################################
#
#   Name       : TDeviceDebug::TDeviceDebug
#
#   Purpose....: Virtual base class for device debugging                                           
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDeviceDebug::TDeviceDebug()
{
}

/*##########################################################################
#
#   Name       : TDeviceDebug::~TDeviceDebug
#
#   Purpose....: Destructor for device debugging                                           
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDeviceDebug::~TDeviceDebug()
{
}

/*##########################################################################
#
#   Name       : TDeviceDebug::RequestFile
#
#   Purpose....: Request a file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TDeviceDebug::RequestFile(TDevice *Device)
{
    return 0;
}

/*##########################################################################
#
#   Name       : TDeviceDebug::ReleaseFile
#
#   Purpose....: Release a file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDeviceDebug::ReleaseFile(TDevice *Device)
{
}

/*##########################################################################
#
#   Name       : TDeviceDebug::MaxFileSize
#
#   Purpose....: Get max file size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDeviceDebug::MaxFileSize()
{
    return 0;
}

/*##########################################################################
#
#   Name       : TDevice::InsertDevice
#
#   Purpose....: Insert device into m_DeviceList
#                                Should only done in constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::InsertDevice()
{
    FListSection.Enter();
    FList = FDeviceList;
    FDeviceList = this;
    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::RemoveDevice
#
#   Purpose....: Remove device from m_DeviceList                   
#                                Should only done in destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::RemoveDevice()
{
    TDevice *ptr;
    TDevice *prev;
    prev = 0;
    FListSection.Enter();
    ptr = FDeviceList;
    while ((ptr != 0) && (ptr != this))
    {
        prev = ptr;
        ptr = ptr->FList;
    }

    if (prev == 0)
        FDeviceList = FDeviceList->FList;
    else
        prev->FList = ptr->FList;

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::GetDevice
#
#   Purpose....: Get first device in list                                           
#
#   In params..: DeviceCallb
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::GetDevices(void (*DeviceCallb)(TDevice *Device))
{
    TDevice *ptr;
    FListSection.Enter();
    ptr = FDeviceList;
    while (ptr != 0)
    {
        (*DeviceCallb)(ptr);
        ptr = ptr->FList;
    }
    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::TDevice
#
#   Purpose....: Constructor for TDevice                                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDevice::TDevice()
  : FPropertySection("Device.Property")
{
    Init();
}

/*##########################################################################
#
#   Name       : TDevice::~TDevice
#
#   Purpose....: Destructor for TDevice                                   
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDevice::~TDevice()
{
    if (FName)
        delete FName;
        
    RemoveDevice();
}

/*##########################################################################
#
#   Name       : TDevice::Init
#
#   Purpose....: Init method for class. register persistent should              
#                                done here.                                                                    
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Init()
{
    FDebug = 0;
    FDebugFile = 0;

    FName = 0;
    FReset = FALSE;
    FOpen = FALSE;
    FEnabled = FALSE;
    FOnline = FALSE;
    FBusy = FALSE;
    OnOnline = 0;
    OnOffline = 0;
    OnIdle = 0;
    OnBusy = 0;
    OnStateChange = 0;

    InsertDevice();
}

/*##########################################################################
#
#   Name       : TDevice::NotifyStateChange
#
#   Purpose....: Notify of state change
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyStateChange()
{
    if (OnStateChange)
        (*OnStateChange)(this);
}

/*##########################################################################
#
#   Name       : TDevice::NotifyReset
#
#   Purpose....: Notify of system reset                                             
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyReset()
{
    FReset = TRUE;
}

/*##########################################################################
#
#   Name       : TDevice::IsReseted
#
#   Purpose....: Check if device is reseted                                                                 #
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if reseted
#
##########################################################################*/
int TDevice::IsReseted() const
{
    return FReset;
}

/*##########################################################################
#
#   Name       : TDevice::ClearReset
#
#   Purpose....: Clear reset indication
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::ClearReset()
{
    FReset = FALSE;
}

/*##########################################################################
#
#   Name       : TDevice::DeviceName
#
#   Purpose....: Default devicename
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::DeviceName(char *Name, int MaxLen) const
{
    if (FName)
        strncpy(Name, FName, MaxLen);
    else
        strncpy(Name, "NO NAME", MaxLen);
    Name[MaxLen-1] = 0;
}

/*##########################################################################
#
#   Name       : TDevice::NotifyOpen
#
#   Purpose....: Notify open                                                       
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyOpen()
{
    FOpen = TRUE;
}

/*##########################################################################
#
#   Name       : TDevice::Open
#
#   Purpose....: Opens device                                                              
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Open()
{
    FPropertySection.Enter();

    if (!FOpen)
    {
        NotifyOpen();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::NotifyClose
#
#   Purpose....: Notify close                                                      
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyClose()
{
    FOpen = FALSE;
}

/*##########################################################################
#
#   Name       : TDevice::Close
#
#   Purpose....: Closes device                                                             
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Close()
{
    FPropertySection.Enter();
    if (FOpen)
    {
        NotifyClose();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::IsOpen
#
#   Purpose....: Checks if device is open
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if open
#
##########################################################################*/
int TDevice::IsOpen()
{
    return FOpen;
}

/*##########################################################################
#
#   Name       : TDevice::NotifyEnable
#
#   Purpose....: Notify enable
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyEnable()
{
    FEnabled = TRUE;
}

/*##########################################################################
#
#   Name       : TDevice::Enable
#
#   Purpose....: Enables device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Enable()
{
    FPropertySection.Enter();
    if (!FEnabled)
    {
        NotifyEnable();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::NotifyDisable
#
#   Purpose....: Notify disable
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyDisable()
{
    FEnabled = FALSE;
}

/*##########################################################################
#
#   Name       : TDevice::Disable
#
#   Purpose....: Disables device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Disable()
{
    FPropertySection.Enter();
    if (FEnabled)
    {
        NotifyDisable();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::IsEnabled
#
#   Purpose....: Checks if device is enabled
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if enabled
#
##########################################################################*/
int TDevice::IsEnabled() const
{
    return FEnabled;
}

/*##########################################################################
#
#   Name       : TDevice::Online
#
#   Purpose....: Sets state to online
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Online()
{
    FPropertySection.Enter();
    if (!FOnline)
    {
        FOnline = TRUE;
        if (OnOnline)
            OnOnline(this);
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::Offline
#
#   Purpose....: Sets state to offline
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Offline()
{
    FPropertySection.Enter();
    if (FOnline)
    {
        FOnline = FALSE;
        if (OnOffline)
            OnOffline(this);
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::IsOnline
#
#   Purpose....: Checks if device is online
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if online
#
##########################################################################*/
int TDevice::IsOnline()
{
    return FOnline;
}

/*##########################################################################
#
#   Name       : TDevice::IsActive
#
#   Purpose....: Checks if device is open and enabled
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if open and enabled
#
##########################################################################*/
int TDevice::IsActive()
{
    return FEnabled && FOpen;
}

/*##########################################################################
#
#   Name       : TDevice::NotifyIdle
#
#   Purpose....: Notify idle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyIdle()
{
    FBusy = FALSE;
    if (OnIdle)
        OnIdle(this);
}

/*##########################################################################
#
#   Name       : TDevice::Idle
#
#   Purpose....: Sets device to idle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Idle()
{
    FPropertySection.Enter();
    if (FBusy)
    {
        NotifyIdle();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::NotifyBusy
#
#   Purpose....: Notify busy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyBusy()
{
    FBusy = TRUE;
    if (OnBusy)
        OnBusy(this);
}

/*##########################################################################
#
#   Name       : TDevice::Busy
#
#   Purpose....: Sets device to busy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Busy()
{
    FPropertySection.Enter();
    if (!FBusy)
    {
        NotifyBusy();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::IsBusy
#
#   Purpose....: Check if device is busy
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if busy
#
##########################################################################*/
int TDevice::IsBusy()
{
    return FBusy;
}

/*##########################################################################
#
#   Name       : TDevice::Install
#
#   Purpose....: Install device debug
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Install(TDeviceDebug *Debug)
{
    FDebug = Debug;
}

/*##########################################################################
#
#   Name       : TDevice::StartDebug
#
#   Purpose....: Starts device debugging
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::StartDebug()
{
    if (FDebug)
        FDebugFile = FDebug->RequestFile(this);
}

/*##########################################################################
#
#   Name       : TDevice::StopDebug
#
#   Purpose....: Stops device debugging
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::StopDebug()
{
    if (FDebug)
        FDebug->ReleaseFile(this);

    FDebugFile = 0;
}
