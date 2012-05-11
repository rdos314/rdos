#include <stdio.h>
#include <stdlib.h>

#include <math.h>

#include <rdos.h>

void main()
{
    int bpp;
    int width;
    int height;
    int vbe;
    int rowsize;
    void *linear;
    int handle;
    char test_str[] = "ÅÄÖ Sæt Główne ᎰᎲᎣ";
    long double x, y;

    x = 1.0;
    y = 3.1456;
    x = sin(x) * y;

    handle = RdosOpenSysIni();
    RdosCloseIni(handle);

    bpp = 24;
    width = 640;
    height = 640;
  
    vbe = RdosSetVideoMode(&bpp, &width, &height, &rowsize, &linear);

    handle = RdosOpenFont(0, 48);
    RdosSetFont(vbe, handle);
    RdosSetFilledStyle(vbe);
    RdosGetStringMetrics(handle, test_str, &width, &height);
    RdosSetDrawColor(vbe, 0x0000FF);
    RdosDrawRect(vbe, 0, 0, 400, 200);
    RdosSetDrawColor(vbe, 0xFFFF00);
    RdosDrawString(vbe, 0, 0, test_str);
    RdosCloseFont(handle);
    
}

