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
# misol.cpp
# Misol weather station class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <arpa/inet.h>
#include <netdb.h>
#include "rdos.h"
#include "misol.h"

/*##########################################################################
#
#   Name       : TMisolWeather::TMisolWeather
#
#   Purpose....: Misol constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMisolWeather::TMisolWeather(char *HostStr, int Port)
{
    int size = strlen(HostStr);

    FOnline = false;

    FHostStr = new char[size + 1];
    strcpy(FHostStr, HostStr);

    FIP = 0;
    FPort = Port;

    Init();
}

/*##########################################################################
#
#   Name       : TMisolWeather::TMisolWeather
#
#   Purpose....: Misol constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMisolWeather::TMisolWeather(char *HostStr, int Port, const char *IniName)
  : FIni(IniName)
{
    int size = strlen(HostStr);

    FOnline = false;

    FHostStr = new char[size + 1];
    strcpy(FHostStr, HostStr);

    FIP = 0;
    FPort = Port;

    Init();
}

/*##########################################################################
#
#   Name       : TMisolWeather::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMisolWeather::Init()
{
    int pyear, pmonth, pday;
    int year, month, day;
    int hour, min, sec;
    int ms, us;
    unsigned long msb, lsb;
    int count;
    char str[40];

    OnWindDir = 0;
    OnWindSpeed = 0;
    OnWindGust = 0;
    OnTemperature = 0;
    OnHumidity = 0;
    OnLight = 0;
    OnUv = 0;
    OnRain = 0;
    OnMinTemp = 0;
    OnMaxTemp = 0;

    FHasMinMax = false;
    FHasDay = false;

    RdosGetTime(&msb, &lsb);
    RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
    RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);

    FIni.GotoSection("Misol");
    FHasRainBase = FIni.ReadVar("Date", str, 50);
    if (FHasRainBase)
    {
        count = sscanf(str, "%04d%02d%02d", &pyear, &pmonth, &pday);
        if (count != 3)
            FHasRainBase = false;
    }

    if (FHasRainBase)
        if (year != pyear || month != pmonth || day != pday)
            FHasRainBase = false;

    if (FHasRainBase)
        FHasRainBase = FIni.ReadVar("Rain", str, 50);

    if (FHasRainBase)
    {
        count = sscanf(str, "%Lf", &FRainBase);
        if (count != 1)
            FHasRainBase = false;
    }

    Start("Misol", 0x8000);
}

/*##########################################################################
#
#   Name       : TMisolWeather::~TMisolWeather
#
#   Purpose....: SmartPowInverter destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMisolWeather::~TMisolWeather()
{
}

/*##########################################################################
#
#   Name       : TMisolWeather::IsOnline
#
#   Purpose....: Is online?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TMisolWeather::IsOnline()
{
    return FOnline;
}

/*##########################################################################
#
#   Name       : TMisolWeather::GetWindDir
#
#   Purpose....: Get current wind direction
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TMisolWeather::GetWindDir()
{
    return FWindDir;
}

/*##########################################################################
#
#   Name       : TMisolWeather::GetWindSpeed
#
#   Purpose....: Get current wind speed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TMisolWeather::GetWindSpeed()
{
    return FWind;
}

/*##########################################################################
#
#   Name       : TMisolWeather::GetWindGust
#
#   Purpose....: Get current wind speed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TMisolWeather::GetWindGust()
{
    return FGust;
}

/*##########################################################################
#
#   Name       : TMisolWeather::GetTemperature
#
#   Purpose....: Get current temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TMisolWeather::GetTemperature()
{
    return FTemp;
}

/*##########################################################################
#
#   Name       : TMisolWeather::GetHumidity
#
#   Purpose....: Get current humidity
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TMisolWeather::GetHumidity()
{
    return FHumidity;
}

/*##########################################################################
#
#   Name       : TMisolWeather::GetLight
#
#   Purpose....: Get current light
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TMisolWeather::GetLight()
{
    return FLight;
}

/*##########################################################################
#
#   Name       : TMisolWeather::GetUv
#
#   Purpose....: Get current UV
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TMisolWeather::GetUv()
{
    return FUV;
}

/*##########################################################################
#
#   Name       : TMisolWeather::GetRain
#
#   Purpose....: Get current rain
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TMisolWeather::GetRain()
{
    return FRain - FRainBase;
}

/*##########################################################################
#
#   Name       : TMisolWeather::DecodeData
#
#   Purpose....: Decode data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMisolWeather::DecodeData(const char *str, int size)
{
    const char *ptr = str;
    unsigned char uch;
    int val;
    int year, month, day, hour;
    unsigned long msb, lsb;
    char rainstr[40];

    if (ptr[0] == 0x24 && ptr[1] == 0x6B)
    {
        memcpy(&uch, ptr + 2, 1);
        val = uch;
        memcpy(&uch, ptr + 3, 1);
        if (uch & 0x80)
            val += 0x100;
        FWindDir =(long double)val;

        if (OnWindDir)
            (*OnWindDir)(this, FWindDir);

        val = (uch & 0xF) << 8;
        memcpy(&uch, ptr + 4, 1);
        val += uch;
        FTemp = ((long double)val - 400.0) / 10.0;

        if (!FHasMinMax)
        {
            FMinTemp = FTemp;
            FMaxTemp = FTemp;
            FHasMinMax = true;
        }

        if (FMinTemp > FTemp)
            FMinTemp = FTemp;

        if (FMaxTemp < FTemp)
            FMaxTemp = FTemp;

        if (OnTemperature)
            (*OnTemperature)(this, FTemp);

        memcpy(&uch, ptr + 5, 1);
        val = uch;
        FHumidity = (long double)val;

        if (OnHumidity)
            (*OnHumidity)(this, FHumidity);

        memcpy(&uch, ptr + 6, 1);
        val = uch;
        FWind = (long double)val / 8.0 * 1.12;

        if (OnWindSpeed)
            (*OnWindSpeed)(this, FWind);

        memcpy(&uch, ptr + 7, 1);
        val = uch;
        FGust = (long double)val * 1.12;

        if (OnWindGust)
            (*OnWindGust)(this, FGust);

        memcpy(&uch, ptr + 8, 1);
        val = uch << 8;
        memcpy(&uch, ptr + 9, 1);
        val += uch;
        FRain = (long double)val * 0.3;

        RdosGetTime(&msb, &lsb);
        RdosDecodeMsbTics(msb, &year, &month, &day, &hour);

        if (!FHasDay)
        {
            FCurrDay = day;
            FHasDay = true;
        }

        if (day != FCurrDay)
        {
            if (OnRain)
                (*OnRain)(this, FRain - FRainBase);

            if (OnMinTemp)
                (*OnMinTemp)(this, FMinTemp);

            if (OnMaxTemp)
                (*OnMaxTemp)(this, FMaxTemp);

            FMinTemp = FTemp;
            FMaxTemp = FTemp;

            FHasRainBase = false;
        }

        if (!FHasRainBase)
        {
            sprintf(rainstr, "%04d%02d%02d", year, month, day);
            FIni.WriteVar("Date", rainstr);

            sprintf(rainstr, "%5.3Lf", FRain);
            FIni.WriteVar("Rain", rainstr);

            FCurrDay = day;
            FHasRainBase = true;
            FRainBase = FRain;
        }

        memcpy(&uch, ptr + 10, 1);
        val = uch << 8;
        memcpy(&uch, ptr + 11, 1);
        val += uch;
        FUV = (long double)val * 0.01;

        if (OnUv)
            (*OnUv)(this, FUV);

        memcpy(&uch, ptr + 12, 1);
        val = uch << 16;
        memcpy(&uch, ptr + 13, 1);
        val += uch << 8;
        memcpy(&uch, ptr + 14, 1);
        val += uch;
        FLight = (long double)val * 0.1;

        if (OnLight)
            (*OnLight)(this, FLight);

        FOnline = true;
    }
}

/*##########################################################################
#
#   Name       : TMisolWeather::Execute
#
#   Purpose....: Execute method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMisolWeather::Execute()
{
    int size;
    int count;
    char buf[40];
    struct hostent *host;

    FOnline = false;

    while (FIP == 0)
    {
        host = gethostbyname(FHostStr);
        if (host)
            FIP = *(long *)host->h_addr_list[0];
        else
            RdosWaitMilli(500);
    }

    for (;;)
    {
        FSocket = new TTcpSocket(FIP, FPort, 5000, 0x2000);
        FSocket->WaitForConnection(5000);

        count = 0;

        while (FSocket->IsOpen())
        {
            if (FSocket->WaitForData(2500))
            {
                size = 0;
                while (FSocket->WaitForData(1000) && size < 40)
                {
                    count = 0;
                    buf[size] = FSocket->Read();
                    size++;
                }
                DecodeData(buf, size);
            }
            else
            {
                FSocket->Push();
                if (count > 10)
                    FOnline = false;
                else
                    count++;
            }
        }

        FOnline = false;

        delete FSocket;
    }
}
