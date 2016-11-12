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
# tempnu.cpp
# Temperature.nu read-out
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include "rdos.h"
#include "tempnu.h"

/*##########################################################################
#
#   Name       : TTemperatureNu::TTemperatureNu
#
#   Purpose....: FroniusInverter constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTemperatureNu::TTemperatureNu(const char *station)
{
    int len;
    
    FOnline = false;

    len = strlen(station) + 1;
    FStation = new char[len];
    strcpy(FStation, station);
    
    FIp = 0;

    Start("Temperature.nu", 0x8000);
}

/*##########################################################################
#
#   Name       : TTemperatureNu::~TTemperatureNu
#
#   Purpose....: FroniusInverter destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTemperatureNu::~TTemperatureNu()
{
    if (FStation)
        delete FStation;
}

/*##########################################################################
#
#   Name       : TTemperatureNu::IsOnline
#
#   Purpose....: Is online?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TTemperatureNu::IsOnline()
{
    return FOnline;
}

/*##########################################################################
#
#   Name       : TTemperatureNu::GetTemperature
#
#   Purpose....: Get temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TTemperatureNu::GetTemperature()
{
    return FTemp;
}

/*##########################################################################
#
#   Name       : TTemperatureNu::Execute
#
#   Purpose....: Execute method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTemperatureNu::Execute()
{
    int size;
    int i;
    char *startptr;
    char *endptr;
    int whole;
    int fract;

    FOnline = false;
    FIp = 0;
    
    while (FIp == 0)
    {
        FIp = RdosNameToIp("api.temperatur.nu");
        if (FIp == 0)
            RdosWaitMilli(2000);
    }

    for (;;)
    {
        FSocket = new TTcpSocket(FIp, 80, 10000, 0x2000);
        FSocket->WaitForConnection(10000);
        if (FSocket->IsOpen())
        {
            strcpy(FBuf, "Get /tnu_1.12.php?p=");
            strcat(FBuf, FStation);
            strcat(FBuf, "&simple&cli=test_app HTTP/1.1\r\n");
            strcat(FBuf, "Host: api.temperatur.nu\r\n");
            strcat(FBuf, "User-Agent: RDOS\r\n");
            strcat(FBuf, "Accept: application/xml\r\n");
            strcat(FBuf, "\r\n");
            FSocket->Write(FBuf);
            FSocket->Push();

            size = 0;
            while (FSocket->WaitForData(10000) && size < 2047)
            { 
                FBuf[size] = FSocket->Read();
                size++;
            }

            FBuf[size] = 0;

            delete FSocket;

            startptr = strstr(FBuf, "<temp>");
            if (startptr)
            {
                startptr += 6;
                endptr = strstr(startptr, "</temp>");
                if (endptr)
                {
                    *endptr = 0;
                    endptr = strstr(startptr, ".");
                    if (endptr)
                    {
                        fract = 1;
                        while (*endptr != 0)
                        {
                            endptr[0] = endptr[1];
                            endptr++;
                            fract = fract * 10;
                        }
                        fract = fract / 10;
                        whole = atol(startptr);
                        FTemp = (long double)whole / (long double)fract; 
                        FOnline = true;
                    }
                }
            }
            else
                FOnline = false;

            for (i = 0; i < 60 * 30; i++)
                RdosWaitMilli(1000);
        }        
    }    
}
