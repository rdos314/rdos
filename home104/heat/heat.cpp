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
#include "openweather.h"
#include "rad.h"
#include "datetime.h"
#include "circ.h"
#include "vp.h"
// #include "climate.h"
#include "power.h"
#include "videodev.h"
#include "radcntrl.h"
#include "solar.h"
#include "table.h"
#include "jpeg.h"
#include "datastor.h"

#define FALSE   0
#define TRUE    !FALSE

#define WIDTH 240
#define HEIGHT 15

TControlThread *control;
TSection FGuiSection;

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
    char str[100];

    LockGUI();

    Label = new TLabelControl(control, 5, 330, 200, 30);
    Label->SetFont(20);
    Label->SetBackColor(100, 100, 100);
    Label->SetDrawColor(0, 0, 0);
    Label->Show();

    UnlockGUI();

    for (;;)
    {
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

int main()
{
    TRad *RadArr[8];
    TCirc *Circ;
    TVp *Vp;
    TPower *Power;
    TFroniusInverter *SolarInv;
    TOpenWeather *w;
//    TClimate *Climate;
    int i;
    int id;
    int diostat;
    int mask;
    TDateTime *CurrTime;
    int mot;
    int circmax;
    int temp;
    int ref;
    int count;
    int temperr;
    int temperrmax;
    long double val;
    int ival;
    long double winddir;
    long NtpIp;
    int SyncCount = 0;
    TFile *file;
    int init = 0x8000;
    int ambient;
    int night;
    int summer;
    int refsum;
    TGraphicDevice *vbe;
    TFont Font(25);
    char str[80];
    int width;
    int height;
    TBitmapGraphicDevice *bitmap;
    TRadControl *RadControl;
    TDataStore *Store;
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

    TLabelFactory SolarCommentFactory;
    TLabelFactory SolarValueFactory;
    TLabelFactory SolarUnitFactory;

    TTableControl *SolarTable;
    
    RdosWaitMilli(2500);

    RdosWriteSerialVal(2, 0, 0);
    RdosWriteSerialVal(2, 1, 0);

    RdosWriteSerialRaw(0x10, 0, 1);

    NtpIp = RdosNameToIp("ntp.lth.se");
    RdosSyncTime(NtpIp);

    vbe = new TVideoGraphicDevice(32, 1280, 1024);
//    vbe = new TVideoGraphicDevice(32, 1280, 768);
    control = new TDisplayControlThread("Control", vbe);
    vbe->SetFont(&Font);

    Store = new TDataStore;

//    bitmap = TJpegBitmapDevice::Create("d:\\heat\\back.jpg");
//    vbe->Blit(bitmap, 0, 0, 0, 0, 1280, 768);

    vbe->SetDrawColor(0, 20, 50);
    vbe->SetFilledStyle();
    vbe->DrawRect(0, 0, vbe->GetWidth(), vbe->GetHeight());

    RadControl = new TRadControl(control, 5, 500, 785, 30 * 7);

    id = 0;
    
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
                strcpy(str, "Kök");
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
            RadArr[id] = new TRad(str, RadControl, id, 0x20 + i);
            Store->Add(RadArr[id]);
            id++;
        }
    }

    RdosWaitMilli(1000);

    Circ = new TCirc(vbe);
    Store->Add(Circ);

    Vp = new TVp(control);
    Store->Add(Vp);

    SolarInv = new TFroniusInverter("192.168.1.51");
    w = new TOpenWeather("2715946", "c88ba239c78cdbea4c1fe561ad4f7b3d");

