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
#include "rad.h"
#include "file.h"
#include "ymodem.h"
#include "log.h"

#define FALSE	0
#define TRUE	!FALSE

TFile *file;

int lvcnt = 0;
long double lv;
TSample lsmin, lsmax;

long double tv[3];
TSample tsmin[3], tsmax[3];

long double rv[4];
TSample rsmin[4], rsmax[4];

THeat *heat;
TRadiator *radiator[16];

int TInDiffOk;
long double TInLast;
long double TInDiff;
long double TInSum;
int InCount;

int MotDiffOk;
long double MotLast;
long double MotDiff;
long double MotSum;
long double MotMax;

int HeatStartCount;
int HeatStopCount;
int WinterRef;

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

void UpdateHeat()
{
	char str[41];

	RdosSetCursorPosition(9, 0);

	if (heat->IsEpStarted())
		RdosWriteString("EP ON  ");
	else
		RdosWriteString("EP OFF ");

	sprintf(str, "%4.1Lf", heat->ReadEpValve());
	RdosWriteString(str);

	RdosSetCursorPosition(9, 12);

	if (heat->IsVpStarted())
		RdosWriteString("VP ON  ");
	else
		RdosWriteString("VP OFF ");

	sprintf(str, "%4.1Lf", heat->ReadVpValve());
	RdosWriteString(str);

	RdosSetCursorPosition(9, 24);

	if (heat->IsCircStarted())
		RdosWriteString("CIRC ON  ");
	else
		RdosWriteString("CIRC OFF ");

}

void LogRad(TRadiator *rad, TRadLog &log)
{
	if (rad && rad->IsOnline())
	{
		log.valid = TRUE;
		log.t = (int)(100.0 * rad->GetTemp());
		log.ref = (int)(100.0 * rad->GetRef());
		log.taux = (int)(100.0 * rad->GetAuxTemp());
		log.motor = (int)(100.0 * rad->GetMotor());
		log.light = (int)(100.0 * rad->GetLight());
	}
	else
	{
		log.valid = FALSE;
		log.t = -1;
		log.ref = -1;
		log.taux = -1;
		log.motor = -1;
		log.light = -1;
	}
}

void LogOne(TLog &log)
{
	int i;
	TDateTime time;

	for (i = 0; i < 7; i++)
		LogRad(radiator[i], log.rad[i]);

	log.LsbTime = time.GetLsb();
	log.MsbTime = time.GetMsb();
	log.epon = heat->IsEpStarted();
	log.vpon = heat->IsVpStarted();
	log.circon = heat->IsCircStarted();
	log.epvalve = (int)(100.0 * heat->ReadEpValve());
	log.vpvalve = (int)(100.0 * heat->ReadVpValve());
	log.circvalve = (int)(100.0 * heat->ReadCircValve());
	log.light = (int)(100.0 * lv);
	log.tout = (int)(100.0 * tv[0]);
	log.ttank = (int)(100.0 * tv[1]);
	log.tpanna = (int)(100.0 * tv[2]);
}

