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
	TChart *temp;
    TChart *aux;
	TChart *motor;
	TChart *light;
	TChart *outlight;
	TChart *panna;
	TChart *tank;
	TChart *ref;
	TChart *tout;
	TChart *vp;
	TChart *ep;
	TChart *circ;
	TChart *vpvalve;
	TChart *epvalve;
	TChart *lines;
	int i, j;
	TJpegBitmapDevice *jpeg;
	long double prevplot;
	int plot;
	long double mintime;
	long double maxtime;

	RdosWaitMilli(250);

	vbe = new TVideoGraphicDevice(24, 1024, 768);

	vbe->SetFilledStyle();
	vbe->SetDrawColor(255, 255, 255);
	vbe->DrawRect(0, 0, vbe->GetWidth(), vbe->GetHeight());

	font = new TFont(15);
	x = new TLinXAxis(font);
	tempy = new TLinYAxis(font);
	motory = new TLinYAxis(font);
	lighty = new TLinYAxis(font);
	vpy = new TLinYAxis(font);
	epy = new TLinYAxis(font);
	circy = new TLinYAxis(font);
	vpvalvey = new TLinYAxis(font);
	epvalvey = new TLinYAxis(font);

	vbe->SetFont(font);

	tank = new TChart(vbe, x, tempy);
	tank->SetWindow(50, 0, 1023, 567);
	vbe->SetDrawColor(128, 128, 0);
	vbe->DrawString(0, 250, "TANK");

	ref = new TChart(vbe, x, tempy);
	ref->SetWindow(50, 0, 1023, 567);
	vbe->SetDrawColor(0, 100, 150);
	vbe->DrawString(0, 350, "REF");

	tout = new TChart(vbe, x, tempy);
	tout->SetWindow(50, 0, 1023, 567);
	vbe->SetDrawColor(0, 128, 128);
	vbe->DrawString(0, 500, "UTE");

	panna = new TChart(vbe, x, tempy);
	panna->SetWindow(50, 0, 1023, 567);
	vbe->SetDrawColor(128, 0, 128);
	vbe->DrawString(0, 150, "PANNA");

	vp = new TChart(vbe, x, vpy);
	vp->SetWindow(50, 668, 1023, 687);
	vbe->SetDrawColor(0, 0, 0);
	vbe->DrawString(0, 673, "VP");

	ep = new TChart(vbe, x, epy);
	ep->SetWindow(50, 688, 1023, 707);
	vbe->SetDrawColor(0, 0, 0);
	vbe->DrawString(0, 693, "EP");

	circ = new TChart(vbe, x, circy);
	circ->SetWindow(50, 708, 1023, 727);
	vbe->SetDrawColor(0, 0, 0);
	vbe->DrawString(0, 713, "CIRC");

	vpvalve = new TChart(vbe, x, vpvalvey);
	vpvalve->SetWindow(50, 728, 1023, 747);
	vbe->SetDrawColor(0, 0, 0);
	vbe->DrawString(0, 733, "VPV");

	epvalve = new TChart(vbe, x, epvalvey);
	epvalve->SetWindow(50, 748, 1023, 767);
	vbe->SetDrawColor(0, 0, 0);
	vbe->DrawString(0, 753, "EPV");

	temp = new TChart(vbe, x, tempy);
	temp->SetWindow(50, 0, 1023, 567);
	vbe->SetDrawColor(200, 0, 0);
	vbe->DrawString(0, 330, "INNE");

	aux = new TChart(vbe, x, tempy);
	aux->SetWindow(50, 0, 1023, 567);
	vbe->SetDrawColor(0, 0, 200);
	vbe->DrawString(0, 370, "KARM");

	lines = new TChart(vbe, x, tempy);
	lines->SetWindow(50, 0, 1023, 567);

	motor = new TChart(vbe, x, motory);
	motor->SetWindow(50, 568, 1023, 617);
	vbe->SetDrawColor(0, 0, 0);
	vbe->DrawString(0, 598, "ELEM");

	light = new TChart(vbe, x, lighty);
	light->SetWindow(50, 618, 1023, 667);
	vbe->SetDrawColor(0, 0, 0);
	vbe->DrawString(0, 648, "LJUS");

	outlight = new TChart(vbe, x, lighty);
	outlight->SetWindow(50, 618, 1023, 667);

	tank->SetColor(128, 128, 0);
	ref->SetColor(0, 100, 150);
	tout->SetColor(0, 128, 128);
	panna->SetColor(128, 0, 128);

	vp->SetColor(0, 0, 0);
	ep->SetColor(0, 0, 0);
	circ->SetColor(0, 0, 0);
	vpvalve->SetColor(0, 0, 0);
	epvalve->SetColor(0, 0, 0);

	temp->SetColor(200, 0, 0);
	aux->SetColor(0, 0, 200);
	motor->SetColor(0, 0, 0);
	light->SetColor(0, 192, 0);
	outlight->SetColor(192, 0, 0);

	tempy->Define(-10.0, 70.0);
	motory->Define(0.0, 10.0);
	lighty->Define(0.0, 3.5);
	vpy->Define(-0.1, 1.1);
	epy->Define(-0.1, 1.1);
	circy->Define(-0.1, 1.1);
	vpvalvey->Define(-1.0, 11.0);
	epvalvey->Define(-1.0, 11.0);

	file = new TFile("full.log");

	logfile = new TFile("raw.txt", 0);

	file->SetPos(0);
	file->Read(&log, sizeof(TLog));
	time.SetRaw(log.MsbTime, log.LsbTime);
	mintime = time;
	x->SetMin(time);

	while (file->IsOpen() && file->GetPos() != file->GetSize())
		file->Read(&log, sizeof(TLog));

	time.SetRaw(log.MsbTime, log.LsbTime);
	maxtime = time;
	x->SetMax(time);

	for (i = 0; i < 7; i++)
	{
		prevplot = 0.0;
		file->SetPos(0);

		for (j = -10; j < 70; j++)
		{
			if (j % 5 == 0)
				lines->SetColor(125, 125, 125);
			else
				lines->SetColor(200, 200, 200);
			val = j;
			lines->Plot(mintime, val);
			lines->LineTo(maxtime, val);
		}

		while (file->IsOpen() && file->GetPos() != file->GetSize())
		{
			file->Read(&log, sizeof(TLog));
			time.SetRaw(log.MsbTime, log.LsbTime);

			if (time > prevplot + 0.1)
				plot = TRUE;
			else
				plot = FALSE;

			if (log.rad[i].valid && log.rad[i].taux)
				prevplot = time;

			val = log.ttank / 100.0;
			if (plot)
				tank->Plot(time, val);
			else
				tank->LineTo(time, val);

			if (log.rad[i].valid)
			{
				val = log.rad[i].ref / 100.0;
				if (plot)
					ref->Plot(time, val);
				else
					ref->LineTo(time, val);
			}

			val = log.tout / 100.0;
			if (plot)
				tout->Plot(time, val);
			else
				tout->LineTo(time, val);

			val = log.tpanna / 100.0;
			if (plot)
				panna->Plot(time, val);
			else
				panna->LineTo(time, val);

			if (log.vpon)
				val = 1.0;
			else
				val = 0.0;
			if (plot)
				vp->Plot(time, val);
			else
				vp->LineTo(time, val);

			if (log.epon)
				val = 1.0;
			else
				val = 0.0;
			if (plot)
				ep->Plot(time, val);
			else
				ep->LineTo(time, val);

			if (log.circon)
				val = 1.0;
			else
				val = 0.0;
			if (plot)
				circ->Plot(time, val);
			else
				circ->LineTo(time, val);

			val = log.vpvalve / 100.0;
			if (plot)
				vpvalve->Plot(time, val);
			else
				vpvalve->LineTo(time, val);

			val = log.epvalve / 100.0;
			if (plot)
				epvalve->Plot(time, val);
			else
				epvalve->LineTo(time, val);

			val = log.light / 100.0;
			if (plot)
				outlight->Plot(time, val);
			else
				outlight->LineTo(time, val);

			if (log.rad[i].valid && log.rad[i].taux)
			{
				val = log.rad[i].t / 100.0;
				if (plot)
					temp->Plot(time, val);
				else
					temp->LineTo(time, val);

				val = log.rad[i].taux / 100.0;
				if (plot)
					aux->Plot(time, val);
				else
					aux->LineTo(time, val);

				val = log.rad[i].motor / 100.0;
				if (plot)
					motor->Plot(time, val);
				else
					motor->LineTo(time, val);

				val = log.rad[i].light / 100.0;
				if (plot)
					light->Plot(time, val);
				else
					light->LineTo(time, val);
			}
		}

		while (!RdosPollKeyboard())
			RdosWaitMilli(1000);

		RdosReadKeyboard();

		jpeg = new TJpegBitmapDevice(vbe);
		jpeg->Blit(vbe, 0, 0, 0, 0, vbe->GetWidth(), vbe->GetHeight());
		sprintf(str, "trend%d.jpg", i);
		jpeg->Save(str);
		delete jpeg;

		vbe->ClearClipRect();
		vbe->SetFilledStyle();
		vbe->SetDrawColor(255, 255, 255);
		vbe->DrawRect(50, 0, vbe->GetWidth(), vbe->GetHeight());
	}

	delete logfile;

}

