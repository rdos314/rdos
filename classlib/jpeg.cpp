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
# bmp.cpp
# JPEG interface
#
########################################################################*/

#include "rdos.h"
#include "jpeg.h"
#include "jinclude.h"
#include "jpeglib.h"

/*##########################################################################
#
#   Name       : TJpegBitmapDevice::TJpegBitmapDevice
#
#   Purpose....: Constructor for TJpegBitmapDevice
#
#   In params..: bpp		bits per pixel
#				 width
#				 height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJpegBitmapDevice::TJpegBitmapDevice(int bpp, int width, int height)
  : TBitmapGraphicDevice(bpp, width, height)
{
}

/*##########################################################################
#
#   Name       : TJpegBitmapDevice::TJpegBitmapDevice
#
#   Purpose....: Constructor for TJpegBitmapDevice
#
#   In params..: dev
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJpegBitmapDevice::TJpegBitmapDevice(const TJpegBitmapDevice &dev)
  : TBitmapGraphicDevice(dev)
{
}

/*##########################################################################
#
#   Name       : TJpegBitmapDevice::Create
#
#   Purpose....: Create a bitmap from a JPEG file
#
#   In params..: FileName		File to read
#   Out params.: *
#   Returns....: bitmap handle
#
##########################################################################*/
TJpegBitmapDevice *TJpegBitmapDevice::Create(const char *FileName)
{
	TJpegBitmapDevice *dev;
	unsigned char *bits;
	int LineSize;
	int Line;
	unsigned char *ptr;
	int handle;
	struct jpeg_decompress_struct cinfo;
	struct jpeg_error_mgr jerr;

	handle = RdosOpenHandle(FileName, O_RDWR);
	if (handle > 0)
	{
		cinfo.err = jpeg_std_error(&jerr);
		jpeg_create_decompress(&cinfo);
		jpeg_stdio_src(&cinfo, handle);
		jpeg_read_header(&cinfo, TRUE);
		jpeg_start_decompress(&cinfo);

		dev = new TJpegBitmapDevice(	24,
										cinfo.output_width,
										cinfo.output_height);

		bits = (unsigned char *)dev->GetLinear();
		LineSize = dev->GetLineSize();

		for (Line = 0; Line < dev->GetHeight(); Line++)
		{
			ptr = bits + Line * LineSize;
			jpeg_read_scanlines(&cinfo, &ptr, 1);
		}

		jpeg_finish_decompress(&cinfo);
		jpeg_destroy_decompress(&cinfo);

		RdosCloseHandle(handle);
		return dev;
	}
	return 0;
}

/*##########################################################################
#
#   Name       : TJpegBitmapDevice::Save
#
#   Purpose....: Save a bitmap to a JPEG file
#
#   In params..: FileName		File to write
#              : bitmap
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJpegBitmapDevice::Save(const char *FileName)
{
	unsigned char *bits;
	unsigned char *ptr;
	int LineSize;
	int Line;
	int handle;
	struct jpeg_compress_struct cinfo;
	struct jpeg_error_mgr jerr;
	TBitmapGraphicDevice *dev;
	int FreeDev = FALSE;

	handle = RdosOpenHandle(FileName, O_CREAT | O_RDWR);
	if (handle > 0)
	{
		if (GetBpp() == 24)
			dev = this;
		else
		{
			FreeDev = TRUE;
			dev = new TBitmapGraphicDevice(24, GetWidth(), GetHeight());
			dev->Blit(this, 0, 0, 0, 0, GetWidth(), GetHeight());
		}

		cinfo.err = jpeg_std_error(&jerr);
		jpeg_create_compress(&cinfo);

		jpeg_stdio_dest(&cinfo, handle);

		cinfo.image_width = GetWidth();
		cinfo.image_height = GetHeight();
		cinfo.input_components = 3;
		cinfo.in_color_space = JCS_RGB;

		jpeg_set_defaults(&cinfo);
		jpeg_start_compress(&cinfo, TRUE);

		bits = (unsigned char *)dev->GetLinear();
		LineSize = dev->GetLineSize();

		for (Line = 0; Line < dev->GetHeight(); Line++)
		{
			ptr = bits + Line * LineSize;
			jpeg_write_scanlines(&cinfo, &ptr, 1);
		}

		jpeg_finish_compress(&cinfo);
		jpeg_destroy_compress(&cinfo);

		RdosCloseHandle(handle);

		if (FreeDev)
			delete dev;
	}

	return FALSE;
}
