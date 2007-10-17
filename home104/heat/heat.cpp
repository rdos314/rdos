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

#include "httpheat.h"
#include "rad.h"
#include "datetime.h"
#include "ws2300.h"
#include "log.h"
#include "circ.h"
#include "temp.h"
#include "vp.h"
#include "graph.h"
#include "videodev.h"

#define FALSE	0
#define TRUE	!FALSE

#define WIDTH 240
#define HEIGHT 15

void WsChanged(TWs2300 *ws)
{
    HttpUpdate();
}

void cdecl main()
{
	TRad *RadArr[8];
	TWs2300 *Ws;
	TCirc *Circ;
	TVp *Vp;
	TTemperature *Temp;
	int i;
	int diostat;
	int mask;
	TDateTime *CurrTime;
	int mot;
	int vpmax;
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
	TLog *log;
	TFile *file;
	int init = 0x8000;
	int ambient;
	int night;
	TGraphic *graphic;
	TGraphicDevice *vbe;
	TFont Font(10);
	char str[80];

	RdosWaitMilli(1000);

	NtpIp = RdosNameToIp("ntp.lth.se");
	RdosSyncTime(NtpIp);

	log = new TLog("e:\\log");

	vbe = new TVideoGraphicDevice(24, 800, 600);
	vbe->SetFont(&Font);

	graphic = new TGraphic(vbe, log);

	vbe->SetDrawColor(255, 255, 255);

	vbe->DrawString(170, 420, "   Ref");
	vbe->DrawString(220, 420, "  Temp");
	vbe->DrawString(270, 420, "P†drag");
	vbe->DrawString(320, 420, "  Ljus");
	vbe->DrawString(370, 420, "Temp 2");

	for (i = 0; i < 8; i++)
	{
		switch (i)
		{
			case 0:
				strcpy(str, "Leif & Lenas sovrum");
				break;

			case 1:
				strcpy(str, "Vardagsrum");
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
				strcpy(str, "Emil & Linneas sovrum");
				break;

			case 6:
				strcpy(str, "Trappa");
				break;

			case 7:
				strcpy(str, "Badrum");
				break;
		}

		vbe->DrawString(5, 420 + 16 * (i + 1), str);

		RadArr[i] = new TRad(vbe, 0x20 + i, 170, 420 + 16 * (i + 1));
		AddHttpRad(RadArr[i]);
		log->Add(RadArr[i]);
	}

	Ws = new TWs2300(1);
	Ws->OnChanged = WsChanged;

	Circ = new TCirc(vbe);

	Vp = new TVp(vbe);

	Temp = new TTemperature(vbe, log);

	log->Add(Ws);
	log->Add(Circ);
	log->Add(Vp);
	log->Add(Temp);

	InitHeatHttp();

	AddHttpWs2300(Ws);
	AddHttpCirc(Circ);
	AddHttpVp(Vp);
	AddHttpTemp(Temp);
	AddHttpLog(log);

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

			if (CurrTime->GetHour() >= 17 || CurrTime->GetHour() <= 7)
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
		vpmax = 0;
		circmax = 0;
		temperrmax = 255;

		for (i = 0; i < 8; i++)
		{
			if (RadArr[i]->IsOnline())
			{
				count++;

				mot = RadArr[i]->GetMotor();
				if (mot > vpmax && i != 7)
					vpmax = mot;

				if (mot > circmax)
					circmax = mot;

				temp = RadArr[i]->GetTemp();
				ref = RadArr[i]->GetRef();

				temperr = temp - ref;

				if (temperr < temperrmax && i != 7)
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
			Vp->SetMotor(vpmax);

		if (count)
			Vp->SetTempError(temperrmax);

		if (diostat & 1)
			HttpSetLightOn();
		else
			HttpSetLightOff();

    	vbe->SetFilledStyle();
    	vbe->SetDrawColor(255, 255, 255);
	    vbe->DrawString(550, 0, "V„derstation");

	    vbe->DrawString(550, 16, "Inomhus");

		val = Ws->GetIndoorTemp();
		sprintf(str, "Temperatur: %5.1Lf", val);

    	vbe->SetDrawColor(0, 0, 0);
		vbe->DrawRect(550, 2 * 16, 550 + WIDTH, 3 * 16 - 1);
		
    	vbe->SetDrawColor(255, 255, 255);
	    vbe->DrawString(550, 2 * 16, str);

		val = Ws->GetIndoorHumidity();
		sprintf(str, "Fuktighet: %4.0Lf%", val);

    	vbe->SetDrawColor(0, 0, 0);
		vbe->DrawRect(550, 3 * 16, 550 + WIDTH, 4 * 16 - 1);
		
    	vbe->SetDrawColor(255, 255, 255);
	    vbe->DrawString(550, 3 * 16, str);

    	vbe->SetDrawColor(255, 255, 255);
	    vbe->DrawString(550, 4 * 16, "Utomhus");

		val = Ws->GetOutdoorTemp();
		sprintf(str, "Temperatur: %5.1Lf", val);

    	vbe->SetDrawColor(0, 0, 0);
		vbe->DrawRect(550, 5 * 16, 550 + WIDTH, 6 * 16 - 1);
		
    	vbe->SetDrawColor(255, 255, 255);
	    vbe->DrawString(550, 5 * 16, str);

		val = Ws->GetOutdoorHumidity();
		sprintf(str, "Fuktighet: %4.0Lf%", val);

    	vbe->SetDrawColor(0, 0, 0);
		vbe->DrawRect(550, 6 * 16, 550 + WIDTH, 7 * 16 - 1);
		
    	vbe->SetDrawColor(255, 255, 255);
	    vbe->DrawString(550, 6 * 16, str);

		val = Ws->GetDewPoint();
		sprintf(str, "Daggpunkt: %5.1Lf", val);

		vbe->SetDrawColor(0, 0, 0);
		vbe->DrawRect(550, 7 * 16, 550 + WIDTH, 8 * 16 - 1);

		vbe->SetDrawColor(255, 255, 255);
		vbe->DrawString(550, 7 * 16, str);

		val = Ws->GetWindChill();
		sprintf(str, "Vindkompenserad: %5.1Lf", val);

    	vbe->SetDrawColor(0, 0, 0);
		vbe->DrawRect(550, 8 * 16, 550 + WIDTH, 9 * 16 - 1);
		
    	vbe->SetDrawColor(255, 255, 255);
	    vbe->DrawString(550, 8 * 16, str);

		val = Ws->GetWindSpeed();
		sprintf(str, "Vind: %5.1Lf m/s", val);

    	vbe->SetDrawColor(0, 0, 0);
		vbe->DrawRect(550, 9 * 16, 550 + WIDTH, 10 * 16 - 1);
		
    	vbe->SetDrawColor(255, 255, 255);
	    vbe->DrawString(550, 9 * 16, str);

		val = Ws->GetWindDir();
		ival = (int)(val / 22 + 0.5);

		strcpy(str, "Vindriktning: ");
		switch (ival)
		{
				case 0:
					 strcat(str, "N");
					 break;

				case 1:
					 strcat(str, "NNO");
					 break;

				case 2:
					 strcat(str, "NO");
					 break;

				case 3:
					 strcat(str, "ONO");
					 break;

				case 4:
					 strcat(str, "O");
					 break;

				case 5:
					 strcat(str, "OSO");
					 break;

				case 6:
					 strcat(str, "SO");
					 break;

				case 7:
					 strcat(str, "SSO");
					 break;

				case 8:
					 strcat(str, "S");
					 break;

				case 9:
					 strcat(str, "SSV");
					 break;

				case 10:
					 strcat(str, "SV");
					 break;

				case 11:
					 strcat(str, "VSV");
					 break;

				case 12:
					 strcat(str, "V");
					 break;

				case 13:
					 strcat(str, "VNV");
					 break;

				case 14:
					 strcat(str, "NV");
					 break;

				case 15:
					 strcat(str, "NNV");
					 break;

				case 16:
					 strcat(str, "N");
					 break;
		}

    	vbe->SetDrawColor(0, 0, 0);
		vbe->DrawRect(550, 10 * 16, 550 + WIDTH, 11 * 16 - 1);
		
    	vbe->SetDrawColor(255, 255, 255);
	    vbe->DrawString(550, 10 * 16, str);

		val = Ws->GetRain1h();
		sprintf(str, "Regn: 1 timme: %5.1Lf mm", val);

    	vbe->SetDrawColor(0, 0, 0);
		vbe->DrawRect(550, 11 * 16, 550 + WIDTH, 12 * 16 - 1);
		
    	vbe->SetDrawColor(255, 255, 255);
	    vbe->DrawString(550, 11 * 16, str);

		val = Ws->GetRain24h();
		sprintf(str, "Regn: 24 timmar: %5.1Lf mm", val);

    	vbe->SetDrawColor(0, 0, 0);
		vbe->DrawRect(550, 12 * 16, 550 + WIDTH, 13 * 16 - 1);
		
    	vbe->SetDrawColor(255, 255, 255);
	    vbe->DrawString(550, 12 * 16, str);

		val = Ws->GetAirPressure();
		sprintf(str, "Lufttryck: %6.1Lf hPa", val);

    	vbe->SetDrawColor(0, 0, 0);
		vbe->DrawRect(550, 13 * 16, 550 + WIDTH, 14 * 16 - 1);
		
    	vbe->SetDrawColor(255, 255, 255);
	    vbe->DrawString(550, 13 * 16, str);

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

