
/* pngwio.c - functions for data output
 *
 * Last changed in libpng 1.6.0 [February 14, 2013]
 * Copyright (c) 1998-2013 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 *
 * This file provides a location for all output.  Users who need
 * special handling are expected to write functions that have the same
 * arguments as these and perform similar functions, but that possibly
 * use different output methods.  Note that you shouldn't change these
 * functions, but rather write replacement functions and then change
 * them at run time with png_set_write_fn(...).
 */

#include "pngpriv.h"

#ifdef PNG_WRITE_SUPPORTED
#include "rdos.h"

/* Write the data to whatever output you are using.  The default routine
 * writes to a file pointer.  Note that this routine sometimes gets called
 * with very small lengths, so you should implement some kind of simple
 * buffering if you are using unbuffered writes.  This should never be asked
 * to write more than 64K on a 16 bit machine.
 */

void /* PRIVATE */
png_write_data(png_structrp png_ptr, png_const_bytep data, png_size_t length)
{
   if (RdosWriteFile(png_ptr->io_ptr, data, length) != length)
          png_error(png_ptr, "Write Error");
}

#ifdef PNG_STDIO_SUPPORTED
/* This is the function that does the actual writing of data.  If you are
 * not writing to a standard C stream, you should create a replacement
 * write_data function and use it at run time with png_set_write_fn(), rather
 * than changing the library.
 */
void PNGCBAPI
png_default_write_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
   png_uint_32 check;

   check = RdosWriteFile(png_ptr->io_ptr, data, length);

   if (check != length)
          png_error(png_ptr, "Write Error");
}
#endif

/* This function is called to output any data pending writing (normally
 * to disk).  After png_flush is called, there should be no data pending
 * writing in any buffers.
 */
#ifdef PNG_WRITE_FLUSH_SUPPORTED
void /* PRIVATE */
png_flush(png_structrp png_ptr)
{
   if (png_ptr->output_flush_fn != NULL)
      (*(png_ptr->output_flush_fn))(png_ptr);
}

#  ifdef PNG_STDIO_SUPPORTED
void PNGCBAPI
png_default_flush(png_structp png_ptr)
{
}
#  endif
#endif
#endif /* PNG_WRITE_SUPPORTED */
