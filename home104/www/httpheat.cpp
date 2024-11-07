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
#include "httpfact.h"
#include "httpheat.h"
#include "sigdev.h"
#include "rad.h"
#include "log.h"

#define FALSE 0
#define TRUE !FALSE

#define WWWROOT "e:\\wwwroot"

TSection SignalSection;
TSignalDevice *SignalList = 0;

int RadCount = 0;
TRad *RadArr[15];
TWs2300 *Ws2300 = 0;
int LightOn = FALSE;
TCirc *Circ;
TVp *Vp;
TLog *Log;

/*##########################################################################
#
#   Name       : round
#
#   Purpose....: round a float to int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int round(long double val)
{
	return (int)(val + 0.5);
}

/*##########################################################################
#
#   Name       : HttpUpdate
#
#   Purpose....: Signal all screen objects
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void HttpUpdate()
{
    TSignalDevice *Signal;
    
    SignalSection.Enter();

    Signal = SignalList;
    while (Signal)
    {
        Signal->Signal();
        Signal = Signal->List;
    }

    SignalSection.Leave();
}

/*##########################################################################
#
#   Name       : InsertSignal
#
#   Purpose....: Insert signal into list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InsertSignal(TSignalDevice *Signal)
{
	SignalSection.Enter();
	Signal->List = SignalList;
	SignalList = Signal;
	SignalSection.Leave();
}

/*##########################################################################
#
#   Name       : RemoveSignal
#
#   Purpose....: Remove signal from list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void RemoveSignal(TSignalDevice *Signal)
{
	TSignalDevice *ptr;
	TSignalDevice *prev;
	prev = 0;

	SignalSection.Enter();
	
	ptr = SignalList;
	while (ptr && ptr != Signal)
    {
		prev = ptr;
		ptr = ptr->List;
    }
    
	if (prev == 0)
		SignalList = SignalList->List;
	else
		prev->List = ptr->List;
		
	SignalSection.Leave();
}

/*##########################################################################
#
#   Name       : THttpTablePage::THttpTablePage
#
#   Purpose....: Constructor for THttpTablePage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpTablePage::THttpTablePage(THttpCommand *Cmd, const char *FileName, const char *Param)
  : THttpCustomPage(Cmd, FileName, Param)
{
}

/*##########################################################################
#
#   Name       : THttpTablePage::~THttpTablePage
#
#   Purpose....: Destructor for THttpTablePage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpTablePage::~THttpTablePage()
{
}

/*##################  THttpTablePage::WriteCenteredFieldHeader ##########################
*   Purpose....: Write centered field header for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void THttpTablePage::WriteCenteredFieldHeader(TFile &File, int RelWidth)
{
    char str[80];

    sprintf(str, "\n<td width=\"%d%\" colspan=2 valign=top>\n", RelWidth);
    File.Write(str);

	File.Write("<p align=\"center\">\n");
	File.Write("<b>\n");
}

/*##################  THttpTablePage::WriteRightFieldHeader ##########################
*   Purpose....: Write right-aligned field header for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void THttpTablePage::WriteRightFieldHeader(TFile &File, int RelWidth)
{
    char str[80];

    sprintf(str, "\n<td width=\"%d%\" colspan=2 valign=top>\n", RelWidth);
    File.Write(str);

	File.Write("<p align=\"right\">\n");
	File.Write("<b>\n");
}

/*##################  THttpTablePage::WriteLeftFieldHeader ##########################
*   Purpose....: Write left-aligned field header for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void THttpTablePage::WriteLeftFieldHeader(TFile &File, int RelWidth)
{
	 char str[80];

	 sprintf(str, "\n<td width=\"%d%\" colspan=2 valign=top>\n", RelWidth);
	 File.Write(str);

	File.Write("<p align=\"left\">\n");
	File.Write("<b>\n");
}

/*##################  THttpTablePage::WriteFieldFooter ##########################
*   Purpose....: Write field footer for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void THttpTablePage::WriteFieldFooter(TFile &File)
{
    File.Write("\n</b>\n");
	File.Write("</p>\n");

	 File.Write("</td>\n");
}

/*##################  THttpTablePage::WriteFloat1 ##########################
*   Purpose....: Write long double with one decimal point	    	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void THttpTablePage::WriteFloat1(TFile &File, long double val)
{
    char str[40];
    int ival;

    ival = round(10 * val);
    
    if (ival < 0)
    {
        File.Write("-");
        ival = -ival;
    }

	sprintf(str, "%d.%d", ival / 10, ival % 10);
	File.Write(str);
}

/*##########################################################################
#
#   Name       : THttpWs2300Page::THttpWs2300Page
#
#   Purpose....: Constructor for THttpWs2300Page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpWs2300Page::THttpWs2300Page(THttpCommand *Cmd, const char *FileName)
  : THttpTablePage(Cmd, FileName, "")
{
}

/*##########################################################################
#
#   Name       : THttpWs2300Page::~THttpWs2300Page
#
#   Purpose....: Destructor for THttpWs2300Page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpWs2300Page::~THttpWs2300Page()
{
}

/*##########################################################################
#
#   Name       : THttpWs2300Page::Get
#
#   Purpose....: Get dynamic page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpWs2300Page::Get(const char *Name)
{
	int ival;
	int r;
	int count;
	char str[100];
	TFile File(FFileName.GetData(), 0);
	TString RowStr;
	int row;
	TSignalDevice Signal;

	InsertSignal(&Signal);

	StartPush();

	while (FCmd->IsOpen() && FCmd->IsEmpty())
	{
		File.SetSize(0);
		File.SetPos(0);

		File.Write("<META HTTP-EQUIV=\"Refresh\" CONTENT=30>\r\n");
		File.Write("<meta http-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\">\r\n");
		File.Write("<html><body>\r\n");
		File.Write("<form action=\"/\" method=\"post\">\r\n");

		File.Write("<body background=\"/water040.jpg\">");

		File.Write("<CENTER>\n");

		File.Write("<h1>");
		File.Write("Väderstation");
		File.Write("</h1>");

		File.Write("<h3>");
		File.Write("Inomhus");
		File.Write("</h3>");

		File.Write("<p><b>");
		File.Write("Temperatur: ");
		WriteFloat1(File, Ws2300->GetIndoorTemp());
		File.Write(" °C");
		File.Write("</b></p>");

		File.Write("<p><b>");
		ival = round(Ws2300->GetIndoorHumidity());
		sprintf(str, "Fuktighet: %d%", ival);
		File.Write(str);
		File.Write("</b></p>");

		File.Write("<h3>");
		File.Write("Utomhus");
		File.Write("</h3>");

		File.Write("<p><b>");
		File.Write("Temperatur: ");
		WriteFloat1(File, Ws2300->GetOutdoorTemp());
		File.Write(" °C");
		File.Write("</b></p>");

		File.Write("<p><b>");
		ival = round(Ws2300->GetOutdoorHumidity());
		sprintf(str, "Fuktighet: %d%", ival);
		File.Write(str);
		File.Write("</b></p>");

		File.Write("<p><b>");
		File.Write("Daggpunkt: ");
		WriteFloat1(File, Ws2300->GetDewPoint());
		File.Write(" °C");
		File.Write("</b></p>");

		File.Write("<p><b>");
		File.Write("Vindkompenserad: ");
		WriteFloat1(File, Ws2300->GetWindChill());
		File.Write(" °C");
		File.Write("</b></p>");

		File.Write("<p><b>");
		File.Write("Vind: ");
		WriteFloat1(File, Ws2300->GetWindSpeed());
		File.Write(" m/s ");

		ival = round(Ws2300->GetWindDir() / 22);
		  switch (ival)
		  {
				case 0:
					 File.Write("N");
					 break;

				case 1:
					 File.Write("NNO");
					 break;

				case 2:
					 File.Write("NO");
					 break;

				case 3:
					 File.Write("ONO");
					 break;

				case 4:
					 File.Write("O");
					 break;

				case 5:
					 File.Write("OSO");
					 break;

				case 6:
					 File.Write("SO");
					 break;

				case 7:
					 File.Write("SSO");
					 break;

				case 8:
					 File.Write("S");
					 break;

				case 9:
					 File.Write("SSV");
					 break;

				case 10:
					 File.Write("SV");
					 break;

				case 11:
					 File.Write("VSV");
					 break;

				case 12:
					 File.Write("V");
					 break;

				case 13:
					 File.Write("VNV");
					 break;

				case 14:
					 File.Write("NV");
					 break;

				case 15:
					 File.Write("NNV");
					 break;

				case 16:
					 File.Write("N");
					 break;
		  }
		File.Write("</b></p>");

		File.Write("<p><b>");
		File.Write("Lufttryck: ");
		WriteFloat1(File, Ws2300->GetAirPressure());
		File.Write(" hPa");
		File.Write("</b></p>");

		File.Write("<p><b>");
		ival = round(10 * Ws2300->GetRain24h());
		sprintf(str, "Regn: 24 timmar: %d.%d mm", ival / 10, ival % 10);
		File.Write(str);
		File.Write("</b></p>");

		File.Write("<p><b>");
		ival = round(10 * Ws2300->GetRain1h());
		sprintf(str, "Regn 1 timme: %d.%d mm", ival / 10, ival % 10);
		File.Write(str);
		File.Write("</b></p>");

		switch (Ws2300->GetForecast())
		{
			case FORECAST_RAINY:
				File.Write("<img border=\"0\" src=\"/rain.gif\" width=\"36\" height=\"26\">");
				break;

			case FORECAST_CLOUDY:
				File.Write("<img border=\"0\" src=\"/cloudy.gif\" width=\"36\" height=\"20\">");
				break;

			case FORECAST_SUNNY:
				File.Write("<img border=\"0\" src=\"/sun.gif\" width=\"28\" height=\"26\">");
				break;
		}

		File.Write("   ");

		switch (Ws2300->GetTendency())
		{
			case TENDENCY_RISING:
				File.Write("<img border=\"0\" src=\"/up.gif\" width=\"12\" height=\"25\">");
				break;

			case TENDENCY_FALLING:
				File.Write("<img border=\"0\" src=\"/down.gif\" width=\"12\" height=\"26\">");
				break;
		}

		File.Write("</CENTERED>\n");

		File.Write("</form>\r\n");
		File.Write("</body></html>\r\n");

		if (!PushFile(FFileName.GetData(), "text/html", 30))
			break;

		Signal.WaitTimeout(25000);

		RdosWaitMilli(50);
		Signal.Clear();
	}

	RemoveSignal(&Signal);
}


/*##########################################################################
#
#   Name       : THttpWs2300Factory::THttpWs2300PageFactory
#
#   Purpose....: Constructor for THttpWs2300PageFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpWs2300PageFactory::THttpWs2300PageFactory(const char *ReqName)
  : THttpCustomPageFactory(ReqName)
{
}

/*##########################################################################
#
#   Name       : THttpWs2300PageFactory::~THttpWs2300PageFactory
#
#   Purpose....: Destructor for THttpWs2300PageFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpWs2300PageFactory::~THttpWs2300PageFactory()
{
}

/*##########################################################################
#
#   Name       : THttpWs2300PageFactory::Create
#
#   Purpose....: Create an instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPage *THttpWs2300PageFactory::Create(THttpCommand *Cmd, const char *Param)
{
	THttpWs2300Page *page;

	TString tempname = CreateUniqueFile(Cmd);
	page = new THttpWs2300Page(Cmd, tempname.GetData());
	return page;
}

/*##########################################################################
#
#   Name       : THttpRadPage::THttpRadPage
#
#   Purpose....: Constructor for THttpRadPage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpRadPage::THttpRadPage(THttpCommand *Cmd, const char *FileName, const char *Param)
  : THttpTablePage(Cmd, FileName, Param)
{
}

/*##########################################################################
#
#   Name       : THttpRadPage::~THttpRadPage
#
#   Purpose....: Destructor for THttpRadPage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpRadPage::~THttpRadPage()
{
}

/*##########################################################################
#
#   Name       : THttpRadPage::CreateTempJpeg
#
#   Purpose....: Create temperature jpeg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJpegBitmapDevice *THttpRadPage::CreateTempJpeg(int address, TDateTime &from, TDateTime &to)
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
	int year;
	int month;
	int day;
	int sameday;
	int firstpass;
	TJpegBitmapDevice *Jpeg = new TJpegBitmapDevice(24, 580, 400);
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
    int skip;
	int Line1;
	int Line2;
	int Line3;
	int Line4;
	int Line5;
	int Line6;

	TimeAxis.Hide();

	TempChart = new TChart(Jpeg, &TimeAxis, &TempAxis);
    PowerChart = new TChart(Jpeg, &TimeAxis, &TempAxis);
	LightChart = new TChart(Jpeg, &TimeAxis, &TempAxis);
	WindChart = new TChart(Jpeg, &TimeAxis, &TempAxis);
	VpChart = new TChart(Jpeg, &TimeScaleAxis, &TempAxis);

	TempChart->SetWindow(0, 0, 489, 269);
	PowerChart->SetWindow(0, 270, 489, 309);
	LightChart->SetWindow(0, 310, 489, 349);
	WindChart->SetWindow(0, 350, 489, 379);
	VpChart->SetWindow(0, 380, 489, 399);

	Jpeg->SetClipRect(490, 0, 579, 399);
	Jpeg->SetDrawColor(255, 255, 255);
	Jpeg->SetFilledStyle();
	Jpeg->DrawRect(490, 0, 579, 399); 
	Jpeg->SetFont(&Font);

	Jpeg->SetDrawColor(255, 0, 0);
	Jpeg->DrawString(442, 20, "Panna");
	
	Jpeg->SetDrawColor(255, 0, 255);
	Jpeg->DrawString(492, 40, "Tank");

	Jpeg->SetDrawColor(128, 255, 0);
	Jpeg->DrawString(492, 60, "Temperatur");

	Jpeg->SetDrawColor(255, 128, 0);
	Jpeg->DrawString(492, 80, "Temperatur 2");

	Jpeg->SetDrawColor(0, 128, 255);
	Jpeg->DrawString(492, 100, "Referens");
	
	Jpeg->SetDrawColor(128, 128, 128);
	Jpeg->DrawString(492, 140, "Utetemperatur");

	Jpeg->SetDrawColor(128, 255, 0);
	Jpeg->DrawString(492, 270, "P†drag");
	
	Jpeg->SetDrawColor(255, 128, 0);
	Jpeg->DrawString(492, 290, "Cirkulation");

	Jpeg->SetDrawColor(128, 128, 240);
	Jpeg->DrawString(492, 360, "Vind");

	Jpeg->SetDrawColor(255, 128, 0);
	Jpeg->DrawString(492, 330, "Ljus");

	Jpeg->SetDrawColor(255, 0, 0);
	Jpeg->DrawString(492, 380, "V„rmepump");

	TimeScaleAxis.SetForeColor(0, 0, 0);
	TimeScaleAxis.SetBackColor(255, 255, 255);

	TempAxis.SetForeColor(0, 0, 0);
	TempAxis.SetBackColor(255, 255, 255);

	TempChart->SetBackColor(255, 255, 255);

	Line1 = 99;
	Line2 = 124;
	Line3 = 149;
	Line4 = 174;
	Line5 = 199;
	Line6 = 224;

	PowerChart->SetBackColor(255, 255, 255);

	WindChart->SetBackColor(255, 255, 255);

	LightChart->SetBackColor(255, 255, 255);

	VpChart->SetBackColor(255, 255, 255);

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
        TempChart->SetLineColor(i, 210, 210, 210);
    	
    	val = (long double)i;
	    TempChart->Add(i, from, val);
	    TempChart->Add(i, to, val);
    }

    for (i = 0; i <= 10; i += 2) 
    {
        PowerChart->SetLineColor(i, 210, 210, 210);

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
				firsttime = TDateTime(year, month, day, from.GetHour(), from.GetMin(), 0, 0, 0);
				currtime = TDateTime(year, month, day, 0, 0, 0, 0, 0);
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
				lasttime = TDateTime(year, month, day, to.GetHour(), to.GetMin(), 59, 999, 999);
		  else
				lasttime = TDateTime(year, month, day, 23, 59, 59, 999, 999);

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
    			    Line6++;
    			    
                	TempChart->SetLineColor(Line1, 128, 128, 128);
                	TempChart->SetLineColor(Line2, 128, 255, 0);
                	TempChart->SetLineColor(Line3, 255, 128, 0);
                	TempChart->SetLineColor(Line4, 0, 128, 255);
                	TempChart->SetLineColor(Line5, 255, 0, 255);
                	TempChart->SetLineColor(Line6, 255, 0, 0);
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

		    	        	    if (ival < 900)
		    	        	    {
    								val = (long double)ival;
	    			                val = val / 10.0;
        
		    						TempChart->Add(Line5, time, val);
		    				    }
    	        		    }
	            		}

                        if (tag->GetID() == LOG_TAG_HEAT)
                        {
        			        var = tag->GetVar(LOG_VAR_Temp);
    	        			if (var)
	    		    		{
		    	        	    ival = var->GetFloat1();

		    	        	    if (ival < 900)
		    	        	    {
    								val = (long double)ival;
	    			                val = val / 10.0;
        
		    						TempChart->Add(Line6, time, val);
		    				    }
    	        		    }
	            		}
                		    
		                if (tag->GetID() == LOG_TAG_RAD)
		                {
		                    index = tag->GetSignedInt(LOG_VAR_Address, -1);
    					    if (index == address)
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

	currtime = TDateTime(from.GetYear(), from.GetMonth(), from.GetDay(), from.GetHour(), 0, 0, 0, 0);

	 i = 30;
	 while (currtime < to)
	 {
        TempChart->SetLineColor(i, 210, 210, 210);
    	
	    TempChart->Add(i, currtime, 0.0);
	    TempChart->Add(i, currtime, 25.0);

        PowerChart->SetLineColor(i, 210, 210, 210);
    	
	    PowerChart->Add(i, currtime, 0.0);
	    PowerChart->Add(i, currtime, 10.0);

	    LightChart->GetYAxis(&ymin, &ymax);
	    if (ymax < 10.0)
	        ymax = 10.0;

        LightChart->SetLineColor(i, 210, 210, 210);
    	
	    LightChart->Add(i, currtime, 0.0);
	    LightChart->Add(i, currtime, ymax);

	    WindChart->GetYAxis(&ymin, &ymax);
	    if (ymax < 5.0)
	        ymax = 5.0;

        WindChart->SetLineColor(i, 210, 210, 210);
    	
	    WindChart->Add(i, currtime, 0.0);
	    WindChart->Add(i, currtime, ymax);

        VpChart->SetLineColor(i, 210, 210, 210);

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
    
    return Jpeg;
}

/*##########################################################################
#
#   Name       : THttpRadPage::CreateHistTempJpeg
#
#   Purpose....: Create history temperature jpeg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpRadPage::CreateHistoryTempJpeg(int address, int year, int month, int day)
{
    char str[256];
    char filename[256];
	TJpegBitmapDevice *Jpeg;
	TLogReader *log;
	TDateTime from = TDateTime(year, month, day, 0, 0, 0, 0, 0);
	TDateTime to = TDateTime(year, month, day, 23, 59, 59, 999, 999);
	TDateTime today;

	if (today.GetYear() == year && today.GetMonth() == month &&  today.GetDay() == day)
		 return FALSE;

	if (!Log)
		 return FALSE;

	log = Log->GetLog(year, month, day);
	if (!log)
		 return FALSE;

    delete log;

	Jpeg = CreateTempJpeg(address, from, to);

	strcpy(filename, WWWROOT);
	strcat(filename, "\\");
	strcat(filename, "image");

	if (!RdosSetCurDir(filename))
		RdosMakeDir(filename);

	sprintf(str, "image\\%d", address);
	strcpy(filename, WWWROOT);
	strcat(filename, "\\");
	strcat(filename, str);

	if (!RdosSetCurDir(filename))
		RdosMakeDir(filename);

	sprintf(str, "image\\%d\\%d", address, year);
	strcpy(filename, WWWROOT);
	strcat(filename, "\\");
	strcat(filename, str);

	if (!RdosSetCurDir(filename))
		RdosMakeDir(filename);

	sprintf(str, "image\\%d\\%d\\%d", address, year, month);
	strcpy(filename, WWWROOT);
	strcat(filename, "\\");
	strcat(filename, str);

	if (!RdosSetCurDir(filename))
		RdosMakeDir(filename);

	sprintf(str, "image\\%d\\%d\\%d\\%d.jpg", address, year, month, day);
	strcpy(filename, WWWROOT);
	strcat(filename, "\\");
	strcat(filename, str);

	if (Jpeg)
	{
		Jpeg->Save(filename);
		delete Jpeg;
		return TRUE;
	}

	return FALSE;
}

/*##########################################################################
#
#   Name       : THttpRadPage::WriteHistTemp
#
#   Purpose....: Write history html-document
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpRadPage::WriteHistoryTemp(int address, int year, int month, int day)
{
    char str[256];
    char filename[256];
	int handle;
	int ok;
    TDateTime time;
	TFile File(FFileName.GetData(), 0);

	sprintf(str, "image\\%d\\%d\\%d\\%d.jpg", address, year, month, day);
    strcpy(filename, WWWROOT);
    strcat(filename, "\\");
    strcat(filename, str);

    handle = RdosOpenHandle(filename, O_RDWR);
    if (handle > 0)
    {
	    ok = TRUE;
        RdosCloseHandle(handle);
    }
    else
        ok = CreateHistoryTempJpeg(address, year, month, day);

    if (ok)
	{
    	File.Write("<IMG SRC=\"");
        sprintf(str, "/image/%d/%d/%d/%d.jpg", address, year, month, day);
    	File.Write(str);
        File.Write("\" align=bottom width=580 height=400 border=0>");

    	WriteFile(FFileName.GetData(), "text/html");
    }
	else
        WriteError(404);
}

/*##########################################################################
#
#   Name       : THttpRadPage::CreateCurrTempJpeg
#
#   Purpose....: Write current temperature jpeg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpRadPage::CreateCurrTempJpeg(int address)
{
	char str[256];
	char filename[256];
	TDateTime from;
	TDateTime to;
	TJpegBitmapDevice *Jpeg;

	from.AddDay(-1);

	Jpeg = CreateTempJpeg(address, from, to);

	strcpy(filename, WWWROOT);
	strcat(filename, "\\");
	strcat(filename, "image");

	if (!RdosSetCurDir(filename))
		RdosMakeDir(filename);

	sprintf(str, "\\%d.jpg", address);
	strcat(filename, str);

	if (Jpeg)
	{
		Jpeg->Save(filename);
		delete Jpeg;
		return TRUE;
	}
	else
    	return FALSE;
}

/*##########################################################################
#
#   Name       : THttpRadPage::WriteTemp
#
#   Purpose....: Write temp html-document
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpRadPage::WriteTemp(int address)
{
    char str[256];
    char filename[256];
	int handle;
	int ok;
    TDateTime time;
    TDateTime filetime;
	TFile File(FFileName.GetData(), 0);
	unsigned long Msb, Lsb;

    sprintf(str, "image\\%d.jpg", address);
    strcpy(filename, WWWROOT);
    strcat(filename, "\\");
    strcat(filename, str);

    handle = RdosOpenHandle(filename, O_RDWR);
    if (handle > 0)
    {
        RdosGetHandleModifyTime(handle, &Msb, &Lsb);
        filetime = TDateTime(Msb, Lsb);
        filetime.AddMin(5);

        if (filetime > time)
            ok = TRUE;
        else
            ok = FALSE;

        RdosCloseHandle(handle);
    }
    else
        ok = FALSE;

    if (!ok)
		ok = CreateCurrTempJpeg(address);

	if (ok)
	{
		File.Write("<IMG SRC=\"");
        sprintf(str, "/rad/%d.jpg", address);
        File.Write(str);
        File.Write("\" align=bottom width=580 height=400 border=0>");

        WriteFile(FFileName.GetData(), "text/html");
    }
    else
        WriteError(404);
}


/*##########################################################################
#
#   Name       : THttpRadPage::WriteTempJpeg
#
#   Purpose....: Write temp jpeg-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpRadPage::WriteTempJpeg(int address)
{
    char str[256];
    char filename[256];

    sprintf(str, "image\\%d.jpg", address);
    strcpy(filename, WWWROOT);
    strcat(filename, "\\");
    strcat(filename, str);

    WriteFile(filename, "jpeg/jpeg");
}

/*##########################################################################
#
#   Name       : THttpRadPage::WriteMain
#
#   Purpose....: Write main page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpRadPage::WriteMain()
{
    long double val;
	int ival;
	int r;
	int count;
	char str[40];
	TString RowStr;
	int row;
	TFile File(FFileName.GetData(), 0);

	TSignalDevice Signal;

	InsertSignal(&Signal);

	StartPush();

	while (FCmd->IsOpen() && FCmd->IsEmpty())
	{
		File.SetSize(0);
		File.SetPos(0);

		File.Write("<META HTTP-EQUIV=\"Refresh\" CONTENT=30>\r\n");
		File.Write("<meta http-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\">\r\n");
		File.Write("<html><body>\r\n");
		File.Write("<form action=\"/\" method=\"post\">\r\n");

		File.Write("<body background=\"/lgren005.jpg\">");

		File.Write("<h1 align=\"center\">");
		File.Write("Styrsystem");
		File.Write("</h1>");
		File.Write("<br>");

		File.Write("<table border=0 cellspacing=0 cellpadding=0>");

		File.Write("<tr style='height:24.75pt'>");

		WriteLeftFieldHeader(File, 15);
		File.Write("Plats");
		WriteFieldFooter(File);

		WriteCenteredFieldHeader(File, 6);
		File.Write("Inställning");
		WriteFieldFooter(File);

		WriteCenteredFieldHeader(File, 6);
		File.Write("Temperatur");
		WriteFieldFooter(File);

		WriteCenteredFieldHeader(File, 6);
		File.Write("Pådrag");
		WriteFieldFooter(File);

		WriteCenteredFieldHeader(File, 6);
		File.Write("Ljus");
		WriteFieldFooter(File);

		WriteCenteredFieldHeader(File, 6);
		File.Write("Temperatur 2");
		WriteFieldFooter(File);

		File.Write("</tr>");

		for (r = 0; r < RadCount; r++)
		{
			if (RadArr[r]->IsOnline())
			{
				File.Write("<tr style='height:24.75pt'>");

				WriteLeftFieldHeader(File, 15);

					 sprintf(str, "<a href=\"/rad/%d.htm\">", r + 0x20);
					 File.Write(str);
				switch (r)
				{
					case 0:
						File.Write("Datarum");
						break;

					case 1:
						File.Write("Vardagsrum");
						break;

					case 2:
						File.Write("Rosa sovrum, nedre plan");
						break;

					case 3:
						File.Write("Blått sovrum, nedre plan");
						break;

					case 4:
						File.Write("Kök");
						break;

					case 5:
						File.Write("Sovrum, övre plan");
						break;

					case 6:
						File.Write("Trappa");
						break;

					case 7:
						File.Write("Badrum");
						break;
				}
					 File.Write("</a>");

				WriteFieldFooter(File);

				WriteCenteredFieldHeader(File, 6);
				ival = RadArr[r]->GetRef();
				sprintf(str, "%d.%d °C", ival / 10, ival % 10);
				File.Write(str);
				WriteFieldFooter(File);

				WriteCenteredFieldHeader(File, 6);
				ival = RadArr[r]->GetTemp();
				sprintf(str, "%d.%d °C", ival / 10, ival % 10);
				File.Write(str);
				WriteFieldFooter(File);

				WriteCenteredFieldHeader(File, 6);
				ival = RadArr[r]->GetMotor();
				if (ival > 100)
					ival = 100;
				sprintf(str, "%d%", ival);
				File.Write(str);
				WriteFieldFooter(File);

				WriteCenteredFieldHeader(File, 6);
				ival = RadArr[r]->GetLight();
				sprintf(str, "%d.%d W/m²", ival / 10, ival % 10);
				File.Write(str);
				WriteFieldFooter(File);

				WriteCenteredFieldHeader(File, 6);
				ival = RadArr[r]->GetAuxTemp();
				sprintf(str, "%d.%d °C", ival / 10, ival % 10);
				File.Write(str);
				WriteFieldFooter(File);

				File.Write("</tr>");
			}
		}

		File.Write("<tr style='height:24.75pt'>");

		WriteLeftFieldHeader(File, 15);
		File.Write("Cirkulation");
		WriteFieldFooter(File);

		WriteCenteredFieldHeader(File, 6);
		ival = round(10.0 * Circ->GetSpeed());
		sprintf(str, "%d%", ival);
		File.Write(str);
		WriteFieldFooter(File);

		File.Write("</tr>");

		File.Write("<tr style='height:24.75pt'>");

		WriteLeftFieldHeader(File, 15);
		File.Write("Tank");
		WriteFieldFooter(File);

		WriteCenteredFieldHeader(File, 15);
		ival = Vp->GetTankTemp();
		sprintf(str, "%d.%d °C", ival / 10, ival % 10);
		File.Write(str);
		WriteFieldFooter(File);

		File.Write("</tr>");

		if (Vp->HasValidTankP())
		{
			File.Write("<tr style='height:24.75pt'>");

			WriteLeftFieldHeader(File, 15);
			File.Write("Effekt Tank");
			WriteFieldFooter(File);

			WriteCenteredFieldHeader(File, 15);
			val = Vp->GetTankP();
			sprintf(str, "%5.2Lf kW", val);
			File.Write(str);
			WriteFieldFooter(File);

			File.Write("</tr>");
		}

		if (Vp->HasValidHeatP())
		{
			File.Write("<tr style='height:24.75pt'>");

			WriteLeftFieldHeader(File, 15);
			File.Write("Effekt Heat");
			WriteFieldFooter(File);

			WriteCenteredFieldHeader(File, 15);
			val = Vp->GetHeatP();
			sprintf(str, "%5.2Lf kW", val);
			File.Write(str);
			WriteFieldFooter(File);

			File.Write("</tr>");
		}

		File.Write("<tr style='height:24.75pt'>");

		WriteLeftFieldHeader(File, 15);
		File.Write("Panna");
		WriteFieldFooter(File);

		WriteCenteredFieldHeader(File, 15);
		ival = Vp->GetHeatTemp();
		sprintf(str, "%d.%d °C", ival / 10, ival % 10);
		File.Write(str);
		WriteFieldFooter(File);

		File.Write("</tr>");

		File.Write("<tr style='height:24.75pt'>");

		WriteLeftFieldHeader(File, 15);
		File.Write("Värmepump");
		WriteFieldFooter(File);

		WriteCenteredFieldHeader(File, 6);
		if (Vp->IsVpOn())
			File.Write("<img border=\"0\" src=\"/sol_rd.gif\" width=\"26\" height=\"26\">");
		else
			File.Write("<img border=\"0\" src=\"/sol_bl.gif\" width=\"26\" height=\"26\">");
		File.Write("</tr>");

		File.Write("<tr style='height:24.75pt'>");

		WriteLeftFieldHeader(File, 15);
		File.Write("Panna");
		WriteFieldFooter(File);

		WriteCenteredFieldHeader(File, 6);
		if (Vp->IsEpOn())
			File.Write("<img border=\"0\" src=\"/sol_rd.gif\" width=\"26\" height=\"26\">");
		else
			File.Write("<img border=\"0\" src=\"/sol_bl.gif\" width=\"26\" height=\"26\">");
		File.Write("</tr>");

		File.Write("<tr style='height:24.75pt'>");

		WriteLeftFieldHeader(File, 15);
		File.Write("Ljus");
		WriteFieldFooter(File);

		WriteCenteredFieldHeader(File, 6);
		if (LightOn)
			File.Write("<img border=\"0\" src=\"/sol_rd.gif\" width=\"26\" height=\"26\">");
		else
			File.Write("<img border=\"0\" src=\"/sol_bl.gif\" width=\"26\" height=\"26\">");

		File.Write("</tr>");

		File.Write("</table>\r\n");

		File.Write("</form>\r\n");
		File.Write("</body></html>\r\n");

		if (!PushFile(FFileName.GetData(), "text/html", 30))
			break;

		Signal.WaitTimeout(25000);

		RdosWaitMilli(50);
		Signal.Clear();
	}

	RemoveSignal(&Signal);
}

/*##########################################################################
#
#   Name       : THttpRadPage::Get
#
#   Purpose....: Get dynamic page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpRadPage::Get(const char *Name)
{
    const char *param;
    int address;
	int year;
	int month;
	int day;
	int count;
	const char *ext;

	param = FParam.GetData();

	count = sscanf(param, "rad/%d/%d/%d/%d", &address, &year, &month, &day);

    if (count == 4)
        WriteHistoryTemp(address, year, month, day);
    else
    {
		count = sscanf(param, "rad/%d", &address);
        if (count == 1)
        {
            ext = strchr(param, '.');
            if (ext)
            {
                if (!strcmp(ext, ".htm"))
        	        WriteTemp(address);
        	    else
        	    {
        	        if (!strcmp(ext, ".jpg"))
        	            WriteTempJpeg(address);
        	        else
    				    WriteError(404);
    		    }
            }
            else
                WriteError(404);
        }
    	else
            WriteMain();
    }
}

/*##########################################################################
#
#   Name       : THttpRadFactory::THttRadPageFactory
#
#   Purpose....: Constructor for THttpRadPageFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpRadPageFactory::THttpRadPageFactory(const char *ReqName)
  : THttpCustomDirFactory(ReqName)
{
}

/*##########################################################################
#
#   Name       : THttpRadPageFactory::~THttpRadPageFactory
#
#   Purpose....: Destructor for THttpRadPageFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpRadPageFactory::~THttpRadPageFactory()
{
}

/*##########################################################################
#
#   Name       : THttpRadPageFactory::Create
#
#   Purpose....: Create an instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPage *THttpRadPageFactory::Create(THttpCommand *Cmd, const char *Param)
{
	THttpRadPage *page;

	TString tempname = CreateUniqueFile(Cmd);
	page = new THttpRadPage(Cmd, tempname.GetData(), Param);
	return page;
}

/*##########################################################################
#
#   Name       : AddHttpRad
#
#   Purpose....: Add radiator to Http-display
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddHttpRad(TRad *Rad)
{
    RadArr[RadCount] = Rad;
    RadCount++;
}

/*##########################################################################
#
#   Name       : AddHttpWs2300
#
#   Purpose....: Add weather station
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddHttpWs2300(TWs2300 *Ws)
{
    Ws2300 = Ws;
}

/*##########################################################################
#
#   Name       : AddHttpCirc
#
#   Purpose....: Add circulation pump
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddHttpCirc(TCirc *circ)
{
    Circ = circ;
}

/*##########################################################################
#
#   Name       : AddHttpVp
#
#   Purpose....: Add heater pump
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddHttpVp(TVp *vp)
{
    Vp = vp;
}

/*##########################################################################
#
#   Name       : AddHttpLog
#
#   Purpose....: Add log
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddHttpLog(TLog *log)
{
    Log = log;
}

/*##########################################################################
#
#   Name       : HttpSetLightOn
#
#   Purpose....: Set light to ON
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void HttpSetLightOn()
{
    LightOn = TRUE;
}

/*##########################################################################
#
#   Name       : HttpSetLightOff
#
#   Purpose....: Set light to OFF
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void HttpSetLightOff()
{
    LightOn = FALSE;
}

/*##########################################################################
#
#   Name       : InitHeatHttp
#
#   Purpose....: Init heat HTTP module
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InitHeatHttp()
{
    THttpSocketServerFactory *Factory = new THttpSocketServerFactory(80, 50, 0x4000);
	THttpWs2300PageFactory *Ws2300Page = new THttpWs2300PageFactory("ws2300.htm");
	THttpRadPageFactory *RadPage = new THttpRadPageFactory("rad/");
	 TWait *Wait = new TWait;

	Factory->RootDir = WWWROOT;
	 Factory->KeepAlive = 45;
	Factory->AddCustomPage(Ws2300Page);
	Factory->AddCustomDir(RadPage);
	Wait->Add(Factory);
	Wait->StartThreadHandler("HTTPD", 0x8000);
}
