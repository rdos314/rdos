/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# comshow.cpp
# Protocol analyzer app.
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "rdos.h"
#include "cbus.h"
#include "file.h"
#include "cbus.h"
#include "sernet.h"
#include "bar.h"
#include "compac.h"
#include "netana.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  main ##########################
*   Purpose....: Program entry-point	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void cdecl main()
{
	RdosWaitMilli(300);
//	TDateTime CbusTime;
//	TDateTime BarTime;
//	int HasCbus;
//	int HasBar;

//	TFile RawCbusFile("z:\\cbus.dat");
//	TFile RawBarFile("z:\\bar.dat");
//	TFile RawFile("z:\\raw.dat");
//	TFile RawFile("z:\\net.log");
	TFile RawFile("z:\compacpu.dat");

//	TCbusProtocolAnalyser CbusAnalyzer(&RawCbusFile, 0x4000);
//	TCotexProtocolAnalyser analyzer(&RawFile, 0x400);
//  TSernetProtocolAnalyser analyzer("comlog", 0x4000);
//	TBarProtocolAnalyser BarAnalyzer(&RawBarFile, 0x400);
	TCompacProtocolAnalyser analyzer(&RawFile, 0x400);
//	TWayneClProtocolAnalyser analyzer(&RawFile, 0x400);
//	TNetProtocolAnalyser analyzer(&RawFile);

//	CbusAnalyzer.DefineLogFile("c:\\volvo\\log.txt");
//	BarAnalyzer.DefineLogFile("c:\\volvo\\log.txt");
//	analyzer.DefineLogFile("cotex.txt");
//	analyzer.DefineLogFile("net.txt");
	analyzer.DefineLogFile("compac.txt");

	for (;;)
	{
		while (!RdosPollKeyboard())
		{

/* for Volvo
			HasCbus = CbusAnalyzer.GetMsg();
			if (HasCbus)
				CbusTime = CbusAnalyzer.GetMsgTime();
			else
				CbusTime = TDateTime();

			HasBar = BarAnalyzer.GetMsg();
			if (HasBar)
				BarTime = BarAnalyzer.GetMsgTime();
			else
				BarTime = TDateTime();

			if (HasCbus && HasBar)
			{
				if (BarTime < CbusTime)
					BarAnalyzer.ShowMsg();
				else
					CbusAnalyzer.ShowMsg();
			}
			else
			{
				if (HasCbus)
					CbusAnalyzer.ShowMsg();

				if (HasBar)
					BarAnalyzer.ShowMsg();
			}
*/
			if (analyzer.GetMsg())
				analyzer.ShowMsg();
			else
				RdosWaitMilli(100);

		}

		if ((RdosReadKeyboard() & 0xFF) == 0x1B)
			return;
	}
}

