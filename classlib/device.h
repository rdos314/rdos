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
# device.h
# Basic device class
#
########################################################################*/

#ifndef _DEVICE_H
#define _DEVICE_H

#include <stdlib.h>

#include "section.h"
#include "thread.h"
#include "datetime.h"
#include "file.h"

#define MAX_DEVICE_NOTIFY_COUNT	10

class TDevice;

class TDeviceDebug : public TThread
{
public:
    TDeviceDebug();
    virtual ~TDeviceDebug();

    virtual TFile *RequestFile(TDevice *Device);
    virtual void ReleaseFile(TDevice *Device);
    virtual int MaxFileSize();
};    

class TDeviceNotify
{
public:
    TDeviceNotify();
    virtual ~TDeviceNotify();

    virtual void NotifyOnline(TDevice *Device);
    virtual void NotifyOffline(TDevice *Device);
    virtual void NotifyIdle(TDevice *Device);
    virtual void NotifyBusy(TDevice *Device);
    virtual void NotifyOpen(TDevice *Device);
    virtual void NotifyClose(TDevice *Device);
    virtual void NotifyEnable(TDevice *Device);
    virtual void NotifyDisable(TDevice *Device);
    virtual void NotifyReset(TDevice *Device);
    virtual void NotifyStateChange(TDevice *Device);
};    

class TDevice : public TThread
{

public:
    TDevice();
    virtual ~TDevice();

    virtual void NotifyReset();
    int IsReseted() const;

    void Open();
    void Close();
    void Enable();
    void Disable();
    int IsEnabled();
        
    virtual int IsOpen();
    virtual int IsActive();
    virtual int IsBusy();
    virtual int IsOnline();
    virtual void DeviceName(char *Name, int MaxLen) const;

    static void GetDevices(void (*DeviceCallb)(TDevice *Device));

    void Install(TDeviceDebug *Debug);
    virtual void StartDeviceDebug();
    virtual void StopDeviceDebug();

    void AddNotify(TDeviceNotify *Notify);
    void RemoveNotify(TDeviceNotify *Notify);

    void (*OnOnline)(TDevice *Device);
    void (*OnOffline)(TDevice *Device);
    void (*OnIdle)(TDevice *Device);
    void (*OnBusy)(TDevice *Device);
    void (*OnOpen)(TDevice *Device);
    void (*OnClose)(TDevice *Device);

    void *StateData;
    void (*OnStateChange)(TDevice *Device);

protected:
    void NotifyStateChange();
    
    virtual void NotifyOpen();
    virtual void NotifyClose();
    virtual void NotifyEnable();
    virtual void NotifyDisable();
    virtual void NotifyIdle();
    virtual void NotifyBusy();

    virtual void Online();
    virtual void Offline();

    void Idle();
    void Busy();

    void ClearReset();

    int FOpen;
    int FEnabled;
    int FOnline;
    int FBusy;
    int FReset;
    char *FName;
    TSection FPropertySection;

    TDeviceDebug *FDebug;
    TFile *FDebugFile;

    int NotifyCount;
    TDeviceNotify *NotifyArr[MAX_DEVICE_NOTIFY_COUNT];

private:
    void Init();
    void InsertDevice();
    void RemoveDevice();

    void NotifyOnline();
    void NotifyOffline();

    static TSection FListSection;
    static TDevice *FDeviceList;
    TDevice *FList;
};

#endif

