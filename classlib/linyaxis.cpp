/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# linyaxis.cpp
# Linear y-axis class
#
########################################################################*/

#include <stdio.h>
#include <string.h>

#include "linyaxis.h"

#define     FALSE       0
#define     TRUE        !FALSE

/*##########################################################################
#
#   Name       : TLinYAxis::TLinYAxis
#
#   Purpose....: Constructor for TLinYAxis, no scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLinYAxis::TLinYAxis()
{
        FFont = 0;
        FScale = 0.0;
}

/*##########################################################################
#
#   Name       : TLinYAxis::TLinYAxis
#
#   Purpose....: Constructor for TLinYAxis, scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLinYAxis::TLinYAxis(TFont *Font)
{
        FFont = Font;
        FScale = 0.0;
}

/*##########################################################################
#
#   Name       : TLinYAxis::~TLinYAxis
#
#   Purpose....: Destructor for TLinYAxis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLinYAxis::~TLinYAxis()
{
}

/*##########################################################################
#
#   Name       : TLinYAxis::PhysToLog
#
#   Purpose....: Convert value to logical coordinate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TLinYAxis::PhysToLog(long double val)
{
        long double range;

        range = FValMax - FValMin;
        if (range)
                return (val - FValMin) / range;
        else
                return 0.0;
}

/*##########################################################################
#
#   Name       : TLinYAxis::LogToPhys
#
#   Purpose....: Convert logical coordinate to value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TLinYAxis::LogToPhys(long double rel)
{
        long double range;

        range = FValMax - FValMin;
        return FValMin + range * rel;
}

/*##########################################################################
#
#   Name       : TLinYAxis::CalcScale
#
#   Purpose....: Calculate scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLinYAxis::CalcScale()
{
    int exp;
    int scales;
    int i;
    long double Start;
    int val;
    int height;

    FFont->GetStringMetrics("-", &FScaleWidth, &FHeight);

    if (FScaleWidth > 4)
        FScaleWidth = FScaleWidth / 2;

    height = FHeight + FHeight / 2;
  
    FScale = FValMax - FValMin;

    if (FScale < 0.0)
    {
        FNegativeScale = TRUE;
        FScale = -FScale;
    }
    else
        FNegativeScale = FALSE;

    if (FScale != 0.0)
    {
        scales = (FYMax - FYMin) / height;
        if (scales == 0)
            FScale = 0.0;
    }

    if (FScale != 0.0)
    {
        FScale = FScale / scales;

        exp = 0;

        while (FScale > 10.0)
        {
            exp++;
            FScale = FScale / 10.0;
        }

                while (FScale <= 1.0)
                {
            exp--;
            FScale = FScale * 10.0;
        }

        if (FScale <= 2.0)
        {
            FScale = 2.0;
            FSubScale = 2;
        }
        else
        {
            if (FScale <= 5.0)
            {
                FScale = 5.0;
                FSubScale = 5;
            }
            else
            {   
                exp++;
                FScale = 1.0;
                FSubScale = 2;
            }
        }

        if (exp > 0)
            for (i = 0; i < exp; i++)
                FScale = FScale * 10.0;

        if (exp < 0)
            for (i = 0; i < -exp; i++) 
                FScale = FScale / 10.0;

        if (FNegativeScale)
            Start = FValMax / FScale;
        else
            Start = FValMin / FScale;        

        if (Start > (long double)0x7FFFFFFF)
            FScale = 0.0;
        
    }     

    if (FScale != 0.0)
    {
        val = (int)Start;
        FFirstVal = val * FScale;

        if (exp < 0)
            FDecimals = -exp;
        else
            FDecimals = 0;

        exp = 1;
        val = FValMin;

        if (val < 0.0)
            val = -val;

        while (val >= 10.0)         
        {
            exp++;
            val = val / 10.0;
        }

        FDigits = exp;

        exp = 1;
        val = FValMax;

        if (val < 0.0)
            val = -val;

        while (val >= 10.0)         
        {
            exp++;
            val = val / 10.0;
        }

        if (exp > FDigits)
            FDigits = exp;

    }
}

/*##########################################################################
#
#   Name       : TLinYAxis::RequiredWidth
#
#   Purpose....: Get required width
#
#   In params..: *
#   Out params.: *
#   Returns....: Min pixels required for scale
#
##########################################################################*/
int TLinYAxis::RequiredWidth()
{
    char str[256];
    int width1;
    int width2;
    int height;
    int width;

    if (FFont)
    {
        CalcScale();

        if (FScale != 0.0)
        {
            Format(str, FValMin);
            FFont->GetStringMetrics(str, &width1, &height);
    
            Format(str, FValMax);
            FFont->GetStringMetrics(str, &width2, &height);

            if (width1 > width2)
                width =  width1 + FScaleWidth + 2;
            else
                width = width2 + FScaleWidth + 2;
        }
        else
            width = 0;
    }
    else
        width = 1;

    if (width < FMinWidth)
        return FMinWidth;
    else
        return width;
}

