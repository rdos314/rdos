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

#define FALSE	0
#define TRUE	!FALSE

void cdecl main()
{
	TRad *RadArr[8];
	TWs2300 *Ws;
	int i;
	int diostat;
	int mask;
	TDateTime *CurrTime;
	int motsum;
	int motcount;
	int mot;
	long double val;
	long double winddir;

	RdosWaitMilli(1000);

	 InitHeatHttp();

	for (i = 0; i < 8; i++)
	{
		RadArr[i] = new TRad(0x20 + i, i);
		AddHttpRad(RadArr[i]);
	 }

	 Ws = new TWs2300(1);

	for (;;)
	{
		RdosSetCursorPosition(0,0);

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

			CurrTime = new TDateTime;

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

			delete CurrTime;
		}
		else
			printf("------");

        motsum = 0;
        motcount = 0;
        
		for (i = 0; i < 8; i++)
		{
			if (RadArr[i]->IsOnline())
		    {
		        motcount++;
		        motsum += RadArr[i]->Motor;
			 }
		}

		if (motcount > 5)
		{
			 mot = motsum / motcount;
			 if (mot >= 70)
				  if ((diostat & 0x20) == 0)
						RdosToggleSerialLine(1, 5);

			 if (mot <= 25)
				  if (diostat & 0x20)
						RdosToggleSerialLine(1, 5);
		  }

		RdosSetCursorPosition(10,0);

		val = Ws->GetIndoorTemp();
		if (val > -100)
			printf("%5.1Lf", val);
		else
			 printf("-----");

		RdosSetCursorPosition(10,10);

		val = Ws->GetIndoorHumidity();
		if (val > -10)
			printf("%4.0Lf%", val);
		else
			printf("----%");

		RdosSetCursorPosition(11,0);

		val = Ws->GetOutdoorTemp();
		if (val > -100)
			printf("%5.1Lf", val);
		else
			 printf("-----");

		RdosSetCursorPosition(11,10);

		val = Ws->GetOutdoorHumidity();
		if (val > -10)
			printf("%4.0Lf%", val);
		else
			printf("----%");

		RdosSetCursorPosition(12,0);

		val = Ws->GetWind(&winddir);
		if (val > -10)
			printf("%5.1Lf m/s   %4Lf", val, winddir);
		else
			printf("----- m/s    ----");

		RdosSetCursorPosition(13,0);

		val = Ws->GetRain1h();
		if (val > -100)
			printf("%5.1Lf mm", val);
		else
			 printf("----- mm");

		RdosSetCursorPosition(13,10);

		val = Ws->GetRain24h();
		if (val > -100)
			printf("%5.1Lf mm", val);
		else
			 printf("----- mm");

		RdosSetCursorPosition(14,0);

		val = Ws->GetAirPressure();
		if (val > -100)
			printf("%6.1Lf hPa", val);
		else
			 printf("----- hPa");

		RdosWaitMilli(1000);
	}
}

