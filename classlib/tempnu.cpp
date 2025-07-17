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
