#include <stdio.h>
#include <stdlib.h>

#include <math.h>

#include <rdos.h>

void *sec_handle;

void TestThread(void *param)
{
    RdosNewEnterSection(sec_handle);

    for (;;)
        RdosWaitMilli(500);
}
    

void main()
{
    int bpp;
    int width;
    int height;
    int vbe;
    int rowsize;
    void *linear;
    int handle;
    char test_str[100];
    long double x, y;
    int ok;
    int size;        

//    CreateSection();

    sec_handle = RdosNewCreateSection();
    sec_handle = RdosNewCreateSection();
    RdosNewEnterSection(sec_handle);

    RdosCreateThread(TestThread, "Sect Test", 0, 0x8000);
    
    RdosNewLeaveSection(sec_handle);
    RdosNewDeleteSection(sec_handle);
    

    for (;;)
        ;    

    x = 1.0;
    y = 3.1456;
    x = sin(x) * y;

    RdosTestGate();

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

