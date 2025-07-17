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

