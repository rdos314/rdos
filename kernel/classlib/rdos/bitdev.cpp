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
