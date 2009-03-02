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
#include "log.h"
#include "lowset.h"
#include "midset.h"
#include "highset.h"

#define FALSE 0
#define TRUE !FALSE

#define VOLUME_TANK 500
#define VOLUME_HEAT 200

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
TVp::TVp(TGraphicDevice *dev, TLog *log)
 : Font(10)
{
    Log = log;
	int i, j;
	int SetArr[MAX_FUZZY_VARS];
	int RuleArr[3][5] =
				{
					{3, 2, 1, 0, 0},
					{4, 3, 3, 3, 2},
					{6, 6, 5, 4, 3},
				};

	FTempDiffVar.Add(0, new TLowFuzzySet(-1.0, -0.5));
	FTempDiffVar.Add(1, new TMidFuzzySet(-1.0, -0.5, 0.0));
	FTempDiffVar.Add(2, new TMidFuzzySet(-0.5, 0.0, 0.5));
	FTempDiffVar.Add(3, new TMidFuzzySet(0.0, 0.5, 1.0));
	FTempDiffVar.Add(4, new THighFuzzySet(0.5, 1.0));
	AddInput(0, &FTempDiffVar);

	FAmbientVar.Add(0, new TLowFuzzySet(0.25, 0.5));
	FAmbientVar.Add(1, new TMidFuzzySet(0.25, 0.5, 1.0));
	FAmbientVar.Add(2, new THighFuzzySet(0.5, 1.0));
	AddInput(1, &FAmbientVar);

	FOutputVar.Add(0, new TLowFuzzySet(-0.8, -0.4));
	FOutputVar.Add(1, new TMidFuzzySet(-0.8, -0.4, -0.2));
	FOutputVar.Add(2, new TMidFuzzySet(-0.4, -0.2, 0.0));
	FOutputVar.Add(3, new TMidFuzzySet(-0.2, 0.0, 0.2));
	FOutputVar.Add(4, new TMidFuzzySet(0.0, 0.2, 0.4));
	FOutputVar.Add(5, new TMidFuzzySet(0.2, 0.4, 0.8));
	FOutputVar.Add(6, new THighFuzzySet(0.4, 0.8));
	AddOutput(&FOutputVar);

	for (i = 0; i < 3; i++)
	{
		for (j = 0; j < 5; j++)
		{
			SetArr[0] = j;
			SetArr[1] = i;
			DefineRule(SetArr, RuleArr[i][j]);
		}
	}

	FTempDiffVar.SetInputValue(0.0);
	FAmbientVar.SetInputValue(0.5);

	vbe = new TGraphicDevice(*dev);

	vbe->SetFont(&Font);

	FTankTemp = 200;
	FHeatTemp = 200;

	FValidTank = FALSE;
	FValidHeat = FALSE;
	FValidPTank = FALSE;
	FValidPHeat = FALSE;
	FValidAmbient = FALSE;

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
	delete vbe;
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
#   Name       : TVp::IsVpOn
#
#   Purpose....: Is VP on?
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::IsVpOn()
{
    return FVpOn;
}

/*##########################################################################
#
#   Name       : TVp::IsEpOn
#
#   Purpose....: Is EP on?
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::IsEpOn()
{
    return FEpOn;
}

/*##########################################################################
#
#   Name       : TVp::HasValidTankTemp
#
#   Purpose....: Check for valid tank temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::HasValidTankTemp()
{
    return FValidTank;
}

/*##########################################################################
#
#   Name       : TVp::HasValidHeatTemp
#
#   Purpose....: Check for valid heat temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::HasValidHeatTemp()
{
	return FValidHeat;
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
#   Name       : TVp::GetHeatTemp
#
#   Purpose....: Get heating system temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::GetHeatTemp()
{
	return FHeatTemp;
}

/*##########################################################################
#
#   Name       : TVp::HasValidTankP
#
#   Purpose....: Check for valid tank effect
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::HasValidTankP()
{
	return FValidPTank;
}

/*##########################################################################
#
#   Name       : TVp::GetTankP
#
#   Purpose....: Get current tank effect
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TVp::GetTankP()
{
	return PTank;
}

/*##########################################################################
#
#   Name       : TVp::HasValidHeatP
#
#   Purpose....: Check for valid heat effect
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::HasValidHeatP()
{
	return FValidPHeat;
}

/*##########################################################################
#
#   Name       : TVp::GetHeatP
#
#   Purpose....: Get current heat effect
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TVp::GetHeatP()
{
	return PHeat;
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
#   Name       : TVp::SetAmbientDiff
#
#   Purpose....: Set ambient temp diff
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetAmbient(int ref, int ambient)
{
    long double fact;
    long double ambdiff;
    long double tankdiff;

    if (FValidTank)
    {

        FSection.Enter();

        FRef = ref;
        FAmbient = ambient;

        ambdiff = FRef - FAmbient;
        tankdiff = FTankTemp - FRef;

        fact = 1.5 * ambdiff / (ambdiff + 2.0 * tankdiff);

        AmbientSum += fact;
        AmbientCount++;
    
        FValidAmbient = TRUE;

        FSection.Leave();    
    }
}

/*##########################################################################
#
#   Name       : TVp::ReadTankData
#
#   Purpose....: Read old tank-data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::ReadTankData()
{
    TDateTime StartTime;
	TDateTime time;
	TLogReader *log;
	TDeviceMsg *msg;
    TDeviceTag *header;
	TDeviceTag *tag;
	TDeviceVar *var;
    int diff;
	int i;
	unsigned long msb;
	unsigned long lsb;
	int ival;

	for (i = 0; i < 40; i++)
	    ValidTankArr[i] = FALSE;

	for (i = 0; i < 20; i++)
	    ValidHeatArr[i] = FALSE;
	
    StartTime.AddMin(-40);
    
	log = Log->GetLog(StartTime.GetYear(), StartTime.GetMonth(), StartTime.GetDay());

    FMaxHeatDay = StartTime.GetDay();
    FMaxHeatTemp = 0;

    msg = 0;
    
    if (log)
    	if (log->GotoFirst())
            msg = log->Get();
    
    while (msg)
    {
        header = msg->GetTag(LOG_TAG_HEADER);
    	if (header)
	    {
		    msb = header->GetUnsignedInt(LOG_VAR_MsbTime, 0);
			lsb = header->GetUnsignedInt(LOG_VAR_LsbTime, 0);
    		time = TDateTime(msb, lsb);

    		if (time >= StartTime)
    		{
    		    diff = time.GetMin() - StartTime.GetMin();
    		    if (diff < 0)
    		        diff += 60;

    		    if (diff >= 0 && diff < 40)
    		    {
                    tag = msg->GetTag(LOG_TAG_TANK);
                    if (tag)
                    {        			        
                        var = tag->GetVar(LOG_VAR_Temp);
    	        		if (var)
	    		    	{
                            TankArr[diff] = var->GetFloat1();
                            ValidTankArr[diff] = TRUE;
                        }
                    }
                }

                diff -= 20;

    		    if (diff >= 0 && diff < 20)
    		    {
                    tag = msg->GetTag(LOG_TAG_HEAT);
                    if (tag)
                    {        			        
                        var = tag->GetVar(LOG_VAR_Temp);
    	        		if (var)
	    		    	{
                            HeatArr[diff] = var->GetFloat1();
                            ValidHeatArr[diff] = TRUE;
                        }
                    }
                }

                tag = msg->GetTag(LOG_TAG_HEAT);
                if (tag)
                {        			        
                    var = tag->GetVar(LOG_VAR_Temp);
    	        	if (var)
	    		    {
                        ival = var->GetFloat1();

                        if (ival > FMaxHeatTemp)
                            FMaxHeatTemp = ival;
                    }
                }

            }
        }

        if (log->GotoNext())
		    msg = log->Get();
		else
		    msg = 0;
    }
    delete log;
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
	int year, month, day;
	int hour, min, sec;
	int ms;
	int LastMin;
	int i;
	long double ValArr[MAX_FUZZY_VARS];
	long double val;
    int ival;
	int diostat;
	long double dT;
	int Sum;
	int Count;
	int PrevCount;
	long double PrevVal;
	int EpLimit;
	char str[50];

	TempSum = 0;
	TempCount = 0;
	AmbientSum = 0;
	AmbientCount = 0;

	for (i = 0; i < MAX_FUZZY_VARS; i++)
		ValArr[i] = 0.0;

    ValArr[1] = 0.5;

	while (!RdosReadSerialLines(1, &diostat))
		RdosWaitMilli(250);

	if (diostat & 0x20)
		FVpOn = TRUE;
	else
		FVpOn = FALSE;

	if (diostat & 0x40)
		FEpOn = TRUE;
	else
		FEpOn = FALSE;

	if (FVpOn)
		FLevel = 9.9;
	else
		FLevel = 0.0;

	ReadTankData();

	FTankSum = 0;
	FTankCount = 0;

	FHeatSum = 0;
	FHeatCount = 0;

	RdosGetTime(&year, &month, &day, &hour, &LastMin, &sec, &ms);

	while (FInstalled)
	{
		if (RdosReadSerialRaw(0x40, 0, &ival))
		{
		    FTankSum += ival;
            FTankCount++;

            if (FTankCount >= 50)
            {
				FTankTemp = FTankSum / FTankCount;

				val = (long double)FTankTemp / 10;
				sprintf(str, "Tank: %5.1Lf", val);

				vbe->SetFilledStyle();
				vbe->SetDrawColor(0, 0, 0);
				vbe->DrawRect(550, 340, 550 + 100, 340 + 12);

				vbe->SetDrawColor(255, 255, 255);
				vbe->DrawString(550, 340, str);

				FValidTank = TRUE;

				FTankSum = 0;
				FTankCount = 0;
			}
		}

		if (RdosReadSerialRaw(0x40, 1, &ival))
		{
			FHeatSum += ival;
			FHeatCount++;

			if (FHeatCount >= 50)
			{
				FHeatTemp = FHeatSum / FHeatCount;

				if (FHeatTemp > FMaxHeatTemp)
				    FMaxHeatTemp = FHeatTemp;

				val = (long double)FHeatTemp / 10;
				sprintf(str, "Panna: %5.1Lf", val);

				vbe->SetFilledStyle();
				vbe->SetDrawColor(0, 0, 0);
				vbe->DrawRect(550, 355, 550 + 100, 355 + 12);

				vbe->SetDrawColor(255, 255, 255);
				vbe->DrawString(550, 355, str);

				FValidHeat = TRUE;

				FHeatSum = 0;
				FHeatCount = 0;
			}
		}

		RdosGetTime(&year, &month, &day, &hour, &min, &sec, &ms);

		if (LastMin != min && TempCount)
		{
			LastMin = min;

			if (FMaxHeatDay != day)
			{
			    FMaxHeatDay = day;
			    FMaxHeatTemp = 0;
			}

			for (i = 1; i < 40; i++)
			{
			    TankArr[i-1] = TankArr[i];
				 ValidTankArr[i-1] = ValidTankArr[i];
			}

			TankArr[39] = FTankTemp;
			ValidTankArr[39] = FValidTank;

            if (FValidTank)
            {
                Sum = 0;
                PrevCount = 0;
                
                for (i = 0; i < 10; i++)
                {
                    if (ValidTankArr[i])
                    {
                        Sum += TankArr[i] * i;
                        PrevCount += i;
                    }
                }

                if (PrevCount)
					PrevVal = (long double)Sum / (long double)PrevCount / 10.0;
				else
					PrevVal = 0;

				Sum = 0;
				Count = 0;

				for (i = 0; i < 10; i++)
				{
					if (ValidTankArr[i + 30])
					{
						Sum += TankArr[i + 30] * i;
						Count += i;
					}
				}

				if (Count)
					val = (long double)Sum / (long double)Count / 10.0;
				else
					val = 0;

				if (Count && PrevCount)
				{
					dT = val - PrevVal;
					PTank = 0.07 * VOLUME_TANK * dT / 30;
					FValidPTank = TRUE;

					sprintf(str, "P Tank: %5.2Lf kW", PTank);

					vbe->SetFilledStyle();
					vbe->SetDrawColor(0, 0, 0);
					vbe->DrawRect(550, 370, 550 + 100, 370 + 12);

					vbe->SetDrawColor(255, 255, 255);
					vbe->DrawString(550, 370, str);
				}
			}

			for (i = 1; i < 20; i++)
			{
				HeatArr[i-1] = HeatArr[i];
				ValidHeatArr[i-1] = ValidHeatArr[i];
			}

			HeatArr[19] = FHeatTemp;
			ValidHeatArr[19] = FValidHeat;

			if (FValidHeat)
			{
				Sum = 0;
				PrevCount = 0;

				for (i = 0; i < 5; i++)
				{
					if (ValidHeatArr[i])
					{
						Sum += HeatArr[i] * i;
						PrevCount += i;
					}
				}

				if (PrevCount)
					PrevVal = (long double)Sum / (long double)PrevCount / 10.0;
				else
					PrevVal = 0;

				Sum = 0;
				Count = 0;

				for (i = 0; i < 5; i++)
				{
					if (ValidHeatArr[i + 15])
					{
						Sum += HeatArr[i + 15] * i;
						Count += i;
					}
				}

				if (Count)
					val = (long double)Sum / (long double)Count / 10.0;
				else
					val = 0;

				if (Count && PrevCount)
				{
					dT = val - PrevVal;
					PHeat = 0.07 * VOLUME_HEAT * dT / 15;
					FValidPHeat = TRUE;

					sprintf(str, "P Panna: %5.2Lf kW", PHeat);

					vbe->SetFilledStyle();
					vbe->SetDrawColor(0, 0, 0);
					vbe->DrawRect(550, 385, 550 + 100, 385 + 12);

					vbe->SetDrawColor(255, 255, 255);
					vbe->DrawString(550, 385, str);
				}
			}

			FSection.Enter();

			if (TempCount)
				ValArr[0] = (long double)TempSum / (long double)TempCount / 10.0;

            if (AmbientCount)
                ValArr[1] = AmbientSum / (long double)AmbientCount; 

			TempSum = 0;
			TempCount = 0;
			AmbientSum = 0;
			AmbientCount = 0;

			FSection.Leave();

			val = Calc(ValArr);
			FLevel += val;

			if (FLevel < 0.0)
				FLevel = 0.0;

			if (FLevel > 9.9)
				FLevel = 9.9;
			
			if (FLevel < 2.5 && FVpOn)
				FVpOn = FALSE;

			if (FLevel > 7.5 && !FVpOn)
				FVpOn = TRUE;

			if (FTankTemp > 400 && FVpOn)
				FVpOn = FALSE;

			if (FValidPHeat && FValidHeat)
			{
				 if (FMaxHeatTemp < 750)
					  EpLimit = 750;
			    else
			        EpLimit = 500;
			    
    			if (PHeat < -0.6)
	    			FEpOn = FALSE;

			    if (FHeatTemp > EpLimit)
			        FEpOn = FALSE;
			    else
			    {
    		    	if (PHeat > -0.2)
	    		    	FEpOn = TRUE;
	    		}
			}

			if (RdosReadSerialLines(1, &diostat))
			{
				if (diostat & 0x20)
				{
					if (!FVpOn)
					{
					    FLevel = 0.0;
						RdosToggleSerialLine(1, 5);
                    }						
				}
				else
				{
					if (FVpOn)
					{
					    FLevel = 9.9;
						RdosToggleSerialLine(1, 5);
					}
				}

				if (diostat & 0x40)
				{
					if (!FEpOn)
						RdosToggleSerialLine(1, 6);
				}
				else
				{
					if (FEpOn)
						RdosToggleSerialLine(1, 6);
				}

			}

			sprintf(str, "VP: %4.1Lf", FLevel);

			vbe->SetFilledStyle();
			vbe->SetDrawColor(0, 0, 0);
			vbe->DrawRect(550, 300, 550 + 100, 300 + 12);

			vbe->SetDrawColor(255, 255, 255);
			vbe->DrawString(550, 300, str);

		}

		RdosWaitMilli(1000);
	}
}
