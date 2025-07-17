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
# bitdev.cpp
# Graphic bitmap class
#
########################################################################*/

#include "rdos.h"
#include "bitdev.h"

/*##########################################################################
#
#   Name       : TBitmapGraphicDevice::TBitmapGraphicDevice
#
#   Purpose....: Constructor for TBitmapGraphicDevice
#
#   In params..: height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice::TBitmapGraphicDevice(int handle)
  : TGraphicDevice(handle)
{
    if (FBitmapHandle)
    	RdosGetBitmapInfo(FBitmapHandle, &FBpp, &FWidth, &FHeight, &FRowSize, &FLinear);
}

/*##########################################################################
#
#   Name       : TBitmapGraphicDevice::TBitmapGraphicDevice
#
#   Purpose....: Constructor for TBitmapGraphicDevice
#
#   In params..: bpp		bits per pixel
#				 width
#				 height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice::TBitmapGraphicDevice(int bpp, int width, int height)
  : TGraphicDevice(bpp, width, height)
{
    FBitmapHandle = RdosCreateBitmap(bpp, width, height);
    InitDevice();
	RdosGetBitmapInfo(FBitmapHandle, &FBpp, &FWidth, &FHeight, &FRowSize, &FLinear);
}

/*##########################################################################
#
#   Name       : TBitmapGraphicDevice::TBitmapGraphicDevice
#
#   Purpose....: Copy constructor for TBitmapGraphicDevice
#
#   In params..: dev		bitmap to copy
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice::TBitmapGraphicDevice(const TBitmapGraphicDevice &dev)
  : TGraphicDevice(dev)
{
}

/*##########################################################################
#
#   Name       : TBitmapGraphicDevice::TBitmapGraphicDevice
#
#   Purpose....: Copy constructor for TBitmapGraphicDevice
#
#   In params..: dev		bitmap to copy
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice::TBitmapGraphicDevice(const TGraphicDevice &dev)
  : TGraphicDevice(dev)
{
}

/*##########################################################################
#
#   Name       : TBitmapGraphicDevice::TBitmapGraphicDevice
#
#   Purpose....: Constructor to create a 1-bit bitmap of a string
#
#   In params..: font           font to use for string
#              : str            string to create bitmap for              
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice::TBitmapGraphicDevice(TFont *font, const char *str)
  : TGraphicDevice(1, 0, 0)
{
    FBitmapHandle = RdosCreateStringBitmap(font->FFontHandle, str);
	RdosGetBitmapInfo(FBitmapHandle, &FBpp, &FWidth, &FHeight, &FRowSize, &FLinear);
}

/*##########################################################################
#
#   Name       : TBitmapGraphicDevice::~TBitmapGraphicDevice
#
#   Purpose....: Desctructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice::~TBitmapGraphicDevice()
{
}
