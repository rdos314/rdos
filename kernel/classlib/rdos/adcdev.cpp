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
# adcdev.cpp
# A/D converter channel class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "adcdev.h"
#include "rdos.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TAdcDevice::TAdcDevice
#
#   Purpose....: Constructor for ADC device channel
#
#   In params..: Channel #
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdcDevice::TAdcDevice(TWait *Wait, int channel)
{
	Init(Wait, channel);
}

/*##########################################################################
#
#   Name       : TAdcDevice::TAdcDevice
#
#   Purpose....: Constructor for ADC device channel
#
#   In params..: Channel #
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdcDevice::TAdcDevice(const char *IniSection, TWait *Wait, int channel)
  : TWaitDevice(IniSection)
{
	Init(Wait, channel);
}

/*##########################################################################
#
#   Name       : TAdcDevice::Init
#
#   Purpose....: Init ADC device channel
#
#   In params..: Wait
#				 Channel #
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcDevice::Init(TWait *Wait, int channel)
{
	FHandle = RdosOpenAdc(channel);
	RdosDefineAdcTime(FHandle, FNextSample.GetMsb(), FNextSample.GetLsb());
	FChannel = channel;
	FSample = 0;
	FDay = 0;
	FHour = 0;
	FMin = 0;
	FSec = 1;
	FMilli = 0;
	FTics = 0;
	OnSample = 0;
	RdosAddWaitForAdc(RegisterWait(Wait), FHandle, this);
}

/*##########################################################################
#
#   Name       : TAdcDevice::~TAdcDevice
#
#   Purpose....: Destructor for ADC device channel
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdcDevice::~TAdcDevice()
{
	RdosCloseAdc(FHandle);
}

/*##########################################################################
#
#   Name       : TAdcDevice::DeviceName
#
#   Purpose....: Get device-name
#
#   In params..: Name		Device name buffer
#			   : MaxLen		Max length of name
#   Out params.: *
#   Returns....: Real value
#
##########################################################################*/
void TAdcDevice::DeviceName(char *Name, int MaxLen) const
{
	char str[80];

	sprintf(str, "ADC channel #%d", FChannel);
	strncpy(Name, str, MaxLen);
}

/*##########################################################################
#
#   Name       : TAdcDevice::GetUnit
#
#   Purpose....: Get unit
#
#   In params..: *
#   Out params.: *
#   Returns....: Measurement unit
#
##########################################################################*/
const char *TAdcDevice::GetUnit()
{
	return "mV";
}

/*##########################################################################
#
#   Name       : TAdcDevice::GetChannel
#
#   Purpose....: Get ADC channel
#
#   In params..: *
#   Out params.: *
#   Returns....: channel
#
##########################################################################*/
int TAdcDevice::GetChannel()
{
	return FChannel;
}

/*##########################################################################
#
#   Name       : TAdcDevice::Define
#
#   Purpose....: Define sample object
#
#   In params..: sample
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcDevice::Define(TSample *Sample)
{
    FSample = Sample;
}

/*##########################################################################
#
#   Name       : TAdcDevice::DefineInterval
#
#   Purpose....: Define sample interval
#
#   In params..: tics		tics
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcDevice::DefineInterval(long tics)
{
	FTics = tics;
	FDay = 0;
	FHour = 0;
	FMin = 0;
	FSec = 0;
	FMilli = 0;
}

/*##########################################################################
#
#   Name       : TAdcDevice::DefineInterval
#
#   Purpose....: Define sample interval
#
#   In params..: day,s hours, min, sec, ms
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcDevice::DefineInterval(long day, long hour, long min, long sec, long milli)
{
	FTics = 0;
	FDay = day;
	FHour = hour;
	FMin = min;
	FSec = sec;
	FMilli = milli;
}

/*##########################################################################
#
#   Name       : TAdcDevice::DefineStart
#
#   Purpose....: Define start time
#
#   In params..: starttime
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcDevice::DefineStart(TDateTime &StartTime)
{
	FNextSample.SetRaw(StartTime.GetMsb(), StartTime.GetLsb());
}

/*##########################################################################
#
#   Name       : TAdcDevice::MvToReal
#
#   Purpose....: Convert from millivolt to real unit
#
#   In params..: Val	millivolt value
#   Out params.: *
#   Returns....: Real value
#
##########################################################################*/
long double TAdcDevice::MvToReal(long double value)
{
	return value;
}

/*##########################################################################
#
#   Name       : TAdcDevice::Sample
#
#   Purpose....: Sample
#
#   In params..: *
#   Out params.: *
#   Returns....: Sampled value
#
##########################################################################*/
long double TAdcDevice::Sample()
{
	int value;

	value = RdosReadAdc(FHandle);
	return MvToReal((long double)value / 32768.0 * 10000.0);
}

/*##########################################################################
#
#   Name       : TAdcDevice::NotifySample
#
#   Purpose....: Notify sample done
#
#   In params..: Value
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcDevice::NotifySample(long double value)
{
	if (OnSample)
		(*OnSample)(this, &FNextSample, value);

	if (FSample)
	    FSample->Add(&FNextSample, value);
}

/*##########################################################################
#
#   Name       : TAdcDevice::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcDevice::SignalNewData()
{
	long double val;

	val = Sample();
	NotifySample(val);

	if (FTics)
		FNextSample.AddTics(FTics);

	if (FDay)
		FNextSample.AddDay(FDay);

	if (FHour)
		FNextSample.AddHour(FHour);

	if (FMin)
		FNextSample.AddMin(FMin);

	if (FSec)
		FNextSample.AddSec(FSec);

	if (FMilli)
		FNextSample.AddMilli(FMilli);

	RdosDefineAdcTime(FHandle, FNextSample.GetMsb(), FNextSample.GetLsb());
}
