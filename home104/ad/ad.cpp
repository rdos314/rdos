#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "adcdev.h"
#include "datetime.h"
#include "secsamp.h"
#include "minsamp.h"
#include "datetime.h"
#include "bitdev.h"
#include "videodev.h"

#define FALSE	0
#define TRUE	!FALSE

static long double Meassured[8];

void SecClear(TSample *sample)
{
	char str[80];
	long double min, max, mean;
	TDateTime time;

	if (sample->GetCount())
	{
		min = sample->GetMin(&time);
		max = sample->GetMax(&time);
		mean = sample->GetMean(&time);

		sprintf(str, "%7.1LfmV", min);
		RdosSetCursorPosition(1, 0);
		RdosWriteString(str);

		sprintf(str, "%7.1LfmV", max);
		RdosSetCursorPosition(2, 0);
		RdosWriteString(str);

		sprintf(str, "%7.1LfmV", mean);
		RdosSetCursorPosition(3, 0);
		RdosWriteString(str);
	}
}

void MinClear(TSample *sample)
{
	char str[80];
	long double min, max, mean;
	TDateTime time;

	if (sample->GetCount())
	{
		min = sample->GetMin(&time);
		max = sample->GetMax(&time);
		mean = sample->GetMean(&time);

		sprintf(str, "%7.1LfmV", min);
		RdosSetCursorPosition(4, 0);
		RdosWriteString(str);

		sprintf(str, "%7.1LfmV", max);
		RdosSetCursorPosition(5, 0);
		RdosWriteString(str);

		sprintf(str, "%7.1LfmV", mean);
		RdosSetCursorPosition(6, 0);
		RdosWriteString(str);
	}
}

void Sample(TAdcDevice *adc, TDateTime *time, long double value)
{
	char str[80];
	int channel = adc->GetChannel();

	sprintf(str, "%7.1LfmV", value);
	RdosSetCursorPosition(0, 0);
	RdosWriteString(str);
}

void Sample()
{
	long double val[16][100];
	long double min, max;
	long double mean;
	int values;
	int i;
	int channel;
	int value;

	for (i = 0; i < 100; i++)
	{
		for (channel = 0; channel < 8; channel++)
		{
//			value = RdosReadAD(channel);
			val[channel][i] = (long double)value / 32768.0 * 10000.0;
		}
		RdosWaitMilli(10);
	}

	for (channel = 0; channel < 8; channel++)
	{
		min = 10000.0;
		max = -10000.0;

		for (i = 0; i < 100; i++)
		{
			if (val[channel][i] < min)
				min = val[channel][i];

			if (val[channel][i] > max)
				max = val[channel][i];
		}

		values = 100;
		mean = 0.0;
		for (i = 0; i < 100; i++)
		{
			if (val[channel][i] > min && val[channel][i] < max)
				mean += val[channel][i];
			else
				values--;
		}

		if (values)
			mean = mean / values;
		else
			mean = (min + max) / 2;
		mean -= 1.0;

		Meassured[channel] = mean;
	}
}

void WriteRaw()
{
	int channel;
	char str[20];

	for (channel = 0; channel < 8; channel++)
	{
		sprintf(str, "%7.1LfmV", Meassured[channel]);
		RdosSetCursorPosition(8 + channel, 0);
		RdosWriteString(str);
	}
}


void OldSample()
{
	int i;
	int channel;
	char str[20];
	int x, y;
	long double temp;
	long double sumarr[8];
	int countarr[8];
	long double minarr[8];
	long double maxarr[8];
	TDateTime *time;
	int PrevMin;
	int PrevDay;
    long double min, max;

	for (channel = 0; channel < 8; channel++)
	{
		sumarr[channel] += Meassured[channel];
		countarr[channel]++;
	}

	temp = sumarr[7] / countarr[7] / 50.0 / 100.0;
	min = minarr[7] / 50.0 / 100.0;
	max = maxarr[7] / 50.0 / 100.0;
	sprintf(str, "LJUS:  %7.3LfW/m2 (%7.3Lf, %7.3Lf)", temp, min, max);
	RdosSetCursorPosition(0, 0);
	RdosWriteString(str);

	temp = sumarr[6] / countarr[6] / 100.0;
	min = minarr[6] / 100.0;
	max = maxarr[6] / 100.0;
	sprintf(str, "TEMP:  %7.2LfC (%7.2Lf, %7.2Lf)", temp, min, max);
	RdosSetCursorPosition(1, 0);
	RdosWriteString(str);

	temp = Meassured[5] / 100.0;
	min = minarr[5] / 100.0;
	max = maxarr[5] / 100.0;
	sprintf(str, "TANK:  %7.1LfC (%7.2Lf, %7.2Lf)", temp, min, max);
	RdosSetCursorPosition(2, 0);
	RdosWriteString(str);

	temp = Meassured[4] / 100.0;
	min = minarr[4] / 100.0;
	max = maxarr[4] / 100.0;
	sprintf(str, "PANNA: %7.1LfC (%7.2Lf, %7.2Lf)", temp, min, max);
	RdosSetCursorPosition(3, 0);
	RdosWriteString(str);
}

void cdecl main()
{
	int channel;
	TWait Wait;
	TAdcDevice *adc[8];
	TSecSample *sec[8];
	TMinSample *min[8];

	for (channel = 0; channel < 1; channel++)
	{
		adc[channel] = new TAdcDevice(&Wait, channel);
		adc[channel]->DefineInterval(11930);
		adc[channel]->OnSample = Sample;
		sec[channel] = new TSecSample;
		sec[channel]->ExcludeSmallest(5);
		sec[channel]->ExcludeLargest(5);
		sec[channel]->BeforeClear = SecClear;
		adc[channel]->Define(sec[channel]);
		min[channel] = new TMinSample;
		min[channel]->BeforeClear = MinClear;
		sec[channel]->Define(min[channel]);
	}

	for (;;)
		Wait.WaitForever();

}

