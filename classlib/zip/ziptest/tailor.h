/*
  tailor.h - Zip 3

  Copyright (c) 1990-2008 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2007-Mar-4 or later
  (the contents of which are also included in zip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/

#include "osdep.h"


/* generic LARGE_FILE_SUPPORT defines
   These get used if not defined above.
   7/21/2004 EG
*/

/* Used to remove arguments in function prototypes for non-ANSI C */
#define OF(a) a
#define OFT(a) a

/* If the compiler can't handle const define ZCONST in osdep.h */
/* Define const itself in case the system include files are bonkers */
#define ZCONST const

/*
 * Some compiler environments may require additional attributes attached
 * to declarations of runtime libary functions (e.g. to prepare for
 * linking against a "shared dll" version of the RTL).  Here, we provide
 * the "empty" default for these attributes.
 */
#define IZ_IMP

/*
 * case mapping functions. case_map is used to ignore case in comparisons,
 * to_up is used to force upper case even on Unix (for dosify option).
 */
#define case_map(c) (c)
#define to_up(c)    ((c) >= 'a' && (c) <= 'z' ? (c)-'a'+'A' : (c))

#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <unistd.h> /* usually defines _POSIX_VERSION */
#include <fcntl.h>
#include <string.h>

typedef void zvoid;

/*
 * A couple of forward declarations that are needed on systems that do
 * not supply C runtime library prototypes.
 */

/*
 * SEEK_* macros, should be defined in stdio.h
 */
/* Define fseek() commands */
#define SEEK_SET 0
#define SEEK_CUR 1

#define FALSE 0
#define TRUE 1

typedef size_t extent;


/* DBCS support for Info-ZIP's zip  (mainly for japanese (-: )
 * by Yoshioka Tsuneo (QWF00133@nifty.ne.jp,tsuneo-y@is.aist-nara.ac.jp)
 * This code is public domain!   Date: 1998/12/20
 */

/* 2007-07-29 SMS.
 * Include <locale.h> here if it will be needed later for Unicode.
 * Otherwise, SETLOCALE may be defined here, and then defined again
 * (differently) when <locale.h> is read later.
 */

#include <locale.h>

    /* Multi Byte Character Set */

extern char *___tmp_ptr;
unsigned char *zmbschr OF((ZCONST unsigned char *, unsigned int));
unsigned char *zmbsrchr OF((ZCONST unsigned char *, unsigned int));

#define CLEN(ptr) mblen((ZCONST char *)ptr, MB_CUR_MAX)
#define PREINCSTR(ptr) (ptr += CLEN(ptr))
#define POSTINCSTR(ptr) (___tmp_ptr=(char *)ptr,ptr += CLEN(ptr),___tmp_ptr)

int lastchar OF((ZCONST char *ptr));

#define MBSCHR(str,c) (char *)zmbschr((ZCONST unsigned char *)(str), c)
#define MBSRCHR(str,c) (char *)zmbsrchr((ZCONST unsigned char *)(str), (c))
#define SETLOCALE(category, locale) setlocale(category, locale)

#define INCSTR(ptr) PREINCSTR(ptr)


/* System independent replacement for "struct utimbuf", which is missing
 * in many older OS environments.
 */
typedef struct ztimbuf {
    time_t actime;              /* new access time */
    time_t modtime;             /* new modification time */
} ztimbuf;

/* This macro round a time_t value to the OS specific resolution */
#define ROUNDED_TIME(time)   (time)

typedef ulg                z_uint4;

#define Z_UINT4_DEFINED
#define FOPW_TMP FOPW

/* Open the old zip file in exclusive mode if possible (to avoid adding
 * zip file to itself).
 */
#define FOPR_EX FOPR


/* MSDOS file or directory attributes */
#define MSDOS_HIDDEN_ATTR 0x02
#define MSDOS_DIR_ATTR 0x10


/* Define this symbol if your target allows access to unaligned data.
 * This is not mandatory, just a speed optimization. The compressed
 * output is strictly identical.
 */
#define UNALIGNED_OK
#define CBSZ 16384
#define ZBSZ 16384

#define SBSZ CBSZ     /* copy buf size for STORED entries, see zipup() */

#undef huge
#undef far
#undef near
#define huge
#define far
#define near
#define nearmalloc malloc
#define nearfree free
#define farmalloc malloc
#define farfree free

#define Far far


