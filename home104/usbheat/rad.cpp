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
# rad.h
# Radiator class
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "rad.h"

#define FALSE 0
#define TRUE !FALSE

#define ROOT_DIR "e:/data/rad"
#define CSV_DAY_HEADER "time;ref;temp1;temp2;motor;light\r\n"

/*##########################################################################
#
#   Name       : TRad::TRad
#
#   Purpose....: Radiator constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRad::TRad(const char *name, TRadControl *control, int rad, int Address)
  : FLog("TRad")
{
    char str[40];

    FControl = control;
    FIndex = rad;
    FAddress = Address;
    Offline();
    Ref = 200;
    Temp = 200;
    Motor = 51;
    Light = 0;
    AuxTemp = 200;
    RefType = 0;

    FControl->Define(FIndex, name);

    FUpdateRefType = FALSE;
    FUpdateRef = FALSE;
    FUpdateAmbient = FALSE;

    FRefSum = 0;
    FRefCount = 0;
    FTempSum = 0;
    FTempCount = 0;
    FMotorSum = 0;
    FMotorCount = 0;
    FLightSum = 0;
    FLightCount = 0;
    FAuxTempSum = 0;
    FAuxTempCount = 0;

    FDayFile = 0;

    sprintf(str, "RAD %d", Address);
    Start(str, 0x2000);
}

/*##########################################################################
#
#   Name       : TRad::~TRad
#
#   Purpose....: Radiator destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRad::~TRad()
{
}

/*##########################################################################
#
#   Name       : TRad::DeviceName
#
#   Purpose....: Device name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::DeviceName(char *Name, int Size) const
{
    strcpy(Name, "RAD");
}

/*##########################################################################
#
#   Name       : TRad::CreateDayFile
#
#   Purpose....: Create/open a day-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::CreateDayFile(int year, int month, int day)
{
    char str[20];
    char filename[256];
    int i, j;
    int filesize;

    if (!RdosSetCurDir(ROOT_DIR))
        RdosMakeDir(ROOT_DIR);

    sprintf(str, "%02hX", FAddress);
    strcpy(filename, ROOT_DIR);
    strcat(filename, "/");
    strcat(filename, str);

    if (!RdosSetCurDir(filename))
        RdosMakeDir(filename);

    sprintf(str, "%02hX/%d", FAddress, year);
    strcpy(filename, ROOT_DIR);
    strcat(filename, "/");
    strcat(filename, str);

    if (!RdosSetCurDir(filename))
        RdosMakeDir(filename);

    sprintf(str, "%02hX/%d/%d", FAddress, year, month);
    strcpy(filename, ROOT_DIR);
    strcat(filename, "/");
    strcat(filename, str);

    if (!RdosSetCurDir(filename))
        RdosMakeDir(filename);

    sprintf(str, "%02hX/%d/%d/%d.csv", FAddress, year, month, day);
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
#   Name       : TRad::GetRef
#
#   Purpose....: Get ref
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::GetRef(char *str)
{
    if (FRefCount == 0)
        str[0] = 0;
    else
    {
        Ref = FRefSum / FRefCount;
        FRefSum = 0;
        FRefCount = 0;

        sprintf(str, "%d.%01d", Ref / 10, Ref % 10);
    }
}

/*##########################################################################
#
#   Name       : TRad::GetTemp
#
#   Purpose....: Get temp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::GetTemp(char *str)
{
    if (FTempCount == 0)
        str[0] = 0;
    else
    {
        Temp = FTempSum / FTempCount;
        FTempSum = 0;
        FTempCount = 0;

        sprintf(str, "%d.%01d", Temp / 10, Temp % 10);
    }
}

/*##########################################################################
#
#   Name       : TRad::GetAuxTemp
#
#   Purpose....: Get aux temp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::GetAuxTemp(char *str)
{
    if (FAuxTempCount == 0)
        str[0] = 0;
    else
    {
        AuxTemp = FAuxTempSum / FAuxTempCount;
        FAuxTempSum = 0;
        FAuxTempCount = 0;

        sprintf(str, "%d.%01d", AuxTemp / 10, AuxTemp % 10);
    }
}

/*##########################################################################
#
#   Name       : TRad::GetMotor
#
#   Purpose....: Get motor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::GetMotor(char *str)
{
    if (FMotorCount == 0)
        str[0] = 0;
    else
    {
        Motor = FMotorSum / FMotorCount;
        FMotorSum = 0;
        FMotorCount = 0;

        sprintf(str, "%d.%01d", Motor / 10, Motor % 10);
    }
}

/*##########################################################################
#
#   Name       : TRad::GetLight
#
#   Purpose....: Get light
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::GetLight(char *str)
{
    if (FLightCount == 0)
        str[0] = 0;
    else
    {
        Light = FLightSum / FLightCount;
        FLightSum = 0;
        FLightCount = 0;

        sprintf(str, "%d.%01d", Light / 10, Light % 10);
    }
}

/*##########################################################################
#
#   Name       : TRad::UpdateDataStore
#
#   Purpose....: Update data store
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::UpdateDataStore(int hour, int min)
{
    char str[50];

    sprintf(str, "%02d:%02d;", hour, min);
    FDayFile->Write(str, strlen(str));

    GetRef(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetTemp(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetAuxTemp(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetMotor(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetLight(str);
    strcat(str, "\r\n");
    FDayFile->Write(str, strlen(str));
}

/*##########################################################################
#
#   Name       : TRad::SetDayRef
#
#   Purpose....: Set day time reference
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::SetDayRef()
{
    RefType = 0;
    FUpdateRefType = TRUE;
}

/*##########################################################################
#
#   Name       : TRad::SetNightRef
#
#   Purpose....: Set night time reference
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::SetNightRef()
{
    RefType = 1;
    FUpdateRefType = TRUE;
}

/*##########################################################################
#
#   Name       : TRad::SetWinterRef
#
#   Purpose....: Set winter time (night) reference
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::SetWinterRef()
{
    RefType = 2;
    FUpdateRefType = TRUE;
}

/*##########################################################################
#
#   Name       : TRad::SetSummerRef
#
#   Purpose....: Set summer time reference (cool generation)
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::SetSummerRef()
{
    RefType = 3;
    FUpdateRefType = TRUE;
}

/*##########################################################################
#
#   Name       : TRad::SetRef
#
#   Purpose....: Set reference temperature
#
#   Out params.: Reference temperature
#   Returns....: *
#
##########################################################################*/
void TRad::SetRef(int Temp)
{
    Ref = Temp;
    FUpdateRef = TRUE;
}

