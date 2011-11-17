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
	TAdcDevice(TWait *Wait, int channel);
	TAdcDevice(const char *IniSection, TWait *Wait, int channel);
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
	void Init(TWait *Wait, int channel);

	int FHandle;
};

#endif

