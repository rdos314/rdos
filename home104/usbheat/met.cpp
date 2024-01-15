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
# vp.h
# Heat pump class
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "met.h"

#define FALSE 0
#define TRUE !FALSE

TSection FDataSection("Met.Data.Section");

static int WindDirCount = 0;
static long double WindDirSum = 0.0;

static int WindSpeedCount = 0;
static long double WindSpeedSum = 0.0;

static int WindGustCount = 0;
static long double WindGustSum = 0.0;

static int OutTempCount = 0;
static long double OutTempSum = 0.0;

static int HumidityCount = 0;
static long double HumiditySum = 0.0;

static int LightCount = 0;
static long double LightSum = 0.0;

static int UvCount = 0;
static long double UvSum = 0.0;

static bool HasRain = false;
static long double Rain = 0.0;

static bool HasMinTemp = false;
static long double MinTemp = 0.0;

static bool HasMaxTemp = false;
static long double MaxTemp = 0.0;

#define ROOT_DIR "e:/data/met"
#define CSV_DAY_HEADER "time;temp;wind;gust;dir;humid;light;uv\r\n"
#define CSV_MONTH_HEADER "time;rain;min;max\r\n"

/*##########################################################################
#
#   Name       : NotifyWindDir
#
#   Purpose....: Notify wind direction
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyWindDir(TMisolWeather *Device, long double val)
{
    FDataSection.Enter();

    WindDirSum += val;
    WindDirCount++;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyWindSpeed
#
#   Purpose....: Notify wind speed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyWindSpeed(TMisolWeather *Device, long double val)
{
    FDataSection.Enter();

    WindSpeedSum += val;
    WindSpeedCount++;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyWindGust
#
#   Purpose....: Notify wind gust
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyWindGust(TMisolWeather *Device, long double val)
{
    FDataSection.Enter();

    WindGustSum += val;
    WindGustCount++;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyTemperature
#
#   Purpose....: Notify temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyTemperature(TMisolWeather *Device, long double val)
{
    FDataSection.Enter();

    OutTempSum += val;
    OutTempCount++;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyHumidity
#
#   Purpose....: Notify humidity
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyHumidity(TMisolWeather *Device, long double val)
{
    FDataSection.Enter();

    HumiditySum += val;
    HumidityCount++;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyLight
#
#   Purpose....: Notify light
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyLight(TMisolWeather *Device, long double val)
{
    FDataSection.Enter();

    LightSum += val;
    LightCount++;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyUv
#
#   Purpose....: Notify UV
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyUv(TMisolWeather *Device, long double val)
{
    FDataSection.Enter();

    UvSum += val;
    UvCount++;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyRain
#
#   Purpose....: Notify rain
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyRain(TMisolWeather *Device, long double val)
{
    FDataSection.Enter();

    Rain = val;
    HasRain = true;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyMinTemp
#
#   Purpose....: Notify min temp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyMinTemp(TMisolWeather *Device, long double val)
{
    FDataSection.Enter();

    MinTemp = val;
    HasMinTemp = true;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyMaxTemp
#
#   Purpose....: Notify max temp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyMaxTemp(TMisolWeather *Device, long double val)
{
    FDataSection.Enter();

    MaxTemp = val;
    HasMaxTemp = true;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : TMet::TMet
#
#   Purpose....: Met constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMet::TMet(TMisolWeather *misol)
{
    misol->OnWindDir = NotifyWindDir;
    misol->OnWindSpeed = NotifyWindSpeed;
    misol->OnWindGust = NotifyWindGust;
    misol->OnTemperature = NotifyTemperature;
    misol->OnHumidity = NotifyHumidity;
    misol->OnLight = NotifyLight;
    misol->OnUv = NotifyUv;
    misol->OnRain = NotifyRain;
    misol->OnMinTemp = NotifyMinTemp;
    misol->OnMaxTemp = NotifyMaxTemp;

    Start("Met", 0x2000);
}

/*##########################################################################
#
#   Name       : TMet::~TMet
#
#   Purpose....: Met destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMet::~TMet()
{
}

/*##########################################################################
#
#   Name       : TMet::CreateDayFile
#
#   Purpose....: Create/open a day-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMet::CreateDayFile(int year, int month, int day)
{
    char str[20];
    char filename[256];
    int i, j;
    int filesize;

    if (!RdosSetCurDir(ROOT_DIR))
        RdosMakeDir(ROOT_DIR);

    sprintf(str, "%d", year);
    strcpy(filename, ROOT_DIR);
    strcat(filename, "/");
    strcat(filename, str);

    if (!RdosSetCurDir(filename))
        RdosMakeDir(filename);

    sprintf(str, "%d/%d", year, month);
    strcpy(filename, ROOT_DIR);
    strcat(filename, "/");
    strcat(filename, str);

    if (!RdosSetCurDir(filename))
        RdosMakeDir(filename);

    sprintf(str, "%d/%d/%d.csv", year, month, day);
    strcpy(filename, ROOT_DIR);
    strcat(filename, "/");
    strcat(filename, str);

    if (FDayFile)
        delete FDayFile;

    FDayFile = new TFile(filename);

    if (!FDayFile->IsOpen())
    {
        delete FDayFile;
        FDayFile = new TFile(filename, 0);
        FDayFile->Write(CSV_DAY_HEADER, strlen(CSV_DAY_HEADER));
    }

    if (FDayFile->IsOpen())
        FDayFile->SetPos(FDayFile->GetSize());
}

/*##########################################################################
#
#   Name       : TMet::CreateMonthFile
#
#   Purpose....: Create/open a month-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TMet::CreateMonthFile(int year, int month)
{
    char str[20];
    char filename[256];
    int i, j;
    int filesize;
    TFile *File;

    if (!RdosSetCurDir(ROOT_DIR))
        RdosMakeDir(ROOT_DIR);

    sprintf(str, "%d", year);
    strcpy(filename, ROOT_DIR);
    strcat(filename, "/");
    strcat(filename, str);

    if (!RdosSetCurDir(filename))
        RdosMakeDir(filename);

    sprintf(str, "%d/%d", year, month);
    strcpy(filename, ROOT_DIR);
    strcat(filename, "/");
    strcat(filename, str);

    if (!RdosSetCurDir(filename))
        RdosMakeDir(filename);

    sprintf(str, "%d/%d/total.csv", year, month);
    strcpy(filename, ROOT_DIR);
    strcat(filename, "/");
    strcat(filename, str);

    File = new TFile(filename);

    if (!File->IsOpen())
    {
        delete File;
        File = new TFile(filename, 0);
        File->Write(CSV_MONTH_HEADER, strlen(CSV_MONTH_HEADER));
    }

    if (File->IsOpen())
        File->SetPos(File->GetSize());

    return File;
}

/*##########################################################################
#
#   Name       : TMet::GetTemp
#
#   Purpose....: Get temperature as string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMet::GetTemp(char *str)
{
    long double val;

    if (OutTempCount)
    {
        val = OutTempSum / (long double)OutTempCount;
        sprintf(str, "%3.1Lf", val);
    }
    else
        str[0] = 0;

    OutTempSum = 0.0;
    OutTempCount = 0;
}

/*##########################################################################
#
#   Name       : TMet::GetWindSpeed
#
#   Purpose....: Get wind speed as string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMet::GetWindSpeed(char *str)
{
    long double val;

    if (WindSpeedCount)
    {
        val = WindSpeedSum / (long double)WindSpeedCount;
        sprintf(str, "%3.1Lf", val);
    }
    else
        str[0] = 0;

    WindSpeedSum = 0.0;
    WindSpeedCount = 0;
}

/*##########################################################################
#
#   Name       : TMet::GetWindGust
#
#   Purpose....: Get wind gust as string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMet::GetWindGust(char *str)
{
    long double val;

    if (WindGustCount)
    {
        val = WindGustSum / (long double)WindGustCount;
        sprintf(str, "%3.1Lf", val);
    }
    else
        str[0] = 0;

    WindGustSum = 0.0;
    WindGustCount = 0;
}

/*##########################################################################
#
#   Name       : TMet::GetWindDir
#
#   Purpose....: Get wind dir as string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMet::GetWindDir(char *str)
{
    int val;

    if (WindDirCount)
    {
        val = (int)WindDirSum / WindDirCount;
        sprintf(str, "%d", val);
    }
    else
        str[0] = 0;

    WindDirSum = 0.0;
    WindDirCount = 0;
}

/*##########################################################################
#
#   Name       : TMet::GetHumidity
#
#   Purpose....: Get humidty as string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMet::GetHumidity(char *str)
{
    int val;

    if (HumidityCount)
    {
        val = (int)HumiditySum / HumidityCount;
        sprintf(str, "%d", val);
    }
    else
        str[0] = 0;

    HumiditySum = 0.0;
    HumidityCount = 0;
}

/*##########################################################################
#
#   Name       : TMet::GetLight
#
#   Purpose....: Get light as string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMet::GetLight(char *str)
{
    long double val;

    if (LightCount)
    {
        val = LightSum / (long double)LightCount;
        sprintf(str, "%3.1Lf", val);
    }
    else
        str[0] = 0;

    LightSum = 0.0;
    LightCount = 0;
}

/*##########################################################################
#
#   Name       : TMet::GetUv
#
#   Purpose....: Get UV as string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMet::GetUv(char *str)
{
    long double val;

    if (UvCount)
    {
        val = UvSum / (long double)UvCount;
        sprintf(str, "%3.1Lf", val);
    }
    else
        str[0] = 0;

    UvSum = 0.0;
    UvCount = 0;
}

/*##########################################################################
#
#   Name       : TMet::UpdateDataStore
#
#   Purpose....: Update data store
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMet::UpdateDataStore(int hour, int min)
{
    char str[80];

    sprintf(str, "%02d:%02d;", hour, min);
    FDayFile->Write(str, strlen(str));

    GetTemp(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetWindSpeed(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetWindGust(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetWindDir(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetHumidity(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetLight(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetUv(str);
    strcat(str, "\r\n");
    FDayFile->Write(str, strlen(str));
}

/*##########################################################################
#
#   Name       : TMet::UpdateMonthData
#
#   Purpose....: Update month data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMet::UpdateMonthData()
{
    TDateTime time;
    TFile *File;
    char str[50];
    int val;

    time.AddHour(-6);

    File = CreateMonthFile(time.GetYear(), time.GetMonth());

    sprintf(str, "%d;", time.GetDay());
    File->Write(str, strlen(str));

    sprintf(str, "%3.1Lf;", Rain);
    File->Write(str, strlen(str));

    sprintf(str, "%3.1Lf;", MinTemp);
    File->Write(str, strlen(str));

    sprintf(str, "%3.1Lf\r\n", MaxTemp);
    File->Write(str, strlen(str));

    delete File;

    HasRain = false;
    HasMinTemp = false;
    HasMaxTemp = false;
}

/*##########################################################################
#
#   Name       : TMet::Execute
#
#   Purpose....: Handler thread
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMet::Execute()
{
    int i;
    TDateTime *CurrTime;
    int LastMin;
    int LastDay;
    int UsedDay;

    FDayFile = 0;

    CurrTime = new TDateTime;
    LastMin = CurrTime->GetMin();
    LastDay = CurrTime->GetDay();
    UsedDay = LastDay;
    CreateDayFile(CurrTime->GetYear(), CurrTime->GetMonth(), CurrTime->GetDay());
    delete CurrTime;

    while (FInstalled)
    {
        CurrTime = new TDateTime;

        if (LastMin != CurrTime->GetMin())
        {
            FDataSection.Enter();

            if (LastDay != CurrTime->GetDay())
            {
                LastDay = CurrTime->GetDay();
                CreateDayFile(CurrTime->GetYear(), CurrTime->GetMonth(), CurrTime->GetDay());
            }

            LastMin = CurrTime->GetMin();
            UpdateDataStore(CurrTime->GetHour(), CurrTime->GetMin());

            if (HasRain && HasMinTemp && HasMaxTemp)
                UpdateMonthData();

            FDataSection.Leave();
        }

        delete CurrTime;

        RdosWaitMilli(1000);
    }
}
