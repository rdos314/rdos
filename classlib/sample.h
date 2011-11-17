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
# sample.h
# Sampling base class
#
########################################################################*/

#ifndef _SAMPLE_H
#define _SAMPLE_H

#include "section.h"
#include "datetime.h"

struct TSampleEntry
{
    long MsbTime;
    long LsbTime;
    long double Value;
    TSampleEntry *NextTime;
    TSampleEntry *NextAmp;
};

class TSample
{
public:
	TSample();
	TSample(int Index, const char *Unit);
	virtual ~TSample();

	void DefineMin(TSample *Sample);
	void DefineMax(TSample *Sample);
	void DefineMean(TSample *Sample);

    int GetCount();

	int GetIndex();
	const char *GetUnit();
    
	int GotoFirst(TDateTime *time, long double *value);
	int GotoNext(TDateTime *time, long double *value);

	int GotoSmallest(TDateTime *time, long double *value);
	int GotoLarger(TDateTime *time, long double *value);

	void ExcludeSmallest(int count);
    void ExcludeLargest(int count);

	virtual long double GetMean(TDateTime *time);
	virtual long double GetMin(TDateTime *time);
	virtual long double GetMax(TDateTime *time);
	
    void Clear();
	virtual void Add(TDateTime *time, long double value);

	void (*BeforeClear)(TSample *Sample);

protected:
	virtual void NotifyBeforeClear();

    TSample *FMinSample;
    TSample *FMaxSample;
    TSample *FMeanSample;
    int FExSmallCount;
    int FExLargeCount;
    int FSampleCount;
    TSampleEntry *FSampleTimeList;
    TSampleEntry *FSampleAmpList;
    TSampleEntry *FCurrent;
    TSection FSection;
	int FIndex;
	char *FUnit;

private:
	void Init();

};

#endif

