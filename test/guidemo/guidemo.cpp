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
#include "jpeg.h"
#include "control.h"
#include "str.h"

#define MAX_ROW 10
#define MAX_COL 10

#define FALSE	0
#define TRUE	!FALSE

int count = 0;
TSprite *NormalSprite;
TSprite *LeftSprite;
TSprite *RightSprite;
TSprite *MouseSprite;
TGraphicDevice *KeyVideo;

class TKeyControl : public TControl
{
public:
    TKeyControl(const char *UpName, const char *DownName, const char *Text, char ch, TControlThread *dev, int row, int col);
    TKeyControl(const char *UpName, const char *DownName, const char *Text, char ch, TControl *control, int row, int col);
    ~TKeyControl();

protected:
	virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);
	virtual int OnLeftUp(int x, int y, int ButtonState, int KeyState);
	virtual int OnLeftDown(int x, int y, int ButtonState, int KeyState);
	virtual int OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
	virtual int OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode);

private:
    void Init(const char *UpName, const char *DownName, const char *Text, char ch, int row, int col);

	char FKey;
    TBitmapGraphicDevice *FUp;
    TBitmapGraphicDevice *FDown;	
    int FPressed;
};        

class TKeyboardControl : public TControl
{
public:
    TKeyboardControl(const char *UpName, const char *DownName, TControlThread *dev);
    ~TKeyboardControl();

    void AddKey(int row, int col, const char *text, char ch);

protected:
    TKeyControl *FKeyMatr[MAX_ROW][MAX_COL];
    TString FUpName;
    TString FDownName;
};        

