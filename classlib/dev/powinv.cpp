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
TSmartPowInverter::TSmartPowInverter(char *IpStr, long IP)
{
    FOnline = false;
    strcpy(FIpStr, IpStr);
    FIP = IP;
    FCurrP = 0.0;
    FDayE = 0.0;

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
#   Name       : TSmartPowInverter::GetCurrentPower
#
#   Purpose....: Get current power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmartPowInverter::GetCurrentPower()
{
    return FCurrP;
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
            strcpy(FBuf, "GET /index.htm HTTP/1.1\r\n");
            strcat(FBuf, "Host: ");
            strcat(FBuf, FIpStr);
            strcat(FBuf, "\r\n");
            strcat(FBuf, "Connection: keep-alive\r\n");
            strcat(FBuf, "Accept: text/html, */*;q=0.01\r\n");
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
            RdosWaitMilli(15000);
        }        

        FOnline = false;
        delete FSocket;
    }    
}
