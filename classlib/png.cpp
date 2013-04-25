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
#   In params..: bpp            bits per pixel
#                                width
#                                height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPngBitmapDevice::TPngBitmapDevice(int width, int height)
  : TBitmapGraphicDevice(24, width, height)
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
  : TBitmapGraphicDevice(handle)
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

    handle = LoadPngBase(FileName);

    if (handle)
        return new TPngBitmapDevice(handle);
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
int TPngBitmapDevice::Save(const char *FileName)
{
    return SavePngBase(FileName, FBitmapHandle);
}