/*##########################################################################
#
#   Name       : TKeyControl::TKeyControl
#
#   Purpose....: Key control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TKeyControl::TKeyControl(const char *UpName, const char *DownName, const char *Text, char ch, TControlThread *dev, int row, int col)
 : TControl(dev)
{
    Init(UpName, DownName, Text, ch, row, col);
}

/*##########################################################################
#
#   Name       : TKeyControl::TKeyControl
#
#   Purpose....: Key control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TKeyControl::TKeyControl(const char *UpName, const char *DownName, const char *Text, char ch, TControl *control, int row, int col)
 : TControl(control)
{
    Init(UpName, DownName, Text, ch, row, col);
}

/*##########################################################################
#
#   Name       : TKeyControl::Init
#
#   Purpose....: Init key control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TKeyControl::Init(const char *UpName, const char *DownName, const char *Text, char ch, int row, int col)
{
	TFont Font(30);
	int xsize;
	int ysize;
	int xstart;
	int ystart;
	int key_xsize;
	int key_ysize;

    FPressed = FALSE;
    FKey = ch;
	Font.GetStringMetrics(Text, &xsize, &ysize);

	FUp = TJpegBitmapDevice::Create(UpName);
	FUp->SetFont(&Font);

	key_xsize = FUp->GetWidth();
	key_ysize = FUp->GetHeight();

	xstart = (key_xsize - xsize) / 2;
	ystart = (key_ysize - ysize) / 2;

	FUp->SetDrawColor(150, 150, 150);
	FUp->SetLgopNone();
	FUp->DrawString(xstart, ystart, Text);
	FUp->DrawString(xstart + 1, ystart, Text);
	FUp->DrawString(xstart - 1, ystart, Text);
	FUp->DrawString(xstart, ystart + 1, Text);
	FUp->DrawString(xstart, ystart - 1, Text);
	FUp->DrawString(xstart + 1, ystart + 1, Text);
	FUp->DrawString(xstart - 1, ystart - 1, Text);
	FUp->DrawString(xstart - 1, ystart + 1, Text);
	FUp->DrawString(xstart + 1, ystart - 1, Text);

	FUp->SetDrawColor(0, 0, 0);
	FUp->DrawString(xstart, ystart, Text);

	FDown = TJpegBitmapDevice::Create(DownName);
	FDown->SetFont(&Font);

	key_xsize = FDown->GetWidth();
	key_ysize = FDown->GetHeight();

	xstart = (key_xsize - xsize) / 2;
	ystart = (key_ysize - ysize) / 2;

	xstart += 4;
	ystart += 4;

	FDown->SetDrawColor(150, 150, 150);
	FDown->SetLgopNone();
	FDown->DrawString(xstart, ystart, Text);
	FDown->DrawString(xstart + 1, ystart, Text);
	FDown->DrawString(xstart - 1, ystart, Text);
	FDown->DrawString(xstart, ystart + 1, Text);
	FDown->DrawString(xstart, ystart - 1, Text);
	FDown->DrawString(xstart + 1, ystart + 1, Text);
	FDown->DrawString(xstart - 1, ystart - 1, Text);
	FDown->DrawString(xstart - 1, ystart + 1, Text);
	FDown->DrawString(xstart + 1, ystart - 1, Text);

	FDown->SetDrawColor(0, 0, 0);
	FDown->DrawString(xstart, ystart, Text);

    xsize = FUp->GetWidth();
    ysize = FUp->GetHeight();
    
	xstart = col * xsize;
	ystart = row * ysize;

	Resize(xsize, ysize);
	Move(xstart, ystart);
	Enable();
	Show();
}

/*##########################################################################
#
#   Name       : TKeyControl::~TKeyControl
#
#   Purpose....: Key control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TKeyControl::~TKeyControl()
{
    delete FUp;
    delete FDown;
}

/*##########################################################################
#
#   Name       : TKeyControl::OnLeftUp
#
#   Purpose....: Handle left button up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TKeyControl::OnLeftUp(int x, int y, int ButtonState, int KeyState)
{
    if (FPressed)
    {
        FPressed = FALSE;
        Redraw();
    }
    
    return FALSE;
}

/*##########################################################################
#
#   Name       : TKeyControl::OnLeftDown
#
#   Purpose....: Handle left button down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TKeyControl::OnLeftDown(int x, int y, int ButtonState, int KeyState)
{
    if (IsInside(x, y))
    {
        PutKey(FKey);
        FPressed = TRUE;
        Redraw();
        return TRUE;
    }
    else
    {
        if (FPressed)
        {
            FPressed = FALSE;
            Redraw();
        }
        return FALSE;
    }
}

/*##########################################################################
#
#   Name       : TKeyControl::OnKeyPressed
#
#   Purpose....: Handle key pressed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TKeyControl::OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    if (VirtualKey == FKey)
    {
        if (!FPressed)
        {
            FPressed = TRUE;
            Redraw();
        }
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TKeyControl::OnKeyReleased
#
#   Purpose....: Handle key released
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TKeyControl::OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    if (VirtualKey == FKey)
    {
        if (FPressed)
        {
            FPressed = FALSE;
            Redraw();
        }
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TKeyControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TKeyControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
	dev->SetLgopNone();

    if (FPressed)
    	dev->Blit(FDown, 0, 0, xmin, ymin, width, height);
    else
    	dev->Blit(FUp, 0, 0, xmin, ymin, width, height);
}

/*##########################################################################
#
#   Name       : TKeyboardControl::TKeyboardControl
#
#   Purpose....: Keyboard control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TKeyboardControl::TKeyboardControl(const char *UpName, const char *DownName, TControlThread *dev)
 : FUpName(UpName),
	FDownName(DownName),
   TControl(dev)
{
}

/*##########################################################################
#
#   Name       : TKeyboardControl::~TKeyboardControl
#
#   Purpose....: Keyboard control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TKeyboardControl::~TKeyboardControl()
{
}

/*##########################################################################
#
#   Name       : TKeyboardControl::AddKey
#
#   Purpose....: Add a keyboard control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TKeyboardControl::AddKey(int row, int col, const char *text, char ch)
{
    TKeyControl *control;
    control = new TKeyControl(FUpName.GetData(), FDownName.GetData(), text, ch, this, row, col);
}



void RandomColor(TGraphicDevice *dev)
{
	int col;

	if (dev->GetBpp() == 1)
	{
		col = 255 * RdosGetRandom(2);
		dev->SetDrawColor(col, col, col);
	}
	else
		dev->SetDrawColor(RdosGetRandom(256), RdosGetRandom(256), RdosGetRandom(256));
}

void RandomLgop(TGraphicDevice *dev)
{
	switch (RdosGetRandom(12))
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
	if (RdosGetRandom(2) == 0)
		dev->SetHollowStyle();
	else
		dev->SetFilledStyle();
}

void RandomLine(TGraphicDevice *dev)
{
	int x1, y1;
	int x2, y2;

	x1 = RdosGetRandom(dev->GetWidth() + dev->GetWidth() / 4) - dev->GetWidth() / 8;
	y1 = RdosGetRandom(dev->GetHeight() + dev->GetHeight() / 4) - dev->GetHeight() / 8;
	x2 = RdosGetRandom(dev->GetWidth() + dev->GetWidth() / 4) - dev->GetWidth() / 8;
	y2 = RdosGetRandom(dev->GetHeight() + dev->GetHeight() / 4) - dev->GetHeight() / 8;

	RandomColor(dev);
	RandomLgop(dev);

	dev->DrawLine(x1, y1, x2, y2);
}

void RandomRect(TGraphicDevice *dev)
{
	int x1, y1;
	int x2, y2;

	x1 = RdosGetRandom(dev->GetWidth() + dev->GetWidth() / 4) - dev->GetWidth() / 8;
	y1 = RdosGetRandom(dev->GetHeight() + dev->GetHeight() / 4) - dev->GetHeight() / 8;
	x2 = RdosGetRandom(dev->GetWidth() + dev->GetWidth() / 4) - dev->GetWidth() / 8;
	y2 = RdosGetRandom(dev->GetHeight() + dev->GetHeight() / 4) - dev->GetHeight() / 8;

	RandomColor(dev);
	RandomLgop(dev);
	RandomFillStyle(dev);

	dev->DrawRect(x1, y1, x2, y2);
}

void RandomEllipse(TGraphicDevice *dev)
{
	int x, y;
	int rx, ry;

	x = RdosGetRandom(dev->GetWidth() + dev->GetWidth() / 4) - dev->GetWidth() / 8;
	y = RdosGetRandom(dev->GetHeight() + dev->GetHeight() / 4) - dev->GetHeight() / 8;
	rx = RdosGetRandom(dev->GetWidth() / 2 + dev->GetWidth() / 8);
	ry = RdosGetRandom(dev->GetHeight() / 2 + dev->GetHeight() / 8);

	RandomColor(dev);
	RandomLgop(dev);
	RandomFillStyle(dev);

	dev->DrawEllipse(x, y, rx, ry);
}

void RandomText(TGraphicDevice *dev)
{
	int x, y;
	char str[80];

	x = RdosGetRandom(dev->GetWidth() + dev->GetWidth() / 4) - dev->GetWidth() / 8;
	y = RdosGetRandom(dev->GetHeight() + dev->GetHeight() / 4) - dev->GetHeight() / 8;

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

void KeyPress(TControlThread *Dev, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
	char str[120];

	sprintf(str, "ExtKey = %04hX, KeyState = %04hX, VK = %02hX, Scan = %02hX, Pressed", ExtKey, KeyState, VirtualKey, ScanCode);
	KeyVideo->SetFilledStyle();
	KeyVideo->SetDrawColor(0, 0, 0);
	KeyVideo->DrawRect(0, KeyVideo->GetHeight() - 35, KeyVideo->GetWidth(), KeyVideo->GetHeight());
	KeyVideo->SetDrawColor(255, 255, 255);
	KeyVideo->DrawString(0, KeyVideo->GetHeight() - 35, str);
}

void KeyRelease(TControlThread *Dev, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
	char str[120];

	sprintf(str, "ExtKey = %04hX, KeyState = %04hX, VK = %02hX, Scan = %02hX, Released", ExtKey, KeyState, VirtualKey, ScanCode);
	KeyVideo->SetFilledStyle();
	KeyVideo->SetDrawColor(0, 0, 0);
	KeyVideo->DrawRect(0, KeyVideo->GetHeight() - 35, KeyVideo->GetWidth(), KeyVideo->GetHeight());
	KeyVideo->SetDrawColor(255, 255, 255);
	KeyVideo->DrawString(0, KeyVideo->GetHeight() - 35, str);
}

void MouseMove(TControlThread *Dev, int x, int y, int MouseButton, int KeyState)
{
	MouseSprite->Move(x, y);
}

void LeftUp(TControlThread *Dev, int x, int y, int MouseButton, int KeyState)
{
	MouseSprite->Hide();
	if (MouseButton & MOUSE_RIGHT_BUTTON)
		MouseSprite = RightSprite;
	else
		MouseSprite = NormalSprite;
	MouseSprite->Move(x, y);
	MouseSprite->Show();
}

void LeftDown(TControlThread *Dev, int x, int y, int MouseButton, int KeyState)
{
	MouseSprite->Hide();
	MouseSprite = LeftSprite;
	MouseSprite->Move(x, y);
	MouseSprite->Show();
}

void RightUp(TControlThread *Dev, int x, int y, int MouseButton, int KeyState)
{
	MouseSprite->Hide();
	if (MouseButton & MOUSE_LEFT_BUTTON)
		MouseSprite = RightSprite;
	else
		MouseSprite = NormalSprite;
	MouseSprite->Move(x, y);
	MouseSprite->Show();
}

void RightDown(TControlThread *Dev, int x, int y, int MouseButton, int KeyState)
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
	TControlThread *ControlDev;
	TKeyboardControl *KeyboardControl;

	RdosWaitMilli(250);

	Keyboard = new TKeyboardDevice;
	Mouse = new TMouseDevice;

	vbe = new TVideoGraphicDevice(24, 800, 480);
//	vbe = new TVideoGraphicDevice(1, 240, 128);

    ControlDev = new TControlThread("Control", vbe, Keyboard, Mouse);    
	
	ControlDev->OnKeyPressed = KeyPress;
	ControlDev->OnKeyReleased = KeyRelease;
//	ControlDev->OnMouseMove = MouseMove;
//	ControlDev->OnLeftUp = LeftUp;
//	ControlDev->OnLeftDown = LeftDown;
//	ControlDev->OnRightUp = RightUp;
//	ControlDev->OnRightDown = RightDown;

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
//	MouseSprite->Show();

	KeyVideo = new TGraphicDevice(*vbe);
	font = new TFont(35);
	KeyVideo->SetFont(font);

    KeyboardControl = new TKeyboardControl("kupp.jpg", "kner.jpg", ControlDev);

    KeyboardControl->AddKey(0, 0, "1", '1');
    KeyboardControl->AddKey(0, 1, "2", '2');
    KeyboardControl->AddKey(0, 2, "3", '3');
    
    KeyboardControl->AddKey(1, 0, "4", '4');
    KeyboardControl->AddKey(1, 1, "5", '5');
    KeyboardControl->AddKey(1, 2, "6", '6');
    
    KeyboardControl->AddKey(2, 0, "7", '7');
    KeyboardControl->AddKey(2, 1, "8", '8');
    KeyboardControl->AddKey(2, 2, "9", '9');
    
    KeyboardControl->AddKey(3, 0, "FEL", 0x8);
    KeyboardControl->AddKey(3, 1, "0", '0');
    KeyboardControl->AddKey(3, 2, "KLAR", 0xd);

    KeyboardControl->Move(50, 50);

    KeyboardControl->Enable();
    KeyboardControl->Show();
    KeyboardControl->Redraw();

    for (;;)
		  RdosWaitMilli(1000);


	vbe->SetDrawColor(255,255,255);
	vbe->DrawLine(0, 0, vbe->GetWidth(), vbe->GetHeight());
	vbe->DrawLine(240, 0, 0, 128);

	vbe->SetClipRect(0, 0, vbe->GetWidth(), vbe->GetHeight() - 35);

//	Planets = new TPlanetThread(vbe, 8);

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
		switch (RdosGetRandom(4))
		{
			case 0:
//				RandomLine(vbe);
				break;

			case 1:
//				RandomRect(vbe);
				break;

			case 2:
//				RandomEllipse(vbe);
				break;

			case 3:
//				RandomText(vbe);
				break;
		}
		RdosWaitMilli(1000);
	}
}

