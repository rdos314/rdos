#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rdos.h"
#include "bmp.h"
#include "videodev.h"
#include "keyboard.h"
#include "mouse.h"
#include "file.h"
#include "log.h"
#include "sample.h"
#include "ymodem.h"
#include "linxaxis.h"
#include "linyaxis.h"
#include "chart.h"
#include "jpeg.h"

#define FALSE	0
#define	TRUE	!FALSE

void RecHeader(TYModem *ymodem, char header)
{
	RdosWriteChar(header);
}

void main()
{
	TFont *font;
	TWait *Wait;
	TWaitDevice *WaitDevice;
	TGraphicDevice *vbe;
	TFile *file;
	TLog log;
	TSample sample;
	TDateTime time;
	TWait wait;
	TSerialDevice Serial(&wait, 2, 19200);
	TYModem ymodem(&Serial);
	char str[81];
	long double val;
	TFile *logfile;
	TLinXAxis *x;
	TLinYAxis *tempy;
	TLinYAxis *motory;
	TLinYAxis *lighty;
	TLinYAxis *vpy;
	TLinYAxis *epy;
	TLinYAxis *circy;
	TLinYAxis *vpvalvey;
	TLinYAxis *epvalvey;
	TChart *temp[7];
	TChart *motor[7];
	TChart *light[7];
	TChart *panna;
	TChart *tank;
	TChart *ref;
	TChart *tout;
	TChart *vp;
	TChart *ep;
	TChart *circ;
	TChart *vpvalve;
	TChart *epvalve;
	int i;
	TJpegBitmapDevice *jpeg;

	RdosWaitMilli(250);

	file = new TFile("raw.log", 0);
	ymodem.OnHeader = RecHeader;

	Serial.Open();
	Serial.Enable();
	Serial.Write('D');

	if (!ymodem.RecFile(file))
		exit(-1);

	vbe = new TVideoGraphicDevice(24, 800, 600);

	font = new TFont(10);
	x = new TLinXAxis(font);
	tempy = new TLinYAxis(font);
	motory = new TLinYAxis(font);
	lighty = new TLinYAxis(font);
	vpy = new TLinYAxis(font);
	epy = new TLinYAxis(font);
	circy = new TLinYAxis(font);
	vpvalvey = new TLinYAxis(font);
	epvalvey = new TLinYAxis(font);

	tank = new TChart(vbe, x, tempy);
	tank->SetWindow(0, 0, 799, 399);

	ref = new TChart(vbe, x, tempy);
	ref->SetWindow(0, 0, 799, 399);

	tout = new TChart(vbe, x, tempy);
	tout->SetWindow(0, 0, 799, 399);

	panna = new TChart(vbe, x, tempy);
	panna->SetWindow(0, 0, 799, 399);

	vp = new TChart(vbe, x, vpy);
	vp->SetWindow(0, 500, 799, 519);

	ep = new TChart(vbe, x, epy);
	ep->SetWindow(0, 520, 799, 539);

	circ = new TChart(vbe, x, circy);
	circ->SetWindow(0, 540, 799, 559);

	vpvalve = new TChart(vbe, x, vpvalvey);
	vpvalve->SetWindow(0, 560, 799, 579);

	epvalve = new TChart(vbe, x, epvalvey);
	epvalve->SetWindow(0, 580, 799, 599);

	for (i = 0; i < 7; i++)
	{
		temp[i] = new TChart(vbe, x, tempy);
		temp[i]->SetWindow(0, 0, 799, 349);

		motor[i] = new TChart(vbe, x, motory);
		motor[i]->SetWindow(0, 350, 799, 424);

		light[i] = new TChart(vbe, x, lighty);
		light[i]->SetWindow(0, 425, 799, 499);

	}

	tank->SetColor(128, 128, 0);
	ref->SetColor(128, 128, 128);
	tout->SetColor(0, 128, 128);
	panna->SetColor(128, 0, 128);

	vp->SetColor(255, 255, 255);
	ep->SetColor(255, 255, 255);
	circ->SetColor(255, 255, 255);
	vpvalve->SetColor(255, 255, 255);
	epvalve->SetColor(255, 255, 255);

	temp[0]->SetColor(255, 0, 0);
	motor[0]->SetColor(255, 0, 0);
	light[0]->SetColor(255, 0, 0);
	temp[1]->SetColor(0, 255, 0);
	motor[1]->SetColor(0, 255, 0);
	light[1]->SetColor(0, 255, 0);
	temp[2]->SetColor(0, 0, 255);
	motor[2]->SetColor(0, 0, 255);
	light[2]->SetColor(0, 0, 255);
	temp[3]->SetColor(255, 255, 0);
	motor[3]->SetColor(255, 255, 0);
	light[3]->SetColor(255, 255, 0);
	temp[4]->SetColor(255, 0, 255);
	motor[4]->SetColor(255, 0, 255);
	light[4]->SetColor(255, 0, 255);
	temp[5]->SetColor(0, 255, 255);
	motor[5]->SetColor(0, 255, 255);
	light[5]->SetColor(0, 255, 255);
	temp[6]->SetColor(255, 255, 255);
	motor[6]->SetColor(255, 255, 255);
	light[6]->SetColor(255, 255, 255);

	x->SetMax(time);
	tempy->Define(-10.0, 60.0);
	motory->Define(0.0, 10.0);
	lighty->Define(0.0, 2.0);
	vpy->Define(-0.1, 1.1);
	epy->Define(-0.1, 1.1);
	circy->Define(-0.1, 1.1);
	vpvalvey->Define(-1.0, 11.0);
	epvalvey->Define(-1.0, 11.0);

	file->SetPos(0);

	logfile = new TFile("raw.txt", 0);

	while (file->IsOpen() && file->GetPos() != file->GetSize())
	{
		file->Read(&log, sizeof(TLog));
		time.SetRaw(log.MsbTime, log.LsbTime);
		if (file->GetPos() == sizeof(TLog))
			x->SetMin(time);

		val = log.ttank / 100.0;
		tank->LineTo(time, val);

		val = log.rad[0].ref / 100.0;
		ref->LineTo(time, val);

		val = log.tout / 100.0;
		tout->LineTo(time, val);

		val = log.tpanna / 100.0;
		panna->LineTo(time, val);

		if (log.vpon)
			val = 1.0;
		else
			val = 0.0;
		vp->LineTo(time, val);

		if (log.epon)
			val = 1.0;
		else
			val = 0.0;
		ep->LineTo(time, val);

		if (log.circon)
			val = 1.0;
		else
			val = 0.0;
		circ->LineTo(time, val);

		val = log.vpvalve / 100.0;
		vpvalve->LineTo(time, val);

		val = log.epvalve / 100.0;
		epvalve->LineTo(time, val);

		for (i = 0; i < 7; i++)
		{
			val = log.rad[i].t / 100.0;
			temp[i]->LineTo(time, val);

			val = log.rad[i].motor / 100.0;
			motor[i]->LineTo(time, val);

			val = log.rad[i].light / 100.0;
			light[i]->LineTo(time, val);
		}
	}

	delete logfile;

	jpeg = new TJpegBitmapDevice(vbe);
	jpeg->Blit(vbe, 0, 0, 0, 0, vbe->GetWidth(), vbe->GetHeight());
	jpeg->Save("trend.jpg");
	delete jpeg;

	while (!RdosPollKeyboard())
		RdosWaitMilli(1000);

	RdosReadKeyboard();
}

