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
  : THttpCustomPage(Cmd, FileName)
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

/*##################  THttpHeatPage::WriteCenteredFieldHeader ##########################
*   Purpose....: Write centered field header for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void THttpHeatPage::WriteCenteredFieldHeader(TFile &File, int RelWidth)
{
    char str[80];

    sprintf(str, "\n<td width=\"%d%\" colspan=2 valign=top>\n", RelWidth);
    File.Write(str);

	File.Write("<p align=\"center\">\n");
	File.Write("<b>\n");
}

/*##################  THttpHeatPage::WriteRightFieldHeader ##########################
*   Purpose....: Write right-aligned field header for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void THttpHeatPage::WriteRightFieldHeader(TFile &File, int RelWidth)
{
    char str[80];

    sprintf(str, "\n<td width=\"%d%\" colspan=2 valign=top>\n", RelWidth);
    File.Write(str);

	File.Write("<p align=\"right\">\n");
	File.Write("<b>\n");
}

/*##################  THttpHeatPage::WriteFieldFooter ##########################
*   Purpose....: Write field footer for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void THttpHeatPage::WriteFieldFooter(TFile &File)
{
    File.Write("\n</b>\n");
	File.Write("</p>\n");

    File.Write("</td>\n");
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

		File.Write("<h1>");
		File.Write("Styrsystem Översikt");
		File.Write("</h1>");
		File.Write("<br>");

		File.Write("<table border=3 cellspacing=0 cellpadding=0>");

		File.Write("<tr style='height:24.75pt'>");

		WriteCenteredFieldHeader(File, 20);
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

				WriteRightFieldHeader(File, 20);
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
    THttpHeatPageFactory *HeatPage = new THttpHeatPageFactory("main.htm");
    TWait *Wait = new TWait;
    
	Factory->RootDir = "d:\\wwwroot";
	Factory->AddCustomPage(HeatPage);
	Wait->Add(Factory);
	Wait->StartThreadHandler("HTTPD", 0x1800);
}
