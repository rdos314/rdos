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
# stopw.cpp
# Stopwatch tool
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "bitdev.h"
#include "videodev.h"
#include "keyboard.h"
#include "mouse.h"

#define FALSE   0
#define TRUE    !FALSE

void cdecl main()
{
    int i;
    TGraphicDevice *vbe;
    TBitmapGraphicDevice *bitmap;
    TFont Font(60);
    unsigned long BaseMsb, BaseLsb;
    unsigned long CurrMsb, CurrLsb;
    int min, sec, ms, us;
    char str[40];
    int strx;
    int stry;

    vbe = new TVideoGraphicDevice(24, 640, 480);

    bitmap = new TBitmapGraphicDevice(vbe->GetBpp(), 400, 100);
    bitmap->SetLgopNone();
    bitmap->SetFilledStyle();
    bitmap->SetFont(&Font);

    bitmap->SetDrawColor(0, 0, 0);
    bitmap->DrawRect(0, 0, 400, 100);

    bitmap->SetDrawColor(0, 255, 0);
    strcpy(str, "0.000");
    Font.GetStringMetrics(str, &strx, &stry);
    bitmap->DrawString(400 - strx, 0, str);

    vbe->Blit(bitmap, 0, 0, 100, 200, bitmap->GetWidth(), bitmap->GetHeight());

    for (;;)
    {
        RdosReadKeyboard();

        RdosGetSysTime(&BaseMsb, &BaseLsb);

        for (;;)
        {
            RdosGetSysTime(&CurrMsb, &CurrLsb);
            RdosDecodeLsbTics(CurrLsb - BaseLsb, &min, &sec, &ms, &us);
            sprintf(str, "%d.%03d", 60 * min + sec, ms);

            bitmap->SetDrawColor(0, 0, 0);
            bitmap->DrawRect(0, 0, 400, 100);

            bitmap->SetDrawColor(0, 255, 0);
            Font.GetStringMetrics(str, &strx, &stry);
            bitmap->DrawString(400 - strx, 0, str);

            vbe->Blit(bitmap, 0, 0, 100, 200, bitmap->GetWidth(), bitmap->GetHeight());

            if (RdosPollKeyboard())
            {
                RdosReadKeyboard();
                break;
            }
            else
                RdosWaitMilli(1);
        }
    }
}

