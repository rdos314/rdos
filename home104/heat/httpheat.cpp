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
#include "linxaxis.h"
#include "linyaxis.h"
#include "timeaxis.h"
#include "chart.h"
#include "jpeg.h"
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
THttpTablePage::THttpTablePage(THttpCommand *Cmd, const char *FileName)
  : THttpCustomPage(Cmd, FileName, "")
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
#   Name       : THttpHeatPage::THttpHeatPage
#
#   Purpose....: Constructor for THttpHeatPage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpHeatPage::THttpHeatPage(THttpCommand *Cmd, const char *FileName)
  : THttpTablePage(Cmd, FileName)
{
}

/*##########################################################################
#
#   Name       : THttpHeatPage::~THttpHeatPage
#
#   Purpose....: Destructor for THttpHeatPage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpHeatPage::~THttpHeatPage()
{
}

/*##########################################################################
#
#   Name       : THttpHeatPage::Get
#
#   Purpose....: Get dynamic page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpHeatPage::Get(const char *Name)
{
    long double val;
	int ival;
	int r;
	int count;
	char str[40];
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

		File.Write("<body background=\"http://www.rdos.net/home104/lgren005.jpg\">");

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
				switch (r)
				{
					case 0:
						File.Write("Leif & Lenas sovrum");
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
						File.Write("Emil & Linneas sovrum");
						break;

					case 6:
						File.Write("Trappa");
						break;

					case 7:
						File.Write("Badrum");
						break;
				}
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
		File.Write("Värmepump");
		WriteFieldFooter(File);

		WriteCenteredFieldHeader(File, 6);
		if (Vp->IsOn())
			File.Write("<img border=\"0\" src=\"http://www.rdos.net/home104/sol_rd.gif\" width=\"26\" height=\"26\">");
		else
			File.Write("<img border=\"0\" src=\"http://www.rdos.net/home104/sol_bl.gif\" width=\"26\" height=\"26\">");
		File.Write("</tr>");

		File.Write("<tr style='height:24.75pt'>");

		WriteLeftFieldHeader(File, 15);
		File.Write("Ljus");
		WriteFieldFooter(File);

		WriteCenteredFieldHeader(File, 6);
		if (LightOn)
			File.Write("<img border=\"0\" src=\"http://www.rdos.net/home104/sol_rd.gif\" width=\"26\" height=\"26\">");
		else
			File.Write("<img border=\"0\" src=\"http://www.rdos.net/home104/sol_bl.gif\" width=\"26\" height=\"26\">");

		File.Write("</tr>");

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
  : THttpTablePage(Cmd, FileName)
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

		File.Write("<body background=\"http://www.rdos.net/home104/water040.jpg\">");

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
				File.Write("<img border=\"0\" src=\"http://www.rdos.net/home104/rain.gif\" width=\"36\" height=\"26\">");
				break;

			case FORECAST_CLOUDY:
				File.Write("<img border=\"0\" src=\"http://www.rdos.net/home104/cloudy.gif\" width=\"36\" height=\"20\">");
				break;

			case FORECAST_SUNNY:
				File.Write("<img border=\"0\" src=\"http://www.rdos.net/home104/sun.gif\" width=\"28\" height=\"26\">");
				break;
		}

		File.Write("   ");

		switch (Ws2300->GetTendency())
		{
			case TENDENCY_RISING:
				File.Write("<img border=\"0\" src=\"http://www.rdos.net/home104/up.gif\" width=\"12\" height=\"25\">");
				break;

			case TENDENCY_FALLING:
				File.Write("<img border=\"0\" src=\"http://www.rdos.net/home104/down.gif\" width=\"12\" height=\"26\">");
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
#   Name       : THttpHeatFactory::THttpHeatPageFactory
#
#   Purpose....: Constructor for THttpHeatPageFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpHeatPageFactory::THttpHeatPageFactory(const char *ReqName)
  : THttpCustomPageFactory(ReqName)
{
}

/*##########################################################################
#
#   Name       : THttpHeatPageFactory::~THttpHeatPageFactory
#
#   Purpose....: Destructor for THttpHeatPageFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpHeatPageFactory::~THttpHeatPageFactory()
{
}

/*##########################################################################
#
#   Name       : THttpHeatPageFactory::Create
#
#   Purpose....: Create an instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPage *THttpHeatPageFactory::Create(THttpCommand *Cmd, const char *Param)
{
	THttpHeatPage *page;

	TString tempname = CreateUniqueFile(Cmd);
	page = new THttpHeatPage(Cmd, tempname.GetData());
	return page;
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
  : THttpCustomPage(Cmd, FileName, Param)
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
void THttpRadPage::CreateTempJpeg(int address, int year, int month, int day)
{
	TJpegBitmapDevice *jpeg;
	TFont *font;
	TLinYAxis *yaxis;
	TTimeXAxis *xaxis;
	TChart *chart;
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
	TDateTime time;
	TDateTime firsttime;
	TDateTime lasttime;
	char str[30];
	char filename[128];

	if (log == 0)
	    return;

	jpeg = new TJpegBitmapDevice(24, 500, 300);

	font = new TFont(10);

	xaxis = new TTimeXAxis(font);
	yaxis = new TLinYAxis(font);
	chart = new TChart(jpeg, xaxis, yaxis);

	xaxis->SetForeColor(0, 0, 0);
	xaxis->SetBackColor(255, 255, 255);

	yaxis->SetForeColor(0, 0, 0);
	yaxis->SetBackColor(255, 255, 255);

	chart->SetBackColor(255, 255, 255);

	chart->SetLineColor(100, 128, 128, 128);
	chart->SetLineColor(101, 128, 255, 0);
	chart->SetLineColor(102, 255, 128, 0);
	chart->SetLineColor(103, 0, 0, 255);

	log = Log->GetLog(year, month, day);

    firsttime = TDateTime(year, month, day, 0, 0, 0, 0);
    lasttime = TDateTime(year, month, day, 23, 59, 59, 999);
    
	for (i = 0; i <= 25; i++) 
	{
    	chart->SetLineColor(i, 210, 210, 210);
    	
	    val = (long double)i;
	    chart->Add(i, firsttime, val);
	    chart->Add(i, lasttime, val);
	}

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

		    tag = msg->GotoFirstTag();
		    while (tag)
		    {
                if (tag->GetID() == LOG_TAG_OUTDOOR)
                {
    			    var = tag->GetVar(LOG_VAR_Temp);
	    			if (var)
					{
			    	    ival = var->GetFloat1();
				        val = (long double)ival;
				        val = val / 10.0;

    					chart->Add(100, time, val);
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
		                    val = (long double)ival;
		                    val = val / 10.0; 

        					chart->Add(101, time, val);
        			    }

		                var = tag->GetVar(LOG_VAR_AuxTemp);
		                if (var)
		                {
		                    ival = var->GetFloat1();
		                    val = (long double)ival;
		                    val = val / 10.0; 

        					chart->Add(102, time, val);
        			    }

		                var = tag->GetVar(LOG_VAR_Ref);
		                if (var)
		                {
		                    ival = var->GetFloat1();
		                    val = (long double)ival;
		                    val = val / 10.0; 

        					chart->Add(103, time, val);
        			    }
        			}
		        }

				tag = msg->GotoNextTag();
		    }
		}

		if (log->GotoNext())
		    msg = log->Get();
		else
			msg = 0;
	}

	chart->Draw();
    
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

    jpeg->Save(filename);
    delete jpeg;
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
    char str[256];
    char filename[256];
    TDateTime time;
    int address;
	int year;
	int month;
	int day;
	int handle;
	TFile File(FFileName.GetData(), 0);

	param = FParam.GetData();

	if (sscanf(param, "rad/%d/%d/%d/%d", &address, &year, &month, &day) != 4)
	{
	    WriteError(404);
	    return;
	}

	sprintf(str, "image\\%d\\%d\\%d\\%d.jpg", address, year, month, day);
	strcpy(filename, WWWROOT);
	strcat(filename, "\\");
	strcat(filename, str);

	handle = RdosOpenFile(filename, 0);
	if (handle)
	    RdosCloseFile(handle);
	else
        CreateTempJpeg(address, year, month, day);

	File.Write("<IMG SRC=\"");
	sprintf(str, "/image/%d/%d/%d/%d.jpg", address, year, month, day);
	File.Write(str);
	File.Write("\" align=bottom width=500 height=300 border=0>");

	WriteFile(FFileName.GetData(), "text/html");

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
    THttpHeatPageFactory *HeatPage = new THttpHeatPageFactory("heat.htm");
	THttpWs2300PageFactory *Ws2300Page = new THttpWs2300PageFactory("ws2300.htm");
	THttpRadPageFactory *RadPage = new THttpRadPageFactory("rad/");
    TWait *Wait = new TWait;
    
	Factory->RootDir = WWWROOT;
    Factory->KeepAlive = 45;
	Factory->AddCustomPage(HeatPage);
	Factory->AddCustomPage(Ws2300Page);
	Factory->AddCustomDir(RadPage);
	Wait->Add(Factory);
	Wait->StartThreadHandler("HTTPD", 0x1800);
}
