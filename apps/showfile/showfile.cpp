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
# showfile.cpp
# Show file tool
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "videodev.h"
#include "waitdev.h"
#include "keyboard.h"
#include "mouse.h"
#include "fileform.h"

#include "bmp.h"

int main(int argc, char **argv)
{
        int width = 640;
        int height = 480;
        TGraphicDevice *vbe;
        TDisplayControlThread *controlthread;
        char FileName[256];
        TKeyboardDevice *Keyboard;
        TMouseDevice *Mouse;
        TGraphicDevice *MouseMask;
        TGraphicDevice *MouseBitmap;
        TFileFormControl *fileform;

      if (argc == 1)
      {
              printf("usage: showfile filename\r\n");
              return 1;
       }

      strcpy(FileName, argv[1]);
//    strcpy(FileName, "showfile.cpp");

        strlwr(FileName);

        vbe = new TVideoGraphicDevice(24, width, height);

        Keyboard = new TKeyboardDevice;
        Mouse = new TMouseDevice;

        controlthread = new TDisplayControlThread("Control", vbe);
        controlthread->Add(Keyboard);
        controlthread->Add(Mouse);

        MouseMask = new TBitmapGraphicDevice(1, 21, 21);
        MouseMask->SetLgopNone();
        MouseMask->DrawLine(0, 9, 20, 9);
        MouseMask->DrawLine(0, 10, 20, 10);
        MouseMask->DrawLine(0, 11, 20, 11);

        MouseMask->DrawLine(9, 0, 9, 20);
        MouseMask->DrawLine(10, 0, 10, 20);
        MouseMask->DrawLine(11, 0, 11, 20);

        MouseBitmap = new TBitmapGraphicDevice(vbe->GetBpp(), 21, 21);
        MouseBitmap->SetLgopNone();
        MouseBitmap->SetDrawColor(128, 128, 128);
        MouseBitmap->DrawLine(0, 9, 20, 9);
        MouseBitmap->DrawLine(0, 11, 20, 11);

        MouseBitmap->DrawLine(9, 0, 9, 20);
        MouseBitmap->DrawLine(11, 0, 11, 20);

        MouseBitmap->SetDrawColor(255, 0, 0);
        MouseBitmap->DrawLine(0, 10, 20, 10);
        MouseBitmap->DrawLine(10, 0, 10, 20);

        controlthread->SetMouseMarker(MouseBitmap, MouseMask, 10, 10);

        fileform = new TFileFormControl(controlthread);
        fileform->Run(FileName);
        delete fileform;

        delete controlthread;
        delete vbe;

}

