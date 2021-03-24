/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2019, Leif Ekblad
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
# web.h
# Web server class
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "web.h"
#include "webheat.h"

#define BUF_SIZE        0x4000
#define STACK_SIZE      0x4000

static TSocketServerFactory *sockfact = 0;
static TMisolWeather *Misol;
static TFroniusInverter *Solar;
static TSmartPowInverter *Wind;

/*##########################################################################
#
#   Name       : TRootFactory::TRootFactory
#
#   Purpose....: Web factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRootFactory::TRootFactory(const char *name)
  : THttpCustomPageFactory(name)
{
}

/*##########################################################################
#
#   Name       : TRootFactory::~TRootFactory
#
#   Purpose....: Web factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRootFactory::~TRootFactory()
{
}

/*##########################################################################
#
#   Name       : TRootFactory::Create
#
#   Purpose....: Create web page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPage *TRootFactory::Create(THttpCommand *cmd)
{
    return new TRootPage(cmd);
}

/*##########################################################################
#
#   Name       : TRootPage::TRootPage
#
#   Purpose....: Web page constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRootPage::TRootPage(THttpCommand *Cmd)
  : THttpCustomPage(Cmd)
{
}

/*##########################################################################
#
#   Name       : TRootPage::~TRootPage
#
#   Purpose....: Web page destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRootPage::~TRootPage()
{
}

/*##########################################################################
#
#   Name       : TRootPage::SendAnswer
#
#   Purpose....: Send answer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRootPage::SendAnswer()
{
    char str[80];
    long double val;
    int ival;

    Write("<!DOCTYPE html>\r\n");
    Write("<html>\r\n");
    Write("<head>\r\n");
    Write(" <meta charset=\"utf-8\">\r\n");
    Write(" <title>Heat control system</title>\r\n");
    Write("</head>\r\n\r\n");
    Write("<body background=\"/blue.jpg\">\r\n");

    Write("<font face=\"Bookman Old Style\">\r\n");
    Write("<b>\r\n");
    Write("<span style='font-size:20.0pt;color:#0033CC'>\r\n");
    Write("Weather station data<br>\r\n");
    Write("<br>\r\n");
    Write("</span>\r\n");

    Write("<table border=3 cellspacing=0 cellpadding=0>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Temperature");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Misol->GetTemperature();
    sprintf(str, "%5.1Lf °C", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Wind");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Misol->GetWindSpeed();
    sprintf(str, "%5.1Lf m/s", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Gust");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Misol->GetWindGust();
    sprintf(str, "%5.1Lf m/s", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Direction");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Misol->GetWindDir();
    ival = (int)val;

    if (ival >= 350 || ival <= 11)
        strcpy(str,"N");

    if (ival >= 12 && ival <= 34)
        strcpy(str,"NNE");

    if (ival >= 35 && ival <= 56)
        strcpy(str,"NE");

    if (ival >= 57 && ival <= 79)
        strcpy(str,"ENE");

    if (ival >= 80 && ival <= 101)
        strcpy(str,"E");

    if (ival >= 102 && ival <= 124)
        strcpy(str,"ESE");

    if (ival >= 125 && ival <= 146)
        strcpy(str,"SE");

    if (ival >= 147 && ival <= 169)
        strcpy(str,"SSE");

    if (ival >= 170 && ival <= 191)
        strcpy(str,"S");

    if (ival >= 192 && ival <= 214)
        strcpy(str,"SSW");

    if (ival >= 215 && ival <= 236)
        strcpy(str,"SW");

    if (ival >= 237 && ival <= 259)
        strcpy(str,"WSW");

    if (ival >= 260 && ival <= 281)
        strcpy(str,"W");

    if (ival >= 282 && ival <= 304)
        strcpy(str,"WNW");

    if (ival >= 305 && ival <= 326)
        strcpy(str,"NW");

    if (ival >= 327 && ival <= 349)
        strcpy(str,"NNW");

    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Humidity");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Misol->GetHumidity();
    ival = (int)val;
    sprintf(str, "%d %%", ival);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Rain");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Misol->GetRain();
    sprintf(str, "%5.1Lf mm", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("UV: ");
    val = Misol->GetUv();
    sprintf(str, "%5.1Lf W/m²", val);
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Light");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td width=\"25%\" colspan=2 valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Misol->GetLight();
    sprintf(str, "%5.1Lf lux", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<table>\r\n");

    Write("</b>\r\n");
    Write("</p>\r\n");

    Write("<form method=\"POST\" action=\"/power/web\">\r\n");

    Write("<input type=\"Submit\" value=\"Power\" name=\"power\">\r\n");

    Write("</form>\r\n");

    Write("</body>\r\n");
    Write("</html>\r\n");

    SendData("text/html");
}

/*##########################################################################
#
#   Name       : TRootPage::Get
#
#   Purpose....: Get page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRootPage::Get(const char *MatchName, const char *UrlName, THttpParam *Param)
{
    SendAnswer();
}

/*##########################################################################
#
#   Name       : TRootPage::Post
#
#   Purpose....: Post page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRootPage::Post(const char *MatchName, const char *UrlName, THttpParam *Param)
{
    SendAnswer();
}

/*##########################################################################
#
#   Name       : TRootPage::Post
#
#   Purpose....: Post page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRootPage::Post(const char *Var, const char *Val)
{
}

/*##########################################################################
#
#   Name       : GetWebConnectionCount
#
#   Purpose....: Get web connection count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetWebConnectionCount()
{
    if (sockfact)
        return sockfact->GetConnectionCount();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : WebSocketThread
#
#   Purpose....: Web socket thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void WebSocketThread(void *ptr)
{
    TPowerHttpServerFactory fact(80, 10, BUF_SIZE);
    TRootFactory rootpage("index.htm");
    TPowerJsonDirFactory jsondir("power/json");
    TPowerWebDirFactory webdir("power/web");

    fact.AddCustomPage(&rootpage);
    fact.AddCustomDir(&jsondir);
    fact.AddCustomDir(&webdir);
    fact.RootDir = "d:/www";

    sockfact = &fact;

    for (;;)
        fact.WaitForever();
}

/*##########################################################################
#
#   Name       : InitWeb
#
#   Purpose....: Init web
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InitWeb(TMisolWeather *misol, TFroniusInverter *solar, TSmartPowInverter *wind)
{
    Misol = misol;
    Solar = solar;
    Wind = wind;

    RdosCreateThread(WebSocketThread, "Web listner", 0, STACK_SIZE);
}
