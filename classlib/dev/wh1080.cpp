/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# wh1080.cpp
# WH1080 weather station device class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "wh1080.h"
#include "rdos.h"

#define     FALSE	0
#define     TRUE	!FALSE

// Control block offsets:
#define WH1080_SAMPLING_INTERVAL    16  // Position of sampling interval
#define WH1080_DATA_COUNT           27  // Position of data_count parameter
#define WH1080_CURRENT_POS          30  // Position of current_pos parameter


/*##########################################################################
#
#   Name       : TWh1080Device::TWh1080Device
#
#   Purpose....: Constructor for TWh1080Device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWh1080Device::TWh1080Device()
  : THidDevice(0x1941, 0x8021)
{
    FIndoorHumidityTime.AddHour(-1);
    FIndoorTemperatureTime.AddHour(-1);
    FOutdoorHumidityTime.AddHour(-1);
    FOutdoorTemperatureTime.AddHour(-1);
    FPressureTime.AddHour(-1);
    FWindAverageTime.AddHour(-1);
    FWindGustTime.AddHour(-1);
    FWindDirTime.AddHour(-1);
    FRainTime.AddHour(-1);

    if (FHidHandle)
        Start("WH1080", 0x4000);
}

/*##########################################################################
#
#   Name       : TWh1080Device::~TWh1080Device
#
#   Purpose....: Destructor for TWh1080Device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWh1080Device::~TWh1080Device()
{
}

/*##########################################################################
#
#   Name       : TWh1080Device::DeviceName
#
#   Purpose....: Return device-name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWh1080Device::DeviceName(char *Name, int MaxLen) const
{
    strncpy(Name, "WH1080", MaxLen);
}

/*##########################################################################
#
#   Name       : TWh1080Device::GetIndoorHumidity
#
#   Purpose....: Read indoor humidity
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TWh1080Device::GetIndoorHumidity()
{
    long double val;

    FSection.Enter();
    val = FIndoorHumidity;
    FSection.Leave();
    
    return val;
}

/*##########################################################################
#
#   Name       : TWh1080Device::GetIndoorTemperature
#
#   Purpose....: Read indoor temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TWh1080Device::GetIndoorTemperature()
{
    long double val;

    FSection.Enter();
    val = FIndoorTemperature;
    FSection.Leave();
    
    return val;
}

/*##########################################################################
#
#   Name       : TWh1080Device::GetOutdoorHumidity
#
#   Purpose....: Read outdoor humidity
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TWh1080Device::GetOutdoorHumidity()
{
    long double val;

    FSection.Enter();
    val = FOutdoorHumidity;
    FSection.Leave();
    
    return val;
}

/*##########################################################################
#
#   Name       : TWh1080Device::GetOutdoorTemperature
#
#   Purpose....: Read outdoor temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TWh1080Device::GetOutdoorTemperature()
{
    long double val;

    FSection.Enter();
    val = FOutdoorTemperature;
    FSection.Leave();
    
    return val;
}

/*##########################################################################
#
#   Name       : TWh1080Device::GetPressure
#
#   Purpose....: Read pressure
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TWh1080Device::GetPressure()
{
    long double val;

    FSection.Enter();
    val = FPressure;
    FSection.Leave();
    
    return val;
}

/*##########################################################################
#
#   Name       : TWh1080Device::GetWindAverage
#
#   Purpose....: Read wind average
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TWh1080Device::GetWindAverage()
{
    long double val;

    FSection.Enter();
    val = FWindAverage;
    FSection.Leave();
    
    return val;
}

/*##########################################################################
#
#   Name       : TWh1080Device::GetWindGust
#
#   Purpose....: Read wind gust
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TWh1080Device::GetWindGust()
{
    long double val;

    FSection.Enter();
    val = FWindGust;
    FSection.Leave();
    
    return val;
}

/*##########################################################################
#
#   Name       : TWh1080Device::GetWindDir
#
#   Purpose....: Read wind direction
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TWh1080Device::GetWindDir()
{
    long double val;

    FSection.Enter();
    val = FWindDir;
    FSection.Leave();
    
    return val;
}

/*##########################################################################
#
#   Name       : TWh1080Device::GetRain
#
#   Purpose....: Read rain accumulator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TWh1080Device::GetRain()
{
    long double val;

    FSection.Enter();
    val = FRain;
    FSection.Leave();
    
    return val;
}

/*##########################################################################
#
#   Name       : TWh1080Device::WaitForData
#
#   Purpose....: Wait for new data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWh1080Device::WaitForData()
{
    FSignal.WaitForever();
}

/*##########################################################################
#
#   Name       : TWh1080Device::IsIndoorHumidityValid
#
#   Purpose....: Check if indoor humidity is valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::IsIndoorHumidityValid()
{
    TDateTime time = FIndoorHumidityTime;

    time.AddMin(10);

    return !time.HasExpired();
}

/*##########################################################################
#
#   Name       : TWh1080Device::IsIndoorTemperatureValid
#
#   Purpose....: Check if indoor temperature is valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::IsIndoorTemperatureValid()
{
    TDateTime time = FIndoorTemperatureTime;

    time.AddMin(10);

    return !time.HasExpired();
}

/*##########################################################################
#
#   Name       : TWh1080Device::IsOutdoorHumidityValid
#
#   Purpose....: Check if outdoor humidity is valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::IsOutdoorHumidityValid()
{
    TDateTime time = FOutdoorHumidityTime;

    time.AddMin(10);

    return !time.HasExpired();
}

/*##########################################################################
#
#   Name       : TWh1080Device::IsOutdoorTemperatureValid
#
#   Purpose....: Check if outdoor temperature is valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::IsOutdoorTemperatureValid()
{
    TDateTime time = FOutdoorTemperatureTime;

    time.AddMin(10);

    return !time.HasExpired();
}

/*##########################################################################
#
#   Name       : TWh1080Device::IsPressureValid
#
#   Purpose....: Check if pressure is valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::IsPressureValid()
{
    TDateTime time = FPressureTime;

    time.AddMin(10);

    return !time.HasExpired();
}

/*##########################################################################
#
#   Name       : TWh1080Device::IsWindAverageValid
#
#   Purpose....: Check if wind average is valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::IsWindAverageValid()
{
    TDateTime time = FWindAverageTime;

    time.AddMin(10);

    return !time.HasExpired();
}

/*##########################################################################
#
#   Name       : TWh1080Device::IsWindGustValid
#
#   Purpose....: Check if wind gust is valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::IsWindGustValid()
{
    TDateTime time = FWindGustTime;

    time.AddMin(10);

    return !time.HasExpired();
}

/*##########################################################################
#
#   Name       : TWh1080Device::IsWindDirValid
#
#   Purpose....: Check if wind direction is valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::IsWindDirValid()
{
    TDateTime time = FWindDirTime;

    time.AddMin(10);

    return !time.HasExpired();
}

/*##########################################################################
#
#   Name       : TWh1080Device::IsRainValid
#
#   Purpose....: Check if rain is valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::IsRainValid()
{
    TDateTime time = FRainTime;

    time.AddMin(10);

    return !time.HasExpired();
}

/*##########################################################################
#
#   Name       : LogData
#
#   Purpose....: Log data block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void LogData(char *Buffer)
{
    int i;
    char str[80];

    for (i = 0; i < 32; i++)
    {
        sprintf(str, "%04hX", Buffer[i]);
        printf(&str[2]);
        if (i % 8 == 7)
            printf("\r\n");
        else
            printf(" ");
    }
}    

/*##########################################################################
#
#   Name       : TWh1080Device::ReadBlock
#
#   Purpose....: Read block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::ReadBlock(int Offset, char *Buffer)
{
    char req[8];

    req[0] = 0xA1;
    req[1] = (char)(Offset / 256);
    req[2] = (char)(Offset & 0xFF);
    req[3] = 0x20;
    req[4] = 0xA1;
    req[5] = (char)(Offset / 256);
    req[6] = (char)(Offset & 0xFF);
    req[7] = 0x20;

//    printf("Read block: %04hX\r\n", Offset);

    if (Write(req, 8))
        if (Read(Buffer, 32, 2500))
        {
//            LogData(Buffer);                
            return TRUE;
        }

//    printf("Failed\r\n");
    return FALSE;
}

/*##########################################################################
#
#   Name       : TWh1080Device::WriteBlock
#
#   Purpose....: Write block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::WriteBlock(int Offset, const char *Buffer)
{
    char req[8];

    req[0] = 0xA0;
    req[1] = (char)(Offset / 256);
    req[2] = (char)(Offset & 0xFF);
    req[3] = 0x20;
    req[4] = 0xA0;
    req[5] = (char)(Offset / 256);
    req[6] = (char)(Offset & 0xFF);
    req[7] = 0x20;

    if (Write(req, 8))
        if (Write(Buffer, 32))
            if (Read(req, 8, 2500))
                return TRUE;
        
    return FALSE;
}

/*##########################################################################
#
#   Name       : TWh1080Device::WriteDataRefresh
#
#   Purpose....: Write data refresh
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::WriteDataRefresh()
{
    char req[8];

    req[0] = 0xA2;
    req[1] = 0;
    req[2] = 0x1A;
    req[3] = 0x20;
    req[4] = 0xA2;
    req[5] = 0xAA;
    req[6] = 0;
    req[7] = 0x20;

    if (Write(req, 8))
        if (Read(req, 8, 2500))
            return TRUE;
        
    return FALSE;
}

/*##########################################################################
#
#   Name       : TWh1080Device::ReadFixedBlock
#
#   Purpose....: Read fixed block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::ReadFixedBlock(char *Buffer)
{
    unsigned char ch0, ch1;

    if (ReadBlock(0, Buffer))
    {
        ch0 = (unsigned char)Buffer[0];
        ch1 = (unsigned char)Buffer[1];
    
        if (ch0 == 0x55 && ch1 == 0xAA)
            return TRUE;

        if (ch0 == 0xFF && ch1 == 0xFF)
            return TRUE;

        if (ch0 == 0x55 && ch1 == 0x55)
            return TRUE;
    }

    return FALSE;
}

/*##########################################################################
#
#   Name       : TWh1080Device::WriteFixedBlock
#
#   Purpose....: Write fixed block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::WriteFixedBlock(char *Buffer)
{
    Buffer[0] = 0x55;
    Buffer[1] = 0xAA;

    if (WriteBlock(0, Buffer))
        if (WriteDataRefresh())
            return TRUE;

    return FALSE;
}

/*##########################################################################
#
#   Name       : TWh1080Device::Setup
#
#   Purpose....: Setup station
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWh1080Device::Setup()
{
    int ok;
    char Buffer[32];

    for (;;)
    {
        ok = ReadFixedBlock(Buffer);
        if (ok)
        {
            if (Buffer[WH1080_SAMPLING_INTERVAL] != 1)
            {
                Buffer[WH1080_SAMPLING_INTERVAL] = 1;
                WriteFixedBlock(Buffer);
            }
            break;
        }       
        RdosWaitMilli(1000);
    }
}

/*##########################################################################
#
#   Name       : TWh1080Device::DecodeData
#
#   Purpose....: Decode data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWh1080Device::DecodeData(char *Buffer)
{
    unsigned char uch;
    unsigned short int usval;
    unsigned char uhi;

    if ((Buffer[0] == 1) && ((Buffer[15] & 0x40) == 0))
    {
        FSection.Enter();
        
        uch = *(unsigned char*)(Buffer + 1);
        if (uch != 0xFF)
        {
            FIndoorHumidity = (long double)uch;
            FIndoorHumidityTime.SetCurrent();
        }

        usval = *(unsigned short int*)(Buffer + 2);
        if (usval != 0xFFFF)
        {
            if (usval & 0x8000)
                usval = -(usval & 0x7FFF);

            FIndoorTemperature = 0.1 * (long double)usval;
            FIndoorTemperatureTime.SetCurrent();
        }        

        uch = *(unsigned char*)(Buffer + 4);
        if (uch != 0xFF)
        {
            FOutdoorHumidity = (long double)uch;
            FOutdoorHumidityTime.SetCurrent();
        }

        usval = *(unsigned short int*)(Buffer + 5);
        if (usval != 0xFFFF)
        {
            if (usval & 0x8000)
                usval = -(usval & 0x7FFF);

            FOutdoorTemperature = 0.1 * (long double)usval;
            FOutdoorTemperatureTime.SetCurrent();
        }        

        usval = *(unsigned short int*)(Buffer + 7);
        if (usval != 0xFFFF)
        {
            FPressure = 0.1 * (long double)usval;
            FPressureTime.SetCurrent();
        }                

        uhi = *(unsigned char*)(Buffer + 11);

        uch = *(unsigned char*)(Buffer + 9);
        usval = (unsigned short int)uch + ((uhi & 0xF) << 8);
        if (usval != 0xFFF)
        {
            FWindAverage = 0.1 * (long double)usval;
            FWindAverageTime.SetCurrent();
        }        

        uch = *(unsigned char*)(Buffer + 10);
        usval = (unsigned short int)uch + ((uhi & 0xF0) << 4);
        if (usval != 0xFFF)
        {
            FWindGust = 0.1 * (long double)usval;
            FWindGustTime.SetCurrent();
        }        

        uch = *(unsigned char*)(Buffer + 12);
        if ((uch & 0x80) == 0)
        {
            FWindDir = 22.5 * (long double)uch;
            FWindDirTime.SetCurrent();
        }        

        usval = *(unsigned short int*)(Buffer + 13);
        if (usval != 0xFFFF)
        {
            FRain = 0.33 * (long double)usval;
            FRainTime.SetCurrent();
        }                

        FSection.Leave();

        FSignal.Signal();
    }
}

/*##########################################################################
#
#   Name       : TWh1080Device::ReadWhole
#
#   Purpose....: Read whole fixed block + current block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWh1080Device::ReadWhole()
{
    int ok;
    char Buffer[32];
    int Offset;
    int pos;

    ok = ReadBlock(0, Buffer);
    if (ok)
        pos = *(unsigned short int *)(Buffer + 30);

    for (Offset = 0x20; ok && Offset < 0x100; Offset += 0x20)
        ok = ReadBlock(Offset, Buffer);

    if (ok)
        ReadBlock(pos, Buffer);
}

/*##########################################################################
#
#   Name       : TWh1080Device::ReadCurr
#
#   Purpose....: Read current block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWh1080Device::ReadCurr()
{
    int ok;
    char Buffer[32];
    int Offset;
    int pos;

    ok = ReadBlock(0, Buffer);
    if (ok)
    {
        pos = *(unsigned short int *)(Buffer + 30);

// The Windows application always read the two last records, but this 
// is a questionable approach given that the first 100h bytes are
// part of the control block, so we will not expect the last position
// to be read correct. A better approach would be to read only the
// last record, but for now it is uncertain if this is a stable approach
// as the weather station seems to hangup when alternative approaches
// to read-out data are used.

        pos -= 0x20;
        if (pos < 0x100)
            pos += 0xFF00;

        ok = ReadBlock(pos, Buffer);
        if (ok)
        {
            if (pos != FReadPos && pos != 0xFFF0)
            {
                FReadPos = pos;
                DecodeData(Buffer + 0x10);            
            }
        }
    }
}
                
/*##########################################################################
#
#   Name       : TWh1080Device::Execute
#
#   Purpose....: Execute method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWh1080Device::Execute()
{
    FReadPos = 0;

    Setup();

    while (FInstalled)
    {
        ReadWhole();
        ReadCurr();
        RdosWaitMilli(15000);
    }
}
