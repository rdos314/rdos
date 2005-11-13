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

#define FALSE 0
#define TRUE !FALSE

TSection SignalSection;
TSignalDevice *SignalList = 0;

int RadCount = 0;
TRad *RadArr[15];
TWs2300 *Ws2300 = 0;
int VpOn = FALSE;
int LightOn = FALSE;

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
  : THttpCustomPage(Cmd, FileName)
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

		File.Write("<body background=\"lgren005.jpg\">");

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
				}
				WriteFieldFooter(File);

				WriteCenteredFieldHeader(File, 6);
				sprintf(str, "%d.%d °C", RadArr[r]->Ref / 10, RadArr[r]->Ref % 10);
				File.Write(str);
				WriteFieldFooter(File);

				WriteCenteredFieldHeader(File, 6);
				sprintf(str, "%d.%d °C", RadArr[r]->Temp / 10, RadArr[r]->Temp % 10);
				File.Write(str);
				WriteFieldFooter(File);

				WriteCenteredFieldHeader(File, 6);
				ival = RadArr[r]->Motor;
				if (ival > 100)
					 ival = 100;
				sprintf(str, "%d%", ival);
				File.Write(str);
				WriteFieldFooter(File);

				WriteCenteredFieldHeader(File, 6);
				sprintf(str, "%d.%d W/m²", RadArr[r]->Light / 10, RadArr[r]->Light % 10);
				File.Write(str);
				WriteFieldFooter(File);

				WriteCenteredFieldHeader(File, 6);
				sprintf(str, "%d.%d °C", RadArr[r]->AuxTemp / 10, RadArr[r]->AuxTemp % 10);
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
		if (VpOn)
			File.Write("<img border=\"0\" src=\"sol_rd.gif\" width=\"26\" height=\"26\">");
		else
			File.Write("<img border=\"0\" src=\"sol_bl.gif\" width=\"26\" height=\"26\">");

		File.Write("</tr>");

		File.Write("<tr style='height:24.75pt'>");

		WriteLeftFieldHeader(File, 15);
		File.Write("Ljus");
		WriteFieldFooter(File);

		WriteCenteredFieldHeader(File, 6);
		if (LightOn)
			File.Write("<img border=\"0\" src=\"sol_rd.gif\" width=\"26\" height=\"26\">");
		else
			File.Write("<img border=\"0\" src=\"sol_bl.gif\" width=\"26\" height=\"26\">");

		File.Write("</tr>");

		File.Write("</table>\r\n");

		File.Write("</form>\r\n");
		File.Write("</body></html>\r\n");

		if (!PushFile(FFileName.GetData(), "text/html", 30))
			break;

		Signal.WaitTimeout(2000);

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

		File.Write("<body background=\"water040.jpg\">");

		File.Write("<CENTER>\n");

		File.Write("<h1>");
		File.Write("Väderstation");
		File.Write("</h1>");

		File.Write("<h3>");
		File.Write("Inomhus");
		File.Write("</h3>");

		File.Write("<p><b>");
		ival = round(10 * Ws2300->GetIndoorTemp());
		sprintf(str, "Temperatur %d.%d °C", ival / 10, ival % 10);
		File.Write(str);
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
		ival = round(10 * Ws2300->GetOutdoorTemp());
		sprintf(str, "Temperatur: %d.%d °C", ival / 10, ival % 10);
		File.Write(str);
		File.Write("</b></p>");

		File.Write("<p><b>");
		ival = round(Ws2300->GetOutdoorHumidity());
		sprintf(str, "Fuktighet: %d%", ival);
		File.Write(str);
		File.Write("</b></p>");

		File.Write("<p><b>");
		ival = round(10 * Ws2300->GetDewPoint());
		sprintf(str, "Daggpunkt: %d.%d °C", ival / 10, ival % 10);
		File.Write(str);
		File.Write("</b></p>");

		File.Write("<p><b>");
		ival = round(10 * Ws2300->GetWindChill());
		sprintf(str, "Vindkompenserad: %d.%d °C", ival / 10, ival % 10);
		File.Write(str);
		File.Write("</b></p>");

		File.Write("<p><b>");
		ival = round(10 * Ws2300->GetWindSpeed());
		sprintf(str, "Vind: %d.%d m/s  ", ival / 10, ival % 10);
		File.Write(str);

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
		ival = round(10 * Ws2300->GetAirPressure());
		sprintf(str, "Lufttryck: %d.%d hPa", ival / 10, ival % 10);
		File.Write(str);
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

		File.Write("</CENTERED>\n");

		File.Write("</form>\r\n");
		File.Write("</body></html>\r\n");

		if (!PushFile(FFileName.GetData(), "text/html", 30))
			break;

		Signal.WaitTimeout(2000);

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
THttpCustomPage *THttpHeatPageFactory::Create(THttpCommand *Cmd)
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
THttpCustomPage *THttpWs2300PageFactory::Create(THttpCommand *Cmd)
{
	THttpWs2300Page *page;

	TString tempname = CreateUniqueFile(Cmd);
	page = new THttpWs2300Page(Cmd, tempname.GetData());
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
#   Name       : HttpSetVpOn
#
#   Purpose....: Set VP to ON
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void HttpSetVpOn()
{
    VpOn = TRUE;
}

/*##########################################################################
#
#   Name       : HttpSetVpOff
#
#   Purpose....: Set VP to OFF
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void HttpSetVpOff()
{
    VpOn = FALSE;
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
    TWait *Wait = new TWait;
    
	Factory->RootDir = "d:\\wwwroot";
    Factory->KeepAlive = 45;
	Factory->AddCustomPage(HeatPage);
	Factory->AddCustomPage(Ws2300Page);
	Wait->Add(Factory);
	Wait->StartThreadHandler("HTTPD", 0x1800);
}
