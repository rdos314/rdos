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
TAdcDevice::TAdcDevice(int channel)
{
        Init(channel);
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
TAdcDevice::TAdcDevice(const char *IniSection, int channel)
  : TWaitDevice(IniSection)
{
        Init(channel);
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
#   Name       : TAdcDevice::Init
#
#   Purpose....: Init ADC device channel
#
#   In params..: Wait
#                                Channel #
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcDevice::Init(int channel)
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
}

/*##########################################################################
#
#   Name       : TAdcDevice::Add
#
#   Purpose....: Add object to wait
#
#   In params..: Wait
#                                Channel #
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAdcDevice::Add(TWait *Wait)
{
        RdosAddWaitForAdc(Wait->GetHandle(), FHandle, (int)this);
}

/*##########################################################################
#
#   Name       : TAdcDevice::DeviceName
#
#   Purpose....: Get device-name
#
#   In params..: Name           Device name buffer
#                          : MaxLen             Max length of name
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
#   In params..: tics           tics
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
#   In params..: Val    millivolt value
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
