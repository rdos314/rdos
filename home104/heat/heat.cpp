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
	
	AddHttpWs2300(Ws);

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
		printf("%5.1Lf", val);

		RdosSetCursorPosition(10,10);
		val = Ws->GetIndoorHumidity();
		printf("%4.0Lf%", val);

		RdosSetCursorPosition(11,0);
		val = Ws->GetOutdoorTemp();
		printf("%5.1Lf", val);

		RdosSetCursorPosition(11,10);
		val = Ws->GetOutdoorHumidity();
		printf("%4.0Lf%", val);

		RdosSetCursorPosition(12,0);
		val = Ws->GetDewPoint();
		printf("%5.1Lf", val);

		RdosSetCursorPosition(12,10);
		val = Ws->GetWindChill();
		printf("%5.1Lf", val);

		RdosSetCursorPosition(13,0);
		val = Ws->GetWindSpeed();
		printf("%5.1Lf m/s", val);

		RdosSetCursorPosition(13,10);
		val = Ws->GetWindDir();
		printf("%4Lf", val);

		RdosSetCursorPosition(14,0);
		val = Ws->GetRain1h();
		printf("%5.1Lf mm", val);

		RdosSetCursorPosition(14,10);
		val = Ws->GetRain24h();
		printf("%5.1Lf mm", val);

		RdosSetCursorPosition(15,0);
		val = Ws->GetAirPressure();
		printf("%6.1Lf hPa", val);

		RdosWaitMilli(1000);
	}
}

