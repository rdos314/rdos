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
# touchcal.cpp
# Touch calibration class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include "touchcal.h"
#include "rdos.h"
#include "ini.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TTouchCalibration::TTouchCalibration
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTouchCalibration::TTouchCalibration()
{
    FIniName = 0;
    Init();
}

/*##########################################################################
#
#   Name       : TTouchCalibration::TTouchCalibration
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTouchCalibration::TTouchCalibration(const char *Ini)
{
    int len = strlen(Ini);

    FIniName = new char[len + 1];
    strcpy(FIniName, Ini);
    Init();
}

/*##########################################################################
#
#   Name       : TTouchCalibration::~TTouchCalibration
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTouchCalibration::~TTouchCalibration()
{
    if (FIniName)
        delete FIniName;
}

/*##########################################################################
#
#   Name       : TTouchCalibration::Init
#
#   Purpose....: Init device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTouchCalibration::Init()
{
    TIniFile *Ini;
    char str[40];
    int div;
    int xx, xy, xo;
    int yx, yy, yo;
    int ok;

    FPoints = 0;

    if (FIniName)
        Ini = new TIniFile(FIniName);
    else
        Ini = new TIniFile;

    Ini->GotoSection("Touch");
    ok = Ini->ReadVar("div", str, 30);
    if (ok)
    {
        div = atoi(str);

        ok = Ini->ReadVar("xx", str, 30);
        if (ok)
            xx = atoi(str);
        else
            xx = 1;

        ok = Ini->ReadVar("xy", str, 30);
        if (ok)
            xy = atoi(str);
        else
            xy = 0;
        
        ok = Ini->ReadVar("xo", str, 30);
        if (ok)
            xo = atoi(str);
        else
            xo = 0;

        ok = Ini->ReadVar("yx", str, 30);
        if (ok)
            yx = atoi(str);
        else
            yx = 0;

        ok = Ini->ReadVar("yy", str, 30);
        if (ok)
            yy = atoi(str);
        else
            yy = 1;

        ok = Ini->ReadVar("yo", str, 30);
        if (ok)
            yo = atoi(str);
        else
            yo = 1;

        RdosSetTouchCalibrateDividend(div);
        RdosSetTouchCalibrateX(xx, xy, xo);
        RdosSetTouchCalibrateY(yx, yy, yo);
    }
    delete Ini;
}

/*##########################################################################
#
#   Name       : TTouchCalibration::Start
#
#   Purpose....: Start calibration
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTouchCalibration::Start()
{
    FPoints = 0;
    RdosResetTouchCalibrate();
}

/*##########################################################################
#
#   Name       : TTouchCalibration::AddPoint
#
#   Purpose....: Add calibration point
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTouchCalibration::AddPoint(int xdisp, int ydisp, int xtouch, int ytouch)
{
    if (FPoints < 3)
    {
        FDispX[FPoints] = xdisp;
        FDispY[FPoints] = ydisp;
        FTouchX[FPoints] = xtouch;
        FTouchY[FPoints] = ytouch;
        FPoints++;
    }
}

/*##########################################################################
#
#   Name       : TTouchCalibration::Calibrate
#
#   Purpose....: Do calibration
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTouchCalibration::Calibrate()
{
    int div;
    int xx, xy, xo;
    int yx, yy, yo;
    int p1, p2;
    int temp;
    TIniFile *Ini;
    char str[40];

    if (FPoints == 3)
    {
        p1 = FDispX[0] - FDispX[2];
        p2 = FDispY[1] - FDispY[2];
        temp = p1 * p2;

        p1 = FDispX[1] - FDispX[2];
        p2 = FDispY[0] - FDispY[2];
        div = temp - p1 * p2;

        if (div)
        {
            p1 = FDispX[0] - FDispX[2];
            p2 = FTouchY[1] - FTouchY[2];
            temp = p1 * p2;

            p1 = FDispX[1] - FDispX[2];
            p2 = FTouchY[0] - FTouchY[2];
            xx = temp - p1 * p2;

            p1 = FTouchX[0] - FTouchX[2];
            p2 = FDispX[1] - FDispX[2];
            temp = p1 * p2;

            p1 = FDispX[0] - FDispX[2];
            p2 = FTouchX[1] - FTouchX[2];
            xy = temp - p1 * p2;

            p1 = FTouchX[2] * FDispX[1];
            p2 = FTouchX[1] * FDispX[2];
            temp = (p1 - p2) * FTouchY[0];

            p1 = FTouchX[0] * FDispX[2];
            p2 = FTouchX[2] * FDispX[0];
            temp += (p1 - p2) * FTouchY[1];

            p1 = FTouchX[1] * FDispX[0];
            p2 = FTouchX[0] * FDispX[1];
            xo = temp + (p1 - p2) * FTouchY[2];

            p1 = FDispY[0] - FDispY[2];
            p2 = FTouchY[1] - FTouchY[2];
            temp = p1 * p2;

            p1 = FDispY[1] - FDispY[2];
            p2 = FTouchY[0] - FTouchY[2];
            yx = temp - p1 * p2;

            p1 = FTouchX[0] - FTouchX[2];
            p2 = FDispY[1] - FDispY[2];
            temp = p1 * p2;

            p1 = FDispY[0] - FDispY[2];
            p2 = FTouchX[1] - FTouchX[2];
            yy = temp - p1 * p2;

            p1 = FTouchX[2] * FDispY[1];
            p2 = FTouchX[1] * FDispY[2];
            temp = (p1 - p2) * FTouchY[0];

            p1 = FTouchX[0] * FDispY[2];
            p2 = FTouchX[2] * FDispY[0];
            temp += (p1 - p2) * FTouchY[1];

            p1 = FTouchX[1] * FDispY[0];
            p2 = FTouchX[0] * FDispY[1];
            yo = temp + (p1 - p2) * FTouchY[2];

            if (FIniName)
               Ini = new TIniFile(FIniName);
            else
                Ini = new TIniFile;

            Ini->GotoSection("Touch");

            sprintf(str, "%d", div);
            Ini->WriteVar("div", str);

            sprintf(str, "%d", xx);
            Ini->WriteVar("xx", str);

            sprintf(str, "%d", xy);
            Ini->WriteVar("xy", str);

            sprintf(str, "%d", xo);
            Ini->WriteVar("xo", str);

            sprintf(str, "%d", yx);
            Ini->WriteVar("yx", str);

            sprintf(str, "%d", yy);
            Ini->WriteVar("yy", str);

            sprintf(str, "%d", yo);
            Ini->WriteVar("yo", str);

            delete Ini;

            RdosSetTouchCalibrateDividend(div);
            RdosSetTouchCalibrateX(xx, xy, xo);
            RdosSetTouchCalibrateY(yx, yy, yo);
        }
    }
}