/*##########################################################################
#
#   Name       : TLinYAxis::DrawLabels
#
#   Purpose....: Draw labels
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLinYAxis::DrawLabels()
{
    char str[256];
    long double val;
        int x, y;
    int width;
    int height;
    
    if (FScale != 0.0)
    {
        if (FNegativeScale)
        {
            val = FFirstVal;

                        while (val >= FValMin)
                        {
                Format(str, val);
                            FFont->GetStringMetrics(str, &width, &height);

                                y = PhysToPixel(val) - FHeight / 2;
                                x = FXMax - FXMin - width - FScaleWidth - 2;
                                if (x > 0)
                                    x = FXMin + x;
                            else
                                        x = FXMin;

                            if (y >= FYMin && y + FHeight <= FYMax)
                            FDev->DrawString(x, y, str);

                                val -= FScale;
                }
        }
                else
                {
                        val = FFirstVal;

                        while (val <= FValMax)
                        {
                Format(str, val);
                FFont->GetStringMetrics(str, &width, &height);

                y = PhysToPixel(val) - FHeight / 2;
                x = FXMax - FXMin - width - FScaleWidth - 2;
                if (x > 0)
                    x = FXMin + x;
                else
                    x = FXMin;

                            if (y >= FYMin && y + FHeight <= FYMax)
                                FDev->DrawString(x, y, str);

                val += FScale;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TLinYAxis::DrawScale
#
#   Purpose....: Draw scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLinYAxis::DrawScale()
{
    long double val;
    long double subval;
    int i;
        int y;
    
    if (FScale != 0.0)
    {
        if (FNegativeScale)
        {
            val = FFirstVal + FScale;

                        while (val >= FValMin)
                        {
                                y = PhysToPixel(val);
                                FDev->DrawLine(FXMax - FScaleWidth, y, FXMax + FScaleWidth, y);

                subval = val - FScale / FSubScale;
                
                                for (i = 1; i < FSubScale; i++)
                {
                                y = PhysToPixel(subval);
                                FDev->DrawLine(FXMax - FScaleWidth / 2, y, FXMax + FScaleWidth / 2, y);
                                subval -= FScale / FSubScale;
                    }
                                
                                val -= FScale;
                }
        }
                else
                {
                        val = FFirstVal - FScale;

                        while (val <= FValMax)
                        {
                                y = PhysToPixel(val);
                                FDev->DrawLine(FXMax - FScaleWidth, y, FXMax + FScaleWidth, y);

                subval = val + FScale / FSubScale;
                
                                for (i = 1; i < FSubScale; i++)
                {
                                y = PhysToPixel(subval);
                                FDev->DrawLine(FXMax - FScaleWidth / 2, y, FXMax + FScaleWidth / 2, y);
                                subval += FScale / FSubScale;
                    }
                val += FScale;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TLinYAxis::Draw
#
#   Purpose....: Draw axis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLinYAxis::Draw()
{
    if (IsVisible())
    {
        FDev->SetClipRect(FXMin, FYMin, FXMax + 2 * FScaleWidth, FYMax);
        FDev->SetLgopNone();
        FDev->SetDrawColor(FRBack, FGBack, FBBack);
        FDev->SetFilledStyle();
        FDev->DrawRect(FXMin, FYMin, FXMax, FYMax - 1);
        FDev->SetDrawColor(FRFore, FGFore, FBFore);
        FDev->DrawLine(FXMax, FYMin, FXMax, FYMax);

        if (FFont)
        {
            FDev->SetFont(FFont);    
            CalcScale();
            DrawLabels();
            DrawScale();
        }
    }        
}
