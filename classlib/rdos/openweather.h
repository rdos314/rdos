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
# openweather.h
# openweather.org class
#
########################################################################*/

#ifndef _OPENWEATHER_H
#define _OPENWEATHER_H

#include "sockobj.h"
#include "thread.h"
#include "json.h"

class TOpenWeather : public TThread
{
public:
    TOpenWeather(const char *station, const char *key);
    virtual ~TOpenWeather();

    bool IsOnline();
    void WaitForData();

    long double GetTemperature();
    long double GetWindSpeed();
    int GetWindDir();
    long double GetPressure();
    long double GetHumidity();
    int GetCloud();
    int GetVisibility();

protected:
    void HandleJson(const char *str);
    virtual void Execute();

    void ResolveIp();

    long double FTemp;
    long double FWindSpeed;
    int FWindDir;
    long double FPressure;
    long double FHumidity;
    int FCloud;
    int FVisibility;
    bool FOnline;
    bool FNewData;

    long FIp;
    char *FStation;
    char *FKey;
    TTcpSocket *FSocket;
    char FBuf[2048];

};

#endif