//    Climate = new TClimate(control);
//    Store->Add(Climate);

    Power = new TPower(control);
    Store->Add(Power);

    RdosCreateThread(TimeThread, "Time", control, 0x4000);

    LockGUI();
    Label = new TLabelControl(control, 5, 300, 200, 30);
    Label->SetFont(20);
    Label->SetBackColor(0, 20, 50);
    Label->SetDrawColor(255, 255, 255);
    Label->SetText("");
    Label->Show();

    CommentLabelFactory.SetSpace(4, 4);
    CommentLabelFactory.SetFont(20);
    CommentLabelFactory.SetBackTransparent();
    CommentLabelFactory.SetDrawColor(0, 0, 0);
    CommentLabelFactory.AlignLeft();
    
    AltLabelFactory.SetSpace(4, 4);
    AltLabelFactory.SetFont(20);
    AltLabelFactory.SetBackColor(100, 100, 100);
    AltLabelFactory.SetDrawColor(0, 0, 0);
    AltLabelFactory.AlignRight();
    
    AziLabelFactory.SetSpace(4, 4);
    AziLabelFactory.SetFont(20);
    AziLabelFactory.SetBackColor(100, 100, 100);
    AziLabelFactory.SetDrawColor(0, 0, 0);
    AziLabelFactory.AlignRight();
    
    PhLabelFactory.SetSpace(4, 4);
    PhLabelFactory.SetFont(20);
    PhLabelFactory.SetBackColor(100, 100, 100);
    PhLabelFactory.SetDrawColor(0, 0, 0);
    PhLabelFactory.AlignRight();

    Table = new TTableControl(control, 850, 300, 400, 220);
    Table->SetBackColor(0, 20, 50);
    Table->SetRowSpacing(5);
    Table->SetColSpacing(8);
    Table->SetSpacingColor(0, 20, 50);
    Table->AddLabelColumn(&CommentLabelFactory, 120);
    Table->AddLabelColumn(&AltLabelFactory, 75);
    Table->AddLabelColumn(&AziLabelFactory, 75);
    Table->AddLabelColumn(&PhLabelFactory, 75);

    Table->AddRow(24, 45);
    Table->AddRow(24, 45);
    Table->AddRow(24, 45);
    Table->AddRow(24, 45);
    Table->AddRow(24, 45);
    Table->AddRow(24, 45);
    Table->AddRow(24, 45);

    Table->SetText(0, 0, "Solen");
    Table->SetText(1, 0, "Månen");
    Table->SetText(2, 0, "Merkurius");
    Table->SetText(3, 0, "Venus");
    Table->SetText(4, 0, "Mars");
    Table->SetText(5, 0, "Jupiter");
    Table->SetText(6, 0, "Saturnus");
    Table->Show();

    SolarCommentFactory.SetSpace(4, 4);
    SolarCommentFactory.SetFont(20);
    SolarCommentFactory.SetBackTransparent();
    SolarCommentFactory.SetDrawColor(0, 0, 0);
    SolarCommentFactory.AlignLeft();
    
    SolarValueFactory.SetSpace(4, 4);
    SolarValueFactory.SetFont(20);
    SolarValueFactory.SetBackColor(100, 100, 100);
    SolarValueFactory.SetDrawColor(0, 0, 0);
    SolarValueFactory.AlignRight();

    SolarUnitFactory.SetSpace(4, 4);
    SolarUnitFactory.SetFont(20);
    SolarUnitFactory.SetBackTransparent();
    SolarUnitFactory.SetDrawColor(0, 0, 0);
    SolarUnitFactory.AlignLeft();

    SolarTable = new TTableControl(control, 850, 50, 400, 200);
    SolarTable->SetBackColor(0, 20, 50);
    SolarTable->SetRowSpacing(5);
    SolarTable->SetColSpacing(8);
    SolarTable->SetSpacingColor(0, 20, 50);
    SolarTable->AddLabelColumn(&SolarCommentFactory, 120);
    SolarTable->AddLabelColumn(&SolarValueFactory, 100);
    SolarTable->AddLabelColumn(&SolarUnitFactory, 75);

    SolarTable->AddRow(24, 45);
    SolarTable->AddRow(24, 45);
    SolarTable->AddRow(24, 45);
    SolarTable->AddRow(24, 45);
    SolarTable->AddRow(24, 45);
    SolarTable->AddRow(24, 45);

    SolarTable->SetText(0, 0, "Effekt");
    SolarTable->SetText(0, 2, "W");

    SolarTable->SetText(1, 0, "Idag");
    SolarTable->SetText(1, 2, "kWh");

    SolarTable->SetText(2, 0, "Temperature");
    SolarTable->SetText(2, 2, "°C");

    SolarTable->SetText(3, 0, "Wind");
    SolarTable->SetText(3, 2, "m/s");

    SolarTable->SetText(4, 0, "Pressure");
    SolarTable->SetText(4, 2, "hPa");

    SolarTable->SetText(5, 0, "Humidity");
    SolarTable->SetText(5, 2, "%");

    SolarTable->Show();

    UnlockGUI();

    for (;;)
    {
        CurrTime = new TDateTime;
            
        solar.SetTime(currtime, 1);
        solar.GetSunPosition(&altitude, &azimuth);

        solalt = altitude;

        Vp->SetSolarAlt(solalt);

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

        if (w->IsOnline())
        {
            val = w->GetTemperature();
            if (val < 100.0 && val > -100.0)  
            {
                sprintf(str, "%5.1Lf", val);
                ambient = (int)(10.0 * val);
            }
            else
                strcpy(str, "err");
            SolarTable->SetText(2, 1, str);

            val = w->GetWindSpeed();
            if (val < 100.0 && val >= 0.0)
                sprintf(str, "%5.1Lf", val);
            else
                strcpy(str, "err");
            SolarTable->SetText(3, 1, str);

            val = w->GetPressure();
            if (val < 2000.0 && val > 0.0)
            {
                ival = (int)val;
                sprintf(str, "%d", ival);
            }
            else
                strcpy(str, "err");
            SolarTable->SetText(4, 1, str);

            val = w->GetHumidity();
            if (val <= 100.0 && val >= 0)
            {
                ival = (int)val;
                sprintf(str, "%d", ival);
            }
            else
                strcpy(str, "err");
            SolarTable->SetText(5, 1, str);
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

        summer = FALSE;

        if (CurrTime->GetMonth() >= 6 && CurrTime->GetMonth() <= 8)
            summer = TRUE;

        if (!summer)
        {
            night = FALSE;
            if (CurrTime->GetHour() >= 19)
                night = TRUE;
            else
                if (CurrTime->GetHour() < 5)
                    night = TRUE;
        }

        delete CurrTime;

        count = 0;
        circmax = 0;
        temperrmax = 255;
        refsum = 0;

        for (i = 0; i < 7; i++)
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
                        if (ambient < 0)
                            RadArr[i]->SetWinterRef();
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
            Circ->SetMaxMotor(circmax);

        if (count)
            Circ->SetMaxTempError(temperrmax);

        if (count)
        {
            Vp->SetTempError(temperrmax);
            Vp->SetAmbient(refsum / count, ambient);
            Vp->SetCirc(circmax, Circ->GetSpeed());
        }

        RdosWaitMilli(1000);

        if (SyncCount == 300)
        {
             RdosSyncTime(NtpIp);
             SyncCount = 0;
        }
        else
             SyncCount++;

    }
}

