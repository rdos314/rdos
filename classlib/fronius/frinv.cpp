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
double TFroniusInverter::GetCurrentPower()
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
double TFroniusInverter::GetDayEnergy()
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
double TFroniusInverter::GetYearEnergy()
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
double TFroniusInverter::GetTotalEnergy()
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
TJsonObject *TFroniusInverter::GetPowerObj(TJsonCollection *data, int index, double *fact)
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
TJsonObject *TFroniusInverter::GetEnergyObj(TJsonCollection *data, int index, double *fact)
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
    double fact;

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
