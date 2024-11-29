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
# datetime.cpp
# Date & time class
#
########################################################################*/

#include <math.h>
#include <memory.h>

#include "rdos.h"
#include "datetime.h"

#define FALSE 0
#define TRUE !FALSE

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
    RdosGetTime(&FMsb, &FLsb);
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
#   Purpose....: Constructor from raw format
#
#   In params..: raw               raw rdos format of date & time
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime::TDateTime(unsigned long long Raw)
{
    unsigned long Val[2];

    memcpy(Val, &Raw, 8);

    FMsb = Val[1];
    FLsb = Val[0];
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
#if defined( __GNUC__) || defined( __WATCOMC__)
    FMsb = (unsigned long)floor(real);
#else
    FMsb = (unsigned long)floorl(real);
#endif
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
    FMicro = 0;
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
    FMicro = 0;
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
TDateTime::TDateTime(int Year, int Month, int Day, int Hour, int Min, int Sec, int Milli, int Micro)
{
    FYear = Year;
    FMonth = Month;
    FDay = Day;
    FHour = Hour;
    FMin = Min;
    FSec = Sec;
    FMilli = Milli;
    FMicro = Micro;
    RecordToRaw();
}

/*##########################################################################
#
#   Name       : TDateTime::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TDateTime &TDateTime::operator=(const TDateTime &src)
{
    FYear = src.FYear;
    FMonth = src.FMonth;
    FDay = src.FDay;
    FHour = src.FHour;
    FMin = src.FMin;
    FSec = src.FSec;
    FMilli = src.FMilli;
    FMicro = src.FMicro;
    FMsb = src.FMsb;
    FLsb = src.FLsb;

    return *this;
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
#   Name       : TDateTime::SetLinuxTimestamp
#
#   Purpose....: Set Linux timestamp in seconds
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::SetLinuxTimestamp(long long val)
{
    long long temp;
    int ival;
    int min;
    int sec;

    temp = val / 3600 + 17269032;
    FMsb = (unsigned long)temp;

    ival = (int)(val % 3600);

    sec = ival % 60;
    min = ival / 60;

    FLsb = RdosCodeLsbTics(min, sec, 0, 0);
    RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::SetLinuxMilliTimestamp
#
#   Purpose....: Set Linux timestamp in milliseconds
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::SetLinuxMilliTimestamp(long long val)
{
    long long temp;
    int ival;
    int min;
    int sec;
    int milli;

    temp = val / 3600 / 1000 + 17269032;
    FMsb = (unsigned long)temp;

    ival = (int)(val % 3600000);

    milli = ival % 1000;
    ival = ival / 1000;

    sec = ival % 60;
    min = ival / 60;

    FLsb = RdosCodeLsbTics(min, sec, milli, 0);
    RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::SetCurrent
#
#   Purpose....: Set current data & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::SetCurrent()
{
    RdosGetTime(&FMsb, &FLsb);
    RawToRecord();
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

    RdosGetTime(&msb, &lsb);

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
#   Name       : TDateTime::WaitUntilExpired
#
#   Purpose....: Wait until time expires
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if expired
#
##########################################################################*/
void TDateTime::WaitUntilExpired() const
{
    RdosWaitRealUntil(FMsb, FLsb);
}

/*##########################################################################
#
#   Name       : TDateTime::GetDayOfWeek
#
#   Purpose....: Get day of week
#
#   In params..: *
#   Out params.: *
#   Returns....: day of week (0 = sunday)
#
##########################################################################*/
int TDateTime::GetDayOfWeek() const
{
    return RdosDayOfWeek(FYear, FMonth, FDay);
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
#   Name       : TDateTime::GetMicroSec
#
#   Purpose....: Get microsecond
#
#   In params..: *
#   Out params.: *
#   Returns....: millisecond
#
##########################################################################*/
int TDateTime::GetMicroSec() const
{
    return FMicro;
}

/*##########################################################################
#
#   Name       : TDateTime::GetLinuxTimestamp
#
#   Purpose....: Get Linux timestamp in seconds
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TDateTime::GetLinuxTimestamp() const
{
    int ival;
    long long val;

    ival = FMin;
    ival = 60 * ival + FSec;

    val = (long long)FMsb - 17269032;
    val = 3600 * val + (long long)ival;

    return val;
}

/*##########################################################################
#
#   Name       : TDateTime::GetLinuxMilliTimestamp
#
#   Purpose....: Get Linux timestamp in milliseconds
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TDateTime::GetLinuxMilliTimestamp() const
{
    int ival;
    long long val;

    ival = FMin;
    ival = 60 * ival + FSec;
    ival = 1000 * ival + FMilli;

    val = (long long)FMsb - 17269032;
    val = 3600 * 1000 * val + (long long)ival;

    return val;
}

/*##########################################################################
#
#   Name       : TDateTime::Set
#
#   Purpose....: Set time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::Set()
{
    RdosSetTime(FMsb, FLsb);
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
    RdosDecodeMsbTics(FMsb, &FYear, &FMonth, &FDay, &FHour);
    RdosDecodeLsbTics(FLsb, &FMin, &FSec, &FMilli, &FMicro);
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
    FMsb = RdosCodeMsbTics(FYear, FMonth, FDay, FHour);
    FLsb = RdosCodeLsbTics(FMin, FSec, FMilli, FMicro);
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
    RdosAddTics(&FMsb, &FLsb, tics);
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
    RdosAddMilli(&FMsb, &FLsb, ms);
    RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::AddMicro
#
#   Purpose....: Add microseconds
#
#   In params..: us             microseconds
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::AddMicro(long us)
{
    RdosAddMicro(&FMsb, &FLsb, us);
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
    RdosAddSec(&FMsb, &FLsb, sec);
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
    RdosAddMin(&FMsb, &FLsb, min);
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
    RdosAddHour(&FMsb, &FLsb, hour);
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
    RdosAddDay(&FMsb, &FLsb, day);
    RawToRecord();
}

/*##########################################################################
#
#   Name       : TDateTime::AddMonth
#
#   Purpose....: Add month
#
#   In params..: month  month
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::AddMonth(long month)
{
    FMonth += month;

    if (month > 0)
    {
        while (FMonth > 12)
        {
            FYear++;
            FMonth -= 12;
        }
    }

    if (month < 0)
    {
        while (FMonth <= 0)
        {
            FYear--;
            FMonth += 12;
        }
    }
    RecordToRaw();
}

/*##########################################################################
#
#   Name       : TDateTime::AddYear
#
#   Purpose....: Add year
#
#   In params..: year
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::AddYear(long year)
{
    FYear += year;
    RecordToRaw();
}

/*##########################################################################
#
#   Name       : TDateTime::NextDay
#
#   Purpose....: Goto next day
#
#   In params..: year
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDateTime::NextDay()
{
    FHour = 0;
    FMin = 0;
    FSec = 0;
    FMilli = 0;
    FMicro = 0;
    RecordToRaw();
    AddDay(1);
}
