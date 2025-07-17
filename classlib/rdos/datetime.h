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
# datetime.h
# Date & time class
#
########################################################################*/

#ifndef _DATETIME_H
#define _DATETIME_H

class TDateTime
{
public:
    TDateTime();
    TDateTime(const TDateTime &Source);
    TDateTime(unsigned long Msb, unsigned long Lsb);
    TDateTime(unsigned long long Raw);
    TDateTime(long double real);
    TDateTime(int Year, int Month, int Day);
    TDateTime(int Year, int Month, int Day, int Hour, int Min, int Sec);
    TDateTime(int Year, int Month, int Day, int Hour, int Min, int Sec, int ms, int us);

    const TDateTime &operator=(const TDateTime &src);
    operator long double () const;

    void SetLinuxTimestamp(long long val);
    void SetLinuxMilliTimestamp(long long val);

    void SetCurrent();

    long GetMsb() const;
    long GetLsb() const;
    void SetRaw(unsigned long Msb, unsigned long Lsb);
    int HasExpired() const;
    void WaitUntilExpired() const;
    void AddTics(long tics);
    void AddMicro(long us);
    void AddMilli(long ms);
    void AddSec(long sec);
    void AddMin(long min);
    void AddHour(long hour);
    void AddDay(long day);
    void AddMonth(long month);
    void AddYear(long year);

    void NextDay();

    int GetDayOfWeek() const;
    int GetYear() const;
    int GetMonth() const;
    int GetDay() const;
    int GetHour() const;
    int GetMin() const;
    int GetSec() const;
    int GetMilliSec() const;
    int GetMicroSec() const;
    long long GetLinuxTimestamp() const;
    long long GetLinuxMilliTimestamp() const;

    void Set();

protected:
    void RawToRecord();
    void RecordToRaw();

private:
    unsigned long FMsb;
    unsigned long FLsb;
    int FYear;
    int FMonth;
    int FDay;
    int FHour;
    int FMin;
    int FSec;
    int FMilli;
    int FMicro;
};

#endif

