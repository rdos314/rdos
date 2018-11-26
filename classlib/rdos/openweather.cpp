/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# openweather.cpp
# openweather.org read-out
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include "rdos.h"
#include "openweather.h"
#include "json.h"

/*##########################################################################
#
#   Name       : TOpenWeather::TOpenWeather
#
#   Purpose....: FroniusInverter constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOpenWeather::TOpenWeather(const char *station, const char *key)
{
    int len;
    
    FOnline = false;
    FNewData = false;

    FTemp = 0.0;
    FWindSpeed = 0.0;
    FWindDir = 0;
    FPressure = 0.0;
    FHumidity = 0.0;
    FCloud = 0;
    FVisibility = 0;

    len = strlen(station) + 1;
    FStation = new char[len];
    strcpy(FStation, station);

    len = strlen(key) + 1;
    FKey = new char[len];
    strcpy(FKey, key);
    
    FIp = 0;

    Start("openweather.org", 0x8000);
}

/*##########################################################################
#
#   Name       : TOpenWeather::~TOpenWeather
#
#   Purpose....: FroniusInverter destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOpenWeather::~TOpenWeather()
{
    if (FStation)
        delete FStation;

    if (FKey)
        delete FKey;
}

/*##########################################################################
#
#   Name       : TOpenWeather::IsOnline
#
#   Purpose....: Is online?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TOpenWeather::IsOnline()
{
    return FOnline;
}

/*##########################################################################
#
#   Name       : TOpenWeather::WaitForData
#
#   Purpose....: Wait for new data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOpenWeather::WaitForData()
{
    while (!FNewData)
        RdosWaitMilli(250);

    FNewData = false;
}

/*##########################################################################
#
#   Name       : TOpenWeather::GetTemperature
#
#   Purpose....: Get temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TOpenWeather::GetTemperature()
{
    return FTemp;
}

/*##########################################################################
#
#   Name       : TOpenWeather::GetWindSpeed
#
#   Purpose....: Get wind speed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TOpenWeather::GetWindSpeed()
{
    return FWindSpeed;
}

/*##########################################################################
#
#   Name       : TOpenWeather::GetWindDir
#
#   Purpose....: Get wind direction
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TOpenWeather::GetWindDir()
{
    return FWindDir;
}

/*##########################################################################
#
#   Name       : TOpenWeather::GetPressure
#
#   Purpose....: Get pressure
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TOpenWeather::GetPressure()
{
    return FPressure;
}

/*##########################################################################
#
#   Name       : TOpenWeather::GetHumidity
#
#   Purpose....: Get humidity
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TOpenWeather::GetHumidity()
{
    return FHumidity;
}

/*##########################################################################
#
#   Name       : TOpenWeather::GetCloud
#
#   Purpose....: Get percent of clouds
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TOpenWeather::GetCloud()
{
    return FCloud;
}

/*##########################################################################
#
#   Name       : TOpenWeather::GetVisibility
#
#   Purpose....: Get visibility
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TOpenWeather::GetVisibility()
{
    return FVisibility;
}

/*##########################################################################
#
#   Name       : TOpenWeather::Execute
#
#   Purpose....: Execute method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOpenWeather::Execute()
{
    char *ptr;
    char *tempptr;
    int size;
    int i;
    TJsonDocument *json;
    TJsonObject *obj;
    TJsonCollection *col;
    TJsonCollection *root;

    FOnline = false;
    FIp = 0;
    
    while (FIp == 0)
    {
        FIp = RdosNameToIp("api.openweathermap.org");
        if (FIp == 0)
            RdosWaitMilli(2000);
    }

    for (;;)
    {
        FSocket = new TTcpSocket(FIp, 80, 10000, 0x2000);
        FSocket->WaitForConnection(10000);
        if (FSocket->IsOpen())
        {
            strcpy(FBuf, "GET /data/2.5/weather?id=");
            strcat(FBuf, FStation);
            strcat(FBuf, "&appid=");
            strcat(FBuf, FKey);
            strcat(FBuf, " HTTP/1.1\r\n");
            strcat(FBuf, "Host: api.openweathermap.org\r\n");
            strcat(FBuf, "Accept: application/json\r\n");
            strcat(FBuf, "User-Agent: RDOS\r\n");
            strcat(FBuf, "\r\n");
            FSocket->Write(FBuf);
            FSocket->Push();

            FSocket->WaitForData(10000);

            size = 0;
            while (FSocket->WaitForData(500) && size < 2047)
            { 
                FBuf[size] = FSocket->Read();
                size++;
            }

            FBuf[size] = 0;

            delete FSocket;

            ptr = FBuf;
            while (ptr[1] != 0xd)
            {
                tempptr = strchr(ptr + 1, 0xd);
                if (tempptr)
                    ptr = tempptr + 1;
                else
                    break;
            }

            while (*ptr == 0xa || *ptr == 0xd)
                ptr++;

            json = new TJsonDocument(ptr);

            root = json->GetRoot();

            if (root)
            {
                col = root->GetCollection("main");
                if (col)
                {
                    obj = col->GetObj("temp");
                    if (obj)
                        FTemp = obj->GetDouble() - 273.15;

                    obj = col->GetObj("pressure");
                    if (obj)
                        FPressure = obj->GetDouble();

                    obj = col->GetObj("humidity");
                    if (obj)
                        FHumidity = obj->GetDouble();
                }
    
                col = root->GetCollection("wind");
                if (col)
                {
                    obj = col->GetObj("speed");
                    if (obj)
                        FWindSpeed = obj->GetDouble();

                    obj = col->GetObj("deg");
                    if (obj)
                        FWindDir = (int)obj->GetInt();
                }

                col = root->GetCollection("clouds");
                if (col)
                {
                    obj = col->GetObj("all");
                    if (obj)
                        FCloud = (int)obj->GetInt();
                }
                
                obj = root->GetObj("visibility");
                if (obj)
                    FVisibility = (int)obj->GetInt();

                FOnline = true;
                FNewData = true;
            }
            else
                FOnline = false;

            delete json;
            
            for (i = 0; i < 60 * 10; i++)
                RdosWaitMilli(1000);
        }        
    }    
}
