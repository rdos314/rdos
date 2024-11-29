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
# pngbase.c
# PNG interface
#
########################################################################*/

#include "malloc.h"
#include "rdos.h"
#include "libpng.h"
#include "zlib.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : png_read_data
#
#   Purpose....: Read data
#
#   In params..: 
#   Out params.: *
#   Returns....: 
#
##########################################################################*/
static void PNGCBAPI png_read_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
   png_size_t check = 0;
   png_voidp io_ptr;

   io_ptr = png_get_io_ptr(png_ptr);
   if (io_ptr != NULL)
   {
      check = RdosReadHandle((int)io_ptr, data, length);
   }

   if (check != length)
   {
      png_error(png_ptr, "Read Error");
   }
}

/*##########################################################################
#
#   Name       : LoadPngBase
#
#   Purpose....: Create a bitmap from a PNG file
#
#   In params..: FileName               File to read
#   Out params.: *
#   Returns....: bitmap handle
#
##########################################################################*/
int LoadPngBase(const char *FileName)
{
    int FileHandle;
    png_structp read_ptr;
    png_infop read_info_ptr, end_info_ptr;
    int interlace_type, compression_type, filter_type;
    int color_type;
    int bitmap = 0;
    int bpp;
    int LineSize;
    void *Linear;
    unsigned char *bits;
    int Line;
    unsigned int width, height;
    int iwidth;
    int iheight;
    int depth;
    unsigned char *ptr;
    unsigned char **row_pointers;

    FileHandle = RdosOpenHandle(FileName, O_RDWR);
    if (FileHandle > 0)
    {
        read_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
        read_info_ptr = png_create_info_struct(read_ptr);
        end_info_ptr = png_create_info_struct(read_ptr);

        if (setjmp(png_jmpbuf(read_ptr)))
            png_destroy_read_struct(&read_ptr, &read_info_ptr, &end_info_ptr);
        else
        {
            png_set_benign_errors(read_ptr, 1);
            png_set_read_fn(read_ptr, (png_voidp)FileHandle, png_read_data);
            png_set_read_status_fn(read_ptr, NULL);
            png_set_keep_unknown_chunks(read_ptr, PNG_HANDLE_CHUNK_ALWAYS, NULL, 0);
            png_read_info(read_ptr, read_info_ptr);

            png_get_IHDR(read_ptr, read_info_ptr, &width, &height, &depth,
                &color_type, &interlace_type, &compression_type, &filter_type);

            if (color_type == PNG_COLOR_TYPE_PALETTE)
                png_set_palette_to_rgb(read_ptr);

            if (color_type == PNG_COLOR_TYPE_GRAY && depth < 8)
                png_set_gray_to_rgb(read_ptr);

            if (depth == 16)
                png_set_strip_16(read_ptr);

            png_set_bgr(read_ptr);
            png_set_interlace_handling(read_ptr);
            png_read_update_info(read_ptr, read_info_ptr);

            bitmap = 0;
            if (color_type & PNG_COLOR_MASK_ALPHA)
                bitmap = RdosCreateAlphaBitmap(width, height);

            if (!bitmap)
                bitmap = RdosCreateBitmap(24, width, height);

            RdosGetBitmapInfo(bitmap, &bpp, &iwidth, &iheight, &LineSize, &Linear);

            bits = (unsigned char *)Linear;

            row_pointers = (unsigned char **)malloc(height * sizeof(void *));

            for (Line = 0; Line < height; Line++)
            {
                ptr = bits + Line * LineSize;
                *(row_pointers + Line) = ptr;
            }

            png_read_image(read_ptr, row_pointers);
            free(row_pointers);

            png_read_end(read_ptr, end_info_ptr);
            png_destroy_read_struct(&read_ptr, &read_info_ptr, 0);
        }
        RdosCloseHandle(FileHandle);
    }
    return bitmap;
}

/*##########################################################################
#
#   Name       : png_write_data
#
#   Purpose....: Write data
#
#   In params..: 
#   Out params.: *
#   Returns....: 
#
##########################################################################*/
static void PNGCBAPI png_write_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
   png_size_t check = 0;
   png_voidp io_ptr;

   io_ptr = png_get_io_ptr(png_ptr);
   if (io_ptr != NULL)
   {
       check = RdosWriteHandle((int)io_ptr, data, length);
   }

   if (check != length)
   {
      png_error(png_ptr, "Write Error");
   }
}

/*##########################################################################
#
#   Name       : SavePngBase
#
#   Purpose....: Save to PNG file
#
#   In params..: FileName               File to write
#   Out params.: *
#   Returns....: bitmap handle
#
##########################################################################*/
int SavePngBase(const char *FileName, int Bitmap)
{
    int FileHandle;
    png_structp write_ptr;
    png_infop write_info_ptr, write_end_info_ptr;
    unsigned char *bits;
    int LineSize;
    int Line;
    void *Linear;
    int bpp;
    int width;
    int height;
    unsigned char **row_pointers;
    unsigned char *ptr;

    FileHandle = RdosOpenHandle(FileName, O_CREAT | O_RDWR);
    if (FileHandle > 0)
    {
        write_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
        write_info_ptr = png_create_info_struct(write_ptr);
        write_end_info_ptr = png_create_info_struct(write_ptr);

        if (setjmp(png_jmpbuf(write_ptr)))
        {
            png_destroy_info_struct(write_ptr, &write_end_info_ptr);
            png_destroy_write_struct(&write_ptr, &write_info_ptr);
        }
        else
        {
            RdosGetBitmapInfo(Bitmap, &bpp, &width, &height, &LineSize, &Linear);

            png_set_benign_errors(write_ptr, 1);
            png_set_write_fn(write_ptr, (png_voidp)FileHandle, png_write_data, NULL);
            png_set_write_status_fn(write_ptr, NULL);
            png_set_keep_unknown_chunks(write_ptr, PNG_HANDLE_CHUNK_ALWAYS, NULL, 0);

            png_set_IHDR(write_ptr, write_info_ptr, 
                        width, height, 
                        8, PNG_COLOR_TYPE_RGB, PNG_INTERLACE_NONE,
                        PNG_COMPRESSION_TYPE_DEFAULT,
                        PNG_FILTER_TYPE_DEFAULT);

            png_write_info(write_ptr, write_info_ptr);
            png_set_bgr(write_ptr);
            
            bits = (unsigned char *)Linear;

            row_pointers = (unsigned char **)malloc(height * sizeof(void *));

            for (Line = 0; Line < height; Line++)
            {
                ptr = bits + Line * LineSize;
                *(row_pointers + Line) = ptr;
            }

            png_write_image(write_ptr, row_pointers);
            free(row_pointers);

            png_write_end(write_ptr, write_end_info_ptr);
            png_destroy_info_struct(write_ptr, &write_end_info_ptr);
            png_destroy_write_struct(&write_ptr, &write_info_ptr);
        }
        RdosCloseHandle(FileHandle);
        return TRUE;
    }

    return FALSE;
}
