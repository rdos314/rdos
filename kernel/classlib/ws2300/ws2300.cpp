/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2005, Leif Ekblad
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
# This code is a modified verision of:
# Control WS2300 weather station
#
#  Copyright 2003-2005, Kenneth Lavrsen
#  This program is published under the GNU General Public license
#
# ws2300.cpp
# WS2300 weather station class library
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#define DEBUG	1

#include "rdos.h"
#include "ws2300.h"
#include "file.h"

#define FALSE 0
#define TRUE !FALSE

#define CHAR_TIMEOUT    175

#define MAXWINDRETRIES      20
#define WRITENIB            0x42
#define WRITEACK            0x10

#define MAXRETRIES          50

/*##########################################################################
#
#   Name       : TWs2300::TWs2300
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWs2300::TWs2300(TSerialDevice *serial)
{
	 FSerial = serial;
	 FFreeSerial = FALSE;

	 Init();
}

/*##########################################################################
#
#   Name       : TWs2300::TWs2300
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWs2300::TWs2300(int Port)
{
	FSerial = new TSerialDevice(Port, 2400, 'N', 8, 1);

#ifdef DEBUG
	TFile *file = new TFile("z:\\raw.dat", 0);
	FSerial->StartDebug(file, 1, 2);
#endif

	FFreeSerial = TRUE;

	Init();
}

/*##########################################################################
#
#   Name       : TWs2300::~TWs2300
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWs2300::~TWs2300()
{
    if (FFreeSerial)
        delete FSerial;
}

/*##########################################################################
#
#   Name       : TWs2300::Init
#
#   Purpose....: Init WS2300
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWs2300::Init()
{
    FSerial->Open();
    FSerial->Enable();
	FSerial->ResetDtr();
    FSerial->SetRts();

    FIndoorTemp = 20.0;
    FOutdoorTemp = 20.0;
    FDewPoint = 20.0;
    FIndoorHumidity = 50.0;
    FOutdoorHumidity = 50.0;
    FWindChill = 20.0;
    FWindSpeed = 0.0;
    FWinDir = 0.0;
    FRain1h = 0.0;
    FRain24h = 0.0;
    FAirPressure = 1013.0;

    Start("WS2300", 0x2000);    
}

/*##########################################################################
#
#   Name       : TWs2300::DeviceName
#
#   Purpose....: Device name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWs2300::DeviceName(char *Name, int MaxLen) const
{
	strncpy(Name,"WS2300",MaxLen);
}

/*##########################################################################
#
#   Name       : TWs2300::GetIndoorTemp
#
#   Purpose....: Get indoor temperature
#
#   Returns....: Temperature
#
##########################################################################*/
long double TWs2300::GetIndoorTemp()
{
    return FIndoorTemp;
}

/*##########################################################################
#
#   Name       : TWs2300::GetOutdoorTemp
#
#   Purpose....: Get outdoor temperature
#
#   Returns....: Temperature
#
##########################################################################*/
long double TWs2300::GetOutdoorTemp()
{
    return FOutdoorTemp;
}

/*##########################################################################
#
#   Name       : TWs2300::GetDewPoint
#
#   Purpose....: Get dewpoint temperature
#
#   Returns....: Temperature
#
##########################################################################*/
long double TWs2300::GetDewPoint()
{
    return FDewPoint;
}

/*##########################################################################
#
#   Name       : TWs2300::GetIndoorHumidity
#
#   Purpose....: Get indoor humidity
#
#   Returns....: Humidity
#
##########################################################################*/
long double TWs2300::GetIndoorHumidity()
{
    return FIndoorHumidity;
}

/*##########################################################################
#
#   Name       : TWs2300::GetOutdoorHumidity
#
#   Purpose....: Get outdoor humidity
#
#   Returns....: Humidity
#
##########################################################################*/
long double TWs2300::GetOutdoorHumidity()
{
    return FOutdoorHumidity;
}

/*##########################################################################
#
#   Name       : TWs2300::GetWindSpeed
#
#   Purpose....: Get wind speed
#
#   Returns....: Wind speed
#
##########################################################################*/
long double TWs2300::GetWindSpeed()
{
    return FWindSpeed;
}

