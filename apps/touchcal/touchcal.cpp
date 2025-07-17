/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# touchcal.cpp
# Touch calibration app.
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "touchcal.h"

#include "bitdev.h"
#include "videodev.h"
#include "waitdev.h"
#include "keyboard.h"
#include "mouse.h"
#include "png.h"
#include "label.h"
#include "image.h"

#define FALSE   0
#define TRUE    !FALSE

struct TCalPoint
{
    int DispX;
    int DispY;
    int Count;
    int SumX;
    int SumY;
};

TSprite *MouseSprite;
int CalState = 0;
TCalPoint CalPoints[3];
int DispX;
int DispY;
int Pressed;

/*##########################################################################
#
#   Name       : CreateMouseMask
#
#   Purpose....: Create mouse mask
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice *CreateMouseMask()
{
    TBitmapGraphicDevice *mono;

    mono = new TBitmapGraphicDevice(1, 40, 40);
        
    mono->SetFilledStyle();
    mono->DrawEllipse(20, 20, 20, 20);
    mono->SetLgopInv();
    mono->DrawRect(15, 15, 25, 25);
    mono->SetHollowStyle();
    mono->SetLgopXor();
    mono->DrawEllipse(20, 20, 15, 15);
    mono->DrawRect(10, 10, 30, 30);
    mono->SetLgopNone();
    mono->DrawLine(0, 0, 40, 40);
    mono->DrawLine(0, 40, 40, 0);
    mono->DrawLine(0, 0, 39, 39);
    mono->DrawLine(0, 39, 39, 0);
    mono->DrawLine(1, 1, 41, 41);
    mono->DrawLine(1, 41, 41, 1);
    mono->DrawLine(1, 1, 40, 40);
    mono->DrawLine(1, 40, 40, 1); 

    return mono;
}

/*##########################################################################
#
#   Name       : CreateMouseBitmap
#
#   Purpose....: Create mouse bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice *CreateMouseBitmap(TGraphicDevice *dev, int r, int g, int b)
{
    TBitmapGraphicDevice *bitmap;

    bitmap = new TBitmapGraphicDevice(dev->GetBpp(), 40, 40);
    bitmap->SetLgopNone();
    bitmap->SetFilledStyle();
    bitmap->SetDrawColor(r, g, b);
    bitmap->DrawRect(0, 0, 40, 40);

    return bitmap;
}

/*##########################################################################
#
#   Name       : MouseMove
#
#   Purpose....: Mouse move
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void MouseMove(TMouseDevice *Mouse, int x, int y, int MouseButton, int KeyState)
{
    MouseSprite->Move(x, y);
}

/*##########################################################################
#
#   Name       : LeftDown
#
#   Purpose....: Pressed touch
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void LeftDown(TMouseDevice *Mouse, int x, int y, int MouseButton, int KeyState)
{
}

/*##########################################################################
#
#   Name       : LeftDown
#
#   Purpose....: Pressed touch
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void cdecl main()
{
    int i;
    int bits;
    int x, y;
    TGraphicDevice *vbe;
    TBitmapGraphicDevice *bitmap;
    TGraphicDevice *MouseMask;
    TGraphicDevice *MouseBitmap;
    TMouseDevice *Mouse;
    TControlThread *ControlThread;
    TWait Wait;
    int Count;

    Mouse = new TMouseDevice;
    Mouse->OnMove = MouseMove;
    Mouse->OnLeftDown = LeftDown;

    vbe = new TVideoGraphicDevice(24, 640, 480);
//      vbe = new TVideoGraphicDevice(24, 1280, 800);
//      vbe = new TVideoGraphicDevice(24, 1280, 1024);
//        vbe = new TVideoGraphicDevice(24, 640, 480);
//      vbe = new TVideoGraphicDevice(24, 800, 600);
//      vbe = new TVideoGraphicDevice(1, 240, 128);
//        vbe = new TVideoGraphicDevice(24, 1920, 1080);

    x = vbe->GetWidth();
    y = vbe->GetHeight();

    ControlThread = new TDisplayControlThread("Control thread", vbe);

    Mouse->SetWindow(20, 20, x - 20, y - 20);
    Mouse->SetMickey(1, 1);

    MouseMask = CreateMouseMask();

    MouseBitmap = CreateMouseBitmap(vbe, 255, 255, 255);
    MouseSprite = vbe->CreateSprite(MouseBitmap, MouseMask, 20, 20);

    Wait.Add(Mouse);
    Wait.StartThreadHandler("IO Thread", 0x1000);

    MouseSprite->Move(100, 100);
    MouseSprite->Show();

    for (;;)
        RdosWaitMilli(250);

}
