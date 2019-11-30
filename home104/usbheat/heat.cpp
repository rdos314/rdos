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
#include "openweather.h"
#include "rad.h"
#include "datetime.h"
#include "vp.h"
#include "videodev.h"
#include "radcntrl.h"
#include "solar.h"
#include "table.h"
#include "jpeg.h"
#include "file.h"
#include "web.h"
#include "rdoslog.h"
#include "chart.h"
#include "timeaxis.h"
#include "linyaxis.h"
#include "png.h"

int GetWebConnectionCount();

#define FALSE   0
#define TRUE    !FALSE

#define MAX_CORES   4
#define MAX_SAMPLES 5 * 60

#define ROOT_DIR "e:/data/power"
#define CSV_DAY_HEADER "time;solar;grid;dump\r\n"
#define CSV_MONTH_HEADER "day;solar;wind\r\n"

#define WIDTH 240
#define HEIGHT 15

TGraphicDevice *vbe;
TControlThread *control;
TSection FGuiSection;

TSection FDataSection;
static TFile *DayFile = 0;

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
    sprintf(str, "%d.%01d\r\n", val / 10, val % 10);
    File->Write(str, strlen(str));

    delete File;

    SolarNewDayE = 0;
    WindNewDayE = 0;
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
    TTableControl *Table;
    TLabelFactory CommentFactory;
    TLabelFactory ValueFactory;
    TLabelFactory ChangeFactory;
    TLabelControl *Label;
    int year, month, day;
    int hour, min, sec;
    int ms, us;
    unsigned long msb, lsb;
    char str[100];
    int count;
    int Gdt;
    int GdtBase;
    int Handle;
    int HandleBase;
    unsigned int Mem;
    unsigned int MemBase;
    long long PhysMem;
    long long PhysBase;
    long long PhysDiff;
    int mb;
    int kb;

    RdosWaitMilli(5000);

    GdtBase = RdosGetFreeGdt();
    HandleBase = RdosGetFreeHandles();
    MemBase = (unsigned int)RdosGetFreeBigLocalLinear();
    PhysBase = RdosGetFreePhysical();

    LockGUI();

    CommentFactory.SetSpace(4, 4);
    CommentFactory.SetFont(30);
    CommentFactory.SetBackTransparent();
    CommentFactory.SetDrawColor(0, 0, 0);
    CommentFactory.AlignLeft();
    
    ValueFactory.SetSpace(4, 4);
    ValueFactory.SetFont(30);
    ValueFactory.SetBackColor(100, 100, 100);
    ValueFactory.SetDrawColor(0, 0, 0);
    ValueFactory.AlignRight();

    ChangeFactory.SetSpace(4, 4);
    ChangeFactory.SetFont(30);
    ChangeFactory.SetBackColor(100, 100, 100);
    ChangeFactory.SetDrawColor(0, 0, 0);
    ChangeFactory.AlignRight();

    Table = new TTableControl(control, 1400, 100, 500, 400);
    Table->SetBackColor(0, 20, 50);
    Table->SetRowSpacing(10);
    Table->SetColSpacing(16);
    Table->SetSpacingColor(0, 20, 50);
    Table->AddLabelColumn(&CommentFactory, 150);
    Table->AddLabelColumn(&ValueFactory, 150);
    Table->AddLabelColumn(&ChangeFactory, 150);

    Table->AddRow(35, 55);
    Table->AddRow(35, 55);
    Table->AddRow(35, 55);
    Table->AddRow(35, 55);
    Table->AddRow(35, 55);

    Table->SetText(0, 0, "GDT");
    Table->SetText(1, 0, "Handles");
    Table->SetText(2, 0, "App mem");
    Table->SetText(3, 0, "Phys mem");
    Table->SetText(4, 0, "Connections");
    Table->Show();

    Label = new TLabelControl(control, 1600, 5, 300, 35);
    Label->SetFont(30);
    Label->SetBackColor(100, 100, 100);
    Label->SetDrawColor(0, 0, 0);
    Label->Show();

    UnlockGUI();

    for (;;)
    {
        Gdt = RdosGetFreeGdt();
        sprintf(str, "%d", Gdt);
        Table->SetText(0, 1, str);
        sprintf(str, "%d", Gdt - GdtBase);
        Table->SetText(0, 2, str);

        Handle = RdosGetFreeHandles();
        sprintf(str, "%d", Handle);
        Table->SetText(1, 1, str);
        sprintf(str, "%d", Handle - HandleBase);
        Table->SetText(1, 2, str);

        Mem = (unsigned int)RdosGetFreeBigLocalLinear();
        mb = Mem / 1024 / 1024;
        kb = Mem - mb * 1024 * 1024;
        kb = kb * 1000 / 1024;
        kb = kb * 100 / 1024;
        sprintf(str, "%d.%05d", mb, kb);
        Table->SetText(2, 1, str);

        kb = Mem - MemBase;
        kb = kb / 1024;
        sprintf(str, "%d", kb);
        Table->SetText(2, 2, str);

        PhysMem = RdosGetFreePhysical();
        mb = (int)(PhysMem / 1024LL / 1024LL);
        kb = PhysMem - (long long)mb * 1024LL * 1024LL;
        kb = kb * 1000 / 1024;
        kb = kb * 100 / 1024;
        sprintf(str, "%d.%05d", mb, kb);
        Table->SetText(3, 1, str);

        PhysDiff = (PhysMem - PhysBase) / 1024;
        kb = (int)PhysDiff;
        sprintf(str, "%d", kb);
        Table->SetText(3, 2, str);

        count = GetWebConnectionCount();
        sprintf(str, "%d", count);
        Table->SetText(4, 1, str);

        RdosGetTime(&msb, &lsb);
        RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
        RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);
    
        sprintf(str, "%04d-%02d-%02d %02d.%02d.%02d",
                        year, month, day,
                        hour, min, sec);
        Label->SetText(str);

        RdosWaitMilli(200);
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
    TChart *FreqChart;
    TTimeXAxis *FreqXAxis;
    TLinYAxis *FreqYAxis;
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
    char CpuVendor[80];
    int CpuVer;
    int FeatureBits;
    int Freq;

    FreqXAxis = new TTimeXAxis(&AxisFont);
    FreqXAxis->SetBackColor(0, 0, 0);
    FreqXAxis->SetForeColor(255, 255, 255);
    FreqYAxis = new TLinYAxis(&AxisFont);
    FreqYAxis->SetBackColor(0, 0, 0);
    FreqYAxis->SetForeColor(255, 255, 255);
    FreqChart = new TChart(vbe, FreqXAxis, FreqYAxis);

    FreqChart->SetWindow(1500, 470, 1790, 610);
    FreqChart->SetBackColor(0, 0, 0);
    FreqChart->SetLineColor(0, 50, 200, 100);
    FreqChart->SetYAxis(1000.0, 3000.0);

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

            PerfChart[Cores]->SetWindow(1100, 20 + Cores * 150, 1390, 160 + Cores * 150);

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

        CpuVer = RdosGetCpuVersion(CpuVendor, &FeatureBits, &Freq);
        YVal = (long double)Freq;
        if (Count == MAX_SAMPLES)
            FreqChart->Remove(0);

        FreqChart->Add(0, XVal, YVal);                    
        FreqChart->Draw();

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
    TFroniusInverter *SolarInv;
    TSmartPowInverter *WindInv;
    TOpenWeather *w;
    int i;
    int index;
    int diostat;
    int mask;
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
    TLabelControl *Label;
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

    NtpIp = RdosNameToIp("pool.ntp.org");
    if (NtpIp)
        RdosSyncTime(NtpIp);

    TRdosDefaultLog Log("d:/log", 50, 128 * 1024, "Log", "");
    Log.Log(0, "", "Started");

    InitWeb();

    RdosWriteSerialVal(2, 0, 0);
    RdosWriteSerialVal(2, 1, 0);

    RdosWriteSerialRaw(0x10, 0, 1);

    vbe = new TVideoGraphicDevice(32, 1920, 1080);
    control = new TDisplayControlThread("Control", vbe);
    vbe->SetFont(&Font);

    vbe->SetDrawColor(0, 20, 50);
    vbe->SetFilledStyle();
    vbe->DrawRect(0, 0, vbe->GetWidth(), vbe->GetHeight());

    RadControl = new TRadControl(control, 5, 640, 1150, 35 * 8);

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

    Vp = new TVp(control);

    SolarInv = new TFroniusInverter("192.168.1.51");
    WindInv = new TSmartPowInverter("192.168.1.100");
    w = new TOpenWeather("2715946", "c88ba239c78cdbea4c1fe561ad4f7b3d");

    ResetSolarWind();

    SolarInv->OnPower = NotifySolarPower;
    SolarInv->OnDayEnergy = NotifySolarDayEnergy;

    WindInv->OnGridPower = NotifyWindGridPower;
    WindInv->OnDumpPower = NotifyWindDumpPower;
    WindInv->OnDayEnergy = NotifyWindDayEnergy;

    RdosCreateThread(TimeThread, "Time", control, 0x4000);
    RdosCreateThread(PerfThread, "Perf", vbe, 0x4000);

    LockGUI();
    Label = new TLabelControl(control, 1700, 50, 200, 35);
    Label->SetFont(35);
    Label->SetBackColor(0, 20, 50);
    Label->SetDrawColor(255, 255, 255);
    Label->SetText("");
    Label->Show();

    CommentLabelFactory.SetSpace(4, 4);
    CommentLabelFactory.SetFont(35);
    CommentLabelFactory.SetBackTransparent();
    CommentLabelFactory.SetDrawColor(0, 0, 0);
    CommentLabelFactory.AlignLeft();
    
    AltLabelFactory.SetSpace(4, 4);
    AltLabelFactory.SetFont(35);
    AltLabelFactory.SetBackColor(100, 100, 100);
    AltLabelFactory.SetDrawColor(0, 0, 0);
    AltLabelFactory.AlignRight();
    
    AziLabelFactory.SetSpace(4, 4);
    AziLabelFactory.SetFont(35);
    AziLabelFactory.SetBackColor(100, 100, 100);
    AziLabelFactory.SetDrawColor(0, 0, 0);
    AziLabelFactory.AlignRight();
    
    PhLabelFactory.SetSpace(4, 4);
    PhLabelFactory.SetFont(35);
    PhLabelFactory.SetBackColor(100, 100, 100);
    PhLabelFactory.SetDrawColor(0, 0, 0);
    PhLabelFactory.AlignRight();

    Table = new TTableControl(control, 1250, 675, 800, 400);
    Table->SetBackColor(0, 20, 50);
    Table->SetRowSpacing(10);
    Table->SetColSpacing(16);
    Table->SetSpacingColor(0, 20, 50);
    Table->AddLabelColumn(&CommentLabelFactory, 150);
    Table->AddLabelColumn(&AltLabelFactory, 125);
    Table->AddLabelColumn(&AziLabelFactory, 125);
    Table->AddLabelColumn(&PhLabelFactory, 125);

    Table->AddRow(35, 55);
    Table->AddRow(35, 55);
    Table->AddRow(35, 55);
    Table->AddRow(35, 55);
    Table->AddRow(35, 55);
    Table->AddRow(35, 55);
    Table->AddRow(35, 55);

    Table->SetText(0, 0, "Solen");
    Table->SetText(1, 0, "Månen");
    Table->SetText(2, 0, "Merkurius");
    Table->SetText(3, 0, "Venus");
    Table->SetText(4, 0, "Mars");
    Table->SetText(5, 0, "Jupiter");
    Table->SetText(6, 0, "Saturnus");
    Table->Show();

    CommentFactory.SetSpace(4, 4);
    CommentFactory.SetFont(35);
    CommentFactory.SetBackTransparent();
    CommentFactory.SetDrawColor(0, 0, 0);
    CommentFactory.AlignLeft();
    
    ValueFactory.SetSpace(4, 4);
    ValueFactory.SetFont(35);
    ValueFactory.SetBackColor(100, 100, 100);
    ValueFactory.SetDrawColor(0, 0, 0);
    ValueFactory.AlignRight();

    UnitFactory.SetSpace(4, 4);
    UnitFactory.SetFont(35);
    UnitFactory.SetBackTransparent();
    UnitFactory.SetDrawColor(0, 0, 0);
    UnitFactory.AlignLeft();

    WeatherTable = new TTableControl(control, 5, 5, 500, 250);
    WeatherTable->SetBackColor(0, 20, 50);
    WeatherTable->SetRowSpacing(10);
    WeatherTable->SetColSpacing(16);
    WeatherTable->SetSpacingColor(0, 20, 50);
    WeatherTable->AddLabelColumn(&CommentFactory, 250);
    WeatherTable->AddLabelColumn(&ValueFactory, 125);
    WeatherTable->AddLabelColumn(&UnitFactory, 125);

    WeatherTable->AddRow(35, 55);
    WeatherTable->AddRow(35, 55);
    WeatherTable->AddRow(35, 55);
    WeatherTable->AddRow(35, 55);
    WeatherTable->AddRow(35, 55);

    WeatherTable->SetText(0, 0, "Temperature");
    WeatherTable->SetText(0, 2, "°C");

    WeatherTable->SetText(1, 0, "Wind");
    WeatherTable->SetText(1, 2, "m/s");

    WeatherTable->SetText(2, 0, "Pressure");
    WeatherTable->SetText(2, 2, "hPa");

    WeatherTable->SetText(3, 0, "Humidity");
    WeatherTable->SetText(3, 2, "%");

    WeatherTable->SetText(4, 0, "Wind Chill");
    WeatherTable->SetText(4, 2, "°C");

    WeatherTable->Show();

    SolarTable = new TTableControl(control, 550, 350, 500, 150);
    SolarTable->SetBackColor(0, 20, 50);
    SolarTable->SetRowSpacing(10);
    SolarTable->SetColSpacing(16);
    SolarTable->SetSpacingColor(0, 20, 50);
    SolarTable->AddLabelColumn(&CommentFactory, 175);
    SolarTable->AddLabelColumn(&ValueFactory, 175);
    SolarTable->AddLabelColumn(&UnitFactory, 100);

    SolarTable->AddRow(35, 55);
    SolarTable->AddRow(35, 55);

    SolarTable->SetText(0, 0, "Effekt");
    SolarTable->SetText(0, 2, "W");

    SolarTable->SetText(1, 0, "Idag");
    SolarTable->SetText(1, 2, "kWh");

    SolarTable->Show();

    WindTable = new TTableControl(control, 550, 5, 500, 300);
    WindTable->SetBackColor(0, 20, 50);
    WindTable->SetRowSpacing(10);
    WindTable->SetColSpacing(16);
    WindTable->SetSpacingColor(0, 20, 50);
    WindTable->AddLabelColumn(&CommentFactory, 175);
    WindTable->AddLabelColumn(&ValueFactory, 175);
    WindTable->AddLabelColumn(&UnitFactory, 100);

    WindTable->AddRow(35, 55);
    WindTable->AddRow(35, 55);
    WindTable->AddRow(35, 55);
    WindTable->AddRow(35, 55);
    WindTable->AddRow(35, 55);
    WindTable->AddRow(35, 55);

    WindTable->SetText(0, 0, "State");
    WindTable->SetText(0, 2, "");

    WindTable->SetText(1, 0, "Error");
    WindTable->SetText(1, 2, "");

    WindTable->SetText(2, 0, "Grid");
    WindTable->SetText(2, 2, "W");

    WindTable->SetText(3, 0, "Dump");
    WindTable->SetText(3, 2, "W");

    WindTable->SetText(4, 0, "Rotor");
    WindTable->SetText(4, 2, "rpm");

    WindTable->SetText(5, 0, "Day");
    WindTable->SetText(5, 2, "kWh");

    WindTable->Show();

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

            val = WindInv->GetCurrentDump();
            ival = (int)val;
            sprintf(str, "%d", ival);
            WindTable->SetText(3, 1, str);

            val = WindInv->GetCurrentRpm();
            sprintf(str, "%7.1Lf", val);
            WindTable->SetText(4, 1, str);

            val = WindInv->GetDayEnergy();
            sprintf(str, "%7.1Lf", val);
            WindTable->SetText(5, 1, str);
        }

        if (w->IsOnline())
        {
            bool valid = false;
            double temp;

            val = w->GetTemperature();
            if (val < 100.0 && val > -100.0)  
            {
                sprintf(str, "%5.1Lf", val);
                ambient = (int)(10.0 * val);

                temp = val;
                valid = true;
            }
            else
                strcpy(str, "err");
            WeatherTable->SetText(0, 1, str);

            val = w->GetWindSpeed();
            if (val < 100.0 && val >= 0.0)
            {
                sprintf(str, "%5.1Lf", val);
                
                if (valid)
                    temp = CalcWindChill(temp, val);
            }
            else
            {
                strcpy(str, "err");
                valid = false;
            }
            WeatherTable->SetText(1, 1, str);

            if (valid)
            {
                ambient = (int)(10.0 * temp);
                sprintf(str, "%5.1Lf", temp);
            }
            else
                strcpy(str, "err");
            WeatherTable->SetText(4, 1, str);

            val = w->GetPressure();
            if (val < 2000.0 && val > 0.0)
            {
                ival = (int)val;
                sprintf(str, "%d", ival);
            }
            else
                strcpy(str, "err");
            WeatherTable->SetText(2, 1, str);

            val = w->GetHumidity();
            if (val <= 100.0 && val >= 0)
            {
                ival = (int)val;
                sprintf(str, "%d", ival);
            }
            else
                strcpy(str, "err");
            WeatherTable->SetText(3, 1, str);
        }
        else
            ambient = 50;

        str[0] = 0;

        if (RdosReadSerialLines(1, &diostat))
        {
            mask = 0x80;
            for (i = 0; i < 8; i++)
            {
                if (diostat & mask)
                    strcat(str, "1");
                else
                    strcat(str, "0");
                mask = mask >> 1;
            }

            currtime = TDateTime();
            
            solar.SetTime(currtime, 1);
            solar.GetSunPosition(&altitude, &azimuth);

            if (altitude < -5.0)
            {
                if ((diostat & 0x80) == 0)
                    RdosToggleSerialLine(1, 7);
            }
            else
            {
                if (diostat & 0x80)
                    RdosToggleSerialLine(1, 7);
            }
        }
        else
            strcpy(str, "------");

        Label->SetText(str);

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
                CreateDayFile(CurrTime->GetYear(), CurrTime->GetMonth(), CurrTime->GetDay());
            }

            LastMin = CurrTime->GetMin();
            UpdateDataStore(CurrTime->GetHour(), CurrTime->GetMin());

            if (SolarNewDayE && WindNewDayE)
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

        if (SyncCount == 3600)
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

