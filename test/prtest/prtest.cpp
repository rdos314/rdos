#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "bmp.h"
#include "jpeg.h"
#include "videodev.h"
#include "keyboard.h"
#include "mouse.h"
#include "printer.h"

#define FALSE	0
#define	TRUE	!FALSE

void main()
{
    TPrinterDevice *prn;
    TBitmapGraphicDevice *pg;
    TGraphicDevice *vbe;
    TFont *font;

	RdosWaitMilli(250);

	prn = new TPrinterDevice(1);
	pg = prn->CreateBitmap(50);
	font = new TFont(20);

	if (pg)
	{
		pg->SetDrawColor(0, 0, 0);
	    pg->SetFont(font);
    	pg->DrawString(5, 5, "Test");

	    vbe = new TVideoGraphicDevice(24, 640, 480);
    	vbe->Blit(pg, 0, 0, 0, 0, pg->GetWidth(), pg->GetHeight());
    }
}

