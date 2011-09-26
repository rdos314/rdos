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

#include "rad.h"
#include "datetime.h"
#include "circ.h"
#include "vp.h"
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

#define RAD_X   5
#define RAD_Y  500


int main()
{
    TRad *RadArr[8];
    TCirc *Circ;
    TVp *Vp;
    int i;
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
    TControlThread *control;
    TRadControl *RadControl;
    TDataStore *Store;
    TSolar solar(55, 49, 5, 13, 14, 43);
    long double altitude;
    long double azimuth;
    TDateTime currtime;

    TLabelFactory CommentLabelFactory;
    TLabelFactory ValueLabelFactory;
    TLabelFactory UnitLabelFactory;

    CommentLabelFactory.SetSpace(4, 4);
    CommentLabelFactory.SetFont(20);
    CommentLabelFactory.SetBackTransparent();
    CommentLabelFactory.SetDrawColor(0, 0, 0);
    CommentLabelFactory.AlignLeft();
    
    ValueLabelFactory.SetSpace(4, 4);
    ValueLabelFactory.SetFont(20);
    ValueLabelFactory.SetBackColor(100, 100, 100);
    ValueLabelFactory.SetDrawColor(0, 0, 0);
    ValueLabelFactory.AlignRight();

    UnitLabelFactory.SetSpace(4, 4);
    UnitLabelFactory.SetFont(20);
    UnitLabelFactory.SetBackTransparent();
    UnitLabelFactory.SetDrawColor(0, 0, 0);
    UnitLabelFactory.AlignLeft();
    
    RdosWaitMilli(1000);

    Store = new TDataStore;

    RdosWriteSerialVal(2, 0, 0);
    RdosWriteSerialVal(2, 1, 0);


    NtpIp = RdosNameToIp("ntp.lth.se");
    RdosSyncTime(NtpIp);

    vbe = new TVideoGraphicDevice(32, 1280, 768);
    control = new TDisplayControlThread("Control", vbe);
    vbe->SetFont(&Font);

//    bitmap = TJpegBitmapDevice::Create("d:\\heat\\back.jpg");
//    vbe->Blit(bitmap, 0, 0, 0, 0, 1280, 768);

    vbe->SetDrawColor(0, 20, 50);
    vbe->SetFilledStyle();
    vbe->DrawRect(0, 0, 1279, 767);

    RadControl = new TRadControl(control, RAD_X, RAD_Y, 800, 30 * 8);

    for (i = 0; i < 8; i++)
    {

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
                strcpy(str, "Bl†tt sovrum, nedre plan");
                break;

            case 4:
                strcpy(str, "K”k");
                break;

            case 5:
                strcpy(str, "Sovrum, ”vre plan");
                break;

            case 6:
                strcpy(str, "Trappa");
                break;

            case 7:
                strcpy(str, "Badrum");
                break;
        }
        RadArr[i] = new TRad(str, RadControl, i, 0x20 + i);
        Store->Add(RadArr[i]);
    }

    Circ = new TCirc(vbe);
    Store->Add(Circ);

    Vp = new TVp(control);
    Store->Add(Vp);

    for (;;)
    {
        RdosSetCursorPosition(0,0);

        CurrTime = new TDateTime;


        if (RdosReadSerialLines(1, &diostat))
        {
            mask = 0x80;
            for (i = 0; i < 8; i++)
            {
                if (diostat & mask)
                    printf("1");
                else
                    printf("0");
                mask = mask >> 1;
            }

            currtime = TDateTime();
            
            solar.SetTime(currtime, 1);
            solar.GetSunPosition(&altitude, &azimuth);

            if (altitude < -5.0)
            {
                if ((diostat & 1) == 0)
                    RdosToggleSerialLine(1, 0);

                if ((diostat & 0x80) == 0)
                    RdosToggleSerialLine(1, 7);
            }
            else
            {
                if (diostat & 1)
                    RdosToggleSerialLine(1, 0);

                if (diostat & 0x80)
                    RdosToggleSerialLine(1, 7);
            }

        }
        else
            printf("------");

        ambient = 150;

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

        for (i = 0; i < 8; i++)
        {
            if (RadArr[i] && RadArr[i]->IsOnline())
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
            Vp->SetAmbient(refsum / count, 100); // 10C outside temperature
         }

         if (count)
         {
            if (RdosReadSerialLines(1, &diostat))
            {
                if (circmax < 25)
                {
                    if ((diostat & 0x40) != 0)
                        RdosToggleSerialLine(1, 6);   // heat
                        
                    if ((diostat & 0x20) != 0)
                        RdosToggleSerialLine(1, 5);   // cold
                }
                
                if (circmax > 75)
                {               
                    if ((diostat & 0x20) == 0)
                        RdosToggleSerialLine(1, 5);   // cold

                    if ((diostat & 0x40) == 0)
                        RdosToggleSerialLine(1, 6);   // heat
                }

                if (circmax == 0)
                    if ((diostat & 0x10) != 0)
                        RdosToggleSerialLine(1, 4);

                if (circmax > 25)
                    if ((diostat & 0x10) == 0)
                        RdosToggleSerialLine(1, 4);
                
            }
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

