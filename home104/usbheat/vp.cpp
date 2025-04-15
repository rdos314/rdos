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

#include "vp.h"
#include "table.h"

#define FALSE 0
#define TRUE !FALSE

#define START_TIMEOUT   5 * 60

void LockGUI();
void UnlockGUI();

#define ROOT_DIR "e:/data/vp"
#define CSV_DAY_HEADER "time;temp;tank;circ;on\r\n"

/*##########################################################################
#
#   Name       : TVp::TVp
#
#   Purpose....: VP constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVp::TVp(TControlThread *control, TOcppNotify *ocpp, THhcRelay *relay)
  : FLog("TVp"),
    FModDev(0x7D01A8C0, 502),
    FEch(&FModDev, 1),
    FSection("Vp")
{
    TModbusDevice PowModbus(0x7701A8C0, 502);

    int i;

    FControl = control;
    FOcpp = ocpp;
    FRelay = relay;
    FCheckDelay = 0;

    FValidAmbient = FALSE;
    FIncCount = 0;
    FHasCirc = FALSE;
    FMaxTank = 350;
    FStartTimeout = 0;

    FCurrPower = 0;
    FPowerSum = 0.0;
    FPowerCount = 0;
    FPowerIndex = 0;

    FDayFile = 0;

    Start("Vp", 0x2000);
}

/*##########################################################################
#
#   Name       : TVp::~TVp
#
#   Purpose....: Circulation pump destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVp::~TVp()
{
}

/*##########################################################################
#
#   Name       : TVp::DeviceName
#
#   Purpose....: Device name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::DeviceName(char *Name, int Size) const
{
        strcpy(Name, "VP");
}

/*##########################################################################
#
#   Name       : TVp::GetTankTemp
#
#   Purpose....: Get tank temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::GetTankTemp()
{
    return FTankTemp;
}

/*##########################################################################
#
#   Name       : TVp::SetTempError
#
#   Purpose....: Set current temp error
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetTempError(int diff)
{
    FSection.Enter();

    TempCount++;
    TempSum += diff;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TVp::SetPower
#
#   Purpose....: Set power
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetPower(long double val)
{
    int i;

    if (FPowerCount == POWER_COUNT)
    {
        FPowerSum -= FPowerArr[FPowerIndex];
        FPowerSum += val;
        FPowerArr[FPowerIndex] = val;

        FPowerIndex++;
        if (FPowerIndex == POWER_COUNT)
        {
            FPowerIndex = 0;
            FPowerSum = 0;
            for (i = 0; i < POWER_COUNT; i++)
                FPowerSum += FPowerArr[i];
        }
    }
    else
    {
        FPowerArr[FPowerCount] = val;
        FPowerSum += val;
        FPowerCount++;
    }

    FCurrPower = (int)(FPowerSum / FPowerCount);
}

/*##########################################################################
#
#   Name       : TVp::SetAmbientDiff
#
#   Purpose....: Set ambient temp diff
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetAmbient(int ref, int ambient, bool night)
{
    FSection.Enter();

    FRef = ref;
    FAmbient = ambient;

    FValidAmbient = TRUE;

    FMaxTank = 200;

    if (ambient < 150)
    {
        if (FCurrPower >= 2000)
        {
            if (ambient < 40)
                FMaxTank = 400 - ambient;
        }
        else
        {
            if (FCurrPower >= 1000)
            {
                if (ambient < 20)
                    FMaxTank = 350 - ambient;
            }
            else
            {
                if (ambient < 0)
                    FMaxTank = 300 - ambient;
            }
        }

        if (FMaxTank > 400)
            FMaxTank = 400;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TVp::SetMaxMotor
#
#   Purpose....: Set current max motor
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetMaxMotor(int motor)
{
    FSection.Enter();

    FMotorCount++;
    FMotorSum += motor;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TVp::WriteCircValve
#
#   Purpose....: Write Circ valve
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::WriteCircValve(long double value)
{
    int temp;

    temp = (int)(value / 10.0 * (long double)0x7FFFFFFF);
    if (temp < 0)
        temp = 0x7FFFFFFF;

    RdosWriteSerialVal(1, 0, temp);
}

/*##########################################################################
#
#   Name       : TVp::UpdateCirc
#
#   Purpose....: Update circ
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::UpdateCirc()
{
    int on;
    int diostat;

    if (RdosReadSerialLines(1, &diostat))
    {
        if ((diostat & 0x10) == 0)
            on = FALSE;
        else
            on = TRUE;

        if (FTankTemp > 230)
        {
            if (FCirc == 0)
            {
                if (on)
                {
                    FLog.Log(0, "UpdateCirc", "Circ off");
                    RdosToggleSerialLine(1, 4);
                }
            }

            if (FCirc > 25)
            {
                if (!on)
                {
                    FLog.Log(0, "UpdateCirc", "Circ on");
                    RdosToggleSerialLine(1, 4);
                }
            }
        }
        else
        {
            if (on)
            {
                FLog.Log(0, "UpdateCirc", "Circ off");
                RdosToggleSerialLine(1, 4);
            }
        }
    }

    if (on)
        WriteCircValve((long double)FCirc);
    else
        WriteCircValve(0.0);
}

/*##########################################################################
#
#   Name       : TVp::SetupCheckDelay
#
#   Purpose....: Setup temp check delay
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetupCheckDelay()
{
    FCheckDelay = 15;
}

/*##########################################################################
#
#   Name       : TVp::UpdateVp
#
#   Purpose....: Update VP
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::UpdateVp()
{
    int tries;
    int diostat;

    FSection.Enter();

    if (FVpCircOn)
    {
        SetupCheckDelay();

        FTankTemp = FEch.GetHeatInlet();

        if (!FEch.IsOn() || FCirc < 25 || FOcpp->IsCharging())
        {
            if (RdosReadSerialLines(1, &diostat))
            {
                if ((diostat & 0x20) != 0)
                {
                    RdosToggleSerialLine(1, 5);   // cold
                    FLog.Log(0, "UpdateVp", "Cold stopped");
                }

                if ((diostat & 0x40) != 0)
                {
                    RdosWaitMilli(250);
                    FLowTemp = FTankTemp - 30;
                    RdosToggleSerialLine(1, 6);   // heat
                    FLog.Log(0, "UpdateVp", "Heat stopped");
                }
                FVpCircOn = false;
            }
        }
    }
    else
    {
        if (FCheckDelay)
            FCheckDelay--;
        else
        {
            SetupCheckDelay();

            if (RdosReadSerialLines(1, &diostat))
            {
                if ((diostat & 0x40) == 0)
                {
                    RdosToggleSerialLine(1, 6);   // heat
                    FLog.Log(0, "UpdateVp", "Heat started");
                }

                RdosWaitMilli(30000);
                FEch.UpdateHeatIn();
                RdosWaitMilli(1500);
            }
        }

        if (RdosReadSerialLines(1, &diostat))
        {
            if ((diostat & 0x40) != 0)
            {
                FTankTemp = FEch.GetHeatInlet();

                if (FTankTemp <= FLowTemp + 5 && FTankTemp < FMaxTank && FCirc > 75 && !FOcpp->IsCharging())
                {
                    FLog.printf(0, "UpdateVp", "Set Limit %d.%01d", FMaxTank / 10, FMaxTank % 10);

                    FEch.SetHeatLimit(FMaxTank + 20);

                    for (tries = 0; tries < 100 && !FEch.IsHeatLimitUpdated(); tries++)
                        RdosWaitMilli(100);

                    if (FEch.IsHeatLimitUpdated())
                    {
                        FLog.printf(0, "UpdateVp", "Limit accepted");
                        RdosWaitMilli(5000);

                        if (RdosReadSerialLines(1, &diostat))
                        {
                            if ((diostat & 0x20) == 0)
                            {
                                RdosWaitMilli(250);
                                RdosToggleSerialLine(1, 5);   // cold
                                FLog.Log(0, "UpdateVp", "Cold started");
                                FVpCircOn = true;
                            }
                        }
                    }
                    else
                        FLog.printf(0, "UpdateVp", "Limit not updated");
                }
                else
                {
                    RdosToggleSerialLine(1, 6);   // heat
                    FLog.printf(0, "UpdateVp", "Heat stopped, temp: %d.%01d", FTankTemp / 10, FTankTemp % 10);
                }
            }
        }
    }

    UpdateCirc();

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TVp::CreateDayFile
#
#   Purpose....: Create/open a day-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::CreateDayFile(int year, int month, int day)
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
#   Name       : TVp::GetTemp
#
#   Purpose....: Get ambient temp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::GetTemp(char *str)
{
    int val;

    val = FAmbient;

    if (val >= 0)
        sprintf(str, "%d.%01d", val / 10, val % 10);
    else
    {
        val = -val;
        sprintf(str, "-%d.%01d", val / 10, val % 10);
    }
}

/*##########################################################################
#
#   Name       : TVp::GetTank
#
#   Purpose....: Get tank temp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::GetTank(char *str)
{
    sprintf(str, "%d.%01d", FTankTemp / 10, FTankTemp % 10);
}

/*##########################################################################
#
#   Name       : TVp::GetCirc
#
#   Purpose....: Get circ
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::GetCirc(char *str)
{
    if (FHasCirc)
        sprintf(str, "%d.%01d", FCirc / 10, FCirc % 10);
    else
        str[0] = 0;
}

/*##########################################################################
#
#   Name       : TVp::GetOn
#
#   Purpose....: Get on
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::GetOn(char *str)
{
    if (FEch.IsOn())
        strcpy(str, "1");
    else
        strcpy(str, "0");
}

/*##########################################################################
#
#   Name       : TVp::UpdateDataStore
#
#   Purpose....: Update data store
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::UpdateDataStore(int hour, int min)
{
    char str[50];

    sprintf(str, "%02d:%02d;", hour, min);
    FDayFile->Write(str, strlen(str));

    GetTemp(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetTank(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetCirc(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetOn(str);
    strcat(str, "\r\n");
    FDayFile->Write(str, strlen(str));
}

/*##########################################################################
#
#   Name       : TVp::Execute
#
#   Purpose....: Handler thread
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::Execute()
{
    int i;
    TDateTime *CurrTime;
    int LastMin;
    int LastDay;
    int UsedDay;
    int diostat;
    int mask;
    int ival;
    char str[50];

    TLabelFactory CommentLabelFactory;
    TLabelFactory ValueLabelFactory;
    TLabelFactory UnitLabelFactory;


    CommentLabelFactory.SetSpace(4, 4);
    CommentLabelFactory.SetFont(25);
    CommentLabelFactory.SetBackColor(0, 20, 50);
    CommentLabelFactory.SetDrawColor(0, 0, 0);
    CommentLabelFactory.AlignLeft();
    CommentLabelFactory.ForceNoScale();

    ValueLabelFactory.SetSpace(4, 4);
    ValueLabelFactory.SetFont(25);
    ValueLabelFactory.SetBackColor(100, 100, 100);
    ValueLabelFactory.SetDrawColor(0, 0, 0);
    ValueLabelFactory.AlignRight();
    ValueLabelFactory.ForceNoScale();

    UnitLabelFactory.SetSpace(4, 4);
    UnitLabelFactory.SetFont(25);
    UnitLabelFactory.SetBackColor(0, 20, 50);
    UnitLabelFactory.SetDrawColor(0, 0, 0);
    UnitLabelFactory.AlignLeft();
    UnitLabelFactory.ForceNoScale();

    TTableControl *Table;

    LockGUI();

    Table = new TTableControl(FControl, 5, 315, 300, 300);
    Table->SetBackColor(0, 20, 50);
    Table->SetRowSpacing(8);
    Table->SetColSpacing(12);
    Table->SetSpacingColor(0, 20, 50);
    Table->AddLabelColumn(&CommentLabelFactory, 125);
    Table->AddLabelColumn(&ValueLabelFactory, 100);
    Table->AddLabelColumn(&UnitLabelFactory, 85);

    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);

    Table->SetText(0, 0, "Heat in");
    Table->SetText(0, 2, "°C");

    Table->SetText(1, 0, "Heat out");
    Table->SetText(1, 2, "°C");

    Table->SetText(2, 0, "Cold in");
    Table->SetText(2, 2, "°C");

    Table->SetText(3, 0, "Auto larm");
    Table->SetText(3, 2, "");

    Table->SetText(4, 0, "Manual larm");
    Table->SetText(4, 2, "");

    Table->SetText(5, 0, "Outputs");
    Table->SetText(5, 2, "");

    Table->SetText(6, 0, "Relays");
    Table->SetText(6, 2, "");

    Table->Show();

    UnlockGUI();

    TempSum = 0;
    TempCount = 0;

    FMotorSum = 0;
    FMotorCount = 0;

    CurrTime = new TDateTime;
    LastMin = CurrTime->GetMin();
    LastDay = CurrTime->GetDay();
    UsedDay = LastDay;
    CreateDayFile(CurrTime->GetYear(), CurrTime->GetMonth(), CurrTime->GetDay());
    delete CurrTime;

    while (FInstalled)
    {
        if (RdosReadSerialLines(1, &diostat))
        {
            if ((diostat & 0x20) == 0)
                FVpCircOn = false;
            else
                FVpCircOn = true;
        }
        break;
    }

    RdosWaitMilli(2000);
    FTankTemp = FEch.GetHeatInlet();
    FLowTemp = 1000;

    while (FInstalled)
    {
       if (RdosReadSerialLines(1, &diostat))
        {
            mask = 0x80;
            for (i = 0; i < 8; i++)
            {
                if (diostat & mask)
                    str[i] = '1';
                else
                    str[i] = '0';
                mask = mask >> 1;
            }
            str[8] = 0;
        }
        else
            strcpy(str, "------");

        Table->SetText(5, 1, str);

       if (FRelay->IsOnline())
        {
            for (i = 0; i < 8; i++)
            {
                if (FRelay->IsOn(7-i))
                    str[i] = '1';
                else
                    str[i] = '0';
            }
            str[8] = 0;
        }
        else
            strcpy(str, "------");

        Table->SetText(6, 1, str);

        if (FVpCircOn)
        {
            ival = FEch.GetHeatInlet();
            sprintf(str, "%d.%01d", ival / 10, ival % 10);
            Table->SetText(0, 1, str);

            ival = FEch.GetHeatOutlet();
            sprintf(str, "%d.%01d", ival / 10, ival % 10);
            Table->SetText(1, 1, str);

            ival = FEch.GetColdInlet();
            sprintf(str, "%d.%01d", ival / 10, ival % 10);
            Table->SetText(2, 1, str);
        }
        else
        {
            ival = FTankTemp;
            sprintf(str, "%d.%01d", ival / 10, ival % 10);
            Table->SetText(0, 1, str);
        }

        ival = FEch.GetAutoAlarms();
        sprintf(str, "%06hX", ival);
        Table->SetText(3, 1, str);

        ival = FEch.GetManualAlarms();
        sprintf(str, "%06hX", ival);
        Table->SetText(4, 1, str);

        CurrTime = new TDateTime;

        if (LastMin != CurrTime->GetMin())
        {
            UpdateVp();

            FSection.Enter();

            if (FMotorCount)
            {
                if (CurrTime->GetMonth() >= 6 && CurrTime->GetMonth() <= 8)
                    FCirc = 99;
                else
                    FCirc = FMotorSum / FMotorCount;

                FHasCirc = TRUE;
            }

            FMotorSum = 0;
            FMotorCount = 0;

            FSection.Leave();
        }
        else
            if (FVpCircOn && FOcpp->IsCharging())
                UpdateVp();

        if (LastMin != CurrTime->GetMin())
        {
            FSection.Enter();

            if (LastDay != CurrTime->GetDay())
            {
                LastDay = CurrTime->GetDay();
                CreateDayFile(CurrTime->GetYear(), CurrTime->GetMonth(), CurrTime->GetDay());
            }

            LastMin = CurrTime->GetMin();
            UpdateDataStore(CurrTime->GetHour(), CurrTime->GetMin());

            FSection.Leave();
        }

        delete CurrTime;

        RdosWaitMilli(1000);
    }
}
