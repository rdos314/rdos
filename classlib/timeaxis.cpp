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
# timeaxis.cpp
# Time axis class
#
########################################################################*/

#include <stdio.h>
#include <string.h>

#include "timeaxis.h"
#include "datetime.h"

#define     FALSE       0
#define     TRUE        !FALSE

/*##########################################################################
#
#   Name       : TTimeXAxis::TTimeXAxis
#
#   Purpose....: Constructor for TTimeXAxis, no scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTimeXAxis::TTimeXAxis()
{
        FFont = 0;
        Init();
}

/*##########################################################################
#
#   Name       : TTimeXAxis::TTimeXAxis
#
#   Purpose....: Constructor for TTimeXAxis, scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTimeXAxis::TTimeXAxis(TFont *Font)
{
        FFont = Font;
        Init();
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
#   Name       : TTimeXAxis::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::Init()
{
        FIncr = 0;
    FDecimals = 0;

    strcpy(FMonth[1], "JAN");
    strcpy(FMonth[2], "FEB");
    strcpy(FMonth[3], "MAR");
    strcpy(FMonth[4], "APR");
    strcpy(FMonth[5], "MAY");
    strcpy(FMonth[6], "JUN");
    strcpy(FMonth[7], "JUL");
    strcpy(FMonth[8], "AUG");
    strcpy(FMonth[9], "SEP");
    strcpy(FMonth[10], "OCT");
    strcpy(FMonth[11], "NOV");
    strcpy(FMonth[12], "DEC");

    FAmerican = FALSE;
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
#   Name       : TTimeXAxis::SetMonthName
#
#   Purpose....: Set month name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::SetMonthName(int Month, const char *Name)
{
    if (Month > 0 && Month <= 12)
        strcpy(FMonth[Month], Name);
}

/*##########################################################################
#
#   Name       : TTimeXAxis::UseAmericanDate
#
#   Purpose....: Use american date format
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::UseAmericanDate()
{
    FAmerican = TRUE;
}

/*##########################################################################
#
#   Name       : TTimeXAxis::UseEuropeanDate
#
#   Purpose....: Use european date format
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::UseEuropeanDate()
{
    FAmerican = FALSE;
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

    if (FFont)
    {
        FFont->GetStringMetrics("-", &FScaleHeight, &height);

        if (FScaleHeight > 4)
            FScaleHeight = FScaleHeight / 2;

        return height + FScaleHeight + 2;
    }
    else
        return 1;
}

/*##########################################################################
#
#   Name       : TTimeXAxis::Format
#
#   Purpose....: Format label
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::Format(char *str, long double val)
{
    TDateTime time(val);
    long double formval;
    int month;
    int day;
    int hour;
    int min;
    int sec;
    int ms;

    switch (FScaleType)
    {
        case TIME_XAXIS_SCALE_YEAR:
            formval = time.GetYear();
            TAxis::Format(str, formval);
            break;

        case TIME_XAXIS_SCALE_MONTH:
            month = time.GetMonth();
            strcpy(str, FMonth[month]);
            break;

        case TIME_XAXIS_SCALE_DATE:
            month = time.GetMonth();
            day = time.GetDay();
            if (FAmerican)
                sprintf(str, "%d/%d", month, day);
            else
                sprintf(str, "%d/%d", day, month);
            break;

        case TIME_XAXIS_SCALE_HOUR:
            hour = time.GetHour();
            if (FAmerican)
                sprintf(str, "%d:00", hour);
            else
                sprintf(str, "%d.00", hour);
            break;

        case TIME_XAXIS_SCALE_MIN:
            hour = time.GetHour();
            min = time.GetMin();
            if (FAmerican)
                sprintf(str, "%d:%02d", hour, min);
            else
                sprintf(str, "%d.%02d", hour, min);
            break;

        case TIME_XAXIS_SCALE_SEC:
            hour = time.GetHour();
            min = time.GetMin();
            sec = time.GetSec();
            if (FAmerican)
                sprintf(str, "%d:%02d:%02d", hour, min, sec);
            else
                sprintf(str, "%d.%02d.%02d", hour, min, sec);
            break;

        case TIME_XAXIS_SCALE_MILLI:
            sec = time.GetSec();
                    ms = time.GetMilliSec();

                    if (FIncr >= 100) 
                    {
                if (FAmerican)
                    sprintf(str, "%2d.%01d", sec, ms / 100);
                else
                    sprintf(str, "%2d,%01d", sec, ms / 100);
            }
            else
            {
                if (FIncr >= 10)
                {
                    if (FAmerican)
                        sprintf(str, "%2d.%02d", sec, ms / 10);
                    else
                        sprintf(str, "%2d,%02d", sec, ms / 10);
                }
                else
                {
                    if (FAmerican)
                        sprintf(str, "%2d.%03d", sec, ms);
                    else
                        sprintf(str, "%2d,%03d", sec, ms);
                }
            }
            break;
    }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::NextTime
#
#   Purpose....: Get next time value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::NextTime(TDateTime &time, int change)
{
    switch (FScaleType)
    {
        case TIME_XAXIS_SCALE_YEAR:
                time.AddYear(change);
                    break;

        case TIME_XAXIS_SCALE_MONTH:
            time.AddMonth(change);
            break;

        case TIME_XAXIS_SCALE_DATE:
            time.AddDay(change);
            break;

        case TIME_XAXIS_SCALE_HOUR:
            time.AddHour(change);
            break;

        case TIME_XAXIS_SCALE_MIN:
            time.AddMin(change);
            break;

        case TIME_XAXIS_SCALE_SEC:
            time.AddSec(change);
            break;

        case TIME_XAXIS_SCALE_MILLI:
            time.AddMilli(change);
            break;
    }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::NextSubScale
#
#   Purpose....: Get next subscale value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::NextSubScale(TDateTime &time)
{
    int incr;

    incr = FIncr / FSubScale;
    
    switch (FScaleType)
    {
        case TIME_XAXIS_SCALE_YEAR:
            if (FSubScale == 4)
            {
                if (FNegativeScale)
                        time.AddMonth(-3);
                    else
                        time.AddMonth(3);
                }
                else
                {
                    if (FNegativeScale)
                        time.AddYear(-incr);
                    else
                        time.AddYear(incr);
                }
                        break;

        case TIME_XAXIS_SCALE_MONTH:
            if (FNegativeScale)
                time.AddMonth(-incr);
            else
                time.AddMonth(incr);
            break;
            
        case TIME_XAXIS_SCALE_DATE:
            if (FSubScale == 4)
            {
                if (FNegativeScale)
                    time.AddHour(-6);
                else
                    time.AddHour(6);
            }
            else
            {
                if (FNegativeScale)
                    time.AddDay(-incr);
                else
                    time.AddDay(incr);
            }
            break;            

        case TIME_XAXIS_SCALE_HOUR:
            if (FSubScale == 4)
            {
                if (FNegativeScale)
                    time.AddMin(-15);
                else
                    time.AddMin(15);
            }
            else
            {
                if (FNegativeScale)
                    time.AddHour(-incr);
                else
                    time.AddHour(incr);
            }
            break;            

        case TIME_XAXIS_SCALE_MIN:
            if (FSubScale == 4)
            {
                if (FNegativeScale)
                    time.AddSec(-15);
                else
                    time.AddSec(15);
            }
            else
            {
                if (FNegativeScale)
                    time.AddMin(-incr);
                else
                    time.AddMin(incr);
            }
            break;            

        case TIME_XAXIS_SCALE_SEC:
            if (FSubScale == 10)
            {
                if (FNegativeScale)
                    time.AddMilli(-500);
                else
                    time.AddMilli(500);
            }
            else
            {
                if (FNegativeScale)
                    time.AddSec(-incr);
                else
                    time.AddSec(incr);
            }
            break;            

        case TIME_XAXIS_SCALE_MILLI:
            if (FNegativeScale)
                time.AddMilli(-incr);
            else
                time.AddMilli(incr);
            break;            
    }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::SetupMilliScale
#
#   Purpose....: Setup milli-second scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::SetupMilliScale(int width)
{
        TDateTime MinTime(FValMin);
        TDateTime MaxTime(FValMax);
        TDateTime time;
        int year;
        int month;
        int day;
        int hour;
        int min;
        int sec;
        int milli;
        int micro;
        int scales;
        int height;

        FScaleType = TIME_XAXIS_SCALE_MILLI;

        FFont->GetStringMetrics("-", &FScaleHeight, &height);

        if (FScaleHeight > 4)
                FScaleHeight = FScaleHeight / 2;

        year = MinTime.GetYear();
        month = MinTime.GetMonth();
        day = MinTime.GetDay();
        hour = MinTime.GetHour();
        min = MinTime.GetMin();
        sec = MinTime.GetSec();
        milli = MinTime.GetMilliSec();
        micro = MinTime.GetMicroSec();
        MinTime = TDateTime(year, month, day, hour, min, sec, milli, micro);
        MinTime.AddTics(1000);

        year = MaxTime.GetYear();
        month = MaxTime.GetMonth();
        day = MaxTime.GetDay();
        hour = MaxTime.GetHour();
        min = MaxTime.GetMin();
        sec = MaxTime.GetSec();
        milli = MaxTime.GetMilliSec();
        micro = MaxTime.GetMicroSec();
        MaxTime = TDateTime(year, month, day, hour, min, sec, milli, micro);
        MaxTime.AddTics(1000);

    FIncr = 0;
    
        if (MaxTime > MinTime)
        {
        FNegativeScale = FALSE;
        MaxTime.AddMilli(1);

        time = MinTime;
        while (time < MaxTime)
        {
            time.AddMilli(1);
            FIncr++;
        }
    }
    else
    {
        FNegativeScale = TRUE;
            MinTime.AddMilli(1);

        time = MaxTime;
        while (time < MinTime)
        {
            time.AddMilli(1);
            FIncr++;
        }
    }

    if (FIncr != 0)
    {
        if (width)
        {
            scales = (FXMax - FXMin) / width;
            if (scales == 0)
                FIncr = 0;
        }
        else
            FIncr = 0;
    }

    if (FIncr != 0)
    {
        if (FIncr <= scales)
        {
            FSubScale = 1;
            FIncr = 1;
        }
        else
        {
            if (FIncr <= 2 * scales)
            {
                FSubScale = 2;
                FIncr = 2;
            }
            else
            {              
                if (FIncr <= 5 * scales)
                {
                    FSubScale = 5;
                    FIncr = 5;
                }
                else
                {
                    if (FIncr <= 10 * scales)
                    {
                        FSubScale = 5;
                        FIncr = 10;
                    }
                    else
                    {
                        if (FIncr <= 20 * scales)
                        {
                            FSubScale = 2;
                            FIncr = 20;
                        }
                        else
                        {
                            if (FIncr <= 50 * scales)
                            {
                                FSubScale = 5;
                                FIncr = 50;
                            }
                            else
                            {
                                if (FIncr <= 100 * scales)
                                {
                                    FSubScale = 5;
                                    FIncr = 100;
                                }
                                else
                                {
                                    if (FIncr <= 200 * scales)
                                    {
                                        FSubScale = 2;
                                        FIncr = 200;
                                    }
                                    else
                                    {
                                        if (FIncr <= 500 * scales)
                                        {
                                            FSubScale = 5;
                                            FIncr = 500;
                                        }
                                        else
                                            FIncr = 0;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (FIncr != 0)
    {
        
        if (FNegativeScale)
        {
            switch (FIncr)
            {
                case 1:
                    FFirstVal = MaxTime;
                    break;

                case 2:
                case 5:
                case 10:
                case 20:
                case 50:
                                case 100:
                                case 200:
                                case 500:
                                        year = MaxTime.GetYear();
                                        month = MaxTime.GetMonth();
                                        day = MaxTime.GetDay();
                                        hour = MaxTime.GetHour();
                                        min = MaxTime.GetMin();
                                        sec = MaxTime.GetSec();
                                        milli = MaxTime.GetMilliSec();
                                        micro = MaxTime.GetMicroSec();
                                        milli = milli / FIncr;
                                        milli = FIncr * milli;
                                        micro = FIncr * micro;
                                        MaxTime = TDateTime(year, month, day, hour, min, sec, milli, micro);
                                        MaxTime.AddTics(1000);
                                        FFirstVal = MaxTime;
                                        break;

                        }
                }
                else
                {
                        switch (FIncr)
                        {
                                case 1:
                                        FFirstVal = MinTime;
                                        break;

                                case 2:
                                case 5:
                                case 10:
                                case 20:
                                case 50:
                                case 100:
                                case 200:
                                case 500:
                                        year = MinTime.GetYear();
                                        month = MinTime.GetMonth();
                                        day = MinTime.GetDay();
                                        hour = MinTime.GetHour();
                                        min = MinTime.GetMin();
                                        sec = MinTime.GetSec();
                                        milli = MinTime.GetMilliSec();
                                        micro = MinTime.GetMicroSec();
                                        milli = milli / FIncr;
                                        milli = FIncr * milli;
                                        MinTime = TDateTime(year, month, day, hour, min, sec, milli, micro);
                                        MinTime.AddTics(1000);
                                        FFirstVal = MinTime;
                                        break;
                        }
                }
                FDigits = 3;
        }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::SetupSecScale
#
#   Purpose....: Setup second scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::SetupSecScale(int width)
{
    TDateTime MinTime(FValMin);
    TDateTime MaxTime(FValMax);
    TDateTime time;
    int year;
    int month;
    int day;
    int hour;
    int min;
    int sec;
    int scales;
    int height;

        FScaleType = TIME_XAXIS_SCALE_SEC;

        FFont->GetStringMetrics("-", &FScaleHeight, &height);

        if (FScaleHeight > 4)
            FScaleHeight = FScaleHeight / 2;

    year = MinTime.GetYear();
    month = MinTime.GetMonth();
    day = MinTime.GetDay();
    hour = MinTime.GetHour();
    min = MinTime.GetMin();
    sec = MinTime.GetSec();
        MinTime = TDateTime(year, month, day, hour, min, sec, 50, 0);

        year = MaxTime.GetYear();
        month = MaxTime.GetMonth();
        day = MaxTime.GetDay();
        hour = MaxTime.GetHour();
        min = MaxTime.GetMin();
        sec = MaxTime.GetSec();
        MaxTime = TDateTime(year, month, day, hour, min, sec, 50, 0);

        FIncr = 0;

        if (MaxTime > MinTime)
        {
                FNegativeScale = FALSE;
                MaxTime.AddSec(1);

                time = MinTime;
                while (time < MaxTime)
                {
                        time.AddSec(1);
                        FIncr++;
                }
        }
        else
        {
                FNegativeScale = TRUE;
                MinTime.AddSec(1);

                time = MaxTime;
                while (time < MinTime)
                {
                        time.AddSec(1);
                        FIncr++;
                }
        }

        if (FIncr != 0)
        {
            if (width)
            {
                scales = (FXMax - FXMin) / width;
                if (scales == 0)
                        FIncr = 0;
            }
            else
                FIncr = 0;
        }

        if (FIncr != 0)
        {
                if (FIncr <= scales)
                {
                        FSubScale = 10;
                        FIncr = 1;
                }
                else
                {
                        if (FIncr <= 2 * scales)
                        {
                                FSubScale = 2;
                                FIncr = 2;
                        }
                        else
                        {
                                if (FIncr <= 5 * scales)
                                {
                                        FSubScale = 5;
                                        FIncr = 5;
                                }
                                else
                                {
                                        if (FIncr <= 15 * scales)
                                        {
                                                FSubScale = 3;
                                                FIncr = 15;
                                        }
                                        else
                                                FIncr = 0;
                                }
                        }
                }
        }

        if (FIncr != 0)
        {

                if (FNegativeScale)
                {
                        switch (FIncr)
                        {
                                case 1:
                                        FFirstVal = MaxTime;
                                        break;

                                case 2:
                                case 5:
                                case 15:
                                        year = MaxTime.GetYear();
                                        month = MaxTime.GetMonth();
                                        day = MaxTime.GetDay();
                                        hour = MaxTime.GetHour();
                                        min = MaxTime.GetMin();
                                        sec = MaxTime.GetSec();
                                        sec = sec / FIncr;
                                        sec = FIncr * sec;
                                        MaxTime = TDateTime(year, month, day, hour, min, sec, 50, 0);
                                        FFirstVal = MaxTime;
                                        break;

                        }
                }
                else
                {
                        switch (FIncr)
                        {
                                case 1:
                                        FFirstVal = MinTime;
                                        break;

                                case 2:
                                case 5:
                                case 15:
                                        year = MinTime.GetYear();
                                        month = MinTime.GetMonth();
                                        day = MinTime.GetDay();
                                        hour = MinTime.GetHour();
                                        min = MinTime.GetMin();
                                        sec = MinTime.GetSec();
                                        sec = sec / FIncr;
                                        sec = FIncr * sec;
                                        MinTime = TDateTime(year, month, day, hour, min, sec, 50, 0);
                                        FFirstVal = MinTime;
                                        break;
                        }
                }
                FDigits = 3;
        }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::SetupMinScale
#
#   Purpose....: Setup minute scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::SetupMinScale(int width)
{
        TDateTime MinTime(FValMin);
        TDateTime MaxTime(FValMax);
        TDateTime time;
        int year;
        int month;
        int day;
        int hour;
        int min;
        int scales;
        int height;

        FScaleType = TIME_XAXIS_SCALE_MIN;

        FFont->GetStringMetrics("-", &FScaleHeight, &height);

        if (FScaleHeight > 4)
                FScaleHeight = FScaleHeight / 2;

        year = MinTime.GetYear();
        month = MinTime.GetMonth();
        day = MinTime.GetDay();
        hour = MinTime.GetHour();
        min = MinTime.GetMin();
        MinTime = TDateTime(year, month, day, hour, min, 0, 50, 0);

        year = MaxTime.GetYear();
        month = MaxTime.GetMonth();
        day = MaxTime.GetDay();
        hour = MaxTime.GetHour();
        min = MaxTime.GetMin();
        MaxTime = TDateTime(year, month, day, hour, min, 0, 50, 0);

        FIncr = 0;

        if (MaxTime > MinTime)
        {
                FNegativeScale = FALSE;
                MaxTime.AddMin(1);

                time = MinTime;
                while (time < MaxTime)
                {
                        time.AddMin(1);
                        FIncr++;
                }
        }
        else
        {
                FNegativeScale = TRUE;
                MinTime.AddMin(1);

                time = MaxTime;
                while (time < MinTime)
                {
                        time.AddMin(1);
                        FIncr++;
                }
        }

        if (FIncr != 0)
        {
            if (width)
            {
                scales = (FXMax - FXMin) / width;
                if (scales == 0)
                        FIncr = 0;
            }
            else
                FIncr = 0;
        }

        if (FIncr != 0)
        {
                if (FIncr <= scales)
                {
                        FSubScale = 4;
                        FIncr = 1;
                }
                else
                {
                        if (FIncr <= 2 * scales)
                        {
                                FSubScale = 2;
                                FIncr = 2;
                        }
                        else
                        {
                                if (FIncr <= 5 * scales)
                                {
                                        FSubScale = 5;
                                        FIncr = 5;
                                }
                                else
                                {
                                        if (FIncr <= 15 * scales)
                                        {
                                                FSubScale = 3;
                                                FIncr = 15;
                                        }
                                        else
                                                FIncr = 0;
                                }
                        }
                }
        }

        if (FIncr != 0)
        {

                if (FNegativeScale)
                {
                        switch (FIncr)
                        {
                                case 1:
                                        FFirstVal = MaxTime;
                                        break;

                                case 2:
                                case 5:
                                case 15:
                                        year = MaxTime.GetYear();
                                        month = MaxTime.GetMonth();
                                        day = MaxTime.GetDay();
                                        hour = MaxTime.GetHour();
                                        min = MaxTime.GetMin();
                                        min = min / FIncr;
                                        min = FIncr * min;
                                        MaxTime = TDateTime(year, month, day, hour, min, 0, 50, 0);
                                        FFirstVal = MaxTime;
                                        break;

                        }
                }
                else
                {
                        switch (FIncr)
                        {
                                case 1:
                                        FFirstVal = MinTime;
                                        break;

                                case 2:
                                case 5:
                                case 15:
                                        year = MinTime.GetYear();
                                        month = MinTime.GetMonth();
                                        day = MinTime.GetDay();
                                        hour = MinTime.GetHour();
                                        min = MinTime.GetMin();
                                        min = min / FIncr;
                                        min = FIncr * min;
                                        MinTime = TDateTime(year, month, day, hour, min, 0, 50, 0);
                                        FFirstVal = MinTime;
                                        break;
                        }
                }
                FDigits = 3;
        }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::SetupHourScale
#
#   Purpose....: Setup hour scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::SetupHourScale(int width)
{
        TDateTime MinTime(FValMin);
        TDateTime MaxTime(FValMax);
        TDateTime time;
        int year;
        int month;
        int day;
        int hour;
        int scales;
        int height;

        FScaleType = TIME_XAXIS_SCALE_HOUR;

        FFont->GetStringMetrics("-", &FScaleHeight, &height);

        if (FScaleHeight > 4)
                FScaleHeight = FScaleHeight / 2;

        year = MinTime.GetYear();
        month = MinTime.GetMonth();
        day = MinTime.GetDay();
        hour = MinTime.GetHour();
        MinTime = TDateTime(year, month, day, hour, 0, 0, 50, 0);

        year = MaxTime.GetYear();
        month = MaxTime.GetMonth();
        day = MaxTime.GetDay();
        hour = MaxTime.GetHour();
        MaxTime = TDateTime(year, month, day, hour, 0, 0, 50, 0);

        FIncr = 0;

        if (MaxTime > MinTime)
        {
                FNegativeScale = FALSE;
                MaxTime.AddHour(1);

                time = MinTime;
                while (time < MaxTime)
                {
                        time.AddHour(1);
                        FIncr++;
                }
        }
        else
        {
                FNegativeScale = TRUE;
                MinTime.AddHour(1);

                time = MaxTime;
                while (time < MinTime)
                {
                        time.AddHour(1);
                        FIncr++;
                }
        }

        if (FIncr != 0)
        {
            if (width)
            {
                scales = (FXMax - FXMin) / width;
                if (scales == 0)
                        FIncr = 0;
            }
            else
                FIncr = 0;
        }

        if (FIncr != 0)
        {
                if (FIncr <= scales)
                {
                        FSubScale = 4;
                        FIncr = 1;
                }
                else
                {
                        if (FIncr <= 2 * scales)
                        {
                                FSubScale = 2;
                                FIncr = 2;
                        }
                        else
                        {
                                if (FIncr <= 3 * scales)
                                {
                                        FSubScale = 3;
                                        FIncr = 3;
                                }
                                else
                                {
                                        if (FIncr <= 6 * scales)
                                        {
                                                FSubScale = 6;
                                                FIncr = 6;
                                        }
                                        else
                                                FIncr = 0;
                                }
                        }
                }
        }

        if (FIncr != 0)
        {

                if (FNegativeScale)
                {
                        switch (FIncr)
                        {
                                case 1:
                                        FFirstVal = MaxTime;
                                        break;

                                case 2:
                                case 3:
                                case 6:
                                        year = MaxTime.GetYear();
                                        month = MaxTime.GetMonth();
                                        day = MaxTime.GetDay();
                                        hour = MaxTime.GetHour();
                                        hour = hour / FIncr;
                                        hour = FIncr * hour;
                                        MaxTime = TDateTime(year, month, day, hour, 0, 0, 50, 0);
                                        FFirstVal = MaxTime;
                                        break;

                        }
                }
                else
                {
                        switch (FIncr)
                        {
                                case 1:
                                        FFirstVal = MinTime;
                                        break;

                                case 2:
                                case 3:
                                case 6:
                                        year = MinTime.GetYear();
                                        month = MinTime.GetMonth();
                                        day = MinTime.GetDay();
                                        hour = MinTime.GetHour();
                                        hour = hour / FIncr;
                                        hour = FIncr * hour;
                                        MinTime = TDateTime(year, month, day, hour, 0, 0, 50, 0);
                                        FFirstVal = MinTime;
                                        break;
                        }
                }
                FDigits = 3;
        }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::SetupDateScale
#
#   Purpose....: Setup date scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::SetupDateScale(int width)
{
        TDateTime MinTime(FValMin);
        TDateTime MaxTime(FValMax);
        TDateTime time;
        int year;
        int month;
        int day;
        int scales;
        int height;
        int dow;

        FScaleType = TIME_XAXIS_SCALE_DATE;

        FFont->GetStringMetrics("-", &FScaleHeight, &height);

        if (FScaleHeight > 4)
                FScaleHeight = FScaleHeight / 2;

        year = MinTime.GetYear();
        month = MinTime.GetMonth();
        day = MinTime.GetDay();
        MinTime = TDateTime(year, month, day, 0, 0, 0, 50, 0);

        year = MaxTime.GetYear();
        month = MaxTime.GetMonth();
        day = MaxTime.GetDay();
        MaxTime = TDateTime(year, month, day, 0, 0, 0, 50, 0);

        FIncr = 0;

        if (MaxTime > MinTime)
        {
                FNegativeScale = FALSE;
                MaxTime.AddDay(1);

                time = MinTime;
                while (time < MaxTime)
                {
                        time.AddDay(1);
                        FIncr++;
                }
        }
        else
        {
                FNegativeScale = TRUE;
                MinTime.AddDay(1);

                time = MaxTime;
                while (time < MinTime)
                {
                        time.AddDay(1);
                        FIncr++;
                }
        }

        if (FIncr != 0)
        {
            if (width)
            {
                scales = (FXMax - FXMin) / width;
                if (scales == 0)
                        FIncr = 0;
            }
            else
                FIncr = 0;
        }

        if (FIncr != 0)
        {
                if (FIncr <= scales)
                {
                        FSubScale = 4;
                        FIncr = 1;
                }
                else
                {
                        if (FIncr <= 2 * scales)
                        {
                                FSubScale = 2;
                                FIncr = 2;
                        }
                        else
                        {
                                if (FIncr <= 7 *scales)
                                {
                                        FSubScale = 7;
                                        FIncr = 7;
                                }
                                else
                                        FIncr = 0;
                        }
                }
        }

        if (FIncr != 0)
        {

                if (FNegativeScale)
                {
                        switch (FIncr)
                        {
                                case 1:
                                        FFirstVal = MaxTime;
                                        break;

                                case 2:
                                        year = MaxTime.GetYear();
                                        month = MaxTime.GetMonth();
                                        day = MaxTime.GetDay();
                                        day = (day - 1) / 2;
                                        day = 2 * day + 1;
                                        MaxTime = TDateTime(year, month, day, 0, 0, 0, 50, 0);
                                        FFirstVal = MaxTime;
                                        break;

                                case 7:
                                        year = MaxTime.GetYear();
                                        month = MaxTime.GetMonth();
                                        day = MaxTime.GetDay();
                                        MaxTime = TDateTime(year, month, day, 0, 0, 0, 50, 0);
                                        dow = MaxTime.GetDayOfWeek();
                                        MaxTime.AddDay(-dow);
                                        FFirstVal = MaxTime;
                                        break;
                        }
                }
                else
                {
                        switch (FIncr)
                        {
                                case 1:
                                        FFirstVal = MinTime;
                                        break;

                                case 2:
                                        year = MinTime.GetYear();
                                        month = MinTime.GetMonth();
                                        day = MinTime.GetDay();
                                        day = (day - 1) / 2;
                                        day = 2 * day + 1;
                                        MinTime = TDateTime(year, month, day, 0, 0, 0, 50, 0);
                                        FFirstVal = MinTime;
                                        break;

                                case 7:
                                        year = MinTime.GetYear();
                                        month = MinTime.GetMonth();
                                        day = MinTime.GetDay();
                                        MinTime = TDateTime(year, month, day, 0, 0, 0, 50, 0);
                                        dow = MinTime.GetDayOfWeek();
                                        MinTime.AddDay(-dow);
                                        FFirstVal = MinTime;
                                        break;
                        }
                }
                FDigits = 3;
        }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::SetupMonthScale
#
#   Purpose....: Setup month scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::SetupMonthScale(int width)
{
        TDateTime MinTime(FValMin);
        TDateTime MaxTime(FValMax);
        TDateTime time;
        int year;
        int month;
        int scales;
        int height;

        FScaleType = TIME_XAXIS_SCALE_MONTH;

        FFont->GetStringMetrics("-", &FScaleHeight, &height);

        if (FScaleHeight > 4)
                FScaleHeight = FScaleHeight / 2;

        year = MinTime.GetYear();
        month = MinTime.GetMonth();
        MinTime = TDateTime(year, month, 1, 0, 0, 0, 50, 0);

        year = MaxTime.GetYear();
        month = MaxTime.GetMonth();
        MaxTime = TDateTime(year, month, 1, 0, 0, 0, 50, 0);

        FIncr = 0;

        if (MaxTime > MinTime)
        {
                FNegativeScale = FALSE;
                MaxTime.AddMonth(1);

                time = MinTime;
                while (time < MaxTime)
                {
                        time.AddMonth(1);
                        FIncr++;
                }
        }
        else
        {
                FNegativeScale = TRUE;
                MinTime.AddMonth(1);

                time = MaxTime;
                while (time < MinTime)
                {
                        time.AddMonth(1);
                        FIncr++;
                }
        }

        if (FIncr != 0)
        {
            if (width)
            {
                scales = (FXMax - FXMin) / width;
                if (scales == 0)
                        FIncr = 0;
            }
            else
                FIncr = 0;
        }

        if (FIncr != 0)
        {
                if (FIncr <= scales)
                {
                        FSubScale = 1;
                        FIncr = 1;
                }
                else
                {
                        if (FIncr <= 3 * scales)
                        {
                                FSubScale = 3;
                                FIncr = 3;
                        }
                        else
                                FIncr = 0;
                }
        }

        if (FIncr != 0)
        {
                if (FNegativeScale)
                {
                        switch (FIncr)
                        {
                                case 1:
                                        FFirstVal = MaxTime;
                                        break;

                                case 3:
                                        year = MaxTime.GetYear();
                                        month = MaxTime.GetMonth();
                                        month = (month - 1) / 3;
                                        month = 3 * month + 1;
                                        MaxTime = TDateTime(year, month, 1, 0, 0, 0, 50, 0);
                                        FFirstVal = MaxTime;
                                        break;
                        }
                }
                else
                {
                        switch (FIncr)
                        {
                                case 1:
                                        FFirstVal = MinTime;
                                        break;

                                case 3:
                                        year = MinTime.GetYear();
                                        month = MinTime.GetMonth();
                                        month = (month - 1) / 3;
                                        month = 3 * month + 1;
                                        MinTime = TDateTime(year, month, 1, 0, 0, 0, 50, 0);
                                        FFirstVal = MinTime;
                                        break;
                        }
                }
                FDigits = 3;
        }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::SetupYearScale
#
#   Purpose....: Setup year scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::SetupYearScale(int width)
{
        TDateTime MinTime(FValMin);
        TDateTime MaxTime(FValMax);
        int exp;
        int scales;
        int i;
        long double Start;
        int val;
        int height;
        int MinYear;
        int MaxYear;

        FScaleType = TIME_XAXIS_SCALE_YEAR;

        FFont->GetStringMetrics("-", &FScaleHeight, &height);

        if (FScaleHeight > 4)
                FScaleHeight = FScaleHeight / 2;

        MinYear = MinTime.GetYear();
        MaxYear = MaxTime.GetYear();

        if (MaxYear > MinYear)
                MaxYear++;
        else
                MinYear++;

        FIncr = MaxYear - MinYear;

        if (FIncr < 0)
        {
                FNegativeScale = TRUE;
                FIncr = -FIncr;
        }
        else
                FNegativeScale = FALSE;

        if (FIncr != 0)
        {
            if (width)
            {
                scales = (FXMax - FXMin) / width;
                if (scales == 0)
                        FIncr = 0;
            }
            else
                FIncr = 0;
        }

        if (FIncr != 0)
        {
                FIncr = (FIncr - 1) / scales + 1;

                exp = 0;

                while (FIncr > 10)
                {
                        exp++;
                        FIncr = FIncr / 10;
                }

                if (FIncr == 1)
                {
                        exp--;
                        FIncr = 10;
                }

                if (FIncr == 0)
                {
                        FIncr = 1;
                        FSubScale = 4;
                }
                else
                {
                        if (FIncr <= 2)
                        {
                                FIncr = 2;
                                FSubScale = 2;
                        }
                        else
                        {
                                if (FIncr <= 5)
                                {
                                        FIncr = 5;
                                        FSubScale = 5;
                                }
                                else
                                {
                                        exp++;
                                        FIncr = 1;
                                        if (exp)
                                                FSubScale = 2;
                                        else
                                                FSubScale = 4;
                                }
                        }
                }

                if (exp > 0)
                        for (i = 0; i < exp; i++)
                                FIncr = FIncr * 10;

                if (FNegativeScale)
                        Start = MaxYear / FIncr;
                else
                        Start = MinYear / FIncr;

                val = Start;
                FFirstVal = TDateTime(val * FIncr, 1, 1, 0, 0, 0, 0, 0);

                exp = 1;
                val = MinYear;

                while (val >= 10)
                {
                        exp++;
                        val = val / 10;
                }

                FDigits = exp;

                exp = 1;
                val = MaxYear;

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
#   Name       : TTimeXAxis::CalcSecScale
#
#   Purpose....: Calculate seconds scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::CalcSecScale(int width)
{
        SetupSecScale(width);

        if (FIncr && FIncr <= 4)
        {
                SetupMilliScale(width);

                if (FIncr == 0)
                        SetupSecScale(width);
        }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::CalcMinScale
#
#   Purpose....: Calculate minute scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::CalcMinScale(int width)
{
        SetupMinScale(width);

        if (FIncr && FIncr <= 4)
        {
                CalcSecScale(width);

                if (FIncr == 0)
                        SetupMinScale(width);
        }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::CalcHourScale
#
#   Purpose....: Calculate hour scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::CalcHourScale(int width)
{
        SetupHourScale(width);

        if (FIncr && FIncr <= 4)
        {
        CalcMinScale(width);

        if (FIncr == 0)
            SetupHourScale(width);
    }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::CalcDateScale
#
#   Purpose....: Calculate date scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::CalcDateScale(int width)
{
    SetupDateScale(width);

    if (FIncr && FIncr <= 4)
    {
        CalcHourScale(width);

        if (FIncr == 0)
            SetupDateScale(width);
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
         SetupMonthScale(width);

    if (FIncr && FIncr <= 4)
    {
        CalcDateScale(width);

        if (FIncr == 0)
            SetupMonthScale(width);
    }
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
    SetupYearScale(width);

         if (FIncr && FIncr <= 4)
         {
                  CalcMonthScale(width);

                  if (FIncr == 0)
                                SetupYearScale(width);
         }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::DrawLabels
#
#   Purpose....: Draw labels
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::DrawLabels()
{
    TDateTime time;
    char str[256];
        int x, y;
    int height;
    int width;
    
    if (FIncr != 0)
    {
        if (FNegativeScale)
        {
            time = TDateTime(FFirstVal);

                        while (time >= FValMin)
                        {
                Format(str, time);
                            FFont->GetStringMetrics(str, &width, &height);

                                x = PhysToPixel(time) - width / 2;
                                y = FYMin + FScaleHeight + 2;

                                if (x >= FXMin && x + width <= FXMax)
                                        FDev->DrawString(x, y, str);

                NextTime(time, -FIncr);
                }
                }
                else
                {
            time = TDateTime(FFirstVal);

                        while (time <= FValMax)
                        {
                            Format(str, time);
                                FFont->GetStringMetrics(str, &width, &height);

                                x = PhysToPixel(time) - width / 2;
                                y = FYMin + FScaleHeight + 2;

                            if (x >= FXMin && x + width <= FXMax)
                                        FDev->DrawString(x, y, str);

                NextTime(time, FIncr);
                }
            }
    }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::DrawScale
#
#   Purpose....: Draw scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::DrawScale()
{
    TDateTime time;
    TDateTime subtime;
        int x;
        int i;

    if (FIncr != 0)
    {
        if (FNegativeScale)
        {
            time = TDateTime(FFirstVal);

            NextTime(time, FIncr);
                        
                        while (time >= FValMin)
                        {
                                x = PhysToPixel(time);
                                FDev->DrawLine(x, FYMin - FScaleHeight, x, FYMin + FScaleHeight);

                                subtime = time;

                                for (i = 0; i < FSubScale; i++)
                            {
                                        x = PhysToPixel(subtime);
                                        FDev->DrawLine(x, FYMin - FScaleHeight / 2, x, FYMin + FScaleHeight / 2);
                                        NextSubScale(subtime);
                            }

                NextTime(time, -FIncr);
                }
            }
                else
                {
            time = TDateTime(FFirstVal);
            NextTime(time, -FIncr);

                        while (time <= FValMax)
                        {
                                x = PhysToPixel(time);
                                FDev->DrawLine(x, FYMin - FScaleHeight, x, FYMin + FScaleHeight);

                                subtime = time;

                                for (i = 0; i < FSubScale; i++)
                            {
                                        x = PhysToPixel(subtime);
                                        FDev->DrawLine(x, FYMin - FScaleHeight / 2, x, FYMin + FScaleHeight / 2);
                                        NextSubScale(subtime);
                            }

                NextTime(time, FIncr);
                    }
            }
    }
}

/*##########################################################################
#
#   Name       : TTimeXAxis::CalcScale
#
#   Purpose....: Calculate scaling
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTimeXAxis::CalcScale()
{
    TDateTime time;
    int ok;
    int final;
    int newwidth;
    int maxwidth;
    char str[256];
    int height;
    int width;

        ok = FALSE;
        final = FALSE;

        FFont->GetStringMetrics("-", &maxwidth, &height);

    while (!ok)
        {
        newwidth = 0;

        CalcYearScale(maxwidth);

        if (FIncr == 0)
                break;

        ok = TRUE;
                if (FNegativeScale)
                {
                    time = TDateTime(FFirstVal);

                        while (time > FValMin)
                        {
                            Format(str, time);
                            FFont->GetStringMetrics(str, &width, &height);
                            
                            width = width + width / 2;
                
                        if (width > maxwidth)
                            {
                                ok = FALSE;
                                maxwidth = width;
                            }

                            if (width > newwidth)
                                newwidth = width;

                NextTime(time, -FIncr);
                }
        }
                else
                {
            time = TDateTime(FFirstVal);

                        while (time < FValMax)
                        {
                Format(str, time);
                FFont->GetStringMetrics(str, &width, &height);

                width = width + width / 2;

                            if (width > maxwidth)
                            {
                                ok = FALSE;
                                maxwidth = width;
                            }

                            if (width > newwidth)
                                newwidth = width;
                                
                NextTime(time, FIncr);
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
