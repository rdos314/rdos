#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "bitdev.h"
#include "videodev.h"
#include "planthr.h"
#include "waitdev.h"
#include "keyboard.h"
#include "mouse.h"

#define FALSE	0
#define TRUE	!FALSE

int count = 0;
TSprite *NormalSprite;
TSprite *LeftSprite;
TSprite *RightSprite;
TSprite *MouseSprite;
TGraphicDevice *KeyVideo;

void RandomColor(TGraphicDevice *dev)
{
	int col;

	if (dev->GetBpp() == 1)
	{
		col = 255 * random(2);
		dev->SetDrawColor(col, col, col);
	}
	else
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

	x1 = random(dev->GetWidth() + dev->GetWidth() / 4) - dev->GetWidth() / 8;
	y1 = random(dev->GetHeight() + dev->GetHeight() / 4) - dev->GetHeight() / 8;
	x2 = random(dev->GetWidth() + dev->GetWidth() / 4) - dev->GetWidth() / 8;
	y2 = random(dev->GetHeight() + dev->GetHeight() / 4) - dev->GetHeight() / 8;

	RandomColor(dev);
	RandomLgop(dev);

	dev->DrawLine(x1, y1, x2, y2);
}

void RandomRect(TGraphicDevice *dev)
{
	int x1, y1;
	int x2, y2;

	x1 = random(dev->GetWidth() + dev->GetWidth() / 4) - dev->GetWidth() / 8;
	y1 = random(dev->GetHeight() + dev->GetHeight() / 4) - dev->GetHeight() / 8;
	x2 = random(dev->GetWidth() + dev->GetWidth() / 4) - dev->GetWidth() / 8;
	y2 = random(dev->GetHeight() + dev->GetHeight() / 4) - dev->GetHeight() / 8;

	RandomColor(dev);
	RandomLgop(dev);
	RandomFillStyle(dev);

	dev->DrawRect(x1, y1, x2, y2);
}

void RandomEllipse(TGraphicDevice *dev)
{
	int x, y;
	int rx, ry;

	x = random(dev->GetWidth() + dev->GetWidth() / 4) - dev->GetWidth() / 8;
	y = random(dev->GetHeight() + dev->GetHeight() / 4) - dev->GetHeight() / 8;
	rx = random(dev->GetWidth() / 2 + dev->GetWidth() / 8);
	ry = random(dev->GetHeight() / 2 + dev->GetHeight() / 8);

	RandomColor(dev);
	RandomLgop(dev);
	RandomFillStyle(dev);

	dev->DrawEllipse(x, y, rx, ry);
}

void RandomText(TGraphicDevice *dev)
{
	int x, y;
	char str[80];

	x = random(dev->GetWidth() + dev->GetWidth() / 4) - dev->GetWidth() / 8;
	y = random(dev->GetHeight() + dev->GetHeight() / 4) - dev->GetHeight() / 8;

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

	for (i = 0; i < dev->GetWidth(); i++)
		dev->DrawLine(0, 3 * i, 3 * i, 0);
}

void Pattern2(TGraphicDevice *dev)
{
	int i;

	dev->SetLgopAdd();
	dev->SetDrawColor(0, 128, 0);

	for (i = -dev->GetWidth() / 3; i < dev->GetWidth() / 3; i++)
		dev->DrawLine(dev->GetHeight(), dev->GetWidth() - 3 * i, 3 * i, 0);
}

