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
# wh1080.h
# WH1080 weather station class
#
########################################################################*/

#ifndef _WH1080_H
#define _WH1080_H

#include "hid.h"
#include "section.h"
#include "sigdev.h"

class TWh1080Device : public THidDevice
{
public:
	TWh1080Device();
    ~TWh1080Device();

    virtual void DeviceName(char *Name, int MaxLen) const;

    long double GetIndoorHumidity();
    long double GetIndoorTemperature();
    long double GetOutdoorHumidity();
    long double GetOutdoorTemperature();
    long double GetPressure();
    long double GetWindAverage();
    long double GetWindGust();
    long double GetWindDir();
    long double GetRain();

    void WaitForData(); 

    int IsIndoorHumidityValid();
    int IsIndoorTemperatureValid();
    int IsOutdoorHumidityValid();
    int IsOutdoorTemperatureValid();
    int IsPressureValid();
    int IsWindAverageValid();
    int IsWindGustValid();
    int IsWindDirValid();
    int IsRainValid();

protected:
    int ReadBlock(int Offset, char *Buffer);
    int WriteBlock(int Offset, const char *Buffer);
    int WriteDataRefresh();
    int ReadFixedBlock(char *Buffer);
    int WriteFixedBlock(char *Buffer);
    int ReadMeassure(int Offset, char *Buffer);

    void Setup();
    void GetCurrentPos();
    void DecodeData(char *Buffer);
    void GetData();
    
	virtual void Execute();

	int FCurrPos;

	TDateTime FIndoorHumidityTime;
	TDateTime FIndoorTemperatureTime;
	TDateTime FOutdoorHumidityTime;
	TDateTime FOutdoorTemperatureTime;
	TDateTime FPressureTime;
	TDateTime FWindAverageTime;
	TDateTime FWindGustTime;
	TDateTime FWindDirTime;
	TDateTime FRainTime;

	long double FIndoorHumidity;
	long double FIndoorTemperature;
	long double FOutdoorHumidity;
	long double FOutdoorTemperature;
	long double FPressure;
	long double FWindAverage;
	long double FWindGust;
	long double FWindDir;
	long double FRain;	

	TSection FSection;
	TSignalDevice FSignal;
};

#endif
