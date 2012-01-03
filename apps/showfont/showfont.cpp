#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rdos.h"
#include "videodev.h"
#include "font.h"

#define FALSE   0
#define TRUE    !FALSE

int main(int argc, char **argv)
{
    TGraphicDevice *vbe;
    int width, height;
    TFont font(20);
    char str[10];
    int x, y;
    int pos;

    width = 640;
    height = 480;

    vbe = new TVideoGraphicDevice(24, width, height);

    vbe->SetDrawColor(255, 255, 255);
    vbe->SetFilledStyle();
    vbe->DrawRect(0, 0, width, height);

    vbe->SetFont(&font);

    for (x = 0; x < 0x10; x++)
    {
        sprintf(str, "%04hX", x);
        str[0] = str[3];
        str[1] = 0;
        vbe->SetDrawColor(0, 0, 0);
        vbe->DrawString(100 + 20 * x, 70, str);                        
        vbe->SetDrawColor(100, 100, 100);
        vbe->DrawLine(100 + 20 * x, 70, 100 + 20 * x, 420);
    }

    for (y = 0; y < 0x10; y++)
    {
        sprintf(str, "%04hX", y);
        str[0] = str[3];
        str[1] = 0;
        vbe->SetDrawColor(0, 0, 0);
        vbe->DrawString(70, 100 + 20 * y, str);                        
        vbe->SetDrawColor(100, 100, 100);
        vbe->DrawLine(70, 100 + 20 * y, 420, 100 + 20 * y);
    }

    vbe->SetDrawColor(0, 0, 0);
    for (y = 0; y < 0x10; y++)
    {
        for (x = 0; x < 0x10; x++)
        {
            pos = 0x10 * y + x;
            str[0] = (char)pos;
            str[1] = 0;
            vbe->DrawString(100 + 20 * x, 100 + 20 * y, str);                        
        }
    }     

    RdosReadKeyboard();
    delete vbe;
    RdosSetTextMode();
    return 0;
}
