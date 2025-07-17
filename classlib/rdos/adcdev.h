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
# adcdev.h
# A/D converter channel class
#
########################################################################*/

#ifndef _ADCDEV_H
#define _ADCDEV_H

#include "waitdev.h"
#include "sample.h"
#include "datetime.h"

class TAdcDevice : public TWaitDevice
{
public:
	TAdcDevice(int channel);
	~TAdcDevice();

	int GetChannel();
	void Define(TSample *sample);
	void DefineInterval(long tics);
	void DefineInterval(long day, long hour, long min, long sec, long milli);
	void DefineStart(TDateTime &StartTime);

	virtual void DeviceName(char *Name, int MaxLen) const;
	virtual const char *GetUnit();
	long double Sample();

	void (*OnSample)(TAdcDevice *Adc, TDateTime *time, long double value);

protected:
	void NotifySample(long double value);

	virtual void SignalNewData();
	virtual void Add(TWait *Wait);
	virtual long double MvToReal(long double mv);

	TDateTime FNextSample;
	TSample *FSample;
	long FDay;
	long FHour;
	long FMin;
	long FSec;
	long FMilli;
	long FTics;
	int FChannel;

private:
	void Init(int channel);

	int FHandle;
};

#endif

