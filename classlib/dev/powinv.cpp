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
# powinv.cpp
# Smart power electronics inverter read-out
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <arpa/inet.h>
#include <netdb.h>
#include "rdos.h"
#include "powinv.h"

/*##########################################################################
#
#   Name       : TSmartPowInverter::TSmartPowInverter
#
#   Purpose....: SmartPowInverter constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSmartPowInverter::TSmartPowInverter(char *HostStr)
{
    int size = strlen(HostStr);

    FOnline = false;

    FHostStr = new char[size + 1];
    strcpy(FHostStr, HostStr);

    FIP = 0;

    FCurrState[0] = 0;
    FCurrError[0] = 0;

    FCurrGrid = 0.0;
    FCurrDump = 0.0;
    FCurrRpm = 0.0;

    FDayE = 0.0;
    FTotalE = 0.0;

    OnState = 0;
    OnError = 0;
    OnGridPower = 0;
    OnDumpPower = 0;
    OnRpm = 0;
    OnDayEnergy = 0;

    Start("SmartPow inverter", 0x8000);
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::~TSmartPowInverter
#
#   Purpose....: SmartPowInverter destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSmartPowInverter::~TSmartPowInverter()
{
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::IsOnline
#
#   Purpose....: Is online?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TSmartPowInverter::IsOnline()
{
    return FOnline;
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::GetCurrentState
#
#   Purpose....: Get current state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSmartPowInverter::GetCurrentState(char *buf)
{
    strcpy(buf, FCurrState);
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::GetCurrentError
#
#   Purpose....: Get current error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSmartPowInverter::GetCurrentError(char *buf)
{
    strcpy(buf, FCurrError);
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::GetCurrentGrid
#
#   Purpose....: Get current grid power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmartPowInverter::GetCurrentGrid()
{
    return FCurrGrid;
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::GetCurrentDump
#
#   Purpose....: Get current dump power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmartPowInverter::GetCurrentDump()
{
    return FCurrDump;
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::GetCurrentRpm
#
#   Purpose....: Get current rpm
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmartPowInverter::GetCurrentRpm()
{
    return FCurrRpm;
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::GetDayEnergy
#
#   Purpose....: Get day energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmartPowInverter::GetDayEnergy()
{
    return FDayE;
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::GetTotalEnergy
#
#   Purpose....: Get total energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmartPowInverter::GetTotalEnergy()
{
    return FDayE;
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::FindTag
#
#   Purpose....: Find tag and return null-terminated
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TSmartPowInverter::FindTag(char *str, const char *tag)
{
    char stag[40];
    char *ptr;
    char *eptr;

    strcpy(stag, "<");
    strcat(stag, tag);

    ptr = strstr(str, stag);

    if (ptr)
    {
        strcpy(stag, "</");
        strcat(stag, tag);
        strcat(stag, ">");

        eptr = strstr(ptr, stag);

        if (eptr)
            *eptr = 0;
        else
            ptr = 0;
    }

    if (ptr)
        ptr = strchr(ptr, '>');

    if (ptr)
        ptr++;

    return ptr;
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::GetValue
#
#   Purpose....: Get value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TSmartPowInverter::GetValue(char *str)
{
    char *ptr;
    char *eptr;

    ptr = strstr(str, "value=");

    if (ptr)
        ptr = strchr(ptr, '"');

    if (ptr)
    {
        ptr++;
        eptr = strchr(ptr, '"');

        if (eptr)
            *eptr = 0;
        else
            ptr = 0;
    }

    return ptr;
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::ConvertFloat
#
#   Purpose....: Convert , to .
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSmartPowInverter::ConvertFloat(char *str)
{
    int i;
    int len = strlen(str);

    for (i = 0; i < len; i++)
        if (str[i] == ',')
            str[i] = '.';
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::NotifyData
#
#   Purpose....: Notify data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSmartPowInverter::NotifyData(char *tag, char *value, char *unit)
{
    int count;
    long double val;

    if (strstr(tag, "State"))
    {
        strcpy(FCurrState, value);
        if (OnState)
            (*OnState)(this, value);
    }

    if (strstr(tag, "Error"))
    {
        strcpy(FCurrError, value);
        if (OnError)
            (*OnError)(this, value);
    }

    if (strstr(tag, "Power Grid"))
    {
        count = sscanf(value, "%Lf", &val);
        if (count)
        {
            FCurrGrid = val;
            if (OnGridPower)
                (*OnGridPower)(this, val);
        }
    }

    if (strstr(tag, "Resistor"))
    {
        count = sscanf(value, "%Lf", &val);
        if (count)
        {
            FCurrDump = val;
            if (OnDumpPower)
                (*OnDumpPower)(this, val);
        }
    }

    if (strstr(tag, "Rotor"))
    {
        count = sscanf(value, "%Lf", &val);
        if (count)
        {
            FCurrRpm = val;
            if (OnRpm)
                (*OnRpm)(this, val);
        }
    }

    if (strstr(tag, "Day"))
    {
        count = sscanf(value, "%Lf", &val);
        if (count)
        {
            FDayE = val;
            if (OnDayEnergy)
                (*OnDayEnergy)(this, val);
        }
    }

    if (strstr(tag, "Energy total"))
    {
        count = sscanf(value, "%Lf", &val);
        if (count)
            FTotalE = val;
    }
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::HandleTr
#
#   Purpose....: Handle tr object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSmartPowInverter::HandleTr(char *str)
{
    char *ptr = str;
    char *pptr;
    char *vptr;
    int len;
    bool dec;

    ptr = FindTag(ptr, "td");

    while (ptr)
    {
        len = strlen(ptr) + 2;
        pptr = ptr;

        ptr = pptr + len;
        ptr = FindTag(ptr, "th");

        if (ptr == 0)
        {
            ptr = pptr + len;
            ptr = FindTag(ptr, "td");
            dec = true;
        }
        else
            dec = false;

        if (ptr)
        {
            len = strlen(ptr) + 2;
            vptr = GetValue(ptr);

            if (vptr)
            {
                if (dec)
                    ConvertFloat(vptr);

                ptr += len;
                ptr = FindTag(ptr, "td");

                if (ptr)
                {
                    NotifyData(pptr, vptr, ptr);

                    len = strlen(ptr) + 2;
                    ptr += len;
                    ptr = FindTag(ptr, "td");
                }
            }
            else
                ptr = 0;
        }
    }
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::HandleTable
#
#   Purpose....: Handle table object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSmartPowInverter::HandleTable(char *str)
{
    char *ptr = str;
    int len;

    ptr = FindTag(ptr, "tr");

    while (ptr)
    {
        len = strlen(ptr) + 2;

        HandleTr(ptr);

        ptr += len;
        ptr = FindTag(ptr, "tr");
    }
}

/*##########################################################################
#
#   Name       : TSmartPowInverter::Execute
#
#   Purpose....: Execute method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSmartPowInverter::Execute()
{
    int size;
    char *ptr;
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
        FSocket = new TTcpSocket(FIP, 80, 5000, 0x2000);
        FSocket->WaitForConnection(5000);
        while (FSocket->IsOpen())
        {
            strcpy(FBuf, "GET / HTTP/1.1\r\n");
            strcat(FBuf, "Host: ");
            strcat(FBuf, FHostStr);
            strcat(FBuf, "\r\n");
            strcat(FBuf, "Connection: keep-alive\r\n");
            strcat(FBuf, "Accept: text/html, */*;q=0.01\r\n");
            strcat(FBuf, "User-Agent: RDOS\r\n");
            strcat(FBuf, "Accept-Encoding: gzip\r\n");
            strcat(FBuf, "Accept-Language: en-US,en;q=0.6\r\n");
            strcat(FBuf, "\r\n");
            FSocket->Write(FBuf);
            FSocket->Push();

            size = 0;
            while (FSocket->WaitForData(1000) && size < 8191)
            { 
                FBuf[size] = FSocket->Read();
                size++;
            }

            FBuf[size] = 0;

            ptr = FindTag(FBuf, "table");
            if (ptr)
            {
                FOnline = true;
                HandleTable(ptr);
            }
            else
                FOnline = false;
 
            RdosWaitMilli(2500);
        }

        delete FSocket;
    }    
}