void UpdateFuzzy()
{
	int val;
	long double fval;
	int chan;
	char str[41];
	TDateTime time;
	int hour;
	int min;
	int night;
	int i;
	long double tsum;
	long double msum;
	int tcount;
	long double motmax;

	tcount = 0;
	tsum = 0.0;
	msum = 0.0;
	motmax = 0.0;

	RdosSetCursorPosition(10, 0);
	RdosWriteString("TEMP ");

	RdosSetCursorPosition(11, 0);
	RdosWriteString("REF  ");

	RdosSetCursorPosition(12, 0);
	RdosWriteString("MOT  ");

	RdosSetCursorPosition(13, 0);
	RdosWriteString("LGHT ");

	RdosSetCursorPosition(14, 0);
	RdosWriteString("ATMP ");

	hour = time.GetHour();
	min = time.GetMin();

	night = FALSE;
	if (hour >= 20)
		night = TRUE;
	else
	{
		if (hour < 6)
			night = TRUE;
	}

	for (i = 0; i < 16; i++)
	{
		if (radiator[i])
		{

			if (radiator[i]->IsOnline())
			{
				fval = radiator[i]->GetMotor();

				tcount++;
				tsum += radiator[i]->GetTemp() - radiator[i]->GetRef();
				msum += fval;

				if (fval > motmax)
					motmax = fval;
			}

			if (night)
			{
				if (tv[0] < 0.0)
					radiator[i]->SetWinterRef();
				else
					radiator[i]->SetNightRef();
			}
			else
				radiator[i]->SetDayRef();

			fval = radiator[i]->GetRef();
			RdosSetCursorPosition(11, 5 + 5 * i);
			sprintf(str, "%4.1Lf ", fval);
			RdosWriteString(str);

			radiator[i]->SetAmbient(tv[0]);

			RdosSetCursorPosition(10, 5 + 5 * i);
			if (radiator[i]->IsOnline())
			{
				fval = radiator[i]->GetTemp();
				sprintf(str, "%4.1Lf ", fval);
				RdosWriteString(str);

			}
			else
				RdosWriteString("---- ");

			RdosSetCursorPosition(13, 5 + 5 * i);
			if (radiator[i]->IsOnline())
			{
				fval = radiator[i]->GetLight();
				sprintf(str, "%4.2Lf ", fval);
				RdosWriteString(str);
			}
			else
				RdosWriteString("---- ");

			RdosSetCursorPosition(14, 5 + 5 * i);
			if (radiator[i]->IsOnline())
			{
				fval = radiator[i]->GetAuxTemp();
				sprintf(str, "%4.1Lf ", fval);
				RdosWriteString(str);
			}
			else
				RdosWriteString("---- ");

			RdosSetCursorPosition(12, 5 + 5 * i);
			if (radiator[i]->IsOnline())
			{
				fval = radiator[i]->GetMotor();
				sprintf(str, " %3.1Lf ", fval);
				RdosWriteString(str);

			}
			else
				RdosWriteString(" --- ");
		}
	}

	if (tcount)
	{
		tsum = tsum / tcount;
		msum = msum / tcount;

		TInSum += tsum;
		InCount++;

		MotSum += msum;

		if (MotMax < motmax)
			MotMax = motmax;

		if (InCount == 10)
		{
			TInSum = TInSum / InCount;

			if (TInDiffOk)
				TInDiff = TInSum - TInLast;

			TInLast = TInSum;

			RdosSetCursorPosition(8, 0);

			if (TInDiffOk)
				sprintf(str, "TERR %6.2Lf %6.2Lf", TInLast, TInDiff);
			else
				sprintf(str, "TERR %6.2Lf", TInLast);

			RdosWriteString(str);

			MotSum = MotSum / InCount;

			if (MotDiffOk)
				MotDiff = MotSum - MotLast;

			MotLast = MotSum;

			fval = (MotMax + MotLast) / 2.0;

			if (fval >= 7.5)
				heat->StartHeat();

			if (fval <= 5.0)
				heat->StopHeat();

			if (fval <= 2.0)
				heat->StopCirc();

			if (fval >= 3.0)
				heat->StartCirc();

			heat->WriteCircValve(fval);

//			if (night)
//				heat->EnableEpTop();
//			else
//				heat->DisableEpTop();

			if (tv[0] > 5.0)
				heat->SetEpLimit(55.0);
			else
				heat->SetEpLimit(65.0);

			if (tv[0] < -2.5)
				heat->EpExclusiveHotWater();
			else
				heat->SharedHotWater();

			RdosSetCursorPosition(8, 20);
			sprintf(str, "MOT %6.2Lf %6.2Lf", MotLast, fval);
			RdosWriteString(str);

			TInDiffOk = TRUE;
			InCount = 0;
			TInSum = 0.0;
			MotMax = 0.0;
			MotDiffOk = TRUE;
			MotSum = 0.0;
		}
	}

	TLog log;

	if (file->IsOpen())
	{
		LogOne(log);
		file->SetPos(file->GetSize());
		file->Write(&log, sizeof(TLog));
	}
}

void SecClear(TSample *sample)
{
	TDateTime time;

	UpdateHeat();

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
				UpdateFuzzy();
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
				heat->UpdateEp(val);
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
//	switch (VirtualKey)
//	{
//		case 0x60:
//			heat->StartHeat();
//			break;
//
//		case 0x6C:
//			heat->StopHeat();
//			break;
//	}
}

void KeyRelease(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
}

void Stat(void *param)
{
	TDateTime *time;
	TWait wait;
	TSerialDevice serial(&wait, 1, 19200);
	TYModem ymodem(&serial);
	char ch;

	RdosWaitMilli(2000);

	serial.Open();
	serial.Enable();

	for (;;)
	{
		if (serial.WaitForChar(2000))
		{
			ch = serial.Read();

			if (ch == 'D')
			{
				if (!ymodem.SendFile("z:\\raw.log"))
					serial.Write("Failed");
			}
			else
				serial.Write(ch);
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

	TInDiffOk = FALSE;
	InCount = 0;
	TInSum = 0.0;
	TInLast = 0.0;
	TInDiff = 0.0;

	MotDiffOk = FALSE;
	MotSum = 0.0;
	MotLast = 0.0;
	MotDiff = 0.0;
	MotMax = 0.0;

	HeatStartCount = 0;
	HeatStopCount = 0;

	RdosWaitMilli(250);

	file = new TFile("z:\\raw.log", 0);

	RdosCreateThread(Stat, "STAT", 0, 0x10000);

	heat = new THeat;
	radiator[0] = new TRadiator(0x20);
	radiator[1] = new TRadiator(0x21);
	radiator[2] = new TRadiator(0x22);
	radiator[3] = new TRadiator(0x23);
	radiator[4] = new TRadiator(0x24);
	radiator[5] = new TRadiator(0x25);
	radiator[6] = new TRadiator(0x26);

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

