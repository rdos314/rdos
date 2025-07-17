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
# axis.cpp
# Axis base class
#
########################################################################*/

#include <stdio.h>
#include <string.h>

#include "axis.h"

#define     FALSE	0
#define     TRUE	!FALSE

/*##########################################################################
#
#   Name       : TAxis::TAxis
#
#   Purpose....: Constructor for TAxis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAxis::TAxis()
{
	FDev = 0;
	FXMin = 0;
	FXMax = 1;
	FYMin = 0;
	FYMax = 1;
	FValMin = 0.0;
	FValMax = 1.0;
	
	FRBack = 255;
	FGBack = 255;
    FBBack = 255;

    FRFore = 0;
    FGFore = 0;
    FBFore = 0;	

    FVisible = TRUE;
}

/*##########################################################################
#
#   Name       : TAxis::~TAxis
#
#   Purpose....: Destructor for TAxis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAxis::~TAxis()
{
}

/*##########################################################################
#
#   Name       : TAxis::IsXAxis
#
#   Purpose....: Check if x-axis object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAxis::IsXAxis()
{
	return FALSE;
}

/*##########################################################################
#
#   Name       : TAxis::IsYAxis
#
#   Purpose....: Check if y-axis object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAxis::IsYAxis()
{
	return FALSE;
}

/*##########################################################################
#
#   Name       : TAxis::IsVisible
#
#   Purpose....: Check if axis is visible
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAxis::IsVisible() const
{
    return FVisible;
}

/*##########################################################################
#
#   Name       : TAxis::Hide
#
#   Purpose....: Hide axis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAxis::Hide()
{
    FVisible = FALSE;
}

/*##########################################################################
#
#   Name       : TAxis::Show
#
#   Purpose....: Show axis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAxis::Show()
{
    FVisible = TRUE;
}

/*##########################################################################
#
#   Name       : TAxis::SetForeColor
#
#   Purpose....: Set foreground color
#
#   In params..: r, g, b
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAxis::SetForeColor(int r, int g, int b)
{
    FRFore = r;
    FGFore = g;
    FBFore = b;
}

/*##########################################################################
#
#   Name       : TAxis::SetBackColor
#
#   Purpose....: Set background color
#
#   In params..: r, g, b
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAxis::SetBackColor(int r, int g, int b)
{
    FRBack = r;
    FGBack = g;
    FBBack = b;
}

/*##########################################################################
#
#   Name       : TAxis::SetWindow
#
#   Purpose....: Set draw window
#
#   In params..: dev
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAxis::SetWindow(int xmin, int ymin, int xmax, int ymax)
{
	FXMin = xmin;
	FXMax = xmax;
	FYMin = ymin;
	FYMax = ymax;
	Update();
}

/*##########################################################################
#
#   Name       : TAxis::Define
#
#   Purpose....: Define graphics device
#
#   In params..: dev
#				 min
#				 max
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAxis::Define(TGraphicDevice *dev)
{
    FDev = dev;
	Update();
}

/*##########################################################################
#
#   Name       : TAxis::Define
#
#   Purpose....: Define value limits
#
#   In params..: min
#				 max
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAxis::Define(long double min, long double max)
{
    FValMin = min;
	FValMax = max;
	Update();
}

/*##########################################################################
#
#   Name       : TAxis::SetMin
#
#   Purpose....: Set min value
#
#   In params..: min
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAxis::SetMin(long double min)
{
    FValMin = min;
	Update();
}

/*##########################################################################
#
#   Name       : TAxis::SetMax
#
#   Purpose....: Set max value
#
#   In params..: max
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAxis::SetMax(long double max)
{
    FValMax = max;
	Update();
}

/*##########################################################################
#
#   Name       : TAxis::LogToPixel
#
#   Purpose....: Convert logical coordinate to pixel
#
#   In params..: rel
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAxis::LogToPixel(long double rel)
{
	long double range;

	if (IsXAxis())
	{
		range = (long double)(FXMax - FXMin);
		return FXMin + (int)(range * rel);
	}

	if (IsYAxis())
	{
		range = (long double)(FYMax - FYMin);
		return FYMax - (int)(range * rel);
	}

	return 0;
}

/*##########################################################################
#
#   Name       : TAxis::PixelToLog
#
#   Purpose....: Convert pixel to logical coordinate
#
#   In params..: pixel
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TAxis::PixelToLog(int pixel)
{
	long double range;

	if (IsXAxis())
	{
		range = (long double)(FXMax - FXMin);
		if (range)
			return (long double)(pixel - FXMin) / range;
		else
			return 0.0;
	}

	if (IsYAxis())
	{
		range = (long double)(FYMax - FYMin);
		if (range)
			return (long double)(FYMax - pixel) / range;
		else
			return 0.0;
	}

	return 0.0;
}

/*##########################################################################
#
#   Name       : TAxis::PhysToPixel
#
#   Purpose....: Convert value to pixel
#
#   In params..: val
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAxis::PhysToPixel(long double val)
{
	long double range;

	if (IsXAxis())
	{
		range = (long double)(FXMax - FXMin);
		return FXMin + (int)(range * PhysToLog(val));
	}
	
	if (IsYAxis())
	{
		range = (long double)(FYMax - FYMin);
		return FYMax - (int)(range * PhysToLog(val));
	}

	return 0;
}

/*##########################################################################
#
#   Name       : TAxis::PixelToPhys
#
#   Purpose....: Convert pixel to value
#
#   In params..: pixel
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TAxis::PixelToPhys(int pixel)
{
	long double range;

	if (IsXAxis())
	{
		range = (long double)(FXMax - FXMin);
		if (range)
			return LogToPhys((long double)(pixel - FXMin) / range);
		else
			return LogToPhys(0.0);
	}

	if (IsYAxis())
	{
		range = (long double)(FYMax - FYMin);
		if (range)
			return LogToPhys((long double)(FYMax - pixel) / range);
		else
			return LogToPhys(0.0);
	}

	return 0.0;
}

/*##########################################################################
#
#   Name       : TAxis::Format
#
#   Purpose....: Format value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAxis::Format(char *str, long double val)
{
    char tempstr[32];
    char formstr[32];
    int len;
    int digits;

    if (val >= 0.0)
        digits = FDigits + FDecimals + 1;
    else
        digits = FDigits + FDecimals + 2;
        
    if (FDecimals)
    {
        sprintf(tempstr, "%d.%dLf", digits, FDecimals);
        strcpy(formstr, "%");
        strcat(formstr, tempstr);            
        sprintf(str, formstr, val);
    }
    else
    {
        sprintf(tempstr, "%d.1Lf", digits + 1);
        strcpy(formstr, "%");
        strcat(formstr, tempstr);            
        sprintf(str, formstr, val);
        len = strlen(str);
        if (len >= 2)
            str[len - 2] = 0;
    }
}

/*##########################################################################
#
#   Name       : TAxis::Draw
#
#   Purpose....: Draw axis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAxis::Draw()
{
}

/*##########################################################################
#
#   Name       : TAxis::Update
#
#   Purpose....: Update
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAxis::Update()
{
}
