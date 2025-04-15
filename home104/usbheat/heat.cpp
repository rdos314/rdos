/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2019, Leif Ekblad
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
# heat.cpp
# Heat control program
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "frinv.h"
#include "powinv.h"
#include "misol.h"
#include "rad.h"
#include "datetime.h"
#include "vp.h"
#include "met.h"
#include "videodev.h"
#include "radcntrl.h"
#include "solar.h"
#include "ocppdev.h"
#include "table.h"
#include "jpeg.h"
#include "file.h"
#include "web.h"
#include "mail.h"
#include "rdoslog.h"
#include "chart.h"
#include "timeaxis.h"
#include "linyaxis.h"
#include "png.h"
#include "ddns.h"
#include "smameter.h"
#include "ini.h"
#include "hhcn818.h"
#include "powhvmp.h"

int GetWebConnectionCount();

#define FALSE   0
#define TRUE    !FALSE

#define MAX_CORES   3
#define MAX_SAMPLES 5 * 60

#define ROOT_DIR "e:/data/power"
#define CSV_DAY_HEADER "time;solar;grid;dump;prod;cons\r\n"
#define CSV_MONTH_HEADER "day;solar;wind;prod;cons\r\n"

#define WIDTH 240
#define HEIGHT 15

TGraphicDevice *vbe;
TControlThread *control;
TSection FGuiSection("Gui.Section");

TSection FDataSection("Data.Section");
static TFile *DayFile = 0;

static TOcppSocketServerFactory *Ocpp;
static TPowHvmP *PowInv = 0;

static int SolarPowerCount;
static int SolarPowerSum;

static long double SolarDayE = 0.0;
static long double SolarNewDayE = 0.0;

static int WindGridCount;
static int WindGridSum;

static int WindDumpCount;
static int WindDumpSum;

static long double WindDayE = 0.0;
static long double WindNewDayE = 0.0;

static int ProdPowerCount = 0;
static double ProdPowerSum;

static int ConsPowerCount = 0;
static double ConsPowerSum;

static double ProdDayE = 0.0;
static double ConsDayE = 0.0;

static TString OcppState;
static double OcppVoltage[3];
static double OcppCurrent[3];
static int OcppEnergy;
static bool OcppHasData = false;

int WdTimeout;


/*##################  WatchdogThread  ##############################################
 *   Purpose....: Watchdog thread                                                                           #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-10-02 le                                                #
 *##########################################################################*/
void WatchdogThread(void *ptr)
{
    TRdosLog Log("");

    bool kick;
    bool prevk = true;

    WdTimeout = 2 * 100;

    for (;;)
    {
        kick = false;

        if (RdosGetFreeGdt() > 1000)
        {
            if (WdTimeout)
            {
                WdTimeout--;
                kick = true;
            }
            else
                if (prevk)
                    Log.Log(0, "", "Watchdog timeout");
        }
        else
            if (prevk)
                Log.Log(0, "", "GDT too low");

        if (kick)
            RdosKickWatchdog();

        prevk = kick;

        RdosWaitMilli(500);
    }
}