/* LARGE_FILE_SUPPORT
 *
 * Types are in osdep.h for each port
 *
 * LARGE_FILE_SUPPORT and ZIP64_SUPPORT are automatically
 * set in osdep.h (for some ports) based on the port and compiler.
 *
 * Function prototypes are below as OF is defined earlier in this file
 * but after osdep.h is included.  In the future ANSI prototype
 * support may be required and the OF define may then go away allowing
 * the function defines to be in the port osdep.h.
 *
 * E. Gordon 9/21/2003
 * Updated 7/24/04 EG
 */
  /* 64-bit Large File Support */

  /* Arguments for all functions are assumed to match the actual
     arguments of the various port calls.  As such only the
     function names are mapped below. */

/* ---------------------------- */

      /* 64-bit stat functions */
#define zstat _stati64
#define zwfstat _fstati64
#define zwstat _wstati64
#define zw_stat struct _stati64
#define zfstat _fstati64
#define zlstat lstat

/* 64-bit fseeko */
/* function in win32.c */
int zfseeko OF((FILE *, zoff_t, int));

/* 64-bit ftello */
/* function in win32.c */
zoff_t zftello OF((FILE *));

/* 64-bit fopen */
#define zfopen fopen
#define zfdopen fdopen

#define LSTAT      SSTAT
#define LSSTAT     SSTAT
#define LSSTATW  SSTATW

/*---------------------------------------------------------------------*/


/* 2004-12-01 SMS.
 * Added fancy zofft() macros, et c.
 */

/* Default fzofft() format selection.
 * Modified 2004-12-27 EG
 */

#define FZOFFT_FMT      ZOFF_T_FORMAT_SIZE_PREFIX /* printf for zoff_t values */
#define FZOFFT_HEX_WID_VALUE     "16"  /* width of 64-bit hex values */
#define FZOFFT_HEX_WID ((char *) -1)
#define FZOFFT_HEX_DOT_WID ((char *) -2)


/* The following default definition of the second input for the crypthead()
 * random seed computation can be used on most systems (all those that
 * supply a UNIX compatible getpid() function).
 */
#ifdef ZCRYPT_INTERNAL
#  ifndef ZCR_SEED2
#    define ZCR_SEED2     (unsigned) getpid()   /* use PID as seed pattern */
#  endif
#endif /* ZCRYPT_INTERNAL */

/* The following OS codes are defined in pkzip appnote.txt */
#ifdef AMIGA
#  define OS_CODE  0x100
#endif
#ifdef VMS
#  define OS_CODE  0x200
#endif
/* unix    3 */
#ifdef VM_CMS
#  define OS_CODE  0x400
#endif
#ifdef ATARI
#  define OS_CODE  0x500
#endif
#ifdef OS2
#  define OS_CODE  0x600
#endif
#ifdef MACOS
#  define OS_CODE  0x700
#endif
/* z system 8 */
/* cp/m     9 */
#ifdef TOPS20
#  define OS_CODE  0xa00
#endif
#ifdef WIN32
#  define OS_CODE  0xb00
#endif
#ifdef QDOS
#  define OS_CODE  0xc00
#endif
#ifdef RISCOS
#  define OS_CODE  0xd00
#endif
#ifdef VFAT
#  define OS_CODE  0xe00
#endif
#ifdef MVS
#  define OS_CODE  0xf00
#endif
#ifdef __BEOS__
#  define OS_CODE  0x1000
#endif
#ifdef TANDEM
#  define OS_CODE  0x1100
#endif
#ifdef THEOS
#  define OS_CODE  0x1200
#endif
/* Yes, there is a gap here. */
#ifdef __ATHEOS__
#  define OS_CODE  0x1E00
#endif

#define NUM_HOSTS 31
/* Number of operating systems. Should be updated when new ports are made */

#if defined(DOS) && !defined(OS_CODE)
#  define OS_CODE  0x000
#endif

#ifndef OS_CODE
#  define OS_CODE  0x300  /* assume Unix */
#endif

/* can't use "return 0" from main() on VMS */
#ifndef EXIT
#  define EXIT  exit
#endif
#ifndef RETURN
#  define RETURN return
#endif

#ifndef ZIPERR
#  define ZIPERR ziperr
#endif

#if (defined(USE_ZLIB) && defined(MY_ZCALLOC))
   /* special zcalloc function is not needed when linked against zlib */
#  undef MY_ZCALLOC
#endif

#if (!defined(USE_ZLIB) && !defined(MY_ZCALLOC))
   /* Any system without a special calloc function */
#  define zcalloc(items,size) \
          (zvoid far *)calloc((unsigned)(items), (unsigned)(size))
#  define zcfree    free
#endif /* !USE_ZLIB && !MY_ZCALLOC */

/* end of tailor.h */