void Pattern3(TGraphicDevice *dev)
{
	int i;

	dev->SetLgopAdd();
	dev->SetDrawColor(128, 0, 0);

	for (i = -dev->GetWidth(); i < dev->GetWidth(); i++)
		dev->DrawLine(0, 3 * i, dev->GetHeight() - 3 * i, dev->GetWidth());
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

TBitmapGraphicDevice *CreateMouseMask()
{
	TBitmapGraphicDevice *mono;

	mono = new TBitmapGraphicDevice(1, 40, 40);
	mono->SetLgopNone();
	mono->SetFilledStyle();
	mono->DrawEllipse(20, 20, 20, 20);
	mono->SetLgopInv();
	mono->DrawRect(15, 15, 25, 25);
	mono->SetHollowStyle();
	mono->SetLgopXor();
	mono->DrawEllipse(20, 20, 15, 15);
	mono->DrawRect(10, 10, 30, 30);
	mono->SetLgopNone();
	mono->DrawLine(0, 0, 40, 40);
	mono->DrawLine(0, 40, 40, 0);
	mono->DrawLine(0, 0, 39, 39);
	mono->DrawLine(0, 39, 39, 0);
	mono->DrawLine(1, 1, 41, 41);
	mono->DrawLine(1, 41, 41, 1);
	mono->DrawLine(1, 1, 40, 40);
	mono->DrawLine(1, 40, 40, 1);

	return mono;
}

TBitmapGraphicDevice *CreateMouseBitmap(TGraphicDevice *dev, int r, int g, int b)
{
	TBitmapGraphicDevice *bitmap;

	bitmap = new TBitmapGraphicDevice(dev->GetBpp(), 40, 40);
	bitmap->SetLgopNone();
	bitmap->SetFilledStyle();
	bitmap->SetDrawColor(r, g, b);
	bitmap->DrawRect(0, 0, 40, 40);

	return bitmap;
}

void KeyPress(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
	char str[120];

	sprintf(str, "ExtKey = %04hX, KeyState = %04hX, VK = %02hX, Scan = %02hX, Pressed", ExtKey, KeyState, VirtualKey, ScanCode);
	KeyVideo->SetFilledStyle();
	KeyVideo->SetDrawColor(0, 0, 0);
	KeyVideo->DrawRect(0, KeyVideo->GetHeight() - 35, KeyVideo->GetWidth(), KeyVideo->GetHeight());
	KeyVideo->SetDrawColor(255, 255, 255);
	KeyVideo->DrawString(0, KeyVideo->GetHeight() - 35, str);
}

void KeyRelease(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
	char str[120];

	sprintf(str, "ExtKey = %04hX, KeyState = %04hX, VK = %02hX, Scan = %02hX, Released", ExtKey, KeyState, VirtualKey, ScanCode);
	KeyVideo->SetFilledStyle();
	KeyVideo->SetDrawColor(0, 0, 0);
	KeyVideo->DrawRect(0, KeyVideo->GetHeight() - 35, KeyVideo->GetWidth(), KeyVideo->GetHeight());
	KeyVideo->SetDrawColor(255, 255, 255);
	KeyVideo->DrawString(0, KeyVideo->GetHeight() - 35, str);
}

void MouseMove(TMouseDevice *Mouse, int x, int y, int MouseButton, int KeyState)
{
	MouseSprite->Move(x, y);
}

void LeftUp(TMouseDevice *Mouse, int x, int y, int MouseButton, int KeyState)
{
	MouseSprite->Hide();
	if (MouseButton & MOUSE_RIGHT_BUTTON)
		MouseSprite = RightSprite;
	else
		MouseSprite = NormalSprite;
	MouseSprite->Move(x, y);
	MouseSprite->Show();
}

void LeftDown(TMouseDevice *Mouse, int x, int y, int MouseButton, int KeyState)
{
	MouseSprite->Hide();
	MouseSprite = LeftSprite;
	MouseSprite->Move(x, y);
	MouseSprite->Show();
}

void RightUp(TMouseDevice *Mouse, int x, int y, int MouseButton, int KeyState)
{
	MouseSprite->Hide();
	if (MouseButton & MOUSE_LEFT_BUTTON)
		MouseSprite = RightSprite;
	else
		MouseSprite = NormalSprite;
	MouseSprite->Move(x, y);
	MouseSprite->Show();
}

void RightDown(TMouseDevice *Mouse, int x, int y, int MouseButton, int KeyState)
{
	MouseSprite->Hide();
	MouseSprite = RightSprite;
	MouseSprite->Move(x, y);
	MouseSprite->Show();
}

void cdecl main()
{
	int i;
	TGraphicDevice *vbe;
	TGraphicDevice *bitmap;
	TFont *font;
	TGraphicDevice *MouseMask;
	TGraphicDevice *MouseBitmap;
	TPlanetThread *Planets;
	TKeyboardDevice *Keyboard;
	TMouseDevice *Mouse;

	RdosWaitMilli(250);

	Keyboard = new TKeyboardDevice;
	Keyboard->OnKeyPress = KeyPress;
	Keyboard->OnKeyRelease = KeyRelease;

	Mouse = new TMouseDevice;
	Mouse->OnMove = MouseMove;
	Mouse->OnLeftUp = LeftUp;
	Mouse->OnLeftDown = LeftDown;
	Mouse->OnRightUp = RightUp;
	Mouse->OnRightDown = RightDown;

	vbe = new TVideoGraphicDevice(24, 800, 600);
//	vbe = new TVideoGraphicDevice(1, 240, 128);

	Mouse->SetWindow(20, 20, vbe->GetWidth() - 20, vbe->GetHeight() - 20);
	Mouse->SetMickey(1, 1);
	Mouse->SetPosition(vbe->GetWidth() / 2, vbe->GetHeight() / 2);

	MouseMask = CreateMouseMask();

	MouseBitmap = CreateMouseBitmap(vbe, 255, 255, 255);
	NormalSprite = vbe->CreateSprite(MouseBitmap, MouseMask, 20, 20);
	NormalSprite->Move(vbe->GetWidth() / 2, vbe->GetHeight() / 2);

	MouseBitmap = CreateMouseBitmap(vbe, 64, 128, 255);
	LeftSprite = vbe->CreateSprite(MouseBitmap, MouseMask, 20, 20);
	LeftSprite->Move(vbe->GetWidth() / 2, vbe->GetHeight() / 2);

	MouseBitmap = CreateMouseBitmap(vbe, 255, 0, 0);
	RightSprite = vbe->CreateSprite(MouseBitmap, MouseMask, 20, 20);
	RightSprite->Move(vbe->GetWidth() / 2, vbe->GetHeight() / 2);

	MouseSprite = NormalSprite;
	MouseSprite->Show();

	KeyVideo = new TGraphicDevice(*vbe);
	font = new TFont(35);
	KeyVideo->SetFont(font);

	TWait Wait;

	Wait.Add(Keyboard);
	Wait.Add(Mouse);
	Wait.StartThreadHandler("IO Thread", 0x1000);

	vbe->SetDrawColor(255,255,255);
	vbe->DrawLine(0, 0, vbe->GetWidth(), vbe->GetHeight());
	vbe->DrawLine(240, 0, 0, 128);

	vbe->SetClipRect(0, 0, vbe->GetWidth(), vbe->GetHeight() - 35);

	Planets = new TPlanetThread(vbe, 8);

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

