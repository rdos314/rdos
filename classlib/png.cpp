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
#include "file.h"
#include "png/png.h"
#include "zlib.h"

#define FALSE	0
#define TRUE	!FALSE

/*##########################################################################
#
#   Name       : TPngBitmapDevice::TPngBitmapDevice
#
#   Purpose....: Constructor for TPngBitmapDevice
#
#   In params..: bpp		bits per pixel
#				 width
#				 height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPngBitmapDevice::TPngBitmapDevice(int bpp, int width, int height)
  : TBitmapGraphicDevice(bpp, width, height)
{
}

/*##########################################################################
#
#   Name       : TPngBitmapDevice::Create
#
#   Purpose....: Create a bitmap from a PNG file
#
#   In params..: FileName		File to read
#   Out params.: *
#   Returns....: bitmap handle
#
##########################################################################*/
TPngBitmapDevice *TPngBitmapDevice::Create(const char *FileName, int r, int g, int b)
{
	int FileHandle;
	png_structp png_ptr = 0;
	png_infop info_ptr = 0;
	png_infop end_info = 0;
	TPngBitmapDevice *dev = 0;
	unsigned char *bits;
	int LineSize;
	int Line;
	unsigned long width, height;
	int depth;
	int color_type;
	int interlace_type;
	unsigned char *ptr;
	char buf[8];
	int ok;
	unsigned char **row_pointers;

	FileHandle = RdosOpenFile(FileName, 0);
	if (FileHandle)
	{
		ok = FALSE;
		if (RdosReadFile(FileHandle, buf, 8) == 8)
		{				
			if (png_sig_cmp((png_byte*)buf, 0, 8) == 0)
				ok = TRUE;
		}

		if (ok)
		{
			png_ptr = png_create_read_struct("", 0, 0, 0);
			if (png_ptr == 0)
				ok = FALSE;
		}

		if (ok)
		{
		    info_ptr = png_create_info_struct(png_ptr);
			if (info_ptr == 0)
				ok = FALSE;
		}
		else
			png_destroy_read_struct(&png_ptr, 0, 0);

		if (ok)
		{
			end_info = png_create_info_struct(png_ptr);
			if (end_info == 0)
				ok = FALSE;
		}
		else
			png_destroy_read_struct(&png_ptr, &info_ptr, 0);

		if (ok)
		{
		    if (setjmp(png_jmpbuf(png_ptr)))
				png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
			else
			{
				png_init_io(png_ptr, FileHandle);
				png_set_sig_bytes(png_ptr, 8);
 				png_read_info(png_ptr, info_ptr);
				png_get_IHDR(png_ptr, info_ptr, &width, &height, &depth, &color_type, &interlace_type, 0, 0);

			    if (color_type == PNG_COLOR_TYPE_PALETTE)
			       png_set_palette_to_rgb(png_ptr);

				if (color_type == PNG_COLOR_TYPE_GRAY && depth < 8)
					png_set_gray_1_2_4_to_8(png_ptr);

				if (depth == 16)
					png_set_strip_16(png_ptr);

				if (color_type & PNG_COLOR_MASK_ALPHA)
					png_set_strip_alpha(png_ptr);
 
			    png_set_bgr(png_ptr);
			    png_set_interlace_handling(png_ptr);
				png_read_update_info(png_ptr, info_ptr);

				dev = new TPngBitmapDevice(24, width, height);
				dev->SetFilledStyle();
                dev->SetDrawColor(r, g, b);
				dev->DrawRect(0, 0, width - 1, height - 1);

				bits = (unsigned char *)dev->GetLinear();
				LineSize = dev->GetLineSize();

				row_pointers = new unsigned char *[height];

				for (Line = 0; Line < height; Line++)
				{
					ptr = bits + Line * LineSize;
					*(row_pointers + Line) = ptr;
				}

				png_read_image(png_ptr, row_pointers);
				delete row_pointers;

			 	png_read_end(png_ptr, end_info);
			    png_destroy_read_struct(&png_ptr, &info_ptr, png_infopp_NULL);
			}
		}
		RdosCloseFile(FileHandle);
	}
	return dev;
}

/*##########################################################################
#
#   Name       : TPngBitmapDevice::Save
#
#   Purpose....: Save a bitmap to a PNG file
#
#   In params..: FileName		File to write
#              : bitmap
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPngBitmapDevice::Save(const char *FileName)
{
	int FileHandle;
	png_structp png_ptr = 0;
	png_infop info_ptr = 0;
	unsigned char *bits;
	int LineSize;
	int Line;
    int ok;
	unsigned char **row_pointers;
	unsigned char *ptr;

	FileHandle = RdosCreateFile(FileName, 0);
	if (FileHandle)
	{
		png_ptr = png_create_write_struct("", 0, 0, 0);
		if (png_ptr == 0)
			ok = FALSE;
		else
			ok = TRUE;

		if (ok)
		{
			info_ptr = png_create_info_struct(png_ptr);
			if (info_ptr == 0)
				ok = FALSE;
		}
		else
			png_destroy_write_struct(&png_ptr, 0);

		if (ok)
		{
			if (setjmp(png_jmpbuf(png_ptr)))
			{
				ok = FALSE;
				png_destroy_write_struct(&png_ptr, &info_ptr);
			}
			else
			{
				png_init_io(png_ptr, FileHandle);
				png_set_compression_level(png_ptr, Z_BEST_COMPRESSION);
				png_set_compression_mem_level(png_ptr, 8);
				png_set_compression_strategy(png_ptr, Z_DEFAULT_STRATEGY);
				png_set_compression_window_bits(png_ptr, 15);
				png_set_compression_method(png_ptr, 8);
				png_set_compression_buffer_size(png_ptr, 8192);
				png_set_IHDR(	png_ptr, info_ptr,
								GetWidth(), GetHeight(),
								8, PNG_COLOR_TYPE_RGB, PNG_INTERLACE_NONE,
								PNG_COMPRESSION_TYPE_DEFAULT,
								PNG_FILTER_TYPE_DEFAULT);

				png_write_info(png_ptr, info_ptr);
				png_set_bgr(png_ptr);

				bits = (unsigned char *)GetLinear();
				LineSize = GetLineSize();

				row_pointers = new unsigned char *[GetHeight()];

				for (Line = 0; Line < GetHeight(); Line++)
				{
					ptr = bits + Line * LineSize;
					*(row_pointers + Line) = ptr;
				}

				png_write_image(png_ptr, row_pointers);
				delete row_pointers;

				png_write_end(png_ptr, info_ptr);
				png_destroy_write_struct(&png_ptr, &info_ptr);
			}
		}
		RdosCloseFile(FileHandle);
		return ok;
	}
	return FALSE;
}
