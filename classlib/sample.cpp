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
# sample.cpp
# Sampling base class
#
########################################################################*/

#include <string.h>
#include "sample.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TSample::TSample
#
#   Purpose....: Constructor for sampling
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSample::TSample()
 : FSection("Sample")
{
	FIndex = 0;
	FUnit = 0;

	Init();
}

/*##########################################################################
#
#   Name       : TSample::TSample
#
#   Purpose....: Constructor for sampling
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSample::TSample(int Index, const char *Unit)
 : FSection("Sample")
{
	int size;

	FIndex = Index;
	size = strlen(Unit);
	FUnit = new char[size+1];
	strcpy(FUnit, Unit);

	Init();
}

/*##########################################################################
#
#   Name       : TSample::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSample::Init()
{
    FMinSample = 0;
    FMaxSample = 0;
    FMeanSample = 0;
    FSampleCount = 0;
    FSampleTimeList = 0;
    FSampleAmpList = 0;
    FCurrent = 0;
    BeforeClear = 0;
    FExSmallCount = 0;
    FExLargeCount = 0;
}

/*##########################################################################
#
#   Name       : TSample::~TSample
#
#   Purpose....: Destructor for sampling
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSample::~TSample()
{
    Clear();
	if (FUnit)
		delete FUnit;
}

/*##########################################################################
#
#   Name       : TSample::GetIndex
#
#   Purpose....: Get index
#
#   In params..: time       sample time
#                value      sample value
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSample::GetIndex()
{
	return FIndex;
}

/*##########################################################################
#
#   Name       : TSample::GetUnit
#
#   Purpose....: Get unit
#
#   In params..: time       sample time
#                value      sample value
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TSample::GetUnit()
{
	return FUnit;
}

/*##########################################################################
#
#   Name       : TSample::Add
#
#   Purpose....: Add a new sample
#
#   In params..: time       sample time
#                value      sample value
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSample::Add(TDateTime *time, long double value)
{
    TSampleEntry *entry;
    TSampleEntry *list;
    TSampleEntry *next;

    entry = new TSampleEntry;
    entry->MsbTime = time->GetMsb();
    entry->LsbTime = time->GetLsb();
    entry->Value = value;
    entry->NextTime = 0;
    entry->NextAmp = 0;

    FSection.Enter();
    list = FSampleTimeList;
    if (list)
    {
        next = list->NextTime;
        while (next)
        {
            list = next;
            next = list->NextTime;
        }
        list->NextTime = entry;
    }
    else
        FSampleTimeList = entry;

    list = FSampleAmpList;
    if (list)
    {
        if (list->Value >= value)
        {
            entry->NextAmp = FSampleAmpList;
            FSampleAmpList = entry;
        }
        else
        {
            next = list->NextAmp;
            while (next && (next->Value < value))
            {
                list = next;
                next = list->NextAmp;
            }
            list->NextAmp = entry;
            entry->NextAmp = next;
        }
    }
    else
        FSampleAmpList = entry;

    FSampleCount++;
    
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TSample::DefineMin
#
#   Purpose....: Define a clear min sample
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSample::DefineMin(TSample *Sample)
{
    FMinSample = Sample;
}

/*##########################################################################
#
#   Name       : TSample::DefineMax
#
#   Purpose....: Define a clear max sample
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSample::DefineMax(TSample *Sample)
{
    FMaxSample = Sample;
}

/*##########################################################################
#
#   Name       : TSample::DefineMean
#
#   Purpose....: Define a clear mean sample
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSample::DefineMean(TSample *Sample)
{
    FMeanSample = Sample;
}

/*##########################################################################
#
#   Name       : TSample::NotifyBeforeClear
#
#   Purpose....: Notify before clear
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSample::NotifyBeforeClear()
{
	if (BeforeClear)
		(*BeforeClear)(this);
}

/*##########################################################################
#
#   Name       : TSample::Clear
#
#   Purpose....: Clear samples
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSample::Clear()
{
	TDateTime time;
	long double val;
	TSampleEntry *entry;
	TSampleEntry *next;

	if (FSampleCount)
	{
		NotifyBeforeClear();

		if (FMinSample)
		{
			val = GetMin(&time);
			FMinSample->Add(&time, val);
		}

		if (FMaxSample)
		{
			val = GetMax(&time);
			FMaxSample->Add(&time, val);
		}

		if (FMeanSample)
		{
			val = GetMean(&time);
			FMeanSample->Add(&time, val);
		}

		FSection.Enter();

		entry = FSampleTimeList;
		while (entry)
		{
			next = entry->NextTime;
			delete entry;
			entry = next;
		}

		FSampleTimeList = 0;
		FSampleAmpList = 0;
		FSampleCount = 0;
		FCurrent = 0;

		FSection.Leave();
	}
}

/*##########################################################################
#
#   Name       : TSample::GetCount
#
#   Purpose....: Get number of samples
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSample::GetCount()
{
    return FSampleCount;
}

/*##########################################################################
#
#   Name       : TSample::GotoFirst
#
#   Purpose....: Goto first sample
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSample::GotoFirst(TDateTime *time, long double *value)
{
    FCurrent = FSampleTimeList;
    if (FCurrent)
    {
		time->SetRaw(FCurrent->MsbTime, FCurrent->LsbTime);
        *value = FCurrent->Value;
        return TRUE;
    }
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TSample::GotoNext
#
#   Purpose....: Goto next sample
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSample::GotoNext(TDateTime *time, long double *value)
{
    if (FCurrent)
        FCurrent = FCurrent->NextTime;

    if (FCurrent)
    {
		time->SetRaw(FCurrent->MsbTime, FCurrent->LsbTime);
        *value = FCurrent->Value;
        return TRUE;
    }
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TSample::GotoSmallest
#
#   Purpose....: Goto smallest sample
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSample::GotoSmallest(TDateTime *time, long double *value)
{
    FCurrent = FSampleAmpList;
    if (FCurrent)
    {
		time->SetRaw(FCurrent->MsbTime, FCurrent->LsbTime);
        *value = FCurrent->Value;
        return TRUE;
    }
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TSample::GotoLarger
#
#   Purpose....: Goto larger sample
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSample::GotoLarger(TDateTime *time, long double *value)
{
    if (FCurrent)
        FCurrent = FCurrent->NextAmp;

    if (FCurrent)
    {
        time->SetRaw(FCurrent->MsbTime, FCurrent->LsbTime);
        *value = FCurrent->Value;
        return TRUE;
    }
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TSample::ExcludeSmallest
#
#   Purpose....: Exclude a number of the smallest samples from statistics
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSample::ExcludeSmallest(int count)
{
    FExSmallCount = count;
}

/*##########################################################################
#
#   Name       : TSample::ExcludeLargest
#
#   Purpose....: Exclude a number of the largest samples from statistics
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSample::ExcludeLargest(int count)
{
    FExLargeCount = count;
}

/*##########################################################################
#
#   Name       : TSample::GetMean
#
#   Purpose....: Get mean value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSample::GetMean(TDateTime *time)
{
    TSampleEntry *entry;
    int i;
    int count;
    long double sum = 0;

	count = FSampleCount - FExLargeCount - FExSmallCount;
    if (count > 0)
    {
        FSection.Enter();
        entry = FSampleAmpList;

        for (i = 0; entry && i < FExSmallCount; i++)
            entry = entry->NextAmp;

        if (entry)
        	time->SetRaw(entry->MsbTime, entry->LsbTime);

        for (i = 0; entry && i < count; i++)
        {
            sum += entry->Value;
            entry = entry->NextAmp;
        }
        FSection.Leave();

        return sum / count;
    }
    else
        return 0.0;
}

/*##########################################################################
#
#   Name       : TSample::GetMin
#
#   Purpose....: Get minimum value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSample::GetMin(TDateTime *time)
{
    TSampleEntry *entry;
    int i;

    FSection.Enter();

    entry = FSampleAmpList;

    for (i = 0; entry && i < FExSmallCount; i++)
        entry = entry->NextAmp;

    FSection.Leave();

    if (entry)
    {
		time->SetRaw(entry->MsbTime, entry->LsbTime);
        return entry->Value;
    }
    else
        return 0.0;
}

/*##########################################################################
#
#   Name       : TSample::GetMax
#
#   Purpose....: Get max value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSample::GetMax(TDateTime *time)
{
    TSampleEntry *entry;
    int i;
    int skip;

	skip = FSampleCount - FExLargeCount - 1;
    if (skip > 0)
    {
        FSection.Enter();

        entry = FSampleAmpList;

        for (i = 0; entry && i < skip; i++)
            entry = entry->NextAmp;

        FSection.Leave();

		time->SetRaw(entry->MsbTime, entry->LsbTime);
        return entry->Value;
    }
    else
        return 0.0;
}
