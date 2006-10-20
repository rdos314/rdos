
/* pngrio.c - functions for data input
 *
 * Last changed in libpng 1.2.9 April 14, 2006
 * For conditions of distribution and use, see copyright notice in png.h
 * Copyright (c) 1998-2006 Glenn Randers-Pehrson
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

#include "rdos.h"
#define PNG_INTERNAL
#include "png.h"

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
void PNGAPI
png_default_read_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
   png_size_t check;

   check = RdosReadFile(png_ptr->file_handle, data, length);

   if (check != length)
      png_error(png_ptr, "Read Error");
}

/* This function allows the application to supply a new input function
   for libpng if standard C streams aren't being used.

   This function takes as its arguments:
   png_ptr      - pointer to a png input data structure
   io_ptr       - pointer to user supplied structure containing info about
                  the input functions.  May be NULL.
   read_data_fn - pointer to a new input function that takes as its
                  arguments a pointer to a png_struct, a pointer to
                  a location where input data can be stored, and a 32-bit
                  unsigned int that is the number of bytes to be read.
                  To exit and output any fatal error messages the new write
                  function should call png_error(png_ptr, "Error msg"). */
void PNGAPI
png_set_read_fn(png_structp png_ptr, png_voidp io_ptr,
   png_rw_ptr read_data_fn)
{
   png_ptr->io_ptr = io_ptr;

#if !defined(PNG_NO_STDIO)
   if (read_data_fn != NULL)
      png_ptr->read_data_fn = read_data_fn;
   else
      png_ptr->read_data_fn = png_default_read_data;
#else
   png_ptr->read_data_fn = read_data_fn;
#endif

   /* It is an error to write to a read device */
   if (png_ptr->write_data_fn != NULL)
   {
      png_ptr->write_data_fn = NULL;
      png_warning(png_ptr,
         "It's an error to set both read_data_fn and write_data_fn in the ");
      png_warning(png_ptr,
         "same structure.  Resetting write_data_fn to NULL.");
   }

#if defined(PNG_WRITE_FLUSH_SUPPORTED)
   png_ptr->output_flush_fn = NULL;
#endif
}
#endif /* PNG_READ_SUPPORTED */
