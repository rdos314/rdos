
/* pngwio.c - functions for data output
 *
 * libpng 1.2.1 - December 12, 2001
 * For conditions of distribution and use, see copyright notice in png.h
 * Copyright (c) 1998-2001 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This file provides a location for all output.  Users who need
 * special handling are expected to write functions that have the same
 * arguments as these and perform similar functions, but that possibly
 * use different output methods.  Note that you shouldn't change these
 * functions, but rather write replacement functions and then change
 * them at run time with png_set_write_fn(...).
 */

#define PNG_INTERNAL
#include "pnglib.h"
#include "rdos.h"
#ifdef PNG_WRITE_SUPPORTED

/* Write the data to whatever output you are using.  The default routine
   writes to a file pointer.  Note that this routine sometimes gets called
   with very small lengths, so you should implement some kind of simple
   buffering if you are using unbuffered writes.  This should never be asked
   to write more than 64K on a 16 bit machine.  */

void /* PRIVATE */
png_write_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
   if (RdosWriteFile(png_ptr->file_handle, data, length) != length)
          png_error(png_ptr, "Write Error");
}

#if !defined(PNG_NO_STDIO)
/* This is the function that does the actual writing of data.  If you are
   not writing to a standard C stream, you should create a replacement
   write_data function and use it at run time with png_set_write_fn(), rather
   than changing the library. */
#ifndef USE_FAR_KEYWORD
static void /* PRIVATE */
png_default_write_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
   png_uint_32 check;

   check = RdosWriteFile(png_ptr->file_handle, data, length);

   if (check != length)
          png_error(png_ptr, "Write Error");
}
#else
/* this is the model-independent version. Since the standard I/O library
   can't handle far buffers in the medium and small models, we have to copy
   the data.
*/

#define NEAR_BUF_SIZE 1024
#define MIN(a,b) (a <= b ? a : b)

static void /* PRIVATE */
png_default_write_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
   png_uint_32 check;
   png_byte *near_data;  /* Needs to be "png_byte *" instead of "png_bytep" */
   png_FILE_p io_ptr;

   /* Check if data really is near. If so, use usual code. */
   near_data = (png_byte *)CVT_PTR_NOCHECK(data);
   io_ptr = (png_FILE_p)CVT_PTR(png_ptr->io_ptr);
   if ((png_bytep)near_data == data)
   {
#if defined(_WIN32_WCE)
      if ( !WriteFile(io_ptr, near_data, length, &check, NULL) )
         check = 0;
#else
      check = fwrite(near_data, 1, length, io_ptr);
#endif
   }
   else
   {
      png_byte buf[NEAR_BUF_SIZE];
      png_size_t written, remaining, err;
      check = 0;
      remaining = length;
      do
      {
         written = MIN(NEAR_BUF_SIZE, remaining);
         png_memcpy(buf, data, written); /* copy far buffer to near buffer */
#if defined(_WIN32_WCE)
         if ( !WriteFile(io_ptr, buf, written, &err, NULL) )
            err = 0;
#else
         err = fwrite(buf, 1, written, io_ptr);
#endif
         if (err != written)
            break;
         else
            check += err;
         data += written;
         remaining -= written;
      }
      while (remaining != 0);
   }
   if (check != length)
      png_error(png_ptr, "Write Error");
}

#endif
#endif

/* This function is called to output any data pending writing (normally
   to disk).  After png_flush is called, there should be no data pending
   writing in any buffers. */
#if defined(PNG_WRITE_FLUSH_SUPPORTED)
void /* PRIVATE */
png_flush(png_structp png_ptr)
{
   if (png_ptr->output_flush_fn != NULL)
      (*(png_ptr->output_flush_fn))(png_ptr);
}

#if !defined(PNG_NO_STDIO)
static void /* PRIVATE */
png_default_flush(png_structp png_ptr)
{
}
#endif
#endif

#if defined(USE_FAR_KEYWORD)
#if defined(_MSC_VER)
void *png_far_to_near(png_structp png_ptr,png_voidp ptr, int check)
{
   void *near_ptr;
   void FAR *far_ptr;
   FP_OFF(near_ptr) = FP_OFF(ptr);
   far_ptr = (void FAR *)near_ptr;
   if(check != 0)
      if(FP_SEG(ptr) != FP_SEG(far_ptr))
         png_error(png_ptr,"segment lost in conversion");
   return(near_ptr);
}
#  else
void *png_far_to_near(png_structp png_ptr,png_voidp ptr, int check)
{
   void *near_ptr;
   void FAR *far_ptr;
   near_ptr = (void FAR *)ptr;
   far_ptr = (void FAR *)near_ptr;
   if(check != 0)
      if(far_ptr != ptr)
         png_error(png_ptr,"segment lost in conversion");
   return(near_ptr);
}
#   endif
#   endif
#endif /* PNG_WRITE_SUPPORTED */
