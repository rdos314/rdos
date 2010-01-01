#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "fileview.h"
#include "videodev.h"
#include "waitdev.h"
#include "keyboard.h"
#include "mouse.h"
#include "scroll.h"

#include "bmp.h"

#define FALSE	0
#define TRUE	!FALSE

int main(int argc, char **argv)
{
	int width = 640;
	int height = 480;
	TGraphicDevice *vbe;
	TControlThread *controlthread;
	TFileViewControl *fileview;
	char FileName[256];
	TKeyboardDevice *Keyboard;
	TMouseDevice *Mouse;
	TGraphicDevice *MouseMask;
	TGraphicDevice *MouseBitmap;

	if (argc == 1)
	{
		printf("usage: showfile filename\r\n");
		return 1;
	 }

	strcpy(FileName, argv[1]);
	strlwr(FileName);

	vbe = new TVideoGraphicDevice(24, width, height);

	Keyboard = new TKeyboardDevice;
	Mouse = new TMouseDevice;

	controlthread = new TControlThread("Control", vbe);
	controlthread->Add(Keyboard);
	controlthread->Add(Mouse);

	MouseMask = new TBitmapGraphicDevice(1, 21, 21);
	MouseMask->SetLgopNone();
	MouseMask->DrawLine(0, 9, 20, 9);
	MouseMask->DrawLine(0, 10, 20, 10);
	MouseMask->DrawLine(0, 11, 20, 11);

	MouseMask->DrawLine(9, 0, 9, 20);
	MouseMask->DrawLine(10, 0, 10, 20);
	MouseMask->DrawLine(11, 0, 11, 20);

	MouseBitmap = new TBitmapGraphicDevice(vbe->GetBpp(), 21, 21);
	MouseBitmap->SetLgopNone();
	MouseBitmap->SetDrawColor(128, 128, 128);
	MouseBitmap->DrawLine(0, 9, 20, 9);
	MouseBitmap->DrawLine(0, 11, 20, 11);

	MouseBitmap->DrawLine(9, 0, 9, 20);
	MouseBitmap->DrawLine(11, 0, 11, 20);

	MouseBitmap->SetDrawColor(255, 0, 0);
	MouseBitmap->DrawLine(0, 10, 20, 10);
	MouseBitmap->DrawLine(10, 0, 10, 20);

	controlthread->SetMouseMarker(MouseBitmap, MouseMask, 10, 10);

	fileview = new TFileViewControl(controlthread, 0, 0, width - 50, height - 50);
	fileview->DefineScroll(25);
	fileview->EnableVerScroll();
	fileview->EnableHorScroll();
	fileview->SetFont(12);
	fileview->Load(FileName);
	fileview->Enable();
	fileview->Show();
	fileview->Redraw();

	for (;;)
		RdosWaitMilli(2000);

	delete fileview;
	delete controlthread;
	delete vbe;

}