/*##########################################################################
#
#   Name       : NotifySolarPower
#
#   Purpose....: Notify solar power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifySolarPower(TFroniusInverter *Device, long double val)
{
    FDataSection.Enter();

    SolarPowerSum += (int)val;
    SolarPowerCount++;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifySolarDayEnergy
#
#   Purpose....: Notify solar day energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifySolarDayEnergy(TFroniusInverter *Device, long double val)
{
    FDataSection.Enter();

    if (val < SolarDayE)
        SolarNewDayE = SolarDayE;

    SolarDayE = val;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyWindGridPower
#
#   Purpose....: Notify wind grid power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyWindGridPower(TSmartPowInverter *Device, long double val)
{
    FDataSection.Enter();

    WindGridSum += (int)val;
    WindGridCount++;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyWindDumpPower
#
#   Purpose....: Notify wind dump power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyWindDumpPower(TSmartPowInverter *Device, long double val)
{
    FDataSection.Enter();

    WindDumpSum += (int)val;
    WindDumpCount++;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyWindDayEnergy
#
#   Purpose....: Notify wind day energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyWindDayEnergy(TSmartPowInverter *Device, long double val)
{
    FDataSection.Enter();

    if (val < WindDayE)
        WindNewDayE = WindDayE;

    WindDayE = val;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyProdPower
#
#   Purpose....: Notify prod power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyProdPower(double val)
{
    FDataSection.Enter();

    ProdPowerSum += val;
    ProdPowerCount++;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyConsPower
#
#   Purpose....: Notify consume power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyConsPower(double val)
{
    FDataSection.Enter();

    ConsPowerSum += val;
    ConsPowerCount++;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyProdDayEnergy
#
#   Purpose....: Notify production day energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyProdDayEnergy(double val)
{
    FDataSection.Enter();

    ProdDayE = val;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyConsDayEnergy
#
#   Purpose....: Notify consume day energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyConsDayEnergy(double val)
{
    FDataSection.Enter();

    ConsDayE = val;

    FDataSection.Leave();
}

/*##########################################################################
#
#   Name       : NotifyOcppState
#
#   Purpose....: Notify OCPP state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyOcppState(TOcppNotify *Server, const char *state)
{
    OcppState = state;
}

/*##########################################################################
#
#   Name       : NotifyOcppStart
#
#   Purpose....: Notify OCPP start
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyOcppStart(TOcppNotify *Server, int val)
{
}

/*##########################################################################
#
#   Name       : NotifyOcppStop
#
#   Purpose....: Notify OCPP stop
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyOcppStop(TOcppNotify *Server, int val)
{
}

/*##########################################################################
#
#   Name       : NotifyOcppData
#
#   Purpose....: Notify OCPP data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void NotifyOcppData(TOcppNotify *Server)
{
    int i;
    double v = Server->GetVoltage(0);

    FDataSection.Enter();

    if (v <= 240.0)
        OcppEnergy = Server->GetEnergy();

    for (i = 0; i < 3; i++)
    {
        OcppVoltage[i] = Server->GetVoltage(i);

        if (v <= 240.0)
            OcppCurrent[i] = Server->GetCurrent(i);
    }

    FDataSection.Leave();

    OcppHasData = true;
}

/*##########################################################################
#
#   Name       : ResetSolarWind
#
#   Purpose....: Reset wind counters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void ResetSolarWind()
{
    SolarPowerCount = 0;
    SolarPowerSum = 0;

    WindGridCount = 0;
    WindGridSum = 0;

    WindDumpCount = 0;
    WindDumpSum = 0;

    ProdPowerCount = 0;
    ProdPowerSum = 0.0;

    ConsPowerCount = 0;
    ConsPowerSum = 0.0;
}

/*##########################################################################
#
#   Name       : GetSolarPower
#
#   Purpose....: Get solar power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void GetSolarPower(char *str)
{
    int val;

    if (SolarPowerCount == 0)
        str[0] = 0;
    else
    {
        val = 10 * SolarPowerSum / SolarPowerCount;
        sprintf(str, "%d.%01d", val / 10, val % 10);
    }
}

/*##########################################################################
#
#   Name       : GetWindGridPower
#
#   Purpose....: Get wind grid power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void GetWindGridPower(char *str)
{
    int val;

    if (WindGridCount == 0)
        str[0] = 0;
    else
    {
        val = 10 * WindGridSum / WindGridCount;
        sprintf(str, "%d.%01d", val / 10, val % 10);
    }
}

/*##########################################################################
#
#   Name       : GetWindDumpPower
#
#   Purpose....: Get wind dump power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void GetWindDumpPower(char *str)
{
    int val;

    if (WindDumpCount == 0)
        str[0] = 0;
    else
    {
        val = 10 * WindDumpSum / WindDumpCount;
        sprintf(str, "%d.%01d", val / 10, val % 10);
    }
}

/*##########################################################################
#
#   Name       : GetProdPower
#
#   Purpose....: Get produce power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void GetProdPower(char *str)
{
    double val;

    if (ProdPowerCount == 0)
        str[0] = 0;
    else
    {
        val = ProdPowerSum / ProdPowerCount;
        sprintf(str, "%3.1Lf", val);
    }
}

/*##########################################################################
#
#   Name       : GetConsPower
#
#   Purpose....: Get consume power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void GetConsPower(char *str)
{
    double val;

    if (ConsPowerCount == 0)
        str[0] = 0;
    else
    {
        val = ConsPowerSum / ConsPowerCount;
        sprintf(str, "%3.1Lf", val);
    }
}

/*##########################################################################
#
#   Name       : CreateDayFile
#
#   Purpose....: Create/open a day-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void CreateDayFile(int year, int month, int day)
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

    if (DayFile)
        delete DayFile;

    DayFile = new TFile(filename);

    if (!DayFile->IsOpen())
    {
        delete DayFile;
        DayFile = new TFile(filename, 0);
        DayFile->Write(CSV_DAY_HEADER, strlen(CSV_DAY_HEADER));
    }

    if (DayFile->IsOpen())
        DayFile->SetPos(DayFile->GetSize());
}

/*##########################################################################
#
#   Name       : CreateMonthFile
#
#   Purpose....: Create/open a month-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static TFile *CreateMonthFile(int year, int month)
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
#   Name       : UpdateDataStore
#
#   Purpose....: Update data store
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void UpdateDataStore(int hour, int min)
{
    char str[50];

    FDataSection.Enter();

    sprintf(str, "%02d:%02d;", hour, min);
    DayFile->Write(str, strlen(str));

    GetSolarPower(str);
    strcat(str, ";");
    DayFile->Write(str, strlen(str));

    GetWindGridPower(str);
    strcat(str, ";");
    DayFile->Write(str, strlen(str));

    GetWindDumpPower(str);
    strcat(str, ";");
    DayFile->Write(str, strlen(str));

    GetProdPower(str);
    strcat(str, ";");
    DayFile->Write(str, strlen(str));

    GetConsPower(str);
    strcat(str, "\r\n");
    DayFile->Write(str, strlen(str));

    FDataSection.Leave();

    ResetSolarWind();
}

/*##########################################################################
#
#   Name       : UpdateMonthData
#
#   Purpose....: Update month data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void UpdateMonthData()
{
    TDateTime time;
    TFile *File;
    char str[50];
    int val;

    time.AddHour(-6);

    File = CreateMonthFile(time.GetYear(), time.GetMonth());

    sprintf(str, "%d;", time.GetDay());
    File->Write(str, strlen(str));

    val = (int)(SolarNewDayE / 100.0 + 0.5);
    sprintf(str, "%d.%01d;", val / 10, val % 10);
    File->Write(str, strlen(str));

    val = (int)(10.0 * WindNewDayE);
    sprintf(str, "%d.%01d;", val / 10, val % 10);
    File->Write(str, strlen(str));

    sprintf(str, "%3.1Lf;", ProdDayE);
    File->Write(str, strlen(str));

    sprintf(str, "%3.1Lf\r\n", ConsDayE);
    File->Write(str, strlen(str));

    delete File;

    SolarNewDayE = 0;
    WindNewDayE = 0;
    ProdDayE = 0.0;
    ConsDayE = 0.0;
}

/*##########################################################################
#
#   Name       : CalcWindChill
#
#   Purpose....: Calculate windchill
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double CalcWindChill(double temp, double wind)
{
    double p;
    double val;

    if (wind < 1.3 || temp > 15.0)
        return temp;
    else
    {
        p = pow(wind, 0.16);
        val = 13.12 + 0.6215 * temp + (0.4863 * temp - 13.94) * p;
        return val;
    }
}

/*##########################################################################
#
#   Name       : LockGUI
#
#   Purpose....: Lock GUI
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void LockGUI()
{
    FGuiSection.Enter();
}

/*##########################################################################
#
#   Name       : UnockGUI
#
#   Purpose....: Unlock GUI
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void UnlockGUI()
{
    FGuiSection.Leave();
}

/*##########################################################################
#
#   Name       : TimeThread
#
#   Purpose....: Time thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TimeThread(void *Param)
{
    TLabelControl *Label;
    int year, month, day;
    int hour, min, sec;
    int ms, us;
    unsigned long msb, lsb;
    int val;
    char str[100];
    TTableControl *Table;
    TTableControl *SumTable;
    TLabelFactory CommentFactory;
    TLabelFactory ValueFactory;
    TLabelFactory UnitFactory;

    RdosWaitMilli(5000);

    CommentFactory.SetSpace(4, 4);
    CommentFactory.SetFont(25);
    CommentFactory.SetBackTransparent();
    CommentFactory.SetDrawColor(0, 0, 0);
    CommentFactory.AlignLeft();
    CommentFactory.ForceNoScale();

    ValueFactory.SetSpace(4, 4);
    ValueFactory.SetFont(25);
    ValueFactory.SetBackColor(100, 100, 100);
    ValueFactory.SetDrawColor(0, 0, 0);
    ValueFactory.AlignRight();
    ValueFactory.ForceNoScale();

    UnitFactory.SetSpace(4, 4);
    UnitFactory.SetFont(25);
    UnitFactory.SetBackTransparent();
    UnitFactory.SetDrawColor(0, 0, 0);
    UnitFactory.AlignLeft();
    UnitFactory.ForceNoScale();

    Table = new TTableControl(control, 925, 5, 370, 300);
    Table->SetBackColor(0, 20, 50);
    Table->SetRowSpacing(8);
    Table->SetColSpacing(12);
    Table->SetSpacingColor(0, 20, 50);
    Table->AddLabelColumn(&CommentFactory, 85);
    Table->AddLabelColumn(&ValueFactory, 150);
    Table->AddLabelColumn(&UnitFactory, 65);

    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);

    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);

    Table->SetText(0, 0, "State");
    Table->SetText(1, 0, "Energy");
    Table->SetText(2, 0, "Mode");
    Table->SetText(3, 0, "Output");
    Table->SetText(4, 0, "PV");
    Table->SetText(5, 0, "SoC");
    Table->SetText(6, 0, "Current");
    Table->SetText(7, 0, "Energy");

    Table->SetText(1, 2, "kWh");
    Table->SetText(3, 2, "W");
    Table->SetText(4, 2, "W");
    Table->SetText(5, 2, "%");
    Table->SetText(6, 2, "A");
    Table->SetText(7, 2, "kWh");
    Table->Show();

    RdosWaitMilli(500);

    LockGUI();

    Label = new TLabelControl(control, 350, 450, 165, 25);
    Label->SetFont(20);
    Label->SetBackColor(100, 100, 100);
    Label->SetDrawColor(0, 0, 0);
    Label->Show();

    UnlockGUI();

    for (;;)
    {
        FDataSection.Enter();

        if (OcppHasData)
        {
            Table->SetText(0, 1, OcppState.GetData());

            sprintf(str, "%d.%03d", OcppEnergy / 1000, OcppEnergy % 1000);
            Table->SetText(1, 1, str);
        }

        FDataSection.Leave();

        RdosGetTime(&msb, &lsb);
        RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
        RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);

        sprintf(str, "%04d-%02d-%02d %02d.%02d.%02d",
                        year, month, day,
                        hour, min, sec);
        Label->SetText(str);

        if (PowInv->HasNewData())
        {
            switch (PowInv->GetMode())
            {
                case 0:
                    strcpy(str, "Power On");
                    break;

                case 1:
                    strcpy(str, "Standby");
                    break;

                case 2:
                    strcpy(str, "Mains");
                    break;

                case 3:
                    strcpy(str, "Off-Grid");
                    break;

                case 4:
                    strcpy(str, "Bypass");
                    break;

                case 5:
                    strcpy(str, "Charging");
                    break;

                default:
                    strcpy(str, "Fault");
                    break;

            }
            Table->SetText(2, 1, str);

            sprintf(str, "%d", (int)PowInv->GetOutputPower());
            Table->SetText(3, 1, str);

            sprintf(str, "%d", (int)PowInv->GetSolarPower());
            Table->SetText(4, 1, str);

            val = (int)(100.0 * PowInv->GetBatterySoc());
            sprintf(str, "%d", val);
            Table->SetText(5, 1, str);

            sprintf(str, "%3.1Lf", PowInv->GetBatteryCurrent());
            Table->SetText(6, 1, str);

            sprintf(str, "%4.3Lf", PowInv->GetBatteryChargeEnergy() / 1000.0);
            Table->SetText(7, 1, str);

            PowInv->ClearNewData();
        }

        RdosWaitMilli(200);
    }
}

/*##########################################################################
#
#   Name       : SmaThread
#
#   Purpose....: SMA meter thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SmaThread(void *Param)
{
    int p;
    double val;
    double ProdBase;
    double ConsBase;
    TSmaMeter sma;
    TIniFile ini("d:/heat/setting.ini");
    TTableControl *Table;
    TTableControl *SumTable;
    TLabelFactory CommentFactory;
    TLabelFactory ValueFactory;
    TLabelFactory UnitFactory;
    int currday;
    int currmin;
    int pyear, pmonth, pday;
    int year, month, day;
    int hour, min, sec;
    int ms, us;
    int ok;
    int count;
    unsigned long msb, lsb;
    int pcount;
    int invdelay = 4;
    double p2sum;
    double p3sum;
    double p2min;
    double p3min;
    double p2;
    double p3;
    double soc;
    int maxca;
    int ca;
    char str[100];

    RdosWaitMilli(5000);

    LockGUI();

    CommentFactory.SetSpace(4, 4);
    CommentFactory.SetFont(25);
    CommentFactory.SetBackTransparent();
    CommentFactory.SetDrawColor(0, 0, 0);
    CommentFactory.AlignLeft();
    CommentFactory.ForceNoScale();

    ValueFactory.SetSpace(4, 4);
    ValueFactory.SetFont(25);
    ValueFactory.SetBackColor(100, 100, 100);
    ValueFactory.SetDrawColor(0, 0, 0);
    ValueFactory.AlignRight();
    ValueFactory.ForceNoScale();

    UnitFactory.SetSpace(4, 4);
    UnitFactory.SetFont(25);
    UnitFactory.SetBackTransparent();
    UnitFactory.SetDrawColor(0, 0, 0);
    UnitFactory.AlignLeft();
    UnitFactory.ForceNoScale();

    Table = new TTableControl(control, 750, 300, 515, 200);
    Table->SetBackColor(0, 20, 50);
    Table->SetRowSpacing(8);
    Table->SetColSpacing(12);
    Table->SetSpacingColor(0, 20, 50);
    Table->AddLabelColumn(&CommentFactory, 100);
    Table->AddLabelColumn(&ValueFactory, 100);
    Table->AddLabelColumn(&ValueFactory, 100);
    Table->AddLabelColumn(&ValueFactory, 100);
    Table->AddLabelColumn(&UnitFactory, 75);

    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);

    Table->SetText(0, 0, "Volt");
    Table->SetText(1, 0, "Current");
    Table->SetText(2, 0, "Prod (P)");
    Table->SetText(3, 0, "Cons (P)");
    Table->SetText(4, 0, "Prod (E)");
    Table->SetText(5, 0, "Cons (E)");

    Table->SetText(0, 4, "V");
    Table->SetText(1, 4, "A");
    Table->SetText(2, 4, "W");
    Table->SetText(3, 4, "W");
    Table->SetText(4, 4, "kWh");
    Table->SetText(5, 4, "kWh");
    Table->Show();

    SumTable = new TTableControl(control, 315, 280, 315, 135);
    SumTable->SetBackColor(0, 20, 50);
    SumTable->SetRowSpacing(8);
    SumTable->SetColSpacing(12);
    SumTable->SetSpacingColor(0, 20, 50);
    SumTable->AddLabelColumn(&CommentFactory, 100);
    SumTable->AddLabelColumn(&ValueFactory, 115);
    SumTable->AddLabelColumn(&UnitFactory, 65);

    SumTable->AddRow(25, 35);
    SumTable->AddRow(25, 35);
    SumTable->AddRow(25, 35);
    SumTable->AddRow(25, 35);

    SumTable->SetText(0, 0, "Prod (P)");
    SumTable->SetText(1, 0, "Cons (P)");
    SumTable->SetText(2, 0, "Prod (E)");
    SumTable->SetText(3, 0, "Cons (E)");

    SumTable->SetText(0, 2, "W");
    SumTable->SetText(1, 2, "W");
    SumTable->SetText(2, 2, "kWh");
    SumTable->SetText(3, 2, "kWh");

    SumTable->Show();

    UnlockGUI();

    sma.WaitForMeassure();

    RdosGetTime(&msb, &lsb);
    RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
    RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);

    ini.GotoSection("SMA");
    ok = ini.ReadVar("Date", str, 50);
    if (ok)
    {
        count = sscanf(str, "%04d%02d%02d", &pyear, &pmonth, &pday);
        if (count != 3)
            ok = FALSE;
    }

    if (ok)
        if (year != pyear || month != pmonth || day != pday)
            ok = FALSE;

    if (ok)
        ok = ini.ReadVar("Prod", str, 50);

    if (ok)
    {
        count = sscanf(str, "%Lf", &ProdBase);
        if (count != 1)
            ok = FALSE;
    }

    if (ok)
        ok = ini.ReadVar("Cons", str, 50);

    if (ok)
    {
        count = sscanf(str, "%Lf", &ConsBase);
        if (count != 1)
            ok = FALSE;
    }

    if (!ok)
    {
        sprintf(str, "%04d%02d%02d", year, month, day);
        ini.WriteVar("Date", str);

        val = sma.GetProduceEnergy();
        sprintf(str, "%5.3Lf", val);
        ini.WriteVar("Prod", str);

        val = sma.GetConsumeEnergy();
        sprintf(str, "%5.3Lf", val);
        ini.WriteVar("Cons", str);
    }

    currday = day;
    currmin = min;

    pcount = 0;
    p2sum = 0;
    p3sum = 0;

    for (;;)
    {
        sma.WaitForMeassure();

        for (p = 1; p <= 3; p++)
        {
            val = sma.GetVolt(p);
            sprintf(str, "%5.3Lf", val);
            Table->SetText(0, p, str);
        }

        for (p = 1; p <= 3; p++)
        {
            val = sma.GetCurrent(p);
            sprintf(str, "%5.3Lf", val);
            Table->SetText(1, p, str);
        }

        for (p = 1; p <= 3; p++)
        {
            val = sma.GetProducePower(p);
            sprintf(str, "%3.1Lf", val);
            Table->SetText(2, p, str);
        }

        for (p = 1; p <= 3; p++)
        {
            val = sma.GetConsumePower(p);
            sprintf(str, "%3.1Lf", val);
            Table->SetText(3, p, str);
        }

        for (p = 1; p <= 3; p++)
        {
            val = sma.GetProduceEnergy(p);
            sprintf(str, "%5.3Lf", val);
            Table->SetText(4, p, str);
        }

        for (p = 1; p <= 3; p++)
        {
            val = sma.GetConsumeEnergy(p);
            sprintf(str, "%5.3Lf", val);
            Table->SetText(5, p, str);
        }

        p2 = sma.GetProducePower(2);
        if (p2 < 1.0)
            p2 = -sma.GetConsumePower(2);

        p3 = sma.GetProducePower(3);
        if (p3 < 1.0)
            p3 = -sma.GetConsumePower(3);

        p2sum += p2;
        if (pcount)
        {
            if (p2 < p2min)
                p2min = p2;
        }
        else
            p2min = p2;

        p3sum += p3;
        if (pcount)
        {
            if (p3 < p3min)
                p3min = p3;
        }
        else
            p3min = p3;

        pcount++;

        val = sma.GetProducePower();
        sprintf(str, "%3.1Lf", val);
        SumTable->SetText(0, 1, str);
        NotifyProdPower(val);

        val = sma.GetConsumePower();
        sprintf(str, "%3.1Lf", val);
        SumTable->SetText(1, 1, str);
        NotifyConsPower(val);

        RdosGetTime(&msb, &lsb);
        RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
        RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);

        if (min != currmin)
        {
            if (invdelay)
                invdelay--;

            soc = PowInv->GetBatterySoc();
            maxca = PowInv->GetMaxChargeCurrent();

            if (soc < 0.7)
                PowInv->SetMaxChargeCurrent(70);
            else if (soc > 1.1)
                PowInv->SetMaxChargeCurrent(4);
            else
            {
                if (soc < 0.9)
                {
                    if (maxca < 5)
                        PowInv->SetMaxChargeCurrent(35);
                }
                else
                {
                    if (maxca > 25)
                        PowInv->SetMaxChargeCurrent(35);
                }
            }

            maxca = PowInv->GetMaxChargeCurrent();

            p2 = (p2sum / (double)pcount + p2min) / 2.0;
            p3 = (p3sum / (double)pcount + p3min) / 2.0;

            val = p2 + p3;

            if (PowInv->GetChargePrio() == 2)
                val += PowInv->GetGridPower();

            ca = (int)(val / 50.0);

            if (ca > maxca)
                ca = maxca;

            if (PowInv && !invdelay)
            {
                if (Ocpp->IsCharging())
                {
                    PowInv->SetChargePrio(3);

                    switch (PowInv->GetOutputPrio())
                    {
                        case 0:
                            if (soc > 0.6)
                                PowInv->SetOutputPrio(2);
                            break;

                        case 2:
                            if (soc < 0.4)
                                PowInv->SetOutputPrio(0);
                            break;
                    }
                }
                else
                {
                    if (ca > 5)
                    {
                        PowInv->SetOutputPrio(0);
                        PowInv->SetChargePrio(2);
                        PowInv->SetMaxGridChargeCurrent(ca);
                    }
                    else
                    {
                        PowInv->SetOutputPrio(2);
                        PowInv->SetChargePrio(3);
                    }
                }
            }

            pcount = 0;
            p2sum = 0.0;
            p3sum = 0.0;

            currmin = min;
        }

        if (day != currday)
        {
            val = sma.GetProduceEnergy();
            sprintf(str, "%5.3Lf", val);
            ini.WriteVar("Prod", str);
            NotifyProdDayEnergy(val - ProdBase);
            ProdBase = val;

            val = sma.GetConsumeEnergy();
            sprintf(str, "%5.3Lf", val);
            ini.WriteVar("Cons", str);
            NotifyConsDayEnergy(val - ConsBase);
            ConsBase = val;

            sprintf(str, "%04d%02d%02d", year, month, day);
            ini.WriteVar("Date", str);

            currday = day;
        }

        val = sma.GetProduceEnergy() - ProdBase;
        sprintf(str, "%5.3Lf", val);
        SumTable->SetText(2, 1, str);

        val = sma.GetConsumeEnergy() - ConsBase;
        sprintf(str, "%5.3Lf", val);
        SumTable->SetText(3, 1, str);
    }
}

/*##################  PerfThread  ##############################################
 *   Purpose....: Watchdog thread                                                                           #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-10-02 le                                                #
 *##########################################################################*/
