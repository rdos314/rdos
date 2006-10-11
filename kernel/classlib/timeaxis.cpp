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
# timeaxis.cpp
# Time x-axis class
#
########################################################################*/

#include <stdio.h>

#include "timeaxis.h"
#include "datetime.h"

#define     FALSE	0
#define     TRUE	!FALSE

/*##########################################################################
#
#   Name       : TTimeXAxis::TTimeXAxis
#
#   Purpose....: Constructor for TTimeXAxis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTimeXAxis::TTimeXAxis(TFont *Font)
{
	FFont = Font;
	FScale = 0;
    FDecimals = 0;
}

/*##########################################################################
#
#   Name       : TTimeXAxis::~TTimeXAxis
#
#   Purpose....: Destructor for TTimeXAxis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTimeXAxis::~TTimeXAxis()
{
}

/*##########################################################################
#
#   Name       : TTimeXAxis::PhysToLog
#
#   Purpose....: Convert value to logical coordinate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TTimeXAxis::PhysToLog(long double val)
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
#   Name       : TTimeXAxis::LogToPhys
#
#   Purpose....: Convert logical coordinate to value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TTimeXAxis::LogToPhys(long double rel)
{
	long double range;

	range = FValMax - FValMin;
	return FValMin + range * rel;
}

/*##########################################################################
#
#   Name       : TTimeXAxis::RequiredHeight
#
#   Purpose....: Get required height
#
#   In params..: *
#   Out params.: *
#   Returns....: Min pixels required
#
##########################################################################*/
int TTimeXAxis::RequiredHeight()
{
    int height;

    FFont->GetStringMetrics("-", &FScaleHeight, &height);

    if (FScaleHeight > 4)
        FScaleHeight = FScaleHeight / 2;

    return height + FScaleHeight + 2;
}

