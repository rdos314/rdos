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
