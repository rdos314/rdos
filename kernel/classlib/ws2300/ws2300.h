/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2005, Leif Ekblad
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
# This code is a modified verision of:
# Control WS2300 weather station
#  
#  Copyright 2003-2005, Kenneth Lavrsen
#  This program is published under the GNU General Public license
#
# ws2300.h
# WS2300 weather station class library
#
########################################################################*/

#ifndef _WS2300_H
#define _WS2300_H

#include "device.h"
#include "serial.h"

class TWs2300 : public TDevice
{
public:
	TWs2300(TSerialDevice *serial);
	TWs2300(int Port);
	~TWs2300();

	virtual void DeviceName(char *Name, int MaxLen) const;

	long double GetIndoorTemp();
    long double GetOutdoorTemp();
    long double GetDewpoint();
    long double GetIndoorHumidity();
    long double GetOutdoorHumidity();
    long double GetWindchill();
    long double GetWind(long double *winddir);
    long double GetRain1h();
    long double GetRain24h();
    long double GetAirPressure();

protected:
    void AddressEncode(int address);
    void CountEncode(int count);
    unsigned char Checksum(const char *buf, int count);
    
    int Reset06();
    int Read(int address, int count, char *buf);
    int Write(int address, int count, const char *buf);
	 int SafeRead(int address, int count, unsigned char *buf);
	 int SafeWrite(int address, int count, const unsigned char *buf);

    TSerialDevice *FSerial;
    int FFreeSerial;
    unsigned char FCmdBuf[25];

private:
    void Init();    
};

#endif
