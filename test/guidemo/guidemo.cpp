#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "bitdev.h"
#include "videodev.h"
#include "planthr.h"

#define FALSE	0
#define TRUE	!FALSE

int count = 0;

void RandomColor(TGraphicDevice *dev)
{
	dev->SetDrawColor(random(256), random(256), random(256));
}

void RandomLgop(TGraphicDevice *dev)
{
	switch (random(12))
    {
        case 0:
            dev->SetLgopNone();
			break;

		case 1:
            dev->SetLgopNull();
			break;

        case 2:
            dev->SetLgopOr();
            break;

        case 3:
			dev->SetLgopAnd();
            break;

        case 4:
            dev->SetLgopXor();
            break;

        case 5:
			dev->SetLgopInv();
            break;

        case 6:
			dev->SetLgopInvOr();
            break;

        case 7:
			dev->SetLgopInvAnd();
			break;

        case 8:
            dev->SetLgopInvXor();
            break;

		case 9:
            dev->SetLgopAdd();
            break;

        case 10:
            dev->SetLgopSub();
            break;

		case 11:
            dev->SetLgopMul();
            break;
    }
}

void RandomFillStyle(TGraphicDevice *dev)
{
	if (random(2) == 0)
		dev->SetHollowStyle();
	else
		dev->SetFilledStyle();
}

void RandomLine(TGraphicDevice *dev)
{
	int x1, y1;
	int x2, y2;

	x1 = random(dev->GetWidth() + 200) - 100;
	y1 = random(dev->GetHeight() + 200) - 100;
	x2 = random(dev->GetWidth() + 200) - 100;
	y2 = random(dev->GetHeight() + 200) - 100;

    RandomColor(dev);
    RandomLgop(dev);

	dev->DrawLine(x1, y1, x2, y2);
}

void RandomRect(TGraphicDevice *dev)
{
	int x1, y1;
	int x2, y2;

	x1 = random(dev->GetWidth() + 200) - 100;
	y1 = random(dev->GetHeight() + 200) - 100;
	x2 = random(dev->GetWidth() + 200) - 100;
	y2 = random(dev->GetHeight() + 200) - 100;

	RandomColor(dev);
	RandomLgop(dev);
	RandomFillStyle(dev);

	dev->DrawRect(x1, y1, x2, y2);
}

void RandomEllipse(TGraphicDevice *dev)
{
	int x, y;
	int rx, ry;

	x = random(dev->GetWidth() + 200) - 100;
	y = random(dev->GetHeight() + 200) - 100;
	rx = random(dev->GetWidth() / 2 + 100);
	ry = random(dev->GetHeight() / 2 + 100);

	RandomColor(dev);
	RandomLgop(dev);
	RandomFillStyle(dev);

	dev->DrawEllipse(x, y, rx, ry);
}

void RandomText(TGraphicDevice *dev)
{
	int x, y;
	char str[80];

	x = random(dev->GetWidth() + 200) - 100;
	y = random(dev->GetHeight() + 200) - 100;

	sprintf(str, "%d", count);

	RandomColor(dev);
	RandomLgop(dev);

	dev->DrawString(x, y, str);
}

void Pattern1(TGraphicDevice *dev)
{
	int i;

	dev->SetLgopAdd();
	dev->SetDrawColor(0, 0, 128);

	for (i = 0; i < 800; i++)
		dev->DrawLine(0, 3 * i, 3 * i, 0);
}

void Pattern2(TGraphicDevice *dev)
{
	int i;

	dev->SetLgopAdd();
	dev->SetDrawColor(0, 128, 0);

	for (i = -250; i < 250; i++)
		dev->DrawLine(dev->GetHeight(), dev->GetWidth() - 3 * i, 3 * i, 0);
}

void Pattern3(TGraphicDevice *dev)
{
	int i;

	dev->SetLgopAdd();
	dev->SetDrawColor(128, 0, 0);

	for (i = -250; i < 250; i++)
		dev->DrawLine(0, 3 * i, dev->GetHeight() - 3 * i, dev->GetWidth());
}

void Pattern4(TGraphicDevice *dev)
{
	TBitmapGraphicDevice mono(1, 400, 100);
	TFont font(24);

	mono.SetLgopNone();
	mono.SetFilledStyle();
	mono.DrawEllipse(50, 50, 50, 50);
	mono.SetLgopInv();
	mono.DrawRect(40, 40, 60, 60);
	mono.SetHollowStyle();
	mono.SetLgopXor();
	mono.DrawEllipse(50, 50, 20, 20);
	mono.DrawRect(20, 20, 80, 80);
	mono.DrawLine(0, 0, 100, 100);
	mono.DrawLine(0, 100, 100, 0);
	mono.SetFont(&font);
	mono.DrawString(100, 75, "1-bit mono");

	dev->SetLgopNone();
	dev->Blit(&mono, 0, 0, 300, 300, 400, 100);
}

