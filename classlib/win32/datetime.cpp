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
# datetime.cpp
# Date & time class
#
########################################################################*/

#include <math.h>

#include "windows.h"
#include "win32.h"
#include "datetime.h"

/*##########################################################################
#
#   Name       : TDateTime::TDateTime
#
#   Purpose....: Constructor for current date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime::TDateTime()
{
        Win32GetTics(GetTickCount(), &FMsb, &FLsb);
        RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::TDateTime
#
#   Purpose....: Copy constructor
#
#   In params..: source         TDateTime to copy
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime::TDateTime(const TDateTime &source)
{
        FMsb = source.FMsb;
        FLsb = source.FLsb;
        RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::TDateTime
#
#   Purpose....: Constructor from raw format
#
#   In params..: raw               raw rdos format of date & time
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime::TDateTime(unsigned long long Raw)
{
    unsigned long Time[2];

    memcpy(Time, &Raw, 8);

    FMsb = Time[1];
    FLsb = Time[0];
    RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::TDateTime
#
#   Purpose....: Constructor from raw format
#
#   In params..: msb, lsb               raw rdos format of date & time
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime::TDateTime(unsigned long Msb, unsigned long Lsb)
{
        FMsb = Msb;
        FLsb = Lsb;
        RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::TDateTime
#
#   Purpose....: Constructor from real
#
#   In params..: real
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime::TDateTime(long double real)
{
    FMsb = (unsigned long)floor(real);
    FLsb = (unsigned long)((real - (long double)FMsb) * 65536.0 * 65536.0);
    RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::TDateTime
#
#   Purpose....: Constructor from date
#
#   In params..: year, month, day
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime::TDateTime(int Year, int Month, int Day)
{
        FYear = Year;
        FMonth = Month;
        FDay = Day;
        FHour = 0;
        FMin = 0;
        FSec = 0;
        FMilli = 0;
        RecordToRaw();
}

/*##########################################################################
#
#   Name       : TDateTime::TDateTime
#
#   Purpose....: Constructor from date & time
#
#   In params..: year, month, day, hour, min, sec
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime::TDateTime(int Year, int Month, int Day, int Hour, int Min, int Sec)
{
        FYear = Year;
        FMonth = Month;
        FDay = Day;
        FHour = Hour;
        FMin = Min;
        FSec = Sec;
        FMilli = 0;
        RecordToRaw();
}

/*##########################################################################
#
#   Name       : TDateTime::TDateTime
#
#   Purpose....: Constructor from date & time
#
#   In params..: year, month, day, hour, min, sec, milli
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime::TDateTime(int Year, int Month, int Day, int Hour, int Min, int Sec, int Milli)
{
        FYear = Year;
        FMonth = Month;
        FDay = Day;
        FHour = Hour;
        FMin = Min;
        FSec = Sec;
        FMilli = Milli;
        RecordToRaw();
}

/*##########################################################################
#
#   Name       : TDateTime::operator long double
#
#   Purpose....: Convert to long double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime::operator long double () const
{
        long double fract;

        fract = (long double)FLsb / 65536.0 / 65536.0;
        return (long double)FMsb + fract;
}

/*##########################################################################
#
#   Name       : TDateTime::SetRaw
#
#   Purpose....: Set data in raw format
#
#   In params..: msb, lsb               raw rdos format of date & time
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::SetRaw(unsigned long Msb, unsigned long Lsb)
{
        FMsb = Msb;
        FLsb = Lsb;
        RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::GetMsb
#
#   Purpose....: Get msb
#
#   In params..: *
#   Out params.: *
#   Returns....: msb
#
##########################################################################*/
long TDateTime::GetMsb() const
{
        return FMsb;
}

/*##########################################################################
#
#   Name       : TDateTime::GetLsb
#
#   Purpose....: Get lsb
#
#   In params..: *
#   Out params.: *
#   Returns....: lsb
#
##########################################################################*/
long TDateTime::GetLsb() const
{
        return FLsb;
}

