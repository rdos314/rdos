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
# waitdev.h
# A waitable device class
#
########################################################################*/

#ifndef _WAIT_DEV_H
#define _WAIT_DEV_H

#include "device.h"
#include "datetime.h"

class TWait;

class TWaitDevice : public TDevice
{
friend class TWait;

public:
	TWaitDevice();
	TWaitDevice(const char *IniSection);
	virtual ~TWaitDevice();

	TWaitDevice *WaitForever();
	TWaitDevice *WaitTimeout(int MilliSec);
	TWaitDevice *WaitUntil(TDateTime &time);

	void StartHandler(const char *Name, int StackSize);

	int ID;

protected:
	void CreateWait();
	void Remove(TWait *Wait);

	virtual void SignalNewData() = 0;
	virtual void Add(TWait *Wait) = 0;

    virtual void Execute();


	TWait *FWait;

private:
void Init();
};

class TWaitList
{
public:
    TWaitDevice *WaitDev;
    TWaitList *List;
};

class TWait
{

public:
	TWait();
	virtual ~TWait();

	void StartThreadHandler(const char *ThreadName, int StackSize);
	virtual void Execute();

	TWaitDevice *Check();
	TWaitDevice *WaitForever();
	TWaitDevice *WaitTimeout(int MilliSec);
	TWaitDevice *WaitUntil(TDateTime &time);
	void Abort();

	void Add(TWaitDevice *dev);
	void Remove(TWaitDevice *dev);

	int GetHandle();

private:
    TWaitList *FWaitList;
    TSection FListSection;
    
    int FHandle;
	int FThreadRunning;
	int FInstalled;
};

#endif

