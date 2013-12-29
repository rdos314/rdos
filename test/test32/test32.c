#include <rdos.h>
#include <stdio.h>
#include <stdlib.h>

#include <math.h>

void main()
{
    int i;
    char *str[50];
    int *param;
    int bpp, width, height, rowsize, linear;

    RdosTestGate();

    bpp = 24;
    width = 1366;
    height = 768;
    
    RdosSetVideoMode(&bpp, &width, &height, &rowsize, &linear);

    RdosTestGate();

    RdosSetTextMode();


    for (;;)
        RdosWaitMilli(1000); 

}

