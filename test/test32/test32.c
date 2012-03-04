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

    bpp = 24;
    width = 640;
    height = 640;
  
    vbe = RdosSetVideoMode(&bpp, &width, &height, &rowsize, &linear);

    RdosTestGate(vbe);
    
}

