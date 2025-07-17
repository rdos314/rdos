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
# timeaxis.h
# Time x-axis class
#
########################################################################*/

#ifndef _TIMEAXIS_H
#define _TIMEAXIS_H

#include "xaxis.h"
#include "font.h"
#include "datetime.h"

#define TIME_XAXIS_SCALE_YEAR   1
#define TIME_XAXIS_SCALE_MONTH  2
#define TIME_XAXIS_SCALE_DATE   3
#define TIME_XAXIS_SCALE_HOUR   4
#define TIME_XAXIS_SCALE_MIN    5
#define TIME_XAXIS_SCALE_SEC    6
#define TIME_XAXIS_SCALE_MILLI  7

class TTimeXAxis : public TXAxis
{
public:
	TTimeXAxis();
	TTimeXAxis(TFont *font);
    ~TTimeXAxis();

	virtual long double PhysToLog(long double val);
	virtual long double LogToPhys(long double rel);

    virtual int RequiredHeight();

	virtual void Draw();

	void SetMonthName(int Month, const char *Name);
	void UseAmericanDate();
	void UseEuropeanDate();

protected:
    void Init();
    virtual void Format(char *str, long double val);
    void NextTime(TDateTime &time, int change);
    void NextSubScale(TDateTime &time);
    void DrawLabels();
    void DrawScale();

    void SetupYearScale(int width);
    void SetupMonthScale(int width);
    void SetupDateScale(int width);
    void SetupHourScale(int width);
    void SetupMinScale(int width);
    void SetupSecScale(int width);
    void SetupMilliScale(int width);

    void CalcYearScale(int width);
    void CalcMonthScale(int width);
    void CalcDateScale(int width);
    void CalcHourScale(int width);
    void CalcMinScale(int width);
    void CalcSecScale(int width);

    void CalcScale();

    int FScaleHeight;
    int FNegativeScale;
    long double FFirstVal;
    int FSubScale;
    int FScaleType;
    int FIncr;

    char FMonth[13][5];
    int FAmerican;

	TFont *FFont;
};

#endif
