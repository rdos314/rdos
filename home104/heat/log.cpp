/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2006, Leif Ekblad
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
# log.h
# Log class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "log.h"
#include "section.h"

#define STACK_SIZE  0x2000

#define LOG_SIGN    0xABEF1456

/*##########################################################################
#
#   Name       : TLog::TLog
#
#   Purpose....: Log constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLog::TLog(const char *RootDir)
{
    int i;
    
    strcpy(FRootDir, RootDir);
    strlwr(FRootDir);

    CreateRootDir();

    for (i = 0; i < 256; i++)
        FRadArr[i] = 0; 

    FWs = 0;
    FCirc = 0;

    Start("LOGGER", STACK_SIZE);
}

/*##########################################################################
#
#   Name       : TLog::TLog
#
#   Purpose....: Log destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLog::~TLog()
{
}

/*##########################################################################
#
#   Name       : TLog::DeviceName
#
#   Purpose....: Device name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLog::DeviceName(char *Name, int Size) const
{
	strcpy(Name, "LOGGER");
}

/*##########################################################################
#
#   Name       : TLog::CreateRootDir
#
#   Purpose....: Create root directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLog::CreateRootDir()
{
    if (!RdosSetCurDir(FRootDir))
        RdosMakeDir(FRootDir);
}

/*##########################################################################
#
#   Name       : TLog::CreateDayFile
#
#   Purpose....: Create/open a day-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLog::CreateDayFile()
{
    char str[20];
    char filename[256];
    TFile *file;
    int i, j;
	int filesize;

	if (FFile)
	    delete FFile;

	sprintf(str, "%d", FYear);
	strcpy(filename, FRootDir);
	strcat(filename, "\\");
	strcat(filename, str);

	if (!RdosSetCurDir(filename))
		RdosMakeDir(filename);

	sprintf(str, "%d\\%d", FYear, FMonth);
	strcpy(filename, FRootDir);
	strcat(filename, "\\");
	strcat(filename, str);

	if (!RdosSetCurDir(filename))
		RdosMakeDir(filename);

	sprintf(str, "%d\\%d\\%d.cot", FYear, FMonth, FDay);
	strcpy(filename, FRootDir);
	strcat(filename, "\\");
	strcat(filename, str);

	FFile = new TFile(filename);
	if (!FFile->IsOpen())
	{
		delete FFile;
		FFile = new TFile(filename, 0);
	}

	if (FFile->IsOpen())
	    FFile->SetPos(FFile->GetSize());
}

/*##########################################################################
#
#   Name       : TLog::Add
#
#   Purpose....: Add radiator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLog::Add(TRad *Rad)
{
    int i;

    i = Rad->GetAddress();
    FRadArr[i] = Rad;
}

/*##########################################################################
#
#   Name       : TLog::Add
#
#   Purpose....: Add weather station
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLog::Add(TWs2300 *ws)
{
    FWs = ws;
}

/*##########################################################################
#
#   Name       : TLog::Add
#
#   Purpose....: Add circulation
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLog::Add(TCirc *circ)
{
    FCirc = circ;
}

/*##########################################################################
#
#   Name       : TLog::Add
#
#   Purpose....: Add VP
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLog::Add(TVp *vp)
{
    FVp = vp;
}

/*##########################################################################
#
#   Name       : TLog::Execute
#
#   Purpose....: Execute thread loop
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLog::Execute()
{
    int year, month, day;
    int hour, min, sec;
    int ms;
    TDeviceMsg *doc;
    TDeviceTag *tag;
    int i;
    TRad *rad;
    int ival;
    unsigned long msb;
    unsigned long lsb;
    int size;
	char *msg;

    RdosGetTime(&FYear, &FMonth, &FDay, &FHour, &FMin, &sec, &ms);
    CreateDayFile();
    
    while (FInstalled)
    {
        RdosGetTime(&year, &month, &day, &hour, &min, &sec, &ms);

        if (year != FYear || month != FMonth || day != FDay)
        {
            FYear = year;
            FMonth = month;
            FDay = day;
            CreateDayFile();
        }

        if (hour != FHour || min != FMin)
        {
            FHour = hour;
            FMin = min;

            RdosRecordToTics(&msb, &lsb, FYear, FMonth, FDay, FHour, FMin, 0, 0);

            doc = new TDeviceMsg(0x10000);

			tag = doc->AddTag(LOG_TAG_HEADER);
			tag->AddUnsignedLong(LOG_VAR_MsbTime, msb);
			tag->AddUnsignedLong(LOG_VAR_LsbTime, lsb);

            if (FWs)
            {
                tag = doc->AddTag(LOG_TAG_INDOOR);
                ival = 10.0 * FWs->GetIndoorTemp();
                tag->AddFloat1(LOG_VAR_Temp, ival);

                ival = FWs->GetIndoorHumidity();
                tag->AddSignedInt(LOG_VAR_Humidity, ival);

                tag = doc->AddTag(LOG_TAG_OUTDOOR);
                ival = 10.0 * FWs->GetOutdoorTemp();
                tag->AddFloat1(LOG_VAR_Temp, ival);

                ival = FWs->GetOutdoorHumidity();
                tag->AddSignedInt(LOG_VAR_Humidity, ival);

                ival = 10.0 * FWs->GetDewPoint();
                tag->AddFloat1(LOG_VAR_Dewpoint, ival);

                ival = 10.0 * FWs->GetWindChill();
                tag->AddFloat1(LOG_VAR_Windchill, ival);

                ival = 10.0 * FWs->GetWindSpeed();
                tag->AddFloat1(LOG_VAR_Windspeed, ival);

                ival = FWs->GetWindDir();
                tag->AddSignedInt(LOG_VAR_Winddir, ival);

                ival = 10.0 * FWs->GetAirPressure();
                tag->AddFloat1(LOG_VAR_Pressure, ival);

                if (FHour == 0)
                {
                    tag = doc->AddTag(LOG_TAG_RAIN);

                    ival = 10.0 * FWs->GetRain1h();
                    tag->AddFloat1(LOG_VAR_Rain, ival);
                }
            }

            if (FCirc)
            {
                tag = doc->AddTag(LOG_TAG_CIRC);
                ival = 10.0 * FCirc->GetSpeed();
                tag->AddFloat1(LOG_VAR_Motor, ival);
            }

            if (FVp)
            {
                tag = doc->AddTag(LOG_TAG_VP);
                ival = FVp->IsOn();
                tag->AddBoolean(LOG_VAR_On, ival);
            }

            for (i = 0; i < 256; i++)
            {
                if (FRadArr[i])
                {
                    rad = FRadArr[i];

					if (rad->IsOnline())
					{
						tag = doc->AddTag(LOG_TAG_RAD);
						tag->AddSignedInt(LOG_VAR_Address, rad->GetAddress());

						tag->AddFloat1(LOG_VAR_Ref, rad->GetRef());
						tag->AddFloat1(LOG_VAR_Temp, rad->GetTemp());
						tag->AddFloat1(LOG_VAR_Motor, rad->GetMotor());
						tag->AddFloat1(LOG_VAR_Light, rad->GetLight());
						tag->AddFloat1(LOG_VAR_AuxTemp, rad->GetAuxTemp());
					}
				}
			}

            size = doc->GetSize();
            msg = new char[size];
            doc->GetData(LOG_SIGN, msg);
            FFile->Write(msg, size);
            delete msg;
        }

        RdosWaitMilli(1000);
    }
}