/*##########################################################################
#
#   Name       : TRad::SetAmbient
#
#   Purpose....: Set ambient (outdoor) temperature
#
#   Out params.: ambient temperature
#   Returns....: *
#
##########################################################################*/
void TRad::SetAmbient(int temp)
{
    Ambient = temp;
    FUpdateAmbient = TRUE;
}

/*##########################################################################
#
#   Name       : TRad::GetAddress
#
#   Purpose....: Get address
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRad::GetAddress()
{
    return FAddress;
}

/*##########################################################################
#
#   Name       : TRad::GetRef
#
#   Purpose....: Get reference temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRad::GetRef()
{
    return Ref;
}

/*##########################################################################
#
#   Name       : TRad::GetTemp
#
#   Purpose....: Get temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRad::GetTemp()
{
    return Temp;
}

/*##########################################################################
#
#   Name       : TRad::GetMotor
#
#   Purpose....: Get motor value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRad::GetMotor()
{
    return Motor;
}

/*##########################################################################
#
#   Name       : TRad::GetLight
#
#   Purpose....: Get light value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRad::GetLight()
{
    return Light;
}

/*##########################################################################
#
#   Name       : TRad::GetAuxTemp
#
#   Purpose....: Get aux-temp value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRad::GetAuxTemp()
{
    return AuxTemp;
}


/*##########################################################################
#
#   Name       : TRad::Execute
#
#   Purpose....: Execute
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRad::Execute()
{
    int val;
    int ok;
    TDateTime *CurrTime;
    int LastMin;
    int LastDay;
    int UsedDay;

    CurrTime = new TDateTime;
    LastMin = CurrTime->GetMin();
    LastDay = CurrTime->GetDay();
    UsedDay = LastDay;
    CreateDayFile(CurrTime->GetYear(), CurrTime->GetMonth(), CurrTime->GetDay());
    delete CurrTime;

    while (FInstalled)
    {
        FSection.Enter();

        ok = TRUE;

        if (!IsOnline())
            ok = RdosReadSerialRaw(FAddress, 0, &val);

        if (ok)
        {
            if (FUpdateRef)
            {
                val = Ref;
                FUpdateRef = !RdosWriteSerialRaw(FAddress, 0, val);
            }

            if (FUpdateAmbient)
            {
                val = 127 + (Ambient - Ref) / 10;
                FUpdateAmbient = !RdosWriteSerialRaw(FAddress, 4, val);
            }

            if (FUpdateRefType)
                FUpdateRefType = !RdosWriteSerialRaw(FAddress, 5, RefType);

            ok = RdosReadSerialRaw(FAddress, 0, &val);

            if (ok)
            {
                if (val > 100 && val < 255)
                {
                    FRefSum += val;
                    FRefCount++;
                    FControl->SetRef(FIndex, val);
                }
                else
                    FLog.printf(0, "", "Ref: %d", val);
            }
            else
                FControl->SetRef(FIndex);

            if (ok)
            {
                ok = RdosReadSerialRaw(FAddress, 1, &val);

                if (ok)
                {
                    if (val > 100 && val < 255)
                    {
                        FTempSum += val;
                        FTempCount++;
                        FControl->SetTemp(FIndex, val);
                    }
                    else
                        FLog.printf(0, "", "Temp: %d", val);
                }
		else
                    FControl->SetTemp(FIndex);
            }

            if (ok)
            {
                ok = RdosReadSerialRaw(FAddress, 2, &val);

                if (ok)
                {
                    if (val >= 0 && val < 500)
                    {
                        val = val * 10 / 25;
                        FMotorSum += val;
                        FMotorCount++;
                        FControl->SetMotor(FIndex, val);
                    }
                    else
                        FLog.printf(0, "", "Motor: %d", val);
		}
		else
                    FControl->SetMotor(FIndex);
            }

            if (ok)
            {
                ok = RdosReadSerialRaw(FAddress, 3, &val);

                if (ok)
                {
                    if (val >= 0 && val < 4096)
                    {
                        FLightSum += val;
                        FLightCount++;
                        FControl->SetLight(FIndex, val);
                    }
                    else
                        FLog.printf(0, "", "Light: %d", val);
                }
                else
		    FControl->SetLight(FIndex);
            }

            if (ok)
            {
                ok = RdosReadSerialRaw(FAddress, 4, &val);

                if (ok)
                {
                    if (val > 100 && val < 255)
                    {
                        FAuxTempSum += val;
                        FAuxTempCount++;
                        FControl->SetAuxTemp(FIndex, val);
                    }
                    else
                        FLog.printf(0, "", "Aux: %d", val);
                }
                else
                    FControl->SetAuxTemp(FIndex);
            }
        }

        if (ok)
            Online();
        else
            Offline();

        CurrTime = new TDateTime;

        if (LastMin != CurrTime->GetMin())
        {
            if (LastDay != CurrTime->GetDay())
            {
                LastDay = CurrTime->GetDay();
                CreateDayFile(CurrTime->GetYear(), CurrTime->GetMonth(), CurrTime->GetDay());
            }

            LastMin = CurrTime->GetMin();
            UpdateDataStore(CurrTime->GetHour(), CurrTime->GetMin());
        }

        delete CurrTime;

        FSection.Leave();

        RdosWaitMilli(1000);
    }
}
