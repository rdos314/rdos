/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2011, Leif Ekblad
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
# wh1080.cpp
# WH1080 weather station class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "wh1080.h"

#define FALSE 0
#define TRUE !FALSE

void main()
{
    char str[256];
    long double val;

    TWh1080Device Wh1080;

    if (Wh1080.IsOnline())
    {
        for (;;)
        {
            Wh1080.WaitForData();

            printf("Indoor ");
            if (Wh1080.IsIndoorHumidityValid())
                printf("%3.0Lf%% ", Wh1080.GetIndoorHumidity());
            else
                printf("--- ");

            if (Wh1080.IsIndoorTemperatureValid())
                printf("%5.1LfC ", Wh1080.GetIndoorTemperature());
            else
                printf("-----  ");
            
            printf("Outdoor ");
            if (Wh1080.IsOutdoorHumidityValid())
                printf("%3.0Lf%% ", Wh1080.GetOutdoorHumidity());
            else
                printf("---  ");

            if (Wh1080.IsOutdoorTemperatureValid())
                printf("%5.1LfC ", Wh1080.GetOutdoorTemperature());
            else
                printf("-----  ");
            
            if (Wh1080.IsPressureValid())
                printf("%6.1Lfhpa ", Wh1080.GetPressure());
            else
                printf("------    ");
            
            if (Wh1080.IsWindAverageValid())
                printf("%4.1Lfm/s ", Wh1080.GetWindAverage());
            else
                printf("---      ");
            
            if (Wh1080.IsWindGustValid())
                printf("%4.1Lfm/s ", Wh1080.GetWindGust());
            else
                printf("---      ");
            
            if (Wh1080.IsWindDirValid())
                printf("%4.0Lf ", Wh1080.GetWindDir());
            else
                printf("----  ");
            
            if (Wh1080.IsRainValid())
                printf("%5.1Lfmm ", Wh1080.GetRain());
            else
                printf("-----    ");

            printf("\r\n");
                        
        }
    }
}

