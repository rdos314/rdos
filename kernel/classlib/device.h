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
# device.h
# Basic device class
#
########################################################################*/

#ifndef _DEVICE_H
#define _DEVICE_H

#include "section.h"
#include "thread.h"

class TDevice : public TThread
{
public:
	TDevice();
	TDevice(const char *IniSection);
	virtual ~TDevice();
	virtual void NotifyReset();
	virtual void Open();
	virtual void Close();
	virtual int IsOpen() const;
	virtual void Enable();
	virtual void Disable();
	virtual int IsActive() const;
	virtual int IsBusy() const;
	virtual int IsEnabled() const;
	virtual int IsOnline() const;
	virtual void DeviceName(char *Name, int MaxLen) const = 0;
	static void GetDevices(void (*DeviceCallb)(TDevice *Device));

	void *Owner;
	void (*OnOnline)(TDevice *Device);
	void (*OnOffline)(TDevice *Device);
	void (*OnIdle)(TDevice *Device);
	void (*OnBusy)(TDevice *Device);

protected:
	int LoadProperty(const char *Name, int Def);
	long LoadProperty(const char *Name, long Def);
	void SaveProperty(const char *Name, int Value);
	void SaveProperty(const char *Name, long Value);
	virtual void Online();
	virtual void Offline();
	virtual void Idle();
	virtual void Busy();
	int IsReseted() const;
	void ClearReset();

private:
	void Init();
	void InsertDevice();
	void RemoveDevice();

	static TSection FListSection;
	static TDevice *FDeviceList;
	TDevice *FList;
	const char *FIniSection;
	int	FOpen;
	int FEnabled;
	int FOnline;
	int FBusy;
	int FReset;
};

#endif

