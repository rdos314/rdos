#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "adcdev.h"
#include "tempdev.h"
#include "lightdev.h"
#include "datetime.h"
#include "secsamp.h"
#include "minsamp.h"
#include "hoursamp.h"
#include "daysamp.h"
#include "datetime.h"
#include "bitdev.h"
#include "videodev.h"
#include "keyboard.h"
#include "heat.h"


#define FALSE	0
#define TRUE	!FALSE

int lvcnt = 0;
long double lv;
TSample lsmin, lsmax;

long double tv[3];
TSample tsmin[3], tsmax[3];

long double rv[4];
TSample rsmin[4], rsmax[4];

THeat heat;

void UpdateTime()
{
	TDateTime CurrentTime;
	char str[80];

	sprintf(str,
			"%04d-%02d-%02d %02d.%02d.%02d",
			CurrentTime.GetYear(),
			CurrentTime.GetMonth(),
			CurrentTime.GetDay(),
			CurrentTime.GetHour(),
			CurrentTime.GetMin(),
			CurrentTime.GetSec());

	RdosSetCursorPosition(15, 0);
	RdosWriteString(str);
}

void UpdateLight(int all)
{
	char str[80];
	TDateTime time;
	int diostat;


	if (all)
		sprintf(str, "LJUS:  %7.3LfW/m2 (%7.3Lf, %7.3Lf)", lv, lsmin.GetMin(&time), lsmax.GetMax(&time));
	else
		sprintf(str, "LJUS:  %7.3LfW/m2", lv);

	RdosSetCursorPosition(0, 0);
	RdosWriteString(str);

	if (lvcnt <= 0)
	{
		lvcnt = 90;

		if (RdosReadSerialLines(1, &diostat))
		{
			if (diostat & 1)
			{
				if (lv > 0.050)
					RdosToggleSerialLine(1, 0);
			}
			else
			{
				if (lv < 0.030)
					RdosToggleSerialLine(1, 0);
			}

			if (diostat & 0x80)
			{
				if (lv > 0.200)
					RdosToggleSerialLine(1, 7);
			}
			else
			{
				if (lv < 0.120)
					RdosToggleSerialLine(1, 7);
			}
		}
	}
	else
		lvcnt--;
}

void UpdateTemp(int index, int all)
{
	char par[20];
	char str[80];
	TDateTime time;

	switch (index)
	{
		case 0:
			strcpy(par, "TEMP:   ");
			break;

		case 1:
			strcpy(par, "TANK:   ");
			break;

		case 2:
			strcpy(par, "PANNA:  ");
			heat.Add(&time, tv[index]);
			break;
	}

	if (all)
		sprintf(str, "%s %7.1LføC (%7.1Lf, %7.1Lf)", par, tv[index], tsmin[index].GetMin(&time), tsmax[index].GetMax(&time));
	else
		sprintf(str, "%s %7.1LføC", par, tv[index]);

	switch (index)
	{
		case 0:
			RdosSetCursorPosition(1, 0);
			break;

		case 1:
			RdosSetCursorPosition(2, 0);
			break;

		case 2:
			RdosSetCursorPosition(3, 0);
			break;
	}

	RdosWriteString(str);
}

void UpdateRaw(int index, int all)
{
	char par[20];
	char str[80];
	TDateTime time;

	switch (index)
	{
		case 0:
			strcpy(par, "CH0:     ");
			break;

		case 1:
			strcpy(par, "CH1:     ");
			break;

		case 2:
			strcpy(par, "CH2:     ");
			break;

		case 3:
			strcpy(par, "CH3:     ");
			break;
	}

	if (all)
		sprintf(str, "%s%7.3LfmV (%7.3Lf, %7.3Lf)", par, rv[index], rsmin[index].GetMin(&time), rsmax[index].GetMax(&time));
	else
		sprintf(str, "%s%7.3LfmV", par, rv[index]);

	switch (index)
	{
		case 0:
			RdosSetCursorPosition(4, 0);
			break;

		case 1:
			RdosSetCursorPosition(5, 0);
			break;

		case 2:
			RdosSetCursorPosition(6, 0);
			break;

		case 3:
			RdosSetCursorPosition(7, 0);
			break;
	}

	RdosWriteString(str);
}

void SecClear(TSample *sample)
{
	TDateTime time;

	if (sample->GetCount())
	{
		switch (sample->GetIndex())
		{
			case 7:
				UpdateTime();
				lv = sample->GetMean(&time);
				UpdateLight(FALSE);
				break;

			case 6:
				tv[0] = sample->GetMean(&time);
				UpdateTemp(0, FALSE);
				break;

			case 5:
				tv[1] = sample->GetMean(&time);
				UpdateTemp(1, FALSE);
				break;

			case 4:
				tv[2] = sample->GetMean(&time);
				UpdateTemp(2, FALSE);
				break;

			case 3:
				rv[0] = sample->GetMean(&time);
				UpdateRaw(0, FALSE);
				break;

			case 2:
				rv[1] = sample->GetMean(&time);
				UpdateRaw(1, FALSE);
				break;

			case 1:
				rv[2] = sample->GetMean(&time);
				UpdateRaw(2, FALSE);
				break;

			case 0:
				rv[3] = sample->GetMean(&time);
				UpdateRaw(3, FALSE);
				break;

		}
	}
}