/*##########################################################################
#
#   Name       : TWs2300::GetWindDir
#
#   Purpose....: Get wind direction
#
#   Returns....: Wind direction
#
##########################################################################*/
long double TWs2300::GetWindDir()
{
    return FWindDir;
}

/*##########################################################################
#
#   Name       : TWs2300::GetWindChill
#
#   Purpose....: Get wind-chill temperature
#
#   Returns....: Temperature
#
##########################################################################*/
long double TWs2300::GetWindChill()
{
    return FWindChill;
}

/*##########################################################################
#
#   Name       : TWs2300::GetRain1h
#
#   Purpose....: Get last 1h rain
#
#   Returns....: Rain amount
#
##########################################################################*/
long double TWs2300::GetRain1h()
{
    return FRain1h;
}

/*##########################################################################
#
#   Name       : TWs2300::GetRain24h
#
#   Purpose....: Get last 24h rain
#
#   Returns....: Rain amount
#
##########################################################################*/
long double TWs2300::GetRain24h()
{
    return FRain24;
}

/*##########################################################################
#
#   Name       : TWs2300::GetAirPressure
#
#   Purpose....: Get air pressure
#
#   Returns....: Air pressure
#
##########################################################################*/
long double TWs2300::GetAirPressure()
{
    return FAirPressure;
}

/*##########################################################################
#
#   Name       : TWs2300::Reset06
#
#   Purpose....: Reset_06 WS2300 by sending command 06
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWs2300::Reset06()
{
	 unsigned char ch;
	int i;

	for (i = 0; i < 100; i++)
	{
		 FSerial->Clear();
		 FSerial->Write(0x6);

		  while (FSerial->WaitForChar(25 + 5 * i))
		  {
				ch = FSerial->Read();
				if (ch == 2)
				{
					 RdosWaitMilli(50);
					 FSerial->Clear();
					 return TRUE;
				}
		  }
	 }
	 return FALSE;
}

/*##########################################################################
#
#   Name       : TWs2300::AddressEncode
#
#   Purpose....: AddressEncode converts a 16 bit address to the form needed
#                by the WS-2300 when sending commands.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWs2300::AddressEncode(int address)
{
	int i;
	unsigned char nibble;

	for (i = 0; i < 4; i++)
	{
		nibble = (unsigned char)((address >> (4 * (3 - i))) & 0x0F);
		FCmdBuf[i] = (unsigned char) (0x82 + (nibble * 4));
	}
}

/*##########################################################################
#
#   Name       : TWs2300::CountEncode
#
#   Purpose....: CountEncode converts the number of bytes we want to read
#                to the form needed by the WS-2300 when sending commands.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWs2300::CountEncode(int count)
{
	int coded;

	coded = (unsigned char) (0xC2 + count * 4);
	if (coded > 0xfe)
		coded = 0xfe;

	 FCmdBuf[4] = (unsigned char)coded;
}

/*##########################################################################
#
#   Name       : TWs2300::Checksum
#
#   Purpose....: Checksum calculates the checksum for the data bytes received
#                from the WS2300
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned char TWs2300::Checksum(const char *buf, int count)
{
	int checksum = 0;
	int i;

	for (i = 0; i < count; i++)
	{
		checksum += buf[i];
	}

	checksum &= 0xFF;

	return (unsigned char)checksum;
}

/*##########################################################################
#
#   Name       : TWs2300::Read
#
#   Purpose....: Read data from the WS2300 based on a given address,
#                and number of data read
#
#   In params..: address (interger - 16 bit)
#                count - number of bytes to read, max value 15
#   Out params.: buf - pointer to an array of chars containing
#                the just read data, not zero terminated
#   Returns....: TRUE if success
#
##########################################################################*/
int TWs2300::Read(int address, int count, char *buf)
{
	int i;
	unsigned char ch;
	unsigned char response;

	 AddressEncode(address);
	 CountEncode(count);

	for (i = 0; i < 4; i++)
	{
		 FSerial->Write(FCmdBuf[i]);

		 if (FSerial->WaitForChar(CHAR_TIMEOUT))
		 {
			  ch = (unsigned char)FSerial->Read();
			response = (unsigned char)(i * 16 + (FCmdBuf[i] - 0x82) / 4);
			  if (ch != response)
					return FALSE;
		 }
		 else
			  return FALSE;
	}

	FSerial->Write(FCmdBuf[4]);

	 if (FSerial->WaitForChar(CHAR_TIMEOUT))
	 {
		  ch = (unsigned char)FSerial->Read();
		response = (unsigned char)(0x30 + count);
		  if (ch != response)
				return FALSE;
	 }
	 else
		  return 0;

	 for (i = 0; i < count; i++)
	 {
		  if (FSerial->WaitForChar(CHAR_TIMEOUT))
				buf[i] = FSerial->Read();
		  else
				return FALSE;
	 }

	 if (FSerial->WaitForChar(CHAR_TIMEOUT))
		  ch = (unsigned char)FSerial->Read();
	 else
		  return FALSE;

	 if (ch != Checksum(buf, count))
		  return FALSE;

	 return TRUE;
}

