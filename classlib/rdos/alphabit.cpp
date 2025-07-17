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
# alphabit.cpp
# Bitmap with alpha (transparency) channel class
#
########################################################################*/

#include "rdos.h"
#include "alphabit.h"

/*##########################################################################
#
#   Name       : TAlphaBitmapDevice::TAlphaBitmapDevice
#
#   Purpose....: Constructor for TAlphaBitmapDevice
#
#   In params..: bpp            bits per pixel
#                                width
#                                height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAlphaBitmapDevice::TAlphaBitmapDevice(int width, int height)
  : TBitmapGraphicDevice(32, width, height)
{
    FBitmapHandle = RdosCreateAlphaBitmap(width, height);
    InitDevice();
    RdosGetBitmapInfo(FBitmapHandle, &FBpp, &FWidth, &FHeight, &FRowSize, &FLinear);
    FMask = 0;
    FAlpha = 0;
}

/*##########################################################################
#
#   Name       : TAlphaBitmapDevice::TAlphaBitmapDevice
#
#   Purpose....: Constructor for TAlphaBitmapDevice
#
#   In params..: bpp            bits per pixel
#                                width
#                                height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAlphaBitmapDevice::TAlphaBitmapDevice(int handle)
  : TBitmapGraphicDevice(handle)
{
    FMask = 0;
    FAlpha = 0;
}

/*##########################################################################
#
#   Name       : TAlphaBitmapDevice::~TAlphaBitmapDevice
#
#   Purpose....: Destructor for TAlphaBitmapDevice
#
#   Returns....: *
#
##########################################################################*/
TAlphaBitmapDevice::~TAlphaBitmapDevice()
{
    if (FMask)
        delete FMask;

    if (FAlpha)
        delete FAlpha;
}

/*##########################################################################
#
#   Name       : TAlphaBitmapDevice::GetMaskBitmap
#
#   Purpose....: Get mask bitmap (if available)
#
#   In params..: FileName               File to write
#              : bitmap
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice *TAlphaBitmapDevice::GetMaskBitmap()
{
    int Handle;

    if (!FMask)
    {
        Handle = RdosExtractValidBitmapMask(FBitmapHandle);
        if (Handle)
            FMask = new TAlphaBitmapDevice(Handle);
    }

    return FMask;
}

/*##########################################################################
#
#   Name       : TAlphaBitmapDevice::GetAlphaBitmap
#
#   Purpose....: Get alpha bitmap (if available)
#
#   In params..: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice *TAlphaBitmapDevice::GetAlphaBitmap()
{
    int Handle;

    if (!FAlpha)
    {
        Handle = RdosExtractValidBitmapMask(FBitmapHandle);
        if (Handle)
            FAlpha = new TAlphaBitmapDevice(Handle);
    }

    return FAlpha;
}