void TestAll(TGraphicDevice *dev)
{
	dev->SetLgopNone();
	dev->SetDrawColor(0, 0, 255);
	dev->SetFilledStyle();
	dev->DrawRect(50, 100, 250, 350);

	dev->SetDrawColor(0, 255, 0);
	dev->SetLgopAdd();
	dev->DrawRect(100, 150, 350, 350);

	dev->SetHollowStyle();
	dev->SetDrawColor(255, 0, 0);
	dev->DrawRect(50, 100, 250, 350);

	dev->DrawLine(350, 100, 50, 300);
	dev->DrawLine(350, 300, 50, 100);
	dev->DrawLine(350, 300, 350, 100);
	dev->DrawLine(50, 100, 50, 300);
	dev->DrawLine(350, 100, 50, 100);
	dev->DrawLine(350, 300, 50, 300);

	dev->SetFilledStyle();
	dev->DrawRect(200, 300, 350, 450);

	dev->SetDrawColor(100, 100, 0);
	dev->DrawEllipse(275, 425, 75, 125);

	dev->SetHollowStyle();
	dev->SetLgopNone();
	dev->SetDrawColor(0, 100, 100);
	dev->DrawEllipse(275, 425, 75, 125);

	dev->SetFilledStyle();
	dev->DrawEllipse(425, 175, 125, 125);
}

void cdecl main()
{
	int i;
	TGraphicDevice *vbe;
	TGraphicDevice *bitmap;
	TFont *font;
	TPlanetThread *Planets;

	RdosWaitMilli(250);

	vbe = new TVideoGraphicDevice(32, 800, 600);

	RdosSetCursorPosition(0, 0);
    RdosWriteString("Test av text mode");

	vbe->SetDrawColor(255,255,255);
	vbe->DrawLine(0, 0, 240, 128);
	vbe->DrawLine(240, 0, 0, 128);

//	vbe->SetClipRect(100, 100, vbe->GetWidth() - 100, vbe-GetHeight() - 100);

	RdosWaitMilli(5000);

	vbe->SetDrawColor(255, 127, 80);
	vbe->SetFilledStyle();
	vbe->SetLgopXor();
	vbe->DrawRect(0, 0, vbe->GetWidth(), vbe->GetHeight());

	RdosWaitMilli(5000);

	vbe->DrawEllipse(vbe->GetWidth() / 2, vbe->GetHeight() / 2, vbe->GetWidth() / 2, vbe->GetHeight() / 2);

	RdosWaitMilli(5000);

	font = new TFont(24);
	vbe->SetFont(font);
	vbe->DrawString(0, vbe->GetHeight() / 2, "RDOS operating system");

	RdosWaitMilli(5000);

	vbe->SetHollowStyle();
	vbe->DrawEllipse(vbe->GetWidth() / 2, vbe->GetHeight() / 2, vbe->GetWidth() / 4, vbe->GetHeight() / 4);

	RdosWaitMilli(5000);

	Planets = new TPlanetThread(vbe, 8);

	bitmap = new TBitmapGraphicDevice(vbe);
	TestAll(bitmap);

	vbe->SetLgopNone();
	vbe->Blit(bitmap, 0, 0, 0, 0, vbe->GetWidth(), vbe->GetHeight());

	delete bitmap;

	vbe->SetLgopAdd();
	vbe->Blit(vbe, 100, 50, 300, 450, vbe->GetWidth(), vbe->GetHeight());

	font = new TFont(50);
	vbe->SetFont(font);

	vbe->SetLgopNone();
	vbe->SetDrawColor(0, 255, 255);
	vbe->DrawString(40, 111, "RDOS operating system");

	delete font;

	RdosWaitMilli(5000);

	Pattern1(vbe);
	RdosWaitMilli(5000);

	Pattern2(vbe);
	RdosWaitMilli(5000);

	Pattern3(vbe);
	RdosWaitMilli(5000);

	Pattern4(vbe);
	RdosWaitMilli(5000);

	font = new TFont(60);
	vbe->SetFont(font);

	for (;;)
	{
		count++;
		switch (random(4))
		{
			case 0:
				RandomLine(vbe);
				break;

			case 1:
				RandomRect(vbe);
				break;

			case 2:
				RandomEllipse(vbe);
				break;

			case 3:
				RandomText(vbe);
				break;
		}
	}
}

