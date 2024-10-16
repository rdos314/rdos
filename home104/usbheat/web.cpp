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
static TPowHvmP *Charger;

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
    Write("<br>Weather station data<br>\r\n");
    Write("</span>\r\n");

    Write("<table cellspacing=2px cellpadding=2px>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Temperature");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Misol->GetTemperature();
    sprintf(str, " %5.1Lf", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" °C");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Wind");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Misol->GetWindSpeed();
    sprintf(str, " %5.1Lf", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" m/s");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Gust");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Misol->GetWindGust();
    sprintf(str, " %5.1Lf", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" m/s");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Direction");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td colspan=2 align='right' valign=top halign=center'>\r\n");
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
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Humidity");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Misol->GetHumidity();
    ival = (int)val;
    sprintf(str, " %d", ival);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" %");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Rain");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Misol->GetRain();
    sprintf(str, " %5.1Lf", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" mm");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("UV");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Misol->GetUv();
    sprintf(str, " %5.1Lf", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" W/m²");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Light");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Misol->GetLight();
    sprintf(str, " %5.1Lf", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" lux");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("</table>\r\n");

    Write("<span style='font-size:20.0pt;color:#0033CC'>\r\n");
    Write("<br>Solar panels<br>\r\n");
    Write("</span>\r\n");

    Write("<table cellspacing=2px cellpadding=2px>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Power");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Solar->GetCurrentPower();
    ival = (int)val;
    sprintf(str, " %d", ival);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" W");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Energy");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Solar->GetDayEnergy() / 1000.0;
    sprintf(str, " %3.1Lf", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" kWh");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("</table>\r\n");

    Write("<span style='font-size:20.0pt;color:#0033CC'>\r\n");
    Write("<br>Wind generator<br>\r\n");
    Write("</span>\r\n");

    Write("<table cellspacing=2px cellpadding=2px>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Power");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Wind->GetCurrentGrid();
    ival = (int)val;
    sprintf(str, " %d", ival);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" W");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Energy");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Wind->GetDayEnergy();
    sprintf(str, " %3.1Lf", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" kWh");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("State");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td colspan=2 align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Wind->GetCurrentState(str);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("</table>\r\n");

    Write("<span style='font-size:20.0pt;color:#0033CC'>\r\n");
    Write("<br>Charger<br>\r\n");
    Write("</span>\r\n");

    Write("<table cellspacing=2px cellpadding=2px>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Solar power");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Charger->GetSolarPower();
    ival = (int)val;
    sprintf(str, " %d", ival);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" W");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Grid power");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Charger->GetGridPower();
    ival = (int)val;
    sprintf(str, " %d", ival);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" W");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Battery power");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Charger->GetBatteryPower();
    ival = (int)val;
    sprintf(str, " %d", ival);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" W");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Used power");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Charger->GetOutputPower();
    ival = (int)val;
    sprintf(str, " %d", ival);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" W");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Solar energy");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Charger->GetSolarEnergy() / 1000.0;
    sprintf(str, " %3.1Lf", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" kWh");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Grid energy");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Charger->GetGridEnergy() / 1000.0;
    sprintf(str, " %3.1Lf", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" kWh");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Charge energy");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Charger->GetBatteryChargeEnergy() / 1000.0;
    sprintf(str, " %3.1Lf", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" kWh");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Discharge energy");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Charger->GetBatteryDischargeEnergy() / 1000.0;
    sprintf(str, " %3.1Lf", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" kWh");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Used energy");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Charger->GetOutputEnergy() / 1000.0;
    sprintf(str, " %3.1Lf", val);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" kWh");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("Battery State of Charge");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    val = Charger->GetBatterySoc();
    ival = (int)(val * 100.0);
    sprintf(str, " %d", ival);
    Write(str);
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write(" %");
    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("<tr style='height:24.75pt'>\r\n");
    Write("<td align='left' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");
    Write("State");
    Write("</span>\r\n");
    Write("</td>\r\n");

    Write("<td colspan=2 align='right' valign=top halign=center'>\r\n");
    Write("<span style='font-size:12.0pt;color:#0033CC'>\r\n");

    switch (Charger->GetMode())
    {
        case 0:
            Write("Power On");
            break;

        case 1:
            Write("Standby");
            break;

        case 2:
            Write("Mains");
            break;

        case 3:
            Write("Off-Grid");
            break;

        case 4:
            Write("Bypass");
            break;

        case 5:
            Write("Charging");
            break;

        default:
            Write("Fault");
            break;

    }

    Write("</span>\r\n");
    Write("</td>\r\n");
    Write("</tr>\r\n");

    Write("</table>\r\n");

    Write("</b>\r\n");
    Write("</p>\r\n");


    Write("<form method=\"POST\" action=\"/power/web\">\r\n");

    Write("<input type=\"Submit\" value=\"Power history\" name=\"power\">\r\n");

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

    rootpage.AddName("");

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
void InitWeb(TMisolWeather *misol, TFroniusInverter *solar, TSmartPowInverter *wind,  TPowHvmP *charger)
{
    Misol = misol;
    Solar = solar;
    Wind = wind;
    Charger = charger;

    RdosCreateThread(WebSocketThread, "Web listner", 0, STACK_SIZE);
}
