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
# showfont.cpp
# Show font tool
#
########################################################################*/

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
