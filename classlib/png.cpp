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
# png.cpp
# PNG interface
#
########################################################################*/

#include "rdos.h"
#include "png.h"

extern "C" 
{
int LoadPngBase(const char *FileName);
int SavePngBase(const char *FileName, int Bitmap);
};

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TPngBitmapDevice::TPngBitmapDevice
#
#   Purpose....: Constructor for TPngBitmapDevice
#
#   In params..:                 width
#                                height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPngBitmapDevice::TPngBitmapDevice(int width, int height)
  : TAlphaBitmapDevice(width, height)
{
}

/*##########################################################################
#
#   Name       : TPngBitmapDevice::TPngBitmapDevice
#
#   Purpose....: Constructor for TPngBitmapDevice
#
#   In params..: bpp            bits per pixel
#                                width
#                                height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPngBitmapDevice::TPngBitmapDevice(int handle)
  : TAlphaBitmapDevice(handle)
{
}

/*##########################################################################
#
#   Name       : TPngBitmapDevice::TPngBitmapDevice
#
#   Purpose....: Constructor for TPngBitmapDevice
#
#   In params..:                 width
#                                height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPngBitmapDevice::~TPngBitmapDevice()
{
}

/*##########################################################################
#
#   Name       : TPngBitmapDevice::Create
#
#   Purpose....: Create a bitmap from a PNG file
#
#   In params..: FileName               File to read
#   Out params.: *
#   Returns....: bitmap handle
#
##########################################################################*/
TPngBitmapDevice *TPngBitmapDevice::Create(const char *FileName, int r, int g, int b)
{
    int handle;
    TPngBitmapDevice *bitmap;

    handle = LoadPngBase(FileName);

    if (handle)
    {
        bitmap = new TPngBitmapDevice(handle);
        RdosCloseBitmap(handle);
        return bitmap;
    }
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TPngBitmapDevice::Save
#
#   Purpose....: Save a bitmap to a PNG file
#
#   In params..: FileName               File to write
#              : bitmap
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPngBitmapDevice::Save(const char *FileName, TGraphicDevice *src)
{
    TBitmapGraphicDevice *bitmap;
    int ok;
    
    bitmap = new TBitmapGraphicDevice(24, src->GetWidth(), src->GetHeight());
    bitmap->Blit(src, 0, 0, 0, 0, src->GetWidth(), src->GetHeight());

    ok = SavePngBase(FileName, bitmap->GetHandle());

    delete bitmap;

    return ok;
}
