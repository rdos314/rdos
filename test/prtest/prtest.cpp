#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "bmp.h"
#include "jpeg.h"
#include "videodev.h"
#include "keyboard.h"
#include "mouse.h"
#include "printer.h"

#define FALSE   0
#define TRUE    !FALSE

void main()
{
    TPrinterDevice *prn;
    TBitmapGraphicDevice *pg;
    TGraphicDevice *vbe;
    int width;
    TFont *font;

    RdosWaitMilli(250);

    prn = new TPrinterDevice(1);

    if (prn->IsPaperEnd())
        printf("out of paper\r\n");
        
    pg = prn->CreateBitmap(1000);
    font = new TFont(70);

    if (pg)
    {
        width = pg->GetWidth();
        pg->SetDrawColor(0, 0, 0);
        pg->SetHollowStyle();
        pg->DrawRect(0, 0, width - 1, 499);
        pg->DrawRect(1, 1, width - 2, 498);
        pg->DrawRect(2, 2, width - 3, 497);
        pg->SetFont(font);
        pg->DrawString(5, 5, "Test");
        pg->DrawString(5, 105, "of");
        pg->DrawString(5, 205, "RDOS");
        pg->DrawString(5, 305, "Printer");
        pg->DrawString(5, 405, "ABCD");
        pg->DrawString(5, 505, "EFGH");
        pg->DrawString(5, 605, "IJKL");
        pg->DrawString(5, 705, "MNOP");
        pg->DrawString(5, 805, "QPRS");
        pg->DrawString(5, 905, "TUVX");

        prn->PrintBitmap(pg);
    }
}

