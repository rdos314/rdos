/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2018, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
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
    if (CalState == 4)
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
    if (CalState < 4)
    {
        CalPoints[CalState].SumX += x;
        CalPoints[CalState].SumY += y;
        CalPoints[CalState].Count++;
    }

    Pressed = TRUE;
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
    TTouchCalibration cal;

    cal.Start();

    Mouse = new TMouseDevice;
    Mouse->OnMove = MouseMove;
    Mouse->OnLeftDown = LeftDown;

    vbe = new TVideoGraphicDevice(24, 1266, 768);
//      vbe = new TVideoGraphicDevice(24, 1280, 800);
//      vbe = new TVideoGraphicDevice(24, 1280, 1024);
//        vbe = new TVideoGraphicDevice(24, 640, 480);
//      vbe = new TVideoGraphicDevice(24, 800, 600);
//      vbe = new TVideoGraphicDevice(1, 240, 128);
//        vbe = new TVideoGraphicDevice(24, 1920, 1080);

    x = vbe->GetWidth();
    y = vbe->GetHeight();

    ControlThread = new TDisplayControlThread("Control thread", vbe);
    CalState = 0;

    Mouse->SetWindow(20, 20, x - 20, y - 20);
    Mouse->SetMickey(1, 1);

    MouseMask = CreateMouseMask();

    MouseBitmap = CreateMouseBitmap(vbe, 255, 255, 255);
    MouseSprite = vbe->CreateSprite(MouseBitmap, MouseMask, 20, 20);

    Wait.Add(Mouse);
    Wait.StartThreadHandler("IO Thread", 0x1000);

    Pressed = FALSE;
    Count = 0;
    CalState = 0;

    CalPoints[0].DispX = (x * 15) / 100;
    CalPoints[0].DispY = (y * 15) / 100;

    CalPoints[1].DispX = (x * 50) / 100;
    CalPoints[1].DispY = (y * 85) / 100;

    CalPoints[2].DispX = (x * 85) / 100;
    CalPoints[2].DispY = (y * 50) / 100;

    for (i = 0; i < 3; i++)
    {
        CalPoints[i].Count = 0;
        CalPoints[i].SumX = 0;
        CalPoints[i].SumY = 0;
    }


    for (;;)
    {
        if (Pressed && CalState < 3)
        {
            CalState++;
            if (CalState == 3)
            {
                if (Count == 4)
                {
                    for (i = 0; i < 3; i++)
                        cal.AddPoint(	CalPoints[i].DispX, CalPoints[i].DispY, 
			                CalPoints[i].SumX / CalPoints[i].Count, CalPoints[i].SumY / CalPoints[i].Count);
                    cal.Calibrate();
                }
                else
                {
                    Count++;
                    CalState = 0;
                }
            }
        }

        if (CalState < 3)
        {
            MouseSprite->Move(CalPoints[CalState].DispX, CalPoints[CalState].DispY);
            MouseSprite->Show();
        }

        Pressed = FALSE;

        Wait.WaitForever();
    }
}