/*##########################################################################
#
#   Name       : TWs2300::Write
#
#   Purpose....: Write data to the WS2300.
#
#   In params..: address (interger - 16 bit)
#                count - number of bytes to read, max value 15
#   Out params.: buf - pointer to an array of chars containing
#                the write data, not zero terminated
#   Returns....: TRUE if success
#
##########################################################################*/
int TWs2300::Write(int address, int count, const char *buf)
{
	unsigned char ch;
	int i;
	unsigned char response;

	 AddressEncode(address);

	for (i = 0; i < 4; i++)
	{
		 FSerial->Write((char)FCmdBuf[i]);

		 if (FSerial->WaitForChar(CHAR_TIMEOUT))
		 {
			  ch = (unsigned char)FSerial->Read();
			response = (unsigned char)(i * 16 + (FCmdBuf[i] - 0x82) / 4);
			  if (ch != response)
					return FALSE;
		 }
		 else
			  return FALSE;
	}

	for (i = 0; i < count; i++)
	{
		FSerial->Write(WRITENIB + (buf[i] * 4));

		 if (FSerial->WaitForChar(CHAR_TIMEOUT))
		 {
			  ch = (unsigned char)FSerial->Read();
			  response = (unsigned char)(buf[i] + WRITEACK);
			  if (ch != response)
					return FALSE;
		 }
		 else
			  return FALSE;
	}

	return TRUE;
}

/*##########################################################################
#
#   Name       : TWs2300::SafeRead
#
#   Purpose....: Read data, retry until success or maxretries
#
#   In params..: address (interger - 16 bit)
#                count - number of bytes to read, max value 15
#   Out params.: buf - pointer to an array of chars containing
#                the just read data, not zero terminated
#   Returns....: TRUE if success
#
##########################################################################*/
int TWs2300::SafeRead(int address, int count, unsigned char *buf)
{
	int j;

	for (j = 0; j < MAXRETRIES; j++)
	{
		if (Reset06())
			if (Read(address, count, (char *)buf))
				return TRUE;

		RdosWaitMilli(500);
	}
	return FALSE;
}

/*##########################################################################
#
#   Name       : TWs2300::SafeWrite
#
#   Purpose....: Write data, retry until success or maxretries
#
#   In params..: address (interger - 16 bit)
#                count - number of bytes to read, max value 15
#   Out params.: buf - pointer to an array of chars containing
#                the write data, not zero terminated
#   Returns....: TRUE if success
#
##########################################################################*/
int TWs2300::SafeWrite(int address, int count, const unsigned char *buf)
{
	int j;

	for (j = 0; j < MAXRETRIES; j++)
	{
		if (Reset06())
			if (Write(address, count, (const char *)buf))
				return TRUE;

		RdosWaitMilli(500);
	}
	return FALSE;
}

