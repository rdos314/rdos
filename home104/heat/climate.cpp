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
# climate.cpp
# Climate class
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "climate.h"

#define FALSE 0
#define TRUE !FALSE


/*##########################################################################
#
#   Name       : TClimate::TClimate
#
#   Purpose....: Climate class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TClimate::TClimate(TControlThread *control)
  : Table(control, 850, 50, 400, 300)
{
    TLabelControl *Label;

    FControl = control;

    CommentLabelFactory.SetSpace(4, 4);
    CommentLabelFactory.SetFont(20);
    CommentLabelFactory.SetBackColor(0, 20, 50);
    CommentLabelFactory.SetDrawColor(0, 0, 0);
    CommentLabelFactory.AlignLeft();
    
    ValueLabelFactory.SetSpace(4, 4);
    ValueLabelFactory.SetFont(20);
    ValueLabelFactory.SetBackColor(100, 100, 100);
    ValueLabelFactory.SetDrawColor(0, 0, 0);
    ValueLabelFactory.AlignRight();

    UnitLabelFactory.SetSpace(4, 4);
    UnitLabelFactory.SetFont(20);
    UnitLabelFactory.SetBackColor(0, 20, 50);
    UnitLabelFactory.SetDrawColor(0, 0, 0);
    UnitLabelFactory.AlignLeft();

    Label = new TLabelControl(FControl, 850, 20, 200, 30);
    Label->SetFont(20);
    Label->SetBackColor(0, 20, 50);
    Label->SetDrawColor(0, 0, 0);
    Label->SetText("Väder");
    Label->Show();

    Table.SetRowSpacing(5);
    Table.SetColSpacing(8);
    Table.SetSpacingTransparent();
    Table.SetBackColor(0, 20, 50);
    Table.AddLabelColumn(&CommentLabelFactory, 220);
    Table.AddLabelColumn(&ValueLabelFactory, 80);
    Table.AddLabelColumn(&UnitLabelFactory, 70);

    Table.AddRow(24, 45);
    Table.AddRow(24, 45);
    Table.AddRow(24, 45);
    Table.AddRow(24, 45);
    Table.AddRow(24, 45);
    Table.AddRow(24, 45);
    Table.AddRow(24, 45);
    Table.AddRow(24, 45);
    Table.AddRow(24, 45);

    Table.SetText(0, 0, "Inne temp");
    Table.SetText(0, 2, "°C");

    Table.SetText(1, 0, "Inne fukt");
    Table.SetText(1, 2, "%");

    Table.SetText(2, 0, "Ute temp");
    Table.SetText(2, 2, "°C");

    Table.SetText(3, 0, "Ute fukt");
    Table.SetText(3, 2, "%");

    Table.SetText(4, 0, "Lufttryck");
    Table.SetText(4, 2, "hPa");

    Table.SetText(5, 0, "Medelvind");
    Table.SetText(5, 2, "m/s");

    Table.SetText(6, 0, "Byvind");
    Table.SetText(6, 2, "m/s");

    Table.SetText(7, 0, "Vindriktning");

    Table.SetText(8, 0, "Regn");
    Table.SetText(8, 2, "mm");
}

/*##########################################################################
#
#   Name       : TClimate::~TClimate
#
#   Purpose....: Climate class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TClimate::~TClimate()
{
}

/*##########################################################################
#
#   Name       : TClimate::NotifyData
#
#   Purpose....: Notify new data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TClimate::NotifyData()
{
    char str[256];

    if (IsIndoorTemperatureValid())
        sprintf(str, "%3.1Lf", GetIndoorTemperature());
    else
        str[0] = 0;
    Table.SetText(0, 1, str);

    if (IsIndoorHumidityValid())
        sprintf(str, "%2.0Lf", GetIndoorHumidity());
    else
        str[0] = 0;
    Table.SetText(1, 1, str);

    if (IsOutdoorTemperatureValid())
        sprintf(str, "%3.1Lf", GetOutdoorTemperature());
    else
        str[0] = 0;
    Table.SetText(2, 1, str);

    if (IsOutdoorHumidityValid())
        sprintf(str, "%2.0Lf", GetOutdoorHumidity());
    else
        str[0] = 0;
    Table.SetText(3, 1, str);

    if (IsPressureValid())
        sprintf(str, "%3.1Lf", GetPressure());
    else
        str[0] = 0;
    Table.SetText(4, 1, str);
            
    if (IsWindAverageValid())
        sprintf(str, "%3.1Lf", GetWindAverage());
    else
        str[0] = 0;
    Table.SetText(5, 1, str);
            
    if (IsWindGustValid())
        sprintf(str, "%3.1Lf", GetWindGust());
    else
        str[0] = 0;
    Table.SetText(6, 1, str);

    if (IsWindDirValid())
    {
        switch (FWindDirIndex)
        {
            case 0:
                strcpy(str, "N");
                break;

            case 1:
                strcpy(str, "NNO");
                break;

            case 2:
                strcpy(str, "NO");
                break;

            case 3:
                strcpy(str, "ONO");
                break;

            case 4:
                strcpy(str, "O");
                break;

            case 5:
                strcpy(str, "OSO");
                break;

            case 6:
                strcpy(str, "SO");
                break;

            case 7:
                strcpy(str, "SSO");
                break;

            case 8:
                strcpy(str, "S");
                break;

            case 9:
                strcpy(str, "SSV");
                break;

            case 10:
                strcpy(str, "SV");
                break;

            case 11:
                strcpy(str, "VSV");
                break;

            case 12:
                strcpy(str, "V");
                break;

            case 13:
                strcpy(str, "VNV");
                break;

            case 14:
                strcpy(str, "NV");
                break;

            case 15:
                strcpy(str, "NNV");
                break;

            default:
                str[0] = 0;
                break;
        }
    }
    else
        str[0] = 0;
    Table.SetText(7, 1, str);
                        
    if (IsRainValid())
        sprintf(str, "%3.1Lf", GetRain());
    else
        str[0] = 0;
    Table.SetText(8, 1, str);
}
