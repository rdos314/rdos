/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
#
# This program is free software; you can reDeviceribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is Deviceributed in the hope that it will be useful,
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
    int IsEnabled() const;
        
    virtual int IsOpen();
    virtual int IsActive();
    virtual int IsBusy();
    virtual int IsOnline();
    virtual void DeviceName(char *Name, int MaxLen) const;

    static void GetDevices(void (*DeviceCallb)(TDevice *Device));

    void Install(TDeviceDebug *Debug);
    virtual void StartDebug();
    virtual void StopDebug();

    void (*OnOnline)(TDevice *Device);
    void (*OnOffline)(TDevice *Device);
    void (*OnIdle)(TDevice *Device);
    void (*OnBusy)(TDevice *Device);

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

private:
    void Init();
    void InsertDevice();
    void RemoveDevice();

    static TSection FListSection;
    static TDevice *FDeviceList;
    TDevice *FList;
};

#endif

