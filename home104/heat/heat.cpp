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
#include "ws2300.h"
#include "circ.h"
#include "vp.h"
#include "videodev.h"
#include "radcntrl.h"
#include "solar.h"
#include "table.h"
#include "jpeg.h"
#include "datastor.h"

#define FALSE	0
#define TRUE	!FALSE

#define WIDTH 240
#define HEIGHT 15

#define RAD_X   5
#define RAD_Y  500


void cdecl main()
{
	TRad *RadArr[8];
	TWs2300 *Ws;
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

	TLabelControl *IndoorLabel;
    TTableControl *IndoorTable;

	TLabelControl *OutdoorLabel;
    TTableControl *OutdoorTable;
    
	RdosWaitMilli(1000);

	Store = new TDataStore;

	RdosWriteSerialVal(2, 0, 0);
	RdosWriteSerialVal(2, 1, 0);


	NtpIp = RdosNameToIp("ntp.lth.se");
	RdosSyncTime(NtpIp);

	vbe = new TVideoGraphicDevice(32, 1280, 768);
	control = new TControlThread("Control", vbe);
	vbe->SetFont(&Font);

	bitmap = TJpegBitmapDevice::Create("d:\\heat\\back.jpg");
	vbe->Blit(bitmap, 0, 0, 0, 0, 1280, 768);

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

	Ws = new TWs2300(1);
	Store->Add(Ws);

	Circ = new TCirc(vbe);
	Store->Add(Circ);

	Vp = new TVp(control);
	Store->Add(Vp);

	IndoorLabel = new TLabelControl(control, 900, 10, 300, 30);
    IndoorLabel->SetFont(20);
    IndoorLabel->SetBackTransparent();
    IndoorLabel->SetDrawColor(0, 0, 0);
    IndoorLabel->SetText("Inomhus");
    IndoorLabel->Show();

	IndoorTable = new TTableControl(control, 900, 40, 300, 60);
	IndoorTable->SetRowSpacing(5);
	IndoorTable->SetColSpacing(8);
	IndoorTable->SetSpacingTransparent();
	IndoorTable->SetBackTransparent();
	IndoorTable->AddLabelColumn(&CommentLabelFactory, 150);
	IndoorTable->AddLabelColumn(&ValueLabelFactory, 80);
	IndoorTable->AddLabelColumn(&UnitLabelFactory, 70);

    IndoorTable->AddRow(24, 45);
    IndoorTable->AddRow(24, 45);

    IndoorTable->SetText(0, 0, "Temperatur");
    IndoorTable->SetText(0, 2, "C");

    IndoorTable->SetText(1, 0, "Fuktighet");
    IndoorTable->SetText(1, 2, "%");

    IndoorTable->Show();

	OutdoorLabel = new TLabelControl(control, 900, 100, 300, 30);
    OutdoorLabel->SetFont(20);
    OutdoorLabel->SetBackTransparent();
    OutdoorLabel->SetDrawColor(0, 0, 0);
    OutdoorLabel->SetText("Utomhus");
    OutdoorLabel->Show();

	OutdoorTable = new TTableControl(control, 900, 130, 300, 300);
	OutdoorTable->SetRowSpacing(5);
	OutdoorTable->SetColSpacing(8);
	OutdoorTable->SetSpacingTransparent();
	OutdoorTable->SetBackTransparent();
	OutdoorTable->AddLabelColumn(&CommentLabelFactory, 150);
	OutdoorTable->AddLabelColumn(&ValueLabelFactory, 80);
	OutdoorTable->AddLabelColumn(&UnitLabelFactory, 70);

	 OutdoorTable->AddRow(24, 45);
	 OutdoorTable->AddRow(24, 45);
	 OutdoorTable->AddRow(24, 45);
	 OutdoorTable->AddRow(24, 45);
	 OutdoorTable->AddRow(24, 45);
	 OutdoorTable->AddRow(24, 45);
	 OutdoorTable->AddRow(24, 45);
	 OutdoorTable->AddRow(24, 45);
	 OutdoorTable->AddRow(24, 45);

	 OutdoorTable->SetText(0, 0, "Temperatur");
	 OutdoorTable->SetText(0, 2, "C");

	 OutdoorTable->SetText(1, 0, "Fuktighet");
	 OutdoorTable->SetText(1, 2, "%");

	 OutdoorTable->SetText(2, 0, "Daggpunkt");
	 OutdoorTable->SetText(2, 2, "C");

	 OutdoorTable->SetText(3, 0, "Vindkomp");
	 OutdoorTable->SetText(3, 2, "C");

	 OutdoorTable->SetText(4, 0, "Vind");
	 OutdoorTable->SetText(4, 2, "m/s");

	 OutdoorTable->SetText(5, 0, "Vindrikt");
	 OutdoorTable->SetText(5, 2, "");

	 OutdoorTable->SetText(6, 0, "Regn, timme");
	 OutdoorTable->SetText(6, 2, "mm");

	 OutdoorTable->SetText(7, 0, "Regn, dygn");
	 OutdoorTable->SetText(7, 2, "mm");

	 OutdoorTable->SetText(8, 0, "Lufttryck");
	 OutdoorTable->SetText(8, 2, "hPa");

	 OutdoorTable->Show();

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

			solar.SetTime(TDateTime(), 1);
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

		ambient = 10 * Ws->GetOutdoorTemp();

		night = FALSE;
		if (CurrTime->GetHour() >= 19)
			night = TRUE;
		else
			if (CurrTime->GetHour() < 5)
				night = TRUE;

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

				if (night)
				{
					if (ambient < 0)
						RadArr[i]->SetWinterRef();
					else
						RadArr[i]->SetNightRef();
				}
				else
					RadArr[i]->SetDayRef();

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
			Vp->SetAmbient(refsum / count, (int)(10.0 * Ws->GetOutdoorTemp()));
//			Vp->SetAmbient(refsum / count, 100); // 10C outside temperature
		 }

		val = Ws->GetIndoorTemp();
		sprintf(str, "%5.1Lf", val);
		  IndoorTable->SetText(0, 1, str);

		val = Ws->GetIndoorHumidity();
		sprintf(str, "%4.0Lf", val);
		  IndoorTable->SetText(1, 1, str);

		val = Ws->GetOutdoorTemp();
		sprintf(str, "%5.1Lf", val);
		  OutdoorTable->SetText(0, 1, str);

		val = Ws->GetOutdoorHumidity();
		sprintf(str, "%4.0Lf", val);
		  OutdoorTable->SetText(1, 1, str);

		val = Ws->GetDewPoint();
		sprintf(str, "%5.1Lf", val);
		  OutdoorTable->SetText(2, 1, str);

		val = Ws->GetWindChill();
		sprintf(str, "%5.1Lf", val);
		  OutdoorTable->SetText(3, 1, str);

		val = Ws->GetWindSpeed();
		sprintf(str, "%5.1Lf", val);
        OutdoorTable->SetText(4, 1, str);

		val = Ws->GetWindDir();
		ival = (int)(val / 22 + 0.5);

		switch (ival)
		{
				case 0:
					 strcpy(str, "N");
					 break;

				case 1:
					 strcpy(str, "NNO");
					 break;

				case 2:
					 strcpy(str, "NO");
					 break;

				case 3:
					 strcpy(str, "ONO");
					 break;

				case 4:
					 strcpy(str, "O");
					 break;

				case 5:
					 strcpy(str, "OSO");
					 break;

				case 6:
					 strcpy(str, "SO");
					 break;

				case 7:
					 strcpy(str, "SSO");
					 break;

				case 8:
					 strcpy(str, "S");
					 break;

				case 9:
					 strcpy(str, "SSV");
					 break;

				case 10:
					 strcpy(str, "SV");
					 break;

				case 11:
					 strcpy(str, "VSV");
					 break;

				case 12:
					 strcpy(str, "V");
					 break;

				case 13:
					 strcpy(str, "VNV");
					 break;

				case 14:
					 strcpy(str, "NV");
					 break;

				case 15:
					 strcpy(str, "NNV");
					 break;

				case 16:
					 strcpy(str, "N");
					 break;
		}
        OutdoorTable->SetText(5, 1, str);

		val = Ws->GetRain1h();
		sprintf(str, "%5.1Lf", val);
        OutdoorTable->SetText(6, 1, str);

		val = Ws->GetRain24h();
		sprintf(str, "%5.1Lf", val);
        OutdoorTable->SetText(7, 1, str);

		val = Ws->GetAirPressure();
		sprintf(str, "%6.1Lf", val);
        OutdoorTable->SetText(8, 1, str);

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

