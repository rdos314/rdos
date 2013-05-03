/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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

