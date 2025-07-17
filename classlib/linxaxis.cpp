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
# linxaxis.cpp
# Linear x-axis base class
#
########################################################################*/

#include <stdio.h>

#include "linxaxis.h"

#define     FALSE	0
#define     TRUE	!FALSE

/*##########################################################################
#
#   Name       : TLinXAxis::TLinXAxis
#
#   Purpose....: Constructor for TLinXAxis, no scales
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLinXAxis::TLinXAxis()
{
	FFont = 0;
	FScale = 0;
}

/*##########################################################################
#
#   Name       : TLinXAxis::TLinXAxis
#
#   Purpose....: Constructor for TLinXAxis, scales
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLinXAxis::TLinXAxis(TFont *Font)
{
	FFont = Font;
	FScale = 0;
}

/*##########################################################################
#
#   Name       : TLinXAxis::~TLinXAxis
#
#   Purpose....: Destructor for TLinXAxis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLinXAxis::~TLinXAxis()
{
}

/*##########################################################################
#
#   Name       : TLinXAxis::PhysToLog
#
#   Purpose....: Convert value to logical coordinate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TLinXAxis::PhysToLog(long double val)
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
#   Name       : TLinXAxis::LogToPhys
#
#   Purpose....: Convert logical coordinate to value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TLinXAxis::LogToPhys(long double rel)
{
	long double range;

	range = FValMax - FValMin;
	return FValMin + range * rel;
}

/*##########################################################################
#
#   Name       : TLinXAxis::RequiredHeight
#
#   Purpose....: Get required height
#
#   In params..: *
#   Out params.: *
#   Returns....: Min pixels required
#
##########################################################################*/
int TLinXAxis::RequiredHeight()
{
    int height;

    if (FFont)
    {
        FFont->GetStringMetrics("-", &FScaleHeight, &height);

        if (FScaleHeight > 4)
            FScaleHeight = FScaleHeight / 2;

        height += FScaleHeight + 2;
		  if (height < FMinHeight)
				return FMinHeight;
		  else
				return height;
	 }
	 else
	 {
		  if (FMinHeight)
				return FMinHeight;
        else
            return 1;
    }
}

/*##########################################################################
#
#   Name       : TLinXAxis::SetupScale
#
#   Purpose....: Setup a scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLinXAxis::SetupScale(int width)
{
    int exp;
    int scales;
    int i;
    long double Start;
    int val;
    int height;

    FFont->GetStringMetrics("-", &FScaleHeight, &height);

    if (FScaleHeight > 4)
        FScaleHeight = FScaleHeight / 2;

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
        scales = (FXMax - FXMin) / width;
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
#   Name       : TLinXAxis::CalcScale
#
#   Purpose....: Calculate scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLinXAxis::CalcScale()
{
	 int width;
	 int height;
	 int ok;
    int final;
    int newwidth;
    int maxwidth;
    long double val;
    char str[256];

    FFont->GetStringMetrics("-", &maxwidth, &height);

    ok = FALSE;
    final = FALSE;
    
    while (!ok)
    {
        newwidth = 0;
            
        SetupScale(maxwidth + maxwidth / 2);

        if (FScale == 0.0)
            break;

        ok = TRUE;
        if (FNegativeScale)
        {
            val = FFirstVal;
    
	        while (val > FValMin)
		    {
                Format(str, val);
	    		FFont->GetStringMetrics(str, &width, &height);

		    	if (width > maxwidth)
			    {
			        ok = FALSE;
			        maxwidth = width;
    			}

	    		if (width > newwidth)
		    	    newwidth = width;
    
	    	    val -= FScale;
	        }
        }
	    else
		{
			val = FFirstVal;

    		while (val < FValMax)
	    	{
                Format(str, val);
                FFont->GetStringMetrics(str, &width, &height);

    			if (width > maxwidth)
	    		{
		    	    ok = FALSE;
			        maxwidth = width;
			    }

    			if (width > newwidth)
	    		    newwidth = width;
		    	        
                val += FScale;
            }
        }

        if (ok && !final)
        {
            final = TRUE;
            
            if (newwidth < maxwidth)
            {
                ok = FALSE;
                maxwidth = newwidth;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TLinXAxis::DrawLabels
#
#   Purpose....: Draw labels
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLinXAxis::DrawLabels()
{
    long double val;
    char str[256];
    int height;
    int width;
	int x, y;
    
    if (FScale != 0.0)
    {
        if (FNegativeScale)
        {
            val = FFirstVal;
    
	    	while (val >= FValMin)
		    {
                Format(str, val);
			    FFont->GetStringMetrics(str, &width, &height);

    			x = PhysToPixel(val) - width / 2;
	    		y = FYMin + FScaleHeight + 2;

		    	if (x >= FXMin && x + width <= FXMax)
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

    			x = PhysToPixel(val) - width / 2;
	    		y = FYMin + FScaleHeight + 2;

    			if (x >= FXMin && x + width <= FXMax)
        			FDev->DrawString(x, y, str);

    		    val += FScale;
	        }
        }
    }
}

/*##########################################################################
#
#   Name       : TLinXAxis::DrawScale
#
#   Purpose....: Draw scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLinXAxis::DrawScale()
{
    long double val;
    long double subval;
	int x;
    int i;
    
    if (FScale != 0.0)
    {
        if (FNegativeScale)
	    {
		    val = FFirstVal + FScale;

    	    while (val >= FValMin)
	    	{
		    	x = PhysToPixel(val);
			    FDev->DrawLine(x, FYMin - FScaleHeight, x, FYMin + FScaleHeight);

			    subval = val - FScale / FSubScale;

    			for (i = 1; i < FSubScale; i++)
	    		{
		    		x = PhysToPixel(subval);
			    	FDev->DrawLine(x, FYMin - FScaleHeight / 2, x, FYMin + FScaleHeight / 2);
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
		    	x = PhysToPixel(val);
			    FDev->DrawLine(x, FYMin - FScaleHeight, x, FYMin + FScaleHeight);

			    subval = val + FScale / FSubScale;

    			for (i = 1; i < FSubScale; i++)
	    	    {
		    		x = PhysToPixel(subval);
			    	FDev->DrawLine(x, FYMin - FScaleHeight / 2, x, FYMin + FScaleHeight / 2);
				    subval += FScale / FSubScale;
    		    }
	    		val += FScale;
		    }
    	}
    }
}

/*##########################################################################
#
#   Name       : TLinXAxis::Draw
#
#   Purpose....: Draw axis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLinXAxis::Draw()
{
	if (IsVisible())
    {
    	FDev->SetClipRect(FXMin, FYMin - 2 * FScaleHeight, FXMax, FYMax);
        FDev->SetLgopNone();
    	FDev->SetDrawColor(FRBack, FGBack, FBBack);
        FDev->SetFilledStyle();
        FDev->DrawRect(FXMin - FAxisOffset, FYMin, FXMax, FYMax);
        FDev->SetDrawColor(FRFore, FGFore, FBFore);
        FDev->DrawLine(FXMin, FYMin, FXMax, FYMin);

        if (FFont)
        {
            FDev->SetFont(FFont);
            CalcScale();
            DrawLabels();
            DrawScale();
        }
    }
}
