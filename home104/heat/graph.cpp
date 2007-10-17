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
# httpheat
# Http for heat class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include "rdos.h"
#include "graph.h"
#include "log.h"
#include "linxaxis.h"
#include "linyaxis.h"
#include "timeaxis.h"
#include "chart.h"

#define FALSE	0
#define TRUE	!FALSE

/*##########################################################################
#
#   Name       : TGraphic::TGraphic
#
#   Purpose....: Constructor for TGraphic
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGraphic::TGraphic(TGraphicDevice *dev, TLog *log)
{
    vbe = new TGraphicDevice(*dev);
    Log = log;
	FAddress = 0x20;
    Show();
    Start("Graphic", 0x4000);
}

/*##########################################################################
#
#   Name       : TGraphic::~TGraphic
#
#   Purpose....: Destructor for TGraphic
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGraphic::~TGraphic()
{
    delete vbe;
}

/*##########################################################################
#
#   Name       : TGraphic::Show
#
#   Purpose....: Show current
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphic::Show()
{
	TLogReader *log;
	TDeviceMsg *msg;
    TDeviceTag *header;
	TDeviceTag *tag;
	TDeviceVar *var;
	int index;
	int ival;
	int i;
	long double val;
	unsigned long msb;
	unsigned long lsb;
	TDateTime prevtime;
	TDateTime time;
	TDateTime firsttime;
	TDateTime lasttime;
	TDateTime currtime;
	int skip;
	int year;
	int month;
	int day;
	int sameday;
	int firstpass;
	TFont Font(10);
	TLinYAxis TempAxis(&Font);
	TTimeXAxis TimeScaleAxis(&Font);
	TTimeXAxis TimeAxis;
	TChart *TempChart;
	TChart *PowerChart;
	TChart *LightChart;
	TChart *WindChart;
	TChart *VpChart;
	int width;
	int retry;
	long double ymin;
	long double ymax;
	TDateTime from;
	TDateTime to;
	int Line1;
	int Line2;
	int Line3;
	int Line4;
	int Line5;

	from.AddDay(-1);

	TimeAxis.Hide();

	TempChart = new TChart(vbe, &TimeAxis, &TempAxis);
	PowerChart = new TChart(vbe, &TimeAxis, &TempAxis);
	LightChart = new TChart(vbe, &TimeAxis, &TempAxis);
	WindChart = new TChart(vbe, &TimeAxis, &TempAxis);
	VpChart = new TChart(vbe, &TimeScaleAxis, &TempAxis);

	TempChart->SetWindow(0, 0, 439, 269);
	PowerChart->SetWindow(0, 270, 439, 309);
	LightChart->SetWindow(0, 310, 439, 349);
	WindChart->SetWindow(0, 350, 439, 379);
	VpChart->SetWindow(0, 380, 439, 399);

	vbe->SetClipRect(440, 0, 529, 399);
	vbe->SetDrawColor(0, 0, 0);
	vbe->SetFilledStyle();
	vbe->DrawRect(440, 0, 529, 399);
	vbe->SetFont(&Font);

	vbe->SetDrawColor(255, 0, 0);
	vbe->DrawString(442, 20, "Tank");

	vbe->SetDrawColor(128, 255, 0);
	vbe->DrawString(442, 40, "Temperatur");

	vbe->SetDrawColor(255, 128, 0);
	vbe->DrawString(442, 60, "Temperatur 2");

	vbe->SetDrawColor(0, 128, 255);
	vbe->DrawString(442, 80, "Referens");

	vbe->SetDrawColor(128, 128, 128);
	vbe->DrawString(442, 140, "Utetemperatur");

	vbe->SetDrawColor(128, 255, 0);
	vbe->DrawString(442, 270, "P†drag");

	vbe->SetDrawColor(255, 128, 0);
	vbe->DrawString(442, 290, "Cirkulation");

	vbe->SetDrawColor(128, 128, 240);
	vbe->DrawString(442, 360, "Vind");

	vbe->SetDrawColor(255, 128, 0);
	vbe->DrawString(442, 330, "Ljus");

	vbe->SetDrawColor(255, 0, 0);
	vbe->DrawString(442, 380, "V„rmepump");

	TimeScaleAxis.SetForeColor(255, 255, 255);
	TimeScaleAxis.SetBackColor(0, 0, 0);

	TempAxis.SetForeColor(255, 255, 255);
	TempAxis.SetBackColor(0, 0, 0);

	TempChart->SetBackColor(0, 0, 0);

	Line1 = 99;
	Line2 = 124;
	Line3 = 149;
	Line4 = 174;
	Line5 = 199;

	PowerChart->SetBackColor(0, 0, 0);

	WindChart->SetBackColor(0, 0, 0);

	LightChart->SetBackColor(0, 0, 0);

	VpChart->SetBackColor(0, 0, 0);

	year = from.GetYear();
	month = from.GetMonth();
	day = from.GetDay();

	TempChart->SetXAxis(from, to);
	PowerChart->SetXAxis(from, to);
	LightChart->SetXAxis(from, to);
	WindChart->SetXAxis(from, to);
	VpChart->SetXAxis(from, to);

    for (i = 0; i <= 25; i++) 
    {
        TempChart->SetLineColor(i, 60, 60, 60);
    	
    	val = (long double)i;
	    TempChart->Add(i, from, val);
	    TempChart->Add(i, to, val);
    }

    for (i = 0; i <= 10; i += 2) 
    {
        PowerChart->SetLineColor(i, 60, 60, 60);

    	val = (long double)i;
	    PowerChart->Add(i, from, val);
		PowerChart->Add(i, to, val);
    }

    prevtime = from;
    prevtime.AddDay(-1);
    
    firstpass = TRUE;
    sameday = FALSE;
    while (!sameday)
    {    
        if (firstpass)
        {
            firsttime = TDateTime(year, month, day, from.GetHour(), from.GetMin(), 0, 0);
            currtime = TDateTime(year, month, day, 0, 0, 0, 0);
            firstpass = FALSE;
        }
        else
        {
            currtime.AddDay(1);
            firsttime = currtime;
        }

    	sameday = TRUE;

        year = firsttime.GetYear();
        month = firsttime.GetMonth();
		day = firsttime.GetDay();

    	if (year != to.GetYear())
	        sameday = FALSE;

    	if (month != to.GetMonth())
			  sameday = FALSE;

    	if (day != to.GetDay())
	        sameday = FALSE;
        
	    if (sameday)
            lasttime = TDateTime(year, month, day, to.GetHour(), to.GetMin(), 59, 999);
        else
            lasttime = TDateTime(year, month, day, 23, 59, 59, 999);
                
	    log = Log->GetLog(year, month, day);

    	if (log->GotoFirst())
            msg = log->Get();
		else
	        msg = 0;

		while (msg)
	    {
			header = msg->GetTag(LOG_TAG_HEADER);
    		if (header)
	    	{
		        msb = header->GetUnsignedInt(LOG_VAR_MsbTime, 0);
			    lsb = header->GetUnsignedInt(LOG_VAR_LsbTime, 0);
    			time = TDateTime(msb, lsb);

    			prevtime.AddMin(5);

    			if (prevtime < time)
    			{
    			    Line1++;
    			    Line2++;
    			    Line3++;
    			    Line4++;
    			    Line5++;
    			    
                	TempChart->SetLineColor(Line1, 128, 128, 128);
                	TempChart->SetLineColor(Line2, 128, 255, 0);
                	TempChart->SetLineColor(Line3, 255, 128, 0);
                	TempChart->SetLineColor(Line4, 0, 128, 255);
                	TempChart->SetLineColor(Line5, 255, 0, 0);
                	PowerChart->SetLineColor(Line1, 128, 255, 0);
            	    PowerChart->SetLineColor(Line2, 255, 128, 0);
                	WindChart->SetLineColor(Line1, 128, 128, 240);
                	LightChart->SetLineColor(Line1, 255, 128, 0);
                	VpChart->SetLineColor(Line1, 255, 0, 0);

                	skip = TRUE;
                }
                else
                    skip = FALSE;

                prevtime = time;

    			if (time >= firsttime && time <= lasttime && !skip)
    			{
    	    	    tag = msg->GotoFirstTag();
	    	        while (tag)
		            {
                        if (tag->GetID() == LOG_TAG_OUTDOOR)
                        {
        			        var = tag->GetVar(LOG_VAR_Temp);
    	        			if (var)
	    		    		{
		    	        	    ival = var->GetFloat1();

		    	        	    if (ival < 500)
		    	        	    {
    								val = (long double)ival;
	    			                val = val / 10.0;
        
		    						TempChart->Add(Line1, time, val);
		    				    }
    	        		    }

        			        var = tag->GetVar(LOG_VAR_Windspeed);
    	        			if (var)
	    		    		{
		    	        	    ival = var->GetFloat1();
								val = (long double)ival;
				                val = val / 10.0;
    
								WindChart->Add(Line1, time, val);
    	        		    }
	            		}
                		    
                        if (tag->GetID() == LOG_TAG_TANK)
                        {
        			        var = tag->GetVar(LOG_VAR_Temp);
    	        			if (var)
	    		    		{
		    	        	    ival = var->GetFloat1();

		    	        	    if (ival < 500)
		    	        	    {
    								val = (long double)ival;
	    			                val = val / 10.0;
        
		    						TempChart->Add(Line5, time, val);
		    				    }
    	        		    }
	            		}
                		    
		                if (tag->GetID() == LOG_TAG_RAD)
		                {
		                    index = tag->GetSignedInt(LOG_VAR_Address, -1);
    					    if (index == FAddress)
        		            {
	        	                var = tag->GetVar(LOG_VAR_Temp);
		                        if (var)
		                        {
									ival = var->GetFloat1();

									if (ival < 500)
									{
										val = (long double)ival;
										val = val / 10.0;

										TempChart->Add(Line2, time, val);
									}
								}

								var = tag->GetVar(LOG_VAR_AuxTemp);
								if (var)
								{
									ival = var->GetFloat1();

									if (ival < 500)
									{
										val = (long double)ival;
										val = val / 10.0;

										TempChart->Add(Line3, time, val);
									}
								}

								var = tag->GetVar(LOG_VAR_Ref);
								if (var)
								{
									ival = var->GetFloat1();

									if (ival < 500)
									{
										val = (long double)ival;
										val = val / 10.0;

										TempChart->Add(Line4, time, val);
									}
								}

								var = tag->GetVar(LOG_VAR_Motor);
								if (var)
								{
									ival = var->GetFloat1();
									val = (long double)ival;
									val = val / 10.0;

									PowerChart->Add(Line1, time, val);
								}

								var = tag->GetVar(LOG_VAR_Light);
								if (var)
								{
									ival = var->GetFloat1();
									val = (long double)ival;
									val = val / 10.0;

									LightChart->Add(Line1, time, val);
								}
							}
						}

						if (tag->GetID() == LOG_TAG_CIRC)
						{
							var = tag->GetVar(LOG_VAR_Motor);
							if (var)
							{
								ival = var->GetFloat1();
								val = (long double)ival;
								val = val / 10.0;

								PowerChart->Add(Line2, time, val);
							}
            			}

                        if (tag->GetID() == LOG_TAG_VP)
                        {
							var = tag->GetVar(LOG_VAR_On);
		                    if (var)
		                    {
								if (var->GetBoolean())
		                            val = 1.0;
		                        else
		                            val = 0.0;

            					VpChart->Add(Line1, time, val);
            			    }
            			}

			        	tag = msg->GotoNextTag();
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

	currtime = TDateTime(from.GetYear(), from.GetMonth(), from.GetDay(), from.GetHour(), 0, 0, 0);

    i = 30;    
    while (currtime < to) 
    {
        TempChart->SetLineColor(i, 60, 60, 60);
    	
	    TempChart->Add(i, currtime, 0.0);
	    TempChart->Add(i, currtime, 25.0);

        PowerChart->SetLineColor(i, 60, 60, 60);
    	
	    PowerChart->Add(i, currtime, 0.0);
	    PowerChart->Add(i, currtime, 10.0);

	    LightChart->GetYAxis(&ymin, &ymax);
	    if (ymax < 10.0)
	        ymax = 10.0;

        LightChart->SetLineColor(i, 60, 60, 60);
    	
	    LightChart->Add(i, currtime, 0.0);
	    LightChart->Add(i, currtime, ymax);

	    WindChart->GetYAxis(&ymin, &ymax);
	    if (ymax < 5.0)
	        ymax = 5.0;

        WindChart->SetLineColor(i, 60, 60, 60);
    	
	    WindChart->Add(i, currtime, 0.0);
	    WindChart->Add(i, currtime, ymax);

        VpChart->SetLineColor(i, 60, 60, 60);
    	
	    VpChart->Add(i, currtime, 0.0);
	    VpChart->Add(i, currtime, 1.0);

		i++;
		currtime.AddHour(1);
	}

    retry = FALSE;

	TempChart->Draw();

	width = TempAxis.RequiredWidth();
	TempAxis.SetMinWidth(width);

	PowerChart->Draw();
    if (width < TempAxis.RequiredWidth())
    {
        retry = TRUE;
    	width = TempAxis.RequiredWidth();
    	TempAxis.SetMinWidth(width);
    }
	
	LightChart->Draw();
    if (width < TempAxis.RequiredWidth())
    {
        retry = TRUE;
    	width = TempAxis.RequiredWidth();
    	TempAxis.SetMinWidth(width);
    }
	
	WindChart->Draw();
    if (width < TempAxis.RequiredWidth())
    {
        retry = TRUE;
    	width = TempAxis.RequiredWidth();
    	TempAxis.SetMinWidth(width);
    }
	
	VpChart->Draw();
    if (width < TempAxis.RequiredWidth())
    {
        retry = TRUE;
    	width = TempAxis.RequiredWidth();
    	TempAxis.SetMinWidth(width);
    }

    if (retry)	
    {
        TempChart->Draw();
        PowerChart->Draw();
        LightChart->Draw();
        WindChart->Draw();
        VpChart->Draw();
    }

    delete VpChart;
    delete WindChart;
    delete LightChart;
    delete PowerChart;
    delete TempChart;
}

/*##########################################################################
#
#   Name       : TGraphic::Execute
#
#   Purpose....: Execute module
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphic::Execute()
{
	while (FInstalled)
	{
	    RdosWaitMilli(30000);
	    RdosWaitMilli(30000);
	    Show();
	}
}
