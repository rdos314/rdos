/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
#   Purpose....: Constructor for TLinXAxis
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

    FFont->GetStringMetrics("-", &FScaleHeight, &height);

    if (FScaleHeight > 4)
        FScaleHeight = FScaleHeight / 2;

    return height + FScaleHeight + 2;
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
void TLinXAxis::CalcScale(int width)
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
    int newwidth;
    int maxwidth;
    int height;
    int width;
    int ok;
    int final;
    char str[256];
    long double val;
    long double subval;
	int x, y;
    int i;

	FDev->SetClipRect(FXMin, FYMin - 2 * FScaleHeight, FXMax, FYMax);
    FDev->SetLgopNone();
	FDev->SetDrawColor(FRBack, FGBack, FBBack);
    FDev->SetFilledStyle();
    FDev->DrawRect(FXMin, FYMin, FXMax, FYMax - 1);
    FDev->SetDrawColor(FRFore, FGFore, FBFore);
    FDev->DrawLine(FXMin, FYMin, FXMax, FYMin);
    FDev->SetFont(FFont);

    FFont->GetStringMetrics("-", &maxwidth, &height);

    ok = FALSE;
    final = FALSE;
    
    while (!ok)
    {
        newwidth = 0;
        
        CalcScale(maxwidth);

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

    if (FScale != 0.0)
    {
        if (FNegativeScale)
        {
            val = FFirstVal;

			while (val > FValMin)
			{
                Format(str, val);
			    FFont->GetStringMetrics(str, &width, &height);

				x = PhysToPixel(val) - width / 2;
				y = FYMin + FScaleHeight + 2;

				FDev->DrawString(x, y, str);

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

				x = PhysToPixel(val) - width / 2;
				y = FYMin + FScaleHeight + 2;

				FDev->DrawString(x, y, str);

				val += FScale;
	        }
        }

        if (FNegativeScale)
	    {
		    val = FFirstVal + FScale;

			while (val > FValMin)
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

			while (val < FValMax)
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