void RawProc(TSample *sample)
{
	char str[80];
	long double val;
	TDateTime time;

	if (sample->GetCount())
	{
		val = sample->GetMean(&time);

		switch (sample->GetIndex())
		{
			case 7:
				lsmin.Add(&time, val);
				lsmax.Add(&time, val);
				UpdateLight(TRUE);
				break;

			case 6:
				tsmin[0].Add(&time, val);
				tsmax[0].Add(&time, val);
				UpdateTemp(0, TRUE);
				break;

			case 5:
				tsmin[1].Add(&time, val);
				tsmax[1].Add(&time, val);
				UpdateTemp(1, TRUE);
				break;

			case 4:
				tsmin[2].Add(&time, val);
				tsmax[2].Add(&time, val);
				UpdateTemp(2, TRUE);
				break;

			case 3:
				rsmin[0].Add(&time, val);
				rsmax[0].Add(&time, val);
				UpdateRaw(0, TRUE);
				break;

			case 2:
				rsmin[1].Add(&time, val);
				rsmax[1].Add(&time, val);
				UpdateRaw(1, TRUE);
				break;

			case 1:
				rsmin[2].Add(&time, val);
				rsmax[2].Add(&time, val);
				UpdateRaw(2, TRUE);
				break;

			case 0:
				rsmin[3].Add(&time, val);
				rsmax[3].Add(&time, val);
				UpdateRaw(3, TRUE);
				break;

		}
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

void CreateChannel(TAdcDevice *dev)
{
	TSample *sec;
	TSample *min;
	TSample *hourmin, *hourmax;
	TSample *day;

	dev->DefineInterval(1193000 / 20);
	sec = new TSecSample(dev->GetChannel(), dev->GetUnit());
	sec->ExcludeSmallest(3);
	sec->ExcludeLargest(3);
	sec->BeforeClear = SecClear;
	dev->Define(sec);

	min = new TMinSample(dev->GetChannel(), dev->GetUnit());
	sec->DefineMean(min);
	min->BeforeClear = RawProc;
}

void KeyPress(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
	char str[40];

	sprintf(str, "Key press info:");
	RdosSetCursorPosition(9, 0);
	RdosWriteString(str);

	sprintf(str, "ExtKey = %02hX, State = %04hX", ExtKey, KeyState);
	RdosSetCursorPosition(10, 0);
	RdosWriteString(str);

	sprintf(str, "VK = %02hX, ScanCode = %02hX", VirtualKey, ScanCode);
	RdosSetCursorPosition(11, 0);
	RdosWriteString(str);
}

void KeyRelease(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
	char str[40];

	sprintf(str, "Key release info:");
	RdosSetCursorPosition(9, 0);
	RdosWriteString(str);

	sprintf(str, "ExtKey = %02hX, State = %04hX", ExtKey, KeyState);
	RdosSetCursorPosition(10, 0);
	RdosWriteString(str);

	sprintf(str, "VK = %02hX, ScanCode = %02hX", VirtualKey, ScanCode);
	RdosSetCursorPosition(11, 0);
	RdosWriteString(str);
}

void DaProc(void *param)
{
	int i;
	int channel;

	for (channel = 0; channel < 8; channel++)
		RdosWriteSerialVal(2, channel, 0x7FFFFFFF);

	for (;;)
	{

		for (channel = 0; channel < 8; channel++)
		{
			for (i = 0; i <= 50; i++)
			{
				RdosWriteSerialVal(2, channel, 0x7FFFFFFF / 50 * i);
				RdosWaitMilli(250);
			}

			for (i = 49; i >= 0; i--)
			{
				RdosWriteSerialVal(2, channel, 0x7FFFFFFF / 50 * i);
				RdosWaitMilli(250);
			}
		}
	}
}

void cdecl main()
{
	int channel;
	TWait Wait;
	TAdcDevice *adc;
	TTempDevice *temp;
	TLightDevice *light;
	TKeyboardDevice *Keyboard;

	RdosWaitMilli(250);

	Keyboard = new TKeyboardDevice(&Wait);
	Keyboard->OnKeyPress = KeyPress;
	Keyboard->OnKeyRelease = KeyRelease;

#ifndef TEST

	light = new TLightDevice(&Wait, 7);
	CreateChannel(light);

	temp = new TTempDevice(&Wait, 6);
	CreateChannel(temp);

	temp = new TTempDevice(&Wait, 5);
	CreateChannel(temp);

	temp = new TTempDevice(&Wait, 4);
	CreateChannel(temp);

	adc = new TAdcDevice(&Wait, 3);
	CreateChannel(adc);

	adc = new TAdcDevice(&Wait, 2);
	CreateChannel(adc);

	adc = new TAdcDevice(&Wait, 1);
	CreateChannel(adc);

	adc = new TAdcDevice(&Wait, 0);
	CreateChannel(adc);

#endif

	for (;;)
		Wait.WaitForever();

}

