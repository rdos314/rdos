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
# showimg.cpp
# Show image file tool
#
########################################################################*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rdos.h"
#include "bmp.h"
#include "jpeg.h"
#include "gif.h"
#include "png.h"
#include "videodev.h"

#define FALSE   0
#define TRUE    !FALSE

int main(int argc, char **argv)
{
        TGraphicDevice *vbe;
        TBitmapGraphicDevice *bitmap;
        int width, height;
        int ratio;
        char FileName[256];

        if (argc == 1)
        {
              printf("usage: showimg filename\r\n");
              return 1;
        }

        strcpy(FileName, argv[1]);
        strlwr(FileName);

        bitmap = 0;

        if (strstr(FileName, ".png"))
                bitmap = TPngBitmapDevice::Create(FileName, 255, 255, 255);

        if (!bitmap && strstr(FileName, ".gif"))
                bitmap = TGifBitmapDevice::Create(FileName);

        if (!bitmap && strstr(FileName, ".jpg"))
                bitmap = TJpegBitmapDevice::Create(FileName);

        if (!bitmap && strstr(FileName, ".bmp"))
                bitmap = TBmpBitmapDevice::Create(FileName);

        if (!bitmap)
        {
                strcpy(FileName, argv[1]);
                strcat(FileName, ".jpg");
                bitmap = TJpegBitmapDevice::Create(FileName);
        }

        if (!bitmap)
        {
                strcpy(FileName, argv[1]);
                strcat(FileName, ".bmp");
                bitmap = TBmpBitmapDevice::Create(FileName);
        }

        if (!bitmap)
        {
                strcpy(FileName, argv[1]);
                strcat(FileName, ".png");
                bitmap = TPngBitmapDevice::Create(FileName, 255 ,255, 255);
        }

        if (!bitmap)
        {
                strcpy(FileName, argv[1]);
                strcat(FileName, ".gif");
                bitmap = TGifBitmapDevice::Create(FileName);
        }

        if (bitmap)
        {
                width = bitmap->GetWidth();
                height = bitmap->GetHeight();
                if (width < 640)
                        width = 640;
                if (height < 480)
                        height = 480;

                ratio = height * 4 / width;
                if (ratio > 3)
                        height = 3 * width / 4;
                else
                        width = 4 * height / 3;

//                width = 1400;
//                height = 1050;

                vbe = new TVideoGraphicDevice(24, width, height);
                vbe->Blit(bitmap, 0, 0, 0, 0, bitmap->GetWidth(), bitmap->GetHeight());
                RdosReadKeyboard();
                delete bitmap;
                delete vbe;
                RdosSetTextMode();
        }
        else
                printf("invalid filename\r\n");

        return 0;
}
