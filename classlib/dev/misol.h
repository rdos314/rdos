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
# misol.h
# Misol weather station class
#
########################################################################*/

#ifndef _MISOL_H
#define _MISOL_H

#include "sockobj.h"
#include "thread.h"
#include "ini.h"

class TMisolWeather : public TThread
{
public:
    TMisolWeather(char *HostStr, int Port, const char *IniName);
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
    void (*OnMinTemp)(TMisolWeather *Device, long double val);
    void (*OnMaxTemp)(TMisolWeather *Device, long double val);

protected:
    void Init();
    void DecodeData(const char *buf, int size);
    virtual void Execute();

    long double FWindDir;
    long double FWind;
    long double FGust;
    long double FTemp;
    long double FMinTemp;
    long double FMaxTemp;
    long double FHumidity;
    long double FLight;
    long double FUV;
    long double FRain;
    long double FRainBase;
    bool FHasRainBase;
    bool FHasMinMax;
    bool FHasDay;
    int FCurrDay;

    bool FOnline;
    long FIP;
    int FPort;
    char *FHostStr;
    TTcpSocket *FSocket;
    TIniFile FIni;
};

#endif