/*##########################################################################
#
#   Name       : TTimeXAxis::CalcYearScale
#
#   Purpose....: Calculate year scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::CalcYearScale(int width)
{
    TDateTime MinTime(FValMin);
    TDateTime MaxTime(FValMax);
    int exp;
    int scales;
    int i;
    long double Start;
    int val;
    int height;

    FFont->GetStringMetrics("-", &FScaleHeight, &height);

    if (FScaleHeight > 4)
        FScaleHeight = FScaleHeight / 2;
    
    FTimeValMin = MinTime.GetYear();
    FTimeValMax = MaxTime.GetYear();

    if (FTimeValMax > FTimeValMin)
        FTimeValMax++;
    else
        FTimeValMin++;
    
    FScale = FTimeValMax - FTimeValMin;

    if (FScale < 0)
    {
        FNegativeScale = TRUE;
        FScale = -FScale;
    }
    else
        FNegativeScale = FALSE;

    if (FScale != 0)
    {
        scales = (FXMax - FXMin) / width;
        if (scales == 0)
            FScale = 0;
    }

    if (FScale != 0)
    {
        FScale = FScale / scales;

        exp = 0;

        while (FScale > 10)
        {
            exp++;
            FScale = FScale / 10;
        }

		if (FScale == 1)
		{
            exp--;
            FScale = 10;
        }

        if (FScale == 0)
        {
            FScale = 1;
            FSubScale = 4;
        }
        else
        {
            if (FScale <= 2)
            {
                FScale = 2;
                FSubScale = 2;
            }
            else
            {
                if (FScale <= 5)
                {
                    FScale = 5;
                    FSubScale = 5;
                }
                else
                {   
                    exp++;
                    FScale = 1;
                    if (exp)
                        FSubScale = 2;
                    else
                        FSubScale = 4;
                }
            }
        }
        
        if (exp > 0)
            for (i = 0; i < exp; i++)
                FScale = FScale * 10;

        if (FNegativeScale)
            Start = FTimeValMax / FScale;
        else
            Start = FTimeValMin / FScale;        

        val = Start;
        FFirstVal = val * FScale;

        exp = 1;
        val = FTimeValMin;

        while (val >= 10)         
        {
            exp++;
            val = val / 10;
        }

        FDigits = exp;

        exp = 1;
        val = FTimeValMax;

        while (val >= 10)         
        {
            exp++;
            val = val / 10;
        }

        if (exp > FDigits)
            FDigits = exp;

    }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::CalcMonthScale
#
#   Purpose....: Calculate month scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::CalcMonthScale(int width)
{
    TDateTime MinTime(FValMin);
    TDateTime MaxTime(FValMax);
    int exp;
    int scales;
    int i;
    long double Start;
    int val;
    int height;

    FFont->GetStringMetrics("-", &FScaleHeight, &height);

    if (FScaleHeight > 4)
        FScaleHeight = FScaleHeight / 2;
    
    FTimeValMin = 12 * MinTime.GetYear() + MinTime.GetMonth();
    FTimeValMax = 12 * MaxTime.GetYear() + MaxTime.GetMonth();

    if (FTimeValMax > FTimeValMin)
        FTimeValMax++;
    else
        FTimeValMin++;
    
    FScale = FTimeValMax - FTimeValMin;

    if (FScale < 0)
    {
        FNegativeScale = TRUE;
        FScale = -FScale;
    }
    else
        FNegativeScale = FALSE;

    if (FScale != 0)
    {
        scales = (FXMax - FXMin) / width;
        if (scales == 0)
            FScale = 0;
    }

    if (FScale != 0)
    {
        if (FScale <= scales)
            FScale = 1;
        else
            FScale = 3;

        if (FNegativeScale)
            Start = FTimeValMax / FScale;
        else
            Start = FTimeValMin / FScale;        

        val = Start;
        FFirstVal = val * FScale;
        FDigits = 3;
    }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::Draw
#
#   Purpose....: Draw axis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::Draw()
{
    TDateTime time;
    int newwidth;
    int maxwidth;
    int height;
    int width;
    int ok;
    int final;
    char str[256];
    int val;
	int x, y;
    int i;
    int count;

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
        
        CalcYearScale(maxwidth);

        if (FScale == 0)
            break;

        ok = TRUE;
        if (FNegativeScale)
        {
            val = FFirstVal;

			while (val > FTimeValMin)
			{
                Format(str, (long double)val);
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

			while (val < FTimeValMax)
			{
                Format(str, (long double)val);
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

    if (FScale != 0)
    {
        if (FNegativeScale)
        {
            val = FFirstVal;

			while (val >= FTimeValMin)
			{
                Format(str, (long double)val);
			    FFont->GetStringMetrics(str, &width, &height);

                time = TDateTime(val, 1, 1, 0, 0, 0, 0);
				x = PhysToPixel(time) - width / 2;
				y = FYMin + FScaleHeight + 2;

				if (x >= FXMin && x + width <= FXMax)
					FDev->DrawString(x, y, str);

				val -= FScale;
			 }
		 }
		else
		{
			val = FFirstVal;

			while (val <= FTimeValMax)
			{
				 Format(str, (long double)val);
				 FFont->GetStringMetrics(str, &width, &height);

			    time = TDateTime(val, 1, 1, 0, 0, 0, 0);
				x = PhysToPixel(time) - width / 2;
				y = FYMin + FScaleHeight + 2;

			    if (x >= FXMin && x + width <= FXMax)
					FDev->DrawString(x, y, str);

				val += FScale;
			  }
		  }

        if (FNegativeScale)
	    {
		    val = FFirstVal + FScale;
			
			while (val >= FTimeValMin)
			{
                time = TDateTime(val, 1, 1, 0, 0, 0, 0);
				x = PhysToPixel(time);
				FDev->DrawLine(x, FYMin - FScaleHeight, x, FYMin + FScaleHeight);

    		    for (i = 1; i < FSubScale; i++)
	    		{
                    time = TDateTime(val, 3 * i, 1, 0, 0, 0, 0);
			    	x = PhysToPixel(time);
				    FDev->DrawLine(x, FYMin - FScaleHeight / 2, x, FYMin + FScaleHeight / 2);
    			}

				val -= FScale;
	        }
	    }
		else
		{
			val = FFirstVal - FScale;

			while (val <= FTimeValMax)
			{
                time = TDateTime(val, 1, 1, 0, 0, 0, 0);
				x = PhysToPixel(time);
				FDev->DrawLine(x, FYMin - FScaleHeight, x, FYMin + FScaleHeight);

    		    for (i = 1; i < FSubScale; i++)
	    		{
                    time = TDateTime(val, 3 * i, 1, 0, 0, 0, 0);
			    	x = PhysToPixel(time);
				    FDev->DrawLine(x, FYMin - FScaleHeight / 2, x, FYMin + FScaleHeight / 2);
    			}

			    val += FScale;
		    }
	    }
    }
}