/*##########################################################################
#
#   Name       : TDateTime::HasExpired
#
#   Purpose....: Check if time has expired
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if expired
#
##########################################################################*/
int TDateTime::HasExpired() const
{
        unsigned long msb, lsb;

        Win32GetTics(GetTickCount(), &msb, &lsb);

        if (msb > FMsb)
                return TRUE;

        if (msb < FMsb)
                return FALSE;

        if (lsb > FLsb)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TDateTime::GetYear
#
#   Purpose....: Get year
#
#   In params..: *
#   Out params.: *
#   Returns....: year
#
##########################################################################*/
int TDateTime::GetYear() const
{
        return FYear;
}

/*##########################################################################
#
#   Name       : TDateTime::GetMonth
#
#   Purpose....: Get month
#
#   In params..: *
#   Out params.: *
#   Returns....: year
#
##########################################################################*/
int TDateTime::GetMonth() const
{
        return FMonth;
}

/*##########################################################################
#
#   Name       : TDateTime::GetDay
#
#   Purpose....: Get day
#
#   In params..: *
#   Out params.: *
#   Returns....: day
#
##########################################################################*/
int TDateTime::GetDay() const
{
        return FDay;
}

/*##########################################################################
#
#   Name       : TDateTime::GetHour
#
#   Purpose....: Get hour
#
#   In params..: *
#   Out params.: *
#   Returns....: hour
#
##########################################################################*/
int TDateTime::GetHour() const
{
        return FHour;
}

/*##########################################################################
#
#   Name       : TDateTime::GetMin
#
#   Purpose....: Get minute
#
#   In params..: *
#   Out params.: *
#   Returns....: minute
#
##########################################################################*/
int TDateTime::GetMin() const
{
        return FMin;
}

/*##########################################################################
#
#   Name       : TDateTime::GetSec
#
#   Purpose....: Get second
#
#   In params..: *
#   Out params.: *
#   Returns....: second
#
##########################################################################*/
int TDateTime::GetSec() const
{
        return FSec;
}

/*##########################################################################
#
#   Name       : TDateTime::GetMilliSec
#
#   Purpose....: Get millisecond
#
#   In params..: *
#   Out params.: *
#   Returns....: millisecond
#
##########################################################################*/
int TDateTime::GetMilliSec() const
{
        return FMilli;
}

/*##########################################################################
#
#   Name       : TDateTime::RawToRecord
#
#   Purpose....: Convert from raw to record format
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::RawToRecord()
{
        Win32TicsToRecord(FMsb, FLsb, &FYear, &FMonth, &FDay, &FHour, &FMin, &FSec, &FMilli);
}

/*##########################################################################
#
#   Name       : TDateTime::RecordToRaw
#
#   Purpose....: Convert from record to raw format
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::RecordToRaw()
{
        Win32RecordToTics(&FMsb, &FLsb, FYear, FMonth, FDay, FHour, FMin, FSec, FMilli);
}

/*##########################################################################
#
#   Name       : TDateTime::AddTics
#
#   Purpose....: Add tics to time
#
#   In params..: tics           tics to add
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::AddTics(long tics)
{
        Win32AddTics(&FMsb, &FLsb, tics);
        RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::AddMilli
#
#   Purpose....: Add milliseconds
#
#   In params..: ms             milliseconds
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::AddMilli(long ms)
{
        Win32AddMilli(&FMsb, &FLsb, ms);
        RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::AddSec
#
#   Purpose....: Add seconds
#
#   In params..: sec    seconds
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::AddSec(long sec)
{
        Win32AddSec(&FMsb, &FLsb, sec);
        RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::AddMin
#
#   Purpose....: Add minutes
#
#   In params..: min    minute
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::AddMin(long min)
{
        Win32AddMin(&FMsb, &FLsb, min);
        RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::AddHour
#
#   Purpose....: Add hours
#
#   In params..: hour   hours
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::AddHour(long hour)
{
        Win32AddHour(&FMsb, &FLsb, hour);
        RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::AddDay
#
#   Purpose....: Add days
#
#   In params..: day    days
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::AddDay(long day)
{
        Win32AddDay(&FMsb, &FLsb, day);
        RawToRecord();
}