/*##########################################################################
#
#   Name       : TWs2300::UpdateIndoorTemp
#
#   Purpose....: Update indoor temperature
#
#   Returns....: success
#
##########################################################################*/
int TWs2300::UpdateIndoorTemp()
{
	unsigned char data[20];

	if (SafeRead(0x346, 2, data))
	{
		FIndoorTemp = ((((data[1] >> 4) * 10 + (data[1] & 0xF) +
					 (data[0] >> 4) / 10.0 + (data[0] & 0xF) / 100.0) - 30.0));
	    return TRUE;
	}
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TWs2300::UpdateOutdoorTemp
#
#   Purpose....: Update outdoor temperature
#
#   Returns....: Success
#
##########################################################################*/
int TWs2300::UpdateOutdoorTemp()
{
	unsigned char data[20];

	if (SafeRead(0x373, 2, data))
	{
		FOutdoorTemp = ((((data[1] >> 4) * 10 + (data[1] & 0xF) +
					 (data[0] >> 4) / 10.0 + (data[0] & 0xF) / 100.0) - 30.0));
		return TRUE;
    }
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TWs2300::UpdateDewpoint
#
#   Purpose....: Update dewpoint temperature
#
#   Returns....: Success
#
##########################################################################*/
int TWs2300::UpdateDewpoint()
{
	unsigned char data[20];

	if (SafeRead(0x3CE, 2, data))
	{
		FDewPoint = ((((data[1] >> 4) * 10 + (data[1] & 0xF) +
					 (data[0] >> 4) / 10.0 + (data[0] & 0xF) / 100.0) - 30.0));
		return TRUE;
	}
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TWs2300::UpdateIndoorHumidity
#
#   Purpose....: Update indoor humidity
#
#   Returns....: Success
#
##########################################################################*/
int TWs2300::UpdateIndoorHumidity()
{
	unsigned char data[20];

	if (SafeRead(0x3FB, 1, data))
	{
		FIndoorHumidity = ((data[0] >> 4) * 10 + (data[0] & 0xF));
		return TRUE;
	}
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TWs2300::UpdateOutdoorHumidity
#
#   Purpose....: Update outdoor humidity
#
#   Returns....: Success
#
##########################################################################*/
int TWs2300::UpdateOutdoorHumidity()
{
	unsigned char data[20];

	if (SafeRead(0x419, 1, data))
	{
		FOutdoorHumidity = ((data[0] >> 4) * 10 + (data[0] & 0xF));
		return TRUE;
    }
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TWs2300::UpdateWind
#
#   Purpose....: Update wind speed & direction
#
#   Returns....: Success
#
##########################################################################*/
int TWs2300::UpdateWind()
{
	unsigned char data[20];
	int i;
	int ok;

	for ( i = 0; i < MAXWINDRETRIES; i++)
	{
		ok = SafeRead(0x527, 3, data);

		if (ok)
		{
			if ((data[0] != 0) || ((data[1] == -1) && (((data[2] & 0xF) == 0)  || ((data[2] & 0xF) == 1))))
			{
			    ok = FALSE;
				RdosWaitMilli(10000);
			}
			else
				break;
		}
	}

    if (ok)
    {
        FWindDir = (data[2]>>4)*22.5;
	    FWindSpeed = (((data[2]&0xF)<<8)+(data[1])) / 10.0;
	}
	
	return ok;
}

/*##########################################################################
#
#   Name       : TWs2300::UpdateWindChill
#
#   Purpose....: Update wind-chill temperature
#
#   Returns....: Success
#
##########################################################################*/
int TWs2300::UpdateWindChill()
{
	unsigned char data[20];

	if (SafeRead(0x3A0, 2, data))
	{
		FWindChill = ((((data[1] >> 4) * 10 + (data[1] & 0xF) +
					 (data[0] >> 4) / 10.0 + (data[0] & 0xF) / 100.0) - 30.0));
		return TRUE;
	}
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TWs2300::UpdateRain1h
#
#   Purpose....: Update 1h rain
#
#   Returns....: Sucess
#
##########################################################################*/
int TWs2300::UpdateRain1h()
{
	unsigned char data[20];

	if (SafeRead(0x4B4, 3, data))
	{
		FRain1h = ( ((data[2] >> 4) * 1000 + (data[2] & 0xF) * 100 +
				 (data[1] >> 4) * 10 + (data[1] & 0xF) + (data[0] >> 4) / 10.0 +
				 (data[0] & 0xF) / 100.0 ));
		return TRUE;
	}
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TWs2300::UpdateRain24h
#
#   Purpose....: Update 24h rain
#
#   Returns....: Success
#
##########################################################################*/
int TWs2300::UpdateRain24h()
{
	unsigned char data[20];

	if (SafeRead(0x497, 3, data))
	{
		FRain24 = ( ((data[2] >> 4) * 1000 + (data[2] & 0xF) * 100 +
				 (data[1] >> 4) * 10 + (data[1] & 0xF) + (data[0] >> 4) / 10.0 +
				 (data[0] & 0xF) / 100.0 ));
		return TRUE;
    }
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TWs2300::UpdateAirPressure
#
#   Purpose....: Update air pressure
#
#   Returns....: Success
#
##########################################################################*/
int TWs2300::UpdateAirPressure()
{
	unsigned char data[20];

	if (SafeRead(0x5D8, 3, data))
	{
		FAirPressure = (((data[2] & 0xF) * 1000 + (data[1] >> 4) * 100 +
					 (data[1] & 0xF) * 10 + (data[0] >> 4) +
					 (data[0] & 0xF) / 10.0));
		return TRUE;
	}
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TWs2300::Execute
#
#   Purpose....: Execute messurements
#
##########################################################################*/
void TWs2300::Execute()
{
    int HasIndoorTemp = FALSE;
    int HasOutdoorTemp = FALSE;
    int HasDewPoint = FALSE;
    int HasIndoorHumidity = FALSE;
    int HasOutdoorHumidity = FALSE;
    int HasWindChill = FALSE;
    int HasRain1h = FALSE;
    int HasRain24h = FALSE;
    int HasWind = FALSE;
    int HasPressure = FALSE;
    int ok;
    TDateTime datetime;
    int lastsec = datetime.GetSec();
    int sec;

    while (FInstalled)
    {
        if (!HasIndoorTemp)
            HasIndoorTemp = GetIndoorTemp();

        if (!HasOutdoorTemp)
            HasOutdoorTemp = GetOutdoorTemp();

        if (!HasDewPoint)
            HasDewPoint = GetDewPoint();

        if (!HasIndoorHumidity)
            HasIndoorHumidity = GetIndoorHumidity();

        if (!HasOutdoorHumidity)
            HasOutdoorHumidity = GetOutdoorHumidity();

        if (!HasWind)
            HasWind = GetWind();

        if (!HasWindChill)
            HasWindChill = GetWindChill();

        if (!HasRain1h)
            HasRain1h = GetRain1h();

        if (!HasRain24h)
            HasRain24h = GetRain24h();

        if (!HasPressure)
            HasPressure = GetPressure();

        datetime = TDateTime::TDateTime();
        sec = datetime.GetSec();

        if (sec < lastsec)
            lastsec -= 60;

        if (sec - lastsec >= 60)
        {
            HasIndoorTemp = FALSE;
            HasOutdoorTemp = FALSE;
            HasDewPoint = FALSE;
            HasIndoorHumidity = FALSE;
            HasOutdoorHumidity = FALSE;
            HasWindChill = FALSE;
            HasWind = FALSE;
            HasRain1h = FALSE;
            HasRain24h = FALSE;
            HasPressure = FALSE;
    
            lastsec = sec;
        }

        ok =    HasIndoorTemp &&
                HasOutdoorTemp &&
                HasDewPoint &&
                HasIndoorHumidity &&
                HasOutdoorHumidity &&
                HasWind &&
                HasWindChill &&
                HasRain1h &&
                HasRain24h &&
                HasPressure;

        if (ok)
        {
            WaitMilli(15000);
            HasWind = FALSE;
        }
    }
}
