#include <stdio.h>
#include <stdlib.h>

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
    char test_str[] = "ÖstersjÖn";

    bpp = 24;
    width = 640;
    height = 640;
  
    vbe = RdosSetVideoMode(&bpp, &width, &height, &rowsize, &linear);

    handle = RdosOpenFont(0, 48);
    RdosSetFont(vbe, handle);
    RdosGetStringMetrics(handle, test_str, &width, &height);
    RdosDrawString(vbe, 0, 0, test_str);
    RdosCloseFont(handle);

    RdosTestGate(vbe);
    
}

