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

#define FALSE 0
#define TRUE !FALSE

#endif

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
#   Name       : TDeviceNotify::TDeviceNotify
#
#   Purpose....: Virtual base class for device notifications
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDeviceNotify::TDeviceNotify()
{
}

/*##########################################################################
#
#   Name       : TDeviceNotify::~TDeviceNotify
#
#   Purpose....: Destructor for device notifications
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDeviceNotify::~TDeviceNotify()
{
}

/*##########################################################################
#
#   Name       : TDeviceNotify::NotifyOnline
#
#   Purpose....: Online notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDeviceNotify::NotifyOnline(TDevice *Device)
{
}

/*##########################################################################
#
#   Name       : TDeviceNotify::NotifyOffline
#
#   Purpose....: Offline notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDeviceNotify::NotifyOffline(TDevice *Device)
{
}

/*##########################################################################
#
#   Name       : TDeviceNotify::NotifyIdle
#
#   Purpose....: Idle notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDeviceNotify::NotifyIdle(TDevice *Device)
{
}

/*##########################################################################
#
#   Name       : TDeviceNotify::NotifyBusy
#
#   Purpose....: Busy notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDeviceNotify::NotifyBusy(TDevice *Device)
{
}

/*##########################################################################
#
#   Name       : TDeviceNotify::NotifyOpen
#
#   Purpose....: Open notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDeviceNotify::NotifyOpen(TDevice *Device)
{
}

/*##########################################################################
#
#   Name       : TDeviceNotify::NotifyClose
#
#   Purpose....: Close notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDeviceNotify::NotifyClose(TDevice *Device)
{
}

/*##########################################################################
#
#   Name       : TDeviceNotify::NotifyEnable
#
#   Purpose....: Enable notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDeviceNotify::NotifyEnable(TDevice *Device)
{
}

/*##########################################################################
#
#   Name       : TDeviceNotify::NotifyDisable
#
#   Purpose....: Disable notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDeviceNotify::NotifyDisable(TDevice *Device)
{
}

/*##########################################################################
#
#   Name       : TDeviceNotify::NotifyReset
#
#   Purpose....: Reset notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDeviceNotify::NotifyReset(TDevice *Device)
{
}

/*##########################################################################
#
#   Name       : TDeviceNotify::NotifyStateChange
#
#   Purpose....: State change notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDeviceNotify::NotifyStateChange(TDevice *Device)
{
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
    int i;

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
    OnOpen = 0;
    OnClose = 0;
    OnStateChange = 0;

    NotifyCount = 0;

    for (i = 0; i < MAX_DEVICE_NOTIFY_COUNT; i++)
        NotifyArr[i] = 0;

    InsertDevice();
}

/*##########################################################################
#
#   Name       : TDevice::AddNotify
#
#   Purpose....: Add notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::AddNotify(TDeviceNotify *Notify)
{
    int i;

    FPropertySection.Enter();

    for (i = 0; i < MAX_DEVICE_NOTIFY_COUNT; i++)
    {
        if (NotifyArr[i] == 0)
        {
            NotifyArr[i] = Notify;
            if (i >= NotifyCount)
                NotifyCount = i + 1;

            break;
        }
    }

    FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::RemoveNotify
#
#   Purpose....: Remove notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::RemoveNotify(TDeviceNotify *Notify)
{
    int i;

    FPropertySection.Enter();

    for (i = 0; i < NotifyCount; i++)
    {
        if (NotifyArr[i] == Notify)
        {
            NotifyArr[i] = 0;
            break;
        }
    }

    while (NotifyCount)
    {
        if (NotifyArr[NotifyCount - 1])
            break;
        else
            NotifyCount--;
    }

    FPropertySection.Leave();
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
    int i;

    if (OnStateChange)
        (*OnStateChange)(this);

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyStateChange(this);
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
    int i;

    FReset = TRUE;

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyReset(this);
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
    int i;

    FOpen = TRUE;

    if (OnOpen)
        (*OnOpen)(this);

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyOpen(this);
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
    int i;

    FOpen = FALSE;

    if (OnClose)
        (*OnClose)(this);

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyClose(this);
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
    int i;

    FEnabled = TRUE;

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyEnable(this);
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
    int i;

    FEnabled = FALSE;

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyDisable(this);
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
int TDevice::IsEnabled()
{
    return FEnabled;
}

/*##########################################################################
#
#   Name       : TDevice::NotifyOnline
#
#   Purpose....: Notify online
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyOnline()
{
    int i;

    FOnline = TRUE;

    if (OnOnline)
        OnOnline(this);

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyOnline(this);
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
        NotifyOnline();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::NotifyOffline
#
#   Purpose....: Notify offline
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyOffline()
{
    int i;

    FOnline = FALSE;

    if (OnOffline)
        OnOffline(this);

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyOffline(this);
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
        NotifyOffline();
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
    int i;

    FBusy = FALSE;

    if (OnIdle)
        OnIdle(this);

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyIdle(this);
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
    int i;

    FBusy = TRUE;

    if (OnBusy)
        OnBusy(this);

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyBusy(this);
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
#   Name       : TDevice::StartDeviceDebug
#
#   Purpose....: Starts device debugging
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::StartDeviceDebug()
{
    if (FDebug)
        FDebugFile = FDebug->RequestFile(this);
}

/*##########################################################################
#
#   Name       : TDevice::StopDeviceDebug
#
#   Purpose....: Stops device debugging
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::StopDeviceDebug()
{
    if (FDebug)
        FDebug->ReleaseFile(this);

    FDebugFile = 0;
}
