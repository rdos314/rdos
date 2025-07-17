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