void PerfThread(void *ptr)
{
    int width, height;
    int i;
    int Cores;
    TFont AxisFont(15);
    TChart *PerfChart[MAX_CORES];
    TTimeXAxis *XAxis[MAX_CORES];
    TLinYAxis *YAxis[MAX_CORES];
    long long CoreTicsArr[MAX_CORES];
    long long NullTicsArr[MAX_CORES];
    long long CoreTics;
    long long NullTics;
    long long CoreDiff;
    long long NullDiff;
    long double XVal;
    long double YVal;
    unsigned long Msb, Lsb;
    int Count = 0;

    for (Cores = 0; Cores < MAX_CORES; Cores++)
    {
        if (RdosGetCoreLoad(Cores, &NullTicsArr[Cores], &CoreTicsArr[Cores]))
        {
            XAxis[Cores] = new TTimeXAxis(&AxisFont);
            XAxis[Cores]->SetBackColor(0, 0, 0);
            XAxis[Cores]->SetForeColor(255, 255, 255);
            YAxis[Cores] = new TLinYAxis(&AxisFont);
            YAxis[Cores]->SetBackColor(0, 0, 0);
            YAxis[Cores]->SetForeColor(255, 255, 255);
            PerfChart[Cores] = new TChart(vbe, XAxis[Cores], YAxis[Cores]);
            PerfChart[Cores] = new TChart(vbe, XAxis[Cores], YAxis[Cores]);

            PerfChart[Cores]->SetWindow(635, 10 + Cores * 90, 900, 100 + Cores * 90);

            PerfChart[Cores]->SetBackColor(0, 0, 0);
            PerfChart[Cores]->SetLineColor(0, 50, 200, 100);
            PerfChart[Cores]->SetYAxis(0.0, 100.0);
        }
        else
            break;
    }

    for (;;)
    {
        RdosWaitMilli(1000);

        RdosGetTime(&Msb, &Lsb);
        XVal = (long double)Lsb / 65536.0 / 65536.0;
        XVal += (long double)Msb;

        for (i = 0; i < Cores; i++)
        {
            RdosGetCoreLoad(i, &NullTics, &CoreTics);
            CoreDiff = CoreTics - CoreTicsArr[i];
            NullDiff = NullTics - NullTicsArr[i];
            CoreTicsArr[i] = CoreTics;
            NullTicsArr[i] = NullTics;
            if (CoreDiff > 1192 * 500)
            {
                YVal = 100.0 - (long double)NullDiff / (long double)CoreDiff * 100.0;
                if (Count == MAX_SAMPLES)
                    PerfChart[i]->Remove(0);

                PerfChart[i]->Add(0, XVal, YVal);
                PerfChart[i]->Draw();
            }
        }
        if (Count < MAX_SAMPLES)
            Count++;

    }
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Main program
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main()
{
    TRad *RadArr[8];
    TVp *Vp;
    TDdns *Ddns;
    TFroniusInverter *SolarInv;
    TSmartPowInverter *WindInv;
    TMisolWeather *Misol;
    TMet *Met;
    THhcRelay *Relay;
    int i;
    int index;
    int diostat;
    TDateTime *CurrTime;
    int LastMin;
    int LastDay;
    int UsedDay;
    int mot;
    int circmax;
    int temp;
    int ref;
    int count;
    int temperr;
    int temperrmax;
    long double val;
    long double PowerSum = 0.0;
    int PowerCount = 0;
    int ival;
    long double winddir;
    long NtpIp;
    int SyncCount = 0;
    TFile *file;
    int init = 0x8000;
    int ambient;
    bool night;
    bool summer;
    int refsum;
    TFont Font(25);
    char str[80];
    int width;
    int height;
    TBitmapGraphicDevice *bitmap;
    TRadControl *RadControl;
    TSolar solar(55, 49, 5, 13, 14, 43);
    long double altitude;
    long double azimuth;
    long double phase;
    long double solalt;
    int ph;
    TDateTime currtime;
    TTableControl *Table;

    TLabelFactory CommentLabelFactory;
    TLabelFactory AltLabelFactory;
    TLabelFactory AziLabelFactory;
    TLabelFactory PhLabelFactory;

    TLabelFactory CommentFactory;
    TLabelFactory ValueFactory;
    TLabelFactory UnitFactory;

    TTableControl *WeatherTable;
    TTableControl *SolarTable;
    TTableControl *WindTable;

    RdosCreateThread(WatchdogThread, "Watdog", 0, 0x2000);

    RdosWaitMilli(2500);

    Ddns = new TDdns;
//    Ddns->UpdateIp();

    NtpIp = RdosNameToIp("pool.ntp.org");
    if (NtpIp)
        RdosSyncTime(NtpIp);

    TRdosDefaultLog Log("d:/log", 50, 128 * 1024, "Log", "");
    Log.Log(0, "", "Started");

    RdosWriteSerialVal(2, 0, 0);
    RdosWriteSerialVal(2, 1, 0);

    RdosWriteSerialRaw(0x10, 0, 1);

    vbe = new TVideoGraphicDevice(32, 1920, 1080);
    control = new TDisplayControlThread("Control", vbe);
    vbe->SetFont(&Font);

    vbe->SetDrawColor(0, 20, 50);
    vbe->SetFilledStyle();
    vbe->DrawRect(0, 0, vbe->GetWidth(), vbe->GetHeight());

    RadControl = new TRadControl(control, 5, 530, 765, 25 * 8);

    index = 0;

    for (i = 0; i < 8; i++)
    {
        str[0] = 0;

        switch (i)
        {
            case 0:
                strcpy(str, "Datarum");
                break;

            case 1:
                strcpy(str, "Vardagsrum, nedre plan");
                break;

            case 2:
                strcpy(str, "Rosa sovrum, nedre plan");
                break;

            case 3:
                strcpy(str, "Blått sovrum, nedre plan");
                break;

            case 4:
//                strcpy(str, "Kök");
                break;

            case 5:
                strcpy(str, "Sovrum, övre plan");
                break;

            case 7:
                strcpy(str, "Badrum");
                break;
        }

        if (strlen(str))
        {
            RadArr[index] = new TRad(str, RadControl, index, 0x20 + i);
            index++;
        }
    }

    for (i = index; i < 8; i++)
        RadArr[i] = 0;

    RdosWaitMilli(1000);

    SolarInv = new TFroniusInverter("192.168.1.51");
    WindInv = new TSmartPowInverter("192.168.1.100");
//    Misol = new TMisolWeather("192.168.1.57", 1234);
    Misol = new TMisolWeather("192.168.1.118", 5001);
    Met = new TMet(Misol);
    Ocpp = new TOcppSocketServerFactory(7000, 100, 0x1000);
    Relay = new THhcRelay("192.168.1.118:5000");

    TModbusDevice PowModbus(0x7701A8C0, 502);
    PowInv = new TPowHvmP(&PowModbus, 1);
    PowInv->StartLog("d:/inv");

    Vp = new TVp(control, Ocpp, Relay);

    InitWeb(Misol, SolarInv, WindInv, PowInv);

    ResetSolarWind();

    SolarInv->OnPower = NotifySolarPower;
    SolarInv->OnDayEnergy = NotifySolarDayEnergy;

    WindInv->OnGridPower = NotifyWindGridPower;
    WindInv->OnDumpPower = NotifyWindDumpPower;
    WindInv->OnDayEnergy = NotifyWindDayEnergy;

    Ocpp->OnState = NotifyOcppState;
    Ocpp->OnStart = NotifyOcppStart;
    Ocpp->OnStop = NotifyOcppStop;
    Ocpp->OnData = NotifyOcppData;

    RdosCreateThread(TimeThread, "Time", control, 0x4000);
    RdosCreateThread(PerfThread, "Perf", vbe, 0x4000);
    RdosCreateThread(SmaThread, "Sma", control, 0x4000);

    LockGUI();

    CommentLabelFactory.SetSpace(4, 4);
    CommentLabelFactory.SetFont(25);
    CommentLabelFactory.SetBackTransparent();
    CommentLabelFactory.SetDrawColor(0, 0, 0);
    CommentLabelFactory.AlignLeft();
    CommentLabelFactory.ForceNoScale();

    AltLabelFactory.SetSpace(4, 4);
    AltLabelFactory.SetFont(25);
    AltLabelFactory.SetBackColor(100, 100, 100);
    AltLabelFactory.SetDrawColor(0, 0, 0);
    AltLabelFactory.AlignRight();
    AltLabelFactory.ForceNoScale();

    AziLabelFactory.SetSpace(4, 4);
    AziLabelFactory.SetFont(25);
    AziLabelFactory.SetBackColor(100, 100, 100);
    AziLabelFactory.SetDrawColor(0, 0, 0);
    AziLabelFactory.AlignRight();
    AziLabelFactory.ForceNoScale();

    PhLabelFactory.SetSpace(4, 4);
    PhLabelFactory.SetFont(25);
    PhLabelFactory.SetBackColor(100, 100, 100);
    PhLabelFactory.SetDrawColor(0, 0, 0);
    PhLabelFactory.AlignRight();
    PhLabelFactory.ForceNoScale();

    Table = new TTableControl(control, 865, 550, 400, 265);
    Table->SetBackColor(0, 20, 50);
    Table->SetRowSpacing(8);
    Table->SetColSpacing(12);
    Table->SetSpacingColor(0, 20, 50);
    Table->AddLabelColumn(&CommentLabelFactory, 65);
    Table->AddLabelColumn(&AltLabelFactory, 80);
    Table->AddLabelColumn(&AziLabelFactory, 80);
    Table->AddLabelColumn(&PhLabelFactory, 80);

    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);
    Table->AddRow(25, 35);

    Table->SetText(0, 0, "Solen");
    Table->SetText(1, 0, "Månen");
    Table->SetText(2, 0, "Merkurius");
    Table->SetText(3, 0, "Venus");
    Table->SetText(4, 0, "Mars");
    Table->SetText(5, 0, "Jupiter");
    Table->SetText(6, 0, "Saturnus");
    Table->Show();

    CommentFactory.SetSpace(4, 4);
    CommentFactory.SetFont(25);
    CommentFactory.SetBackTransparent();
    CommentFactory.SetDrawColor(0, 0, 0);
    CommentFactory.AlignLeft();
    CommentFactory.ForceNoScale();

    ValueFactory.SetSpace(4, 4);
    ValueFactory.SetFont(25);
    ValueFactory.SetBackColor(100, 100, 100);
    ValueFactory.SetDrawColor(0, 0, 0);
    ValueFactory.AlignRight();
    ValueFactory.ForceNoScale();

    UnitFactory.SetSpace(4, 4);
    UnitFactory.SetFont(25);
    UnitFactory.SetBackTransparent();
    UnitFactory.SetDrawColor(0, 0, 0);
    UnitFactory.AlignLeft();
    UnitFactory.ForceNoScale();

    WeatherTable = new TTableControl(control, 5, 5, 300, 300);
    WeatherTable->SetBackColor(0, 20, 50);
    WeatherTable->SetRowSpacing(8);
    WeatherTable->SetColSpacing(12);
    WeatherTable->SetSpacingColor(0, 20, 50);
    WeatherTable->AddLabelColumn(&CommentFactory, 125);
    WeatherTable->AddLabelColumn(&ValueFactory, 100);
    WeatherTable->AddLabelColumn(&UnitFactory, 85);

    WeatherTable->AddRow(25, 35);
    WeatherTable->AddRow(25, 35);
    WeatherTable->AddRow(25, 35);
    WeatherTable->AddRow(25, 35);
    WeatherTable->AddRow(25, 35);
    WeatherTable->AddRow(25, 35);
    WeatherTable->AddRow(25, 35);
    WeatherTable->AddRow(25, 35);
    WeatherTable->AddRow(25, 35);

    WeatherTable->SetText(0, 0, "Temperature");
    WeatherTable->SetText(0, 2, "°C");

    WeatherTable->SetText(1, 0, "Wind");
    WeatherTable->SetText(1, 2, "m/s");

    WeatherTable->SetText(2, 0, "Gust");
    WeatherTable->SetText(2, 2, "m/s");

    WeatherTable->SetText(3, 0, "Direction");
    WeatherTable->SetText(3, 2, "");

    WeatherTable->SetText(4, 0, "Wind Chill");
    WeatherTable->SetText(4, 2, "°C");

    WeatherTable->SetText(5, 0, "Humidity");
    WeatherTable->SetText(5, 2, "%");

    WeatherTable->SetText(6, 0, "Rain");
    WeatherTable->SetText(6, 2, "mm");

    WeatherTable->SetText(7, 0, "UV");
    WeatherTable->SetText(7, 2, "W/m²");

    WeatherTable->SetText(8, 0, "Light");
    WeatherTable->SetText(8, 2, "Lux");

    WeatherTable->Show();

    WindTable = new TTableControl(control, 315, 5, 315, 180);
    WindTable->SetBackColor(0, 20, 50);
    WindTable->SetRowSpacing(8);
    WindTable->SetColSpacing(12);
    WindTable->SetSpacingColor(0, 20, 50);
    WindTable->AddLabelColumn(&CommentFactory, 100);
    WindTable->AddLabelColumn(&ValueFactory, 115);
    WindTable->AddLabelColumn(&UnitFactory, 65);

    WindTable->AddRow(25, 35);
    WindTable->AddRow(25, 35);
    WindTable->AddRow(25, 35);
    WindTable->AddRow(25, 35);
    WindTable->AddRow(25, 35);

    WindTable->SetText(0, 0, "State");
    WindTable->SetText(0, 2, "");

    WindTable->SetText(1, 0, "Error");
    WindTable->SetText(1, 2, "");

    WindTable->SetText(2, 0, "Power");
    WindTable->SetText(2, 2, "W");

    WindTable->SetText(3, 0, "Rotor");
    WindTable->SetText(3, 2, "rpm");

    WindTable->SetText(4, 0, "Day");
    WindTable->SetText(4, 2, "kWh");
    WindTable->Show();

    SolarTable = new TTableControl(control, 315, 200, 315, 85);
    SolarTable->SetBackColor(0, 20, 50);
    SolarTable->SetRowSpacing(8);
    SolarTable->SetColSpacing(12);
    SolarTable->SetSpacingColor(0, 20, 50);
    SolarTable->AddLabelColumn(&CommentFactory, 100);
    SolarTable->AddLabelColumn(&ValueFactory, 115);
    SolarTable->AddLabelColumn(&UnitFactory, 85);

    SolarTable->AddRow(25, 35);
    SolarTable->AddRow(25, 35);

    SolarTable->SetText(0, 0, "Power");
    SolarTable->SetText(0, 2, "W");

    SolarTable->SetText(1, 0, "Today");
    SolarTable->SetText(1, 2, "kWh");

    SolarTable->Show();

    UnlockGUI();

    CurrTime = new TDateTime;
    LastMin = CurrTime->GetMin();
    LastDay = CurrTime->GetDay();
    UsedDay = LastDay;
    CreateDayFile(CurrTime->GetYear(), CurrTime->GetMonth(), CurrTime->GetDay());
    delete CurrTime;

    for (;;)
    {
        CurrTime = new TDateTime;

        solar.SetTime(currtime, 1);
        solar.GetSunPosition(&altitude, &azimuth);

        solalt = altitude;

        sprintf(str, "%5.2Lf", altitude);
        Table->SetText(0, 1, str);

        sprintf(str, "%5.2Lf", azimuth);
        Table->SetText(0, 2, str);

        solar.GetMoonPosition(&altitude, &azimuth);
        phase = 100.0 * solar.GetMoonPhase();
        ph = (int)phase;

        sprintf(str, "%5.2Lf", altitude);
        Table->SetText(1, 1, str);

        sprintf(str, "%5.2Lf", azimuth);
        Table->SetText(1, 2, str);

        sprintf(str, "%d%", ph);
        Table->SetText(1, 3, str);

        solar.GetMercuryPosition(&altitude, &azimuth);
        phase = 100.0 * solar.GetMercuryPhase();
        ph = (int)phase;

        sprintf(str, "%5.2Lf", altitude);
        Table->SetText(2, 1, str);

        sprintf(str, "%5.2Lf", azimuth);
        Table->SetText(2, 2, str);

        sprintf(str, "%d%", ph);
        Table->SetText(2, 3, str);

        solar.GetVenusPosition(&altitude, &azimuth);
        phase = 100.0 * solar.GetVenusPhase();
        ph = (int)phase;

        sprintf(str, "%5.2Lf", altitude);
        Table->SetText(3, 1, str);

        sprintf(str, "%5.2Lf", azimuth);
        Table->SetText(3, 2, str);

        sprintf(str, "%d%", ph);
        Table->SetText(3, 3, str);

        solar.GetMarsPosition(&altitude, &azimuth);
        phase = 100.0 * solar.GetMarsPhase();
        ph = (int)phase;

        sprintf(str, "%5.2Lf", altitude);
        Table->SetText(4, 1, str);

        sprintf(str, "%5.2Lf", azimuth);
        Table->SetText(4, 2, str);

        sprintf(str, "%d%", ph);
        Table->SetText(4, 3, str);

        solar.GetJupiterPosition(&altitude, &azimuth);
        phase = 100.0 * solar.GetJupiterPhase();
        ph = (int)phase;

        sprintf(str, "%5.2Lf", altitude);
        Table->SetText(5, 1, str);

        sprintf(str, "%5.2Lf", azimuth);
        Table->SetText(5, 2, str);

        sprintf(str, "%d%", ph);
        Table->SetText(5, 3, str);

        solar.GetSaturnPosition(&altitude, &azimuth);
        phase = 100.0 * solar.GetSaturnPhase();
        ph = (int)phase;

        sprintf(str, "%5.2Lf", altitude);
        Table->SetText(6, 1, str);

        sprintf(str, "%5.2Lf", azimuth);
        Table->SetText(6, 2, str);

        sprintf(str, "%d%", ph);
        Table->SetText(6, 3, str);

        if (SolarInv->IsOnline())
        {
            val = SolarInv->GetCurrentPower();
            if (val < 11000.0 && val >= 0.0)
            {
                PowerSum += val;
                ival = (int)val;
                sprintf(str, "%d", ival);
            }
            else
                strcpy(str, "err");
            SolarTable->SetText(0, 1, str);

            val = SolarInv->GetDayEnergy() / 1000.0;
            if (val < 100.0 && val >= 0)
                sprintf(str, "%7.3Lf", val);
            else
                strcpy(str, "err");
            SolarTable->SetText(1, 1, str);
        }

        if (WindInv->IsOnline())
        {
            WindInv->GetCurrentState(str);
            WindTable->SetText(0, 1, str);

            WindInv->GetCurrentError(str);
            WindTable->SetText(1, 1, str);

            val = WindInv->GetCurrentGrid();
            ival = (int)val;
            sprintf(str, "%d", ival);
            WindTable->SetText(2, 1, str);

            PowerSum += val;
            PowerCount++;

            val = WindInv->GetCurrentRpm();
            sprintf(str, "%7.1Lf", val);
            WindTable->SetText(3, 1, str);

            val = WindInv->GetDayEnergy();
            sprintf(str, "%7.1Lf", val);
            WindTable->SetText(4, 1, str);
        }

        if (Misol->IsOnline())
        {
            bool valid = false;
            double temp;

            val = Misol->GetTemperature();
            temp = val;
            sprintf(str, "%5.1Lf", val);
            ambient = (int)(10.0 * val);
            WeatherTable->SetText(0, 1, str);

            val = Misol->GetWindSpeed();
            sprintf(str, "%5.1Lf", val);
            temp = CalcWindChill(temp, val);
            ambient = (int)(10.0 * temp);
            WeatherTable->SetText(1, 1, str);

            val = Misol->GetWindGust();
            sprintf(str, "%5.1Lf", val);
            WeatherTable->SetText(2, 1, str);

            val = Misol->GetWindDir();
            ival = (int)val;

            if (ival >= 350 || ival <= 11)
                strcpy(str,"N");

            if (ival >= 12 && ival <= 34)
                strcpy(str,"NNO");

            if (ival >= 35 && ival <= 56)
                strcpy(str,"NO");

            if (ival >= 57 && ival <= 79)
                strcpy(str,"ONO");

            if (ival >= 80 && ival <= 101)
                strcpy(str,"O");

            if (ival >= 102 && ival <= 124)
                strcpy(str,"OSO");

            if (ival >= 125 && ival <= 146)
                strcpy(str,"SO");

            if (ival >= 147 && ival <= 169)
                strcpy(str,"SSO");

            if (ival >= 170 && ival <= 191)
                strcpy(str,"S");

            if (ival >= 192 && ival <= 214)
                strcpy(str,"SSV");

            if (ival >= 215 && ival <= 236)
                strcpy(str,"SV");

            if (ival >= 237 && ival <= 259)
                strcpy(str,"VSV");

            if (ival >= 260 && ival <= 281)
                strcpy(str,"V");

            if (ival >= 282 && ival <= 304)
                strcpy(str,"VNV");

            if (ival >= 305 && ival <= 326)
                strcpy(str,"NV");

            if (ival >= 327 && ival <= 349)
                strcpy(str,"NNV");

            WeatherTable->SetText(3, 1, str);

            sprintf(str, "%5.1Lf", temp);
            WeatherTable->SetText(4, 1, str);

            val = Misol->GetHumidity();
            ival = (int)val;
            sprintf(str, "%d", ival);
            WeatherTable->SetText(5, 1, str);

            val = Misol->GetRain();
            sprintf(str, "%5.1Lf", val);
            WeatherTable->SetText(6, 1, str);

            val = Misol->GetUv();
            sprintf(str, "%5.1Lf", val);
            WeatherTable->SetText(7, 1, str);

            val = Misol->GetLight();
            sprintf(str, "%5.1Lf", val);
            WeatherTable->SetText(8, 1, str);
        }
        else
            ambient = 50;

        str[0] = 0;

        if (RdosReadSerialLines(1, &diostat))
        {
            currtime = TDateTime();

            solar.SetTime(currtime, 1);
            solar.GetSunPosition(&altitude, &azimuth);

            if (altitude < -5.0)
            {
                if ((diostat & 0x80) == 0)
                    RdosToggleSerialLine(1, 7);

                if (!Relay->IsOn(7))
                    Relay->On(7);
            }
            else
            {
                if (diostat & 0x80)
                    RdosToggleSerialLine(1, 7);

                if (Relay->IsOn(7))
                    Relay->Off(7);
            }
        }

        if (LastMin != CurrTime->GetMin())
        {
            WdTimeout = 2 * 100;

            if (PowerCount)
            {
                Vp->SetPower(PowerSum / PowerCount);
                PowerSum = 0;
                PowerCount = 0;
            }

            if (LastDay != CurrTime->GetDay())
            {
                LastDay = CurrTime->GetDay();
                PowInv->ClearEnergy();
                CreateDayFile(CurrTime->GetYear(), CurrTime->GetMonth(), CurrTime->GetDay());
            }

            LastMin = CurrTime->GetMin();
            UpdateDataStore(CurrTime->GetHour(), CurrTime->GetMin());

            if (SolarNewDayE && (WindNewDayE || WindDayE == 0.0))
                UpdateMonthData();
        }

        summer = false;

        if (CurrTime->GetMonth() >= 6 && CurrTime->GetMonth() <= 8)
            summer = true;

        if (!summer)
        {
            night = false;
            if (CurrTime->GetHour() >= 19)
                night = true;
            else
                if (CurrTime->GetHour() < 5)
                    night = true;
        }

        delete CurrTime;

        count = 0;
        circmax = 0;
        temperrmax = 255;
        refsum = 0;

        for (i = 0; i < 8; i++)
        {
            if (i != 4 && RadArr[i] && RadArr[i]->IsOnline())
            {
                count++;

                mot = RadArr[i]->GetMotor();
                if (mot > circmax)
                    circmax = mot;

                temp = RadArr[i]->GetTemp();
                ref = RadArr[i]->GetRef();

                refsum += ref;

                temperr = temp - ref;

                if (temperr < temperrmax)
                    temperrmax = temperr;

                if (summer)
                    RadArr[i]->SetSummerRef();
                else
                {
                    if (night)
                    {
                        if (ambient < 50)
                            RadArr[i]->SetDayRef();
                        else
                            RadArr[i]->SetNightRef();
                    }
                    else
                        RadArr[i]->SetDayRef();
                }

                RadArr[i]->SetAmbient(ambient);
             }
        }

        if (count)
            Vp->SetMaxMotor(circmax);

        if (count)
        {
            Vp->SetTempError(temperrmax);
            Vp->SetAmbient(refsum / count, ambient, night);
        }

        RdosWaitMilli(1000);

        if (SyncCount == 360)
        {
            NtpIp = RdosNameToIp("pool.ntp.org");
            if (NtpIp)
                RdosSyncTime(NtpIp);
             SyncCount = 0;
        }
        else
             SyncCount++;

    }
}

