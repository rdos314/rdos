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
# frinv.cpp
# Fronius inverter read-out
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include "rdos.h"
#include "frinv.h"

/*##########################################################################
#
#   Name       : TFroniusInverter::TFroniusInverter
#
#   Purpose....: FroniusInverter constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFroniusInverter::TFroniusInverter(char *IpStr, long IP)
{
    FCurrFact = 1.0;
    FDayFact = 0.001;
    FYearFact = 0.001;
    FTotalFact = 0.001;
    FOnline = false;
    strcpy(FIpStr, IpStr);
    FIP = IP;

    Start("Fronius inverter", 0x8000);
}

/*##########################################################################
#
#   Name       : TFroniusInverter::~TFroniusInverter
#
#   Purpose....: FroniusInverter destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFroniusInverter::~TFroniusInverter()
{
}

/*##########################################################################
#
#   Name       : TFroniusInverter::GetPowerFact
#
#   Purpose....: Get power factor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TFroniusInverter::GetPowerFact(char *unit)
{    
    if (!strcmp(unit, "kW"))
        return 1000.0;

    if (!strcmp(unit, "MW"))
        return 1000000.0;

    return 1.0;
}

/*##########################################################################
#
#   Name       : TFroniusInverter::GetPowerFact
#
#   Purpose....: Get power factor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TFroniusInverter::GetEnergyFact(char *unit)
{    
    if (!strcmp(unit, "kWh"))
        return 1.0;

    if (!strcmp(unit, "MWh"))
        return 1000.0;

    return 0.001;
}

/*##########################################################################
#
#   Name       : TFroniusInverter::NotifyUnit
#
#   Purpose....: Notify unit used
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFroniusInverter::NotifyUnit(char *name, char *unit)
{    
    if (!strcmp(name, "PAC"))
        FCurrFact = GetPowerFact(unit);

    if (!strcmp(name, "DAY_ENERGY"))
        FDayFact = GetEnergyFact(unit);
    
    if (!strcmp(name, "YEAR_ENERGY"))
        FYearFact = GetEnergyFact(unit);
    
    if (!strcmp(name, "TOTAL_ENERGY"))
        FTotalFact = GetEnergyFact(unit);
}

/*##########################################################################
#
#   Name       : TFroniusInverter::NotifyValue
#
#   Purpose....: Notify value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFroniusInverter::NotifyValue(char *name, int index, int value)
{
    if (index == 1)
    {
        if (!strcmp(name, "PAC"))
            FCurrP = (long double)value * FCurrFact;

        if (!strcmp(name, "DAY_ENERGY"))
            FDayE = (long double)value * FDayFact;
    
        if (!strcmp(name, "YEAR_ENERGY"))
            FYearE = (long double)value * FYearFact;
    
        if (!strcmp(name, "TOTAL_ENERGY"))
            FTotalE = (long double)value * FTotalFact;
    }
}

/*##########################################################################
#
#   Name       : TFroniusInverter::DecodeUnit
#
#   Purpose....: Decode unit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFroniusInverter::DecodeUnit(char *name, char *data)
{
    char *ptr;
    char *unit = strchr(data, 0x22);

    if (unit)
    {
        unit++;
        ptr = strchr(unit, 0x22);
        if (ptr)
        {
            *ptr = 0;
            NotifyUnit(name, unit);
        }
    }
}

/*##########################################################################
#
#   Name       : TFroniusInverter::DecodeData
#
#   Purpose....: Decode data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFroniusInverter::DecodeData(char *name, char *data)
{
    bool hasq = false;
    char *ptr = data;
    char *ip = 0;
    char *vp = 0;

    while (*ptr)
    {
        switch (*ptr)
        {
            case 0x22:
                if (hasq)
                {
                    *ptr = 0;
                    hasq = false;
                }
                else
                {
                    if (!ip)
                    {
                        ip = ptr + 1;
                        hasq = true;
                    }
                }
                break;

            case ':':
                vp = ptr + 1;
                break;
        }
        ptr++;
    }

    if (ip && vp)
        NotifyValue(name, atoi(ip), atoi(vp));
}

/*##########################################################################
#
#   Name       : TFroniusInverter::NotifyField
#
#   Purpose....: Notify field
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFroniusInverter::NotifyField(char *name, char *field, char *data)
{
    if (!strcmp(field, "Unit"))
        DecodeUnit(name, data);

    if (!strcmp(field, "Values"))
        DecodeData(name, data);
}

/*##########################################################################
#
#   Name       : TFroniusInverter::NotifyParam
#
#   Purpose....: Notify parameter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFroniusInverter::NotifyParam(char *name, char *data)
{
    int count = 0;
    bool hasq = false;
    char *ptr = data;
    char *pp = 0;
    char *pd = 0;

    while (*ptr)
    {
        switch (*ptr)
        {
            case '{':
                if (count == 0 && pp)
                    pd = ptr + 1;
                
                count++;
                break;

            case '}':
                count--;
                if (count == 0 && pp && pd)
                {
                    *ptr = 0;
                    NotifyField(name, pp, pd);
                    pp = 0;
                    pd = 0;
                }
                break;

            case 0x22:
                if (count == 0)
                {
                    if (hasq)
                    {
                        *ptr = 0;
                        hasq = false;
                    }
                    else
                    {
                        if (!pp)
                        {
                            pp = ptr + 1;
                            hasq = true;
                        }
                    }
                }
                break;

            case ':':
                if (count == 0)
                    pd = ptr + 1;
                break;

            case ',':
                if (pp && pd)
                {
                    *ptr = 0;
                    NotifyField(name, pp, pd);
                    pp = 0;
                    pd = 0;
                }
                break;
                
            default:
                break;                    
        }
        ptr++;
    }

    if (pp && pd)
        NotifyField(name, pp, pd);
}

/*##########################################################################
#
#   Name       : TFroniusInverter::GetQuoted
#
#   Purpose....: Get quoted data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TFroniusInverter::GetQuoted(char *str)
{
    char *ptr = str;
    int count = 0;
    bool hasq = false;
    char *dp = 0;
    char *np = 0;

    while (*ptr)
    {
        switch (*ptr)
        {
            case '{':
                count++;
                if (count == 1)
                    dp = ptr + 1;
                break;

            case '}':
                count--;
                if (count == 0)
                {
                    *ptr = 0;
                    if (np && dp)
                        NotifyParam(np, dp);
                    return ptr + 1;
                }
                break;

            case 0x22:
                if (count == 0)
                {
                    if (hasq)
                    {
                        *ptr = 0;
                        hasq = false;
                    }
                    else
                    {
                        hasq = true;
                        np = ptr + 1;
                    }
                }
                break;

            default:
                break;            
        }
        ptr++;
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TFroniusInverter::GetBlock
#
#   Purpose....: Get block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TFroniusInverter::GetBlock(char *str)
{
    int count = 0;
    char *ptr = str;

    while (*ptr)
    {
        switch (*ptr)
        {
            case '{':
                count++;
                break;

            case '}':
                count--;
                if (count == 0)
                {
                    *ptr = 0;
                    return str + 1;
                }
                break;

            default:
                break;
        }
        ptr++;
    }

    return 0;
}

/*##########################################################################
#
#   Name       : TFroniusInverter::Execute
#
#   Purpose....: Execute method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFroniusInverter::Execute()
{
    char ch;
    int size;
    char *ptr;

    FOnline = false;

    for (;;)
    {
        FSocket = new TTcpSocket(FIP, 80, 5000, 0x2000);
        FSocket->WaitForConnection(5000);
        while (FSocket->IsOpen())
        {
            strcpy(FBuf, "GET /solar_api/v1/GetInverterRealtimeData.fcgi?Scope=System HTTP/1.1\r\n");
            strcat(FBuf, "Host: ");
            strcat(FBuf, FIpStr);
            strcat(FBuf, "\r\n");
            strcat(FBuf, "Connection: keep-alive\r\n");
            strcat(FBuf, "Accept: application/json, text/javascript, */*;q=0.01\r\n");
            strcat(FBuf, "X-Requested-With: XMLHttpRequest\r\n");
            strcat(FBuf, "User-Agent: RDOS\r\n");
            strcat(FBuf, "Accept-Encoding: gzip\r\n");
            strcat(FBuf, "Accept-Language: en-US,en;q=0.6\r\n");
            strcat(FBuf, "Cookie: lang=en\r\n");
            strcat(FBuf, "\r\n");
            FSocket->Write(FBuf);
            FSocket->Push();

            size = 0;
            while (FSocket->WaitForData(1000) && size < 2047)
            { 
                FBuf[size] = FSocket->Read();
                size++;
            }

            FBuf[size] = 0;
            ptr = strstr(FBuf, "Data");
            if (ptr)
                ptr = strchr(ptr, '{');

            if (ptr)
                ptr = GetBlock(ptr);

            if (ptr)
            {
                while (ptr)
                    ptr = GetQuoted(ptr);

                FOnline = true;
            }

            RdosWaitMilli(15000);
        }        

        delete FSocket;
    }    
}
