/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-20019, Leif Ekblad
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
# misol.h
# Misol weather station class
#
########################################################################*/

#ifndef _MISOL_H
#define _MISOL_H

#include "sockobj.h"
#include "thread.h"

class TMisolWeather : public TThread
{
public:
    TMisolWeather(char *HostStr, int Port);
    virtual ~TMisolWeather();

    bool IsOnline();

    long double GetWindDir();
    long double GetWindSpeed();
    long double GetWindGust();
    long double GetTemperature();
    long double GetHumidity();
    long double GetLight();
    long double GetUv();
    long double GetRain();

    void (*OnWindDir)(TMisolWeather *Device, long double val);
    void (*OnWindSpeed)(TMisolWeather *Device, long double val);
    void (*OnWindGust)(TMisolWeather *Device, long double val);
    void (*OnTemperature)(TMisolWeather *Device, long double val);
    void (*OnHumidity)(TMisolWeather *Device, long double val);
    void (*OnLight)(TMisolWeather *Device, long double val);
    void (*OnUv)(TMisolWeather *Device, long double val);
    void (*OnRain)(TMisolWeather *Device, long double val);

protected:
    void DecodeData(const char *buf, int size);
    virtual void Execute();

    long double FWindDir;
    long double FWind;
    long double FGust;
    long double FTemp;
    long double FHumidity;
    long double FLight;
    long double FUV;
    long double FRain;

    bool FOnline;
    long FIP;
    int FPort;
    char *FHostStr;
    TTcpSocket *FSocket;
};

#endif

