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
# frinv.cpp
# Fronius inverter read-out
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <arpa/inet.h>
#include <netdb.h>
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
TFroniusInverter::TFroniusInverter(char *HostStr)
{
    int size = strlen(HostStr);

    FOnline = false;

    OnPower = 0;
    OnDayEnergy = 0;

    FHostStr = new char[size + 1];
    strcpy(FHostStr, HostStr);

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
    delete FHostStr;
}

/*##########################################################################
#
#   Name       : TFroniusInverter::IsOnline
#
#   Purpose....: Is online?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFroniusInverter::IsOnline()
{
    return FOnline;
}

/*##########################################################################
#
#   Name       : TFroniusInverter::GetCurrentPower
#
#   Purpose....: Get current power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TFroniusInverter::GetCurrentPower()
{
    return FCurrP;
}

/*##########################################################################
#
#   Name       : TFroniusInverter::GetDayEnergy
#
#   Purpose....: Get day energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TFroniusInverter::GetDayEnergy()
{
    return FDayE;
}

/*##########################################################################
#
#   Name       : TFroniusInverter::GetYearEnergy
#
#   Purpose....: Get year energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TFroniusInverter::GetYearEnergy()
{
    return FYearE;
}

/*##########################################################################
#
#   Name       : TFroniusInverter::GetTotalEnergy
#
#   Purpose....: Get total energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TFroniusInverter::GetTotalEnergy()
{
    return FTotalE;
}

/*##########################################################################
#
#   Name       : TFroniusInverter::DecodePower
#
#   Purpose....: Decode power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TFroniusInverter::GetPowerObj(TJsonCollection *data, int index, long double *fact)
{
    TJsonCollection *values;
    TJsonObject *obj;
    TString str;

    *fact = 0.0;

    obj = data->GetObj("Unit");
    if (obj)
    {
        str = obj->GetText();

        if (str == "W")
            *fact = 1.0;

        if (str == "kW")
            *fact = 1000.0;

        if (str == "MW")
            *fact = 1000000.0;
    }

    if (*fact)
    {
        values = data->GetCollection("Values");
        if (values)
        {
            str.printf("%d", index);
            obj = values->GetObj(str.GetData());
            if (obj)
                return obj;
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TFroniusInverter::GetEnergyObj
#
#   Purpose....: Get energy object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TFroniusInverter::GetEnergyObj(TJsonCollection *data, int index, long double *fact)
{
    TJsonCollection *values;
    TJsonObject *obj;
    TString str;

    *fact = 0.0;

    obj = data->GetObj("Unit");
    if (obj)
    {
        str = obj->GetText();

        if (str == "Wh")
            *fact = 1.0;

        if (str == "kWh")
            *fact = 1000.0;

        if (str == "MWh")
            *fact = 1000000.0;
    }

    if (*fact)
    {
        values = data->GetCollection("Values");
        if (values)
        {
            str.printf("%d", index);
            obj = values->GetObj(str.GetData());
            if (obj)
                return obj;
        }
    }

    return 0;
}

/*##########################################################################
#
#   Name       : TFroniusInverter::HandleJson
#
#   Purpose....: Handle json data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFroniusInverter::HandleJson(const char *str)
{
    TJsonDocument json(str);
    TJsonCollection *root = json.GetRoot();
    TJsonCollection *body;
    TJsonCollection *data;
    TJsonCollection *col;
    TJsonObject *obj;
    long double fact;

    if (root)
    {
        body = root->GetCollection("Body");
        if (body)
        {
            data = body->GetCollection("Data");
            if (data)
            {
                col = data->GetCollection("PAC");
                if (col)
                {
                    obj = GetPowerObj(col, 1, &fact);
                    if (obj)
                    {
                        FCurrP = fact * obj->GetDouble();
                        if (OnPower)
                            (*OnPower)(this, FCurrP);
                    }
                }

                col = data->GetCollection("DAY_ENERGY");
                if (col)
                {
                    obj = GetEnergyObj(col, 1, &fact);
                    if (obj)
                    {
                        FDayE = fact * obj->GetDouble();
                        if (OnDayEnergy)
                            (*OnDayEnergy)(this, FDayE);
                    }
                }

                col = data->GetCollection("YEAR_ENERGY");
                if (col)
                {
                    obj = GetEnergyObj(col, 1, &fact);
                    if (obj)
                        FYearE = fact * obj->GetDouble();
                }

                col = data->GetCollection("TOTAL_ENERGY");
                if (col)
                {
                    obj = GetEnergyObj(col, 1, &fact);
                    if (obj)
                        FTotalE = fact * obj->GetDouble();
                }
                FOnline = true;
            }
        }
    }
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
    int size;
    char *ptr;
    char *tempptr;
    struct hostent *host;

    FOnline = false;
    FIP = 0;

    RdosWaitMilli(2000);

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
        FSocket = new TTcpSocket(FIP, 80, 5000, 0x2000);
        FSocket->WaitForConnection(5000);
        while (FSocket->IsOpen())
        {
            strcpy(FBuf, "GET /solar_api/v1/GetInverterRealtimeData.fcgi?Scope=System HTTP/1.1\r\n");
            strcat(FBuf, "Host: ");
            strcat(FBuf, FHostStr);
            strcat(FBuf, "\r\n");
            strcat(FBuf, "Accept: application/json\r\n");
            strcat(FBuf, "User-Agent: RDOS\r\n");
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

            ptr = FBuf;
            while (ptr[1] != 0xd)
            {
                tempptr = strchr(ptr + 1, 0xd);
                if (tempptr)
                    ptr = tempptr + 1;
                else
                    break;
            }

            while (*ptr && *ptr != '{')
                ptr++;

            if (*ptr == '{')
                HandleJson(ptr);

            RdosWaitMilli(15000);
        }

        FOnline = false;
        delete FSocket;
    }
}
