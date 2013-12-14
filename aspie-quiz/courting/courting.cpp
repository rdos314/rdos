#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "bitdev.h"
#include "videodev.h"
#include "waitdev.h"
#include "keyboard.h"
#include "mouse.h"

#define FALSE   0
#define TRUE    !FALSE

TGraphicDevice *vbe;

#define PI      3.1415926373
#define SCALE   3

/*##########################################################################
#
#   Name       : Draw
#
#   Purpose....: Draw pattern
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void Draw(int x, int y, double rot, int len, int width)
{
    int i;
    double xdiff, ydiff;
    double px, py;
        
    px = (double)len * cos(rot);
    py = (double)len * sin(rot);        

    vbe->DrawLine(x, y, x + (int)px, y + (int)py);

    for (i = 1; i < width; i++)
    {
        xdiff = (double)i * cos(rot + PI / 2);
        ydiff = (double)i * sin(rot + PI / 2);

        vbe->DrawLine(x + (int)xdiff, y + (int)ydiff, x + (int)(px + xdiff), y + (int)(py + ydiff));

        xdiff = (double)i * cos(rot - PI / 2);
        ydiff = (double)i * sin(rot - PI / 2);

        vbe->DrawLine(x + (int)xdiff, y + (int)ydiff, x + (int)(px + xdiff), y + (int)(py + ydiff));
    }
}

/*##########################################################################
#
#   Name       : ShowCue
#
#   Purpose....: Show cue
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ShowCue(int female, int x, int y, double rot)
{
    if (female)
        vbe->SetDrawColor(255, 128, 0);
    else
        vbe->SetDrawColor(0, 128, 255);

    Draw(x * SCALE, y, rot, 5 * SCALE, 2);
    Draw(x * SCALE, y, rot + PI + PI / 12, 7 * SCALE, 2);
    Draw(x * SCALE, y, rot + PI - PI / 12, 7 * SCALE, 2);
}

/*##########################################################################
#
#   Name       : HideCue
#
#   Purpose....: Hide cue
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void HideCue(int x, int y, double rot)
{
    vbe->SetDrawColor(0, 0, 0);

    Draw(x * SCALE, y, rot, 5 * SCALE, 2);
    Draw(x * SCALE, y, rot + PI + PI / 12, 7 * SCALE, 2);
    Draw(x * SCALE, y, rot + PI - PI / 12, 7 * SCALE, 2);
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Main
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main()
{
    int i;
    
    vbe = new TVideoGraphicDevice(24, 1366, 768);
//    vbe = new TVideoGraphicDevice(24, 640, 480);

    for (i = 0; i < 2560; i++)
    {
        ShowCue(TRUE, i / 10, i / 10, PI * i / 50);
        RdosWaitMilli(40);
        HideCue(i / 10, i / 10, PI * i / 50);
    }
    
    return 0;        
}

