
/* pngrio.c - functions for data input
 *
 * libpng 1.2.1 - December 12, 2001
 * For conditions of distribution and use, see copyright notice in png.h
 * Copyright (c) 1998-2001 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This file provides a location for all input.  Users who need
 * special handling are expected to write a function that has the same
 * arguments as this and performs a similar function, but that possibly
 * has a different input method.  Note that you shouldn't change this
 * function, but rather write a replacement function and then make
 * libpng use it at run time with png_set_read_fn(...).
 */

#define PNG_INTERNAL
#include "png.h"
#include "rdos.h"

/* Read the data from whatever input you are using.  The default routine
   reads from a file pointer.  Note that this routine sometimes gets called
   with very small lengths, so you should implement some kind of simple
   buffering if you are using unbuffered reads.  This should never be asked
   to read more then 64K on a 16 bit machine. */
void /* PRIVATE */
png_read_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
   png_debug1(4,"reading %d bytes\n", (int)length);
   if (RdosReadFile(png_ptr->file_handle, data, length) != length)
	  png_error(png_ptr, "Read Error");
}

#if !defined(PNG_NO_STDIO)
/* This is the function that does the actual reading of data.  If you are
   not reading from a standard C stream, you should create a replacement
   read_data function and use it at run time with png_set_read_fn(), rather
   than changing the library. */
#ifndef USE_FAR_KEYWORD
static void /* PRIVATE */
png_default_read_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
   png_size_t check;

   check = RdosReadFile(png_ptr->file_handle, data, length);

   if (check != length)
	  png_error(png_ptr, "Read Error");
}
#else
/* this is the model-independent version. Since the standard I/O library
   can't handle far buffers in the medium and small models, we have to copy
   the data.
*/

#define NEAR_BUF_SIZE 1024
#define MIN(a,b) (a <= b ? a : b)

static void /* PRIVATE */
png_default_read_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
   png_size_t check;

   check = RdosReadFile(png_ptr->file_handle, data, length);

   if (check != length)
      png_error(png_ptr, "Read Error");
}
#endif
#endif

