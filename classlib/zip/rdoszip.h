/*
  Copyright (c) 1990-2009 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2009-Jan-02 or later
  (the contents of which are also included in unzip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/*---------------------------------------------------------------------------
    RDOS specific configuration section:
  ---------------------------------------------------------------------------*/

#ifndef __rdoscfg_h
#define __rdoscfg_h

#include "rdos.h"

#include <sys/types.h>          /* off_t, time_t, dev_t, ... */
#include <sys/stat.h>
#include <io.h>                 /* read(), open(), etc. */
#include <time.h>
#include <memory.h>
#include <fcntl.h>

#include "zlib.h"

#define GOT_UTIMBUF
#define USE_ZLIB
#define SET_DIR_ATTRIB

#ifndef Cdecl
#  define Cdecl __cdecl
#endif


#define DIR_END       '\\'      /* OS uses '\\' as directory separator */
#define DIR_END2      '/'       /* also check for '/' (RTL may convert) */
#define lenEOL        2
#define PutNativeEOL  {*q++ = native(CR); *q++ = native(LF);}

#undef UTF8_MAYBE_NATIVE

/* The following compiler systems provide or use a runtime library with a
 * locale-aware isprint() implementation.  For these systems, the "enhanced"
 * unprintable charcode detection in fnfilter() gets enabled.
 */
/* RDOS runs solely on little-endian processors; enable support
 * for the 32-bit optimized CRC-32 C code by default.
 */

#ifdef __WATCOMC__
#  ifdef __386__
#    ifndef WATCOMC_386
#      define WATCOMC_386
#    endif
#    define __32BIT__
#    undef far
#    define far
#    undef near
#    define near
#    undef Cdecl
#    define Cdecl

/* gaah -- Watcom's docs claim that _get_osfhandle exists, but it doesn't.  */
#    define _get_osfhandle _os_handle

/* Get asm routines to link properly without using "__cdecl": */
#    ifndef USE_ZLIB
#      pragma aux crc32         "_*" parm caller [] value [eax] modify [eax]
#      pragma aux get_crc_table "_*" parm caller [] value [eax] \
                                      modify [eax ecx edx]
#    endif /* !USE_ZLIB */
#  endif /* __386__ */
#endif /* __WATCOMC__ */

#define SCREENWIDTH 80
#define SCREENSIZE(scrrows, scrcols)  screensize(scrrows, scrcols)
int screensize(int *tt_rows, int *tt_cols);

/* on the DOS or NT console screen, line-wraps are always enabled */
#define SCREENLWRAP 1
#define TABSIZE 8

/* base type for file offsets and file sizes */
typedef long zoff_t;
# define ZOFF_T_DEFINED

  /* stat struct */
typedef struct stat z_stat;
# define Z_STAT_DEFINED

#  define FZOFFT_FMT "l"
#  define FZOFFT_HEX_WID_VALUE "8"


#  define SHORTHDRSTATS "%9lu  %02u%c%02u%c%02u %02u:%02u  %c"
#  define SHORTFILETRAILER " --------                   -------\n%9lu                   %9lu file%s\n"

#endif /* !__rdoscfg_h */
