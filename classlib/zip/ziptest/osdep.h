/*
  win32/osdep.h

  Copyright (c) 1990-2008 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2007-Mar-4 or later
  (the contents of which are also included in zip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/

/* Automatic setting of the common Microsoft C idenfifier MSC.
 * NOTE: Watcom also defines M_I*86 !
 */

#if defined(__WATCOMC__) && defined(__386__)
#  define WATCOMC_386
#endif

/* enable multibyte character set support by default */
#define _MBCS

/* Get types and stat */
#include <sys/types.h>
#include <sys/stat.h>
#include <io.h>

#define MSDOS

#define USE_CASE_MAP
#define PROCNAME(n) (action == ADD || action == UPDATE ? wild(n) : \
                     procname(n, filter_match_case))
#define BROKEN_FSEEK
#define HAVE_FSEEKABLE


/* popen
 *
 * On Win32 must map to _popen() and _pclose()
 */
#define popen _popen
#define pclose _pclose

/* WIN32_OEM
 *
 * This enables storing paths in archives on WIN32 in OEM format
 * which is more work but seems the standard now.  It also enables
 * converting paths in read DOS archives from assumed OEM to ANSI.
 */
#define WIN32_OEM

/* Large File Support
 *
 *  If this is set it is assumed that the port
 *  supports 64-bit file calls.  The types are
 *  defined here.  Any local implementations are
 *  in Win32.c and the prototypes for the calls are
 *  in tailor.h.  Note that a port must support
 *  these calls fully or should not set
 *  LARGE_FILE_SUPPORT.
 */

/* Note also that ZOFF_T_FORMAT_SIZE_PREFIX has to be defined here
   or tailor.h will define defaults */

/* If port has LARGE_FILE_SUPPORT then define here
   to make large file support automatic unless overridden */


    /* MS C and VC */
#define LARGE_FILE_SUPPORT

    /* base types for file offsets and file sizes */
typedef __int64             zoff_t;
typedef unsigned __int64    uzoff_t;

    /* 64-bit stat struct */
typedef struct _stati64 z_stat;

    /* printf format size prefix for zoff_t values */
#define ZOFF_T_FORMAT_SIZE_PREFIX "ll"

/* Automatically set ZIP64_SUPPORT if supported */

/* MS C and VC */
#define ZIP64_SUPPORT

#define zchar char


/* File operations--use "b" for binary if allowed or fixed length 512 on VMS
 *                  use "S" for sequential access on NT to prevent the NT
 *                  file cache eating up memory with large .zip files
 */
#define FOPR "rb"
#define FOPM "r+b"
#define FOPW "wbS"

#define NT_TZBUG_WORKAROUND
#define USE_EF_UT_TIME

#define NTSD_EAS

#define ZP_NEED_MEMCOMPR

/* Enable use of optimized x86 assembler version of longest_match() for
   MSDOS, WIN32 and OS2 per default.  */
#define ASMV

/* Enable use of optimized x86 assembler version of crc32() for
   MSDOS, WIN32 and OS2 per default.  */
#define ASM_CRC

#define NO_UNISTD_H

/* Microsoft C requires additional attributes attached to all RTL function
 * declarations when linking against the CRTL dll.
 */
#define IZ_IMP

/* WIN32 runs solely on little-endian processors; enable support
 * for the 32-bit optimized CRC-32 C code by default.
 */
#define IZ_CRC_LE_OPTIMIZ

/* the following definitions are considered as "obsolete" by Microsoft and
 * might be missing in some versions of <windows.h>
 */
#define AnsiToOem CharToOemA
#define OemToAnsi OemToCharA

   /* "real" native WIN32 compilers use ANSI coded strings in C RTL calls */
#define CRTL_CP_IS_ISO

   /* C RTL's file system support assumes ANSI coded strings */
#define ISO_TO_INTERN(src, dst)  {if ((src) != (dst)) strcpy((dst), (src));}
#define OEM_TO_INTERN(src, dst)  OemToAnsi(src, dst)
#define INTERN_TO_ISO(src, dst)  {if ((src) != (dst)) strcpy((dst), (src));}
#define INTERN_TO_OEM(src, dst)  AnsiToOem(src, dst)
#define _OEM_INTERN(str1) OEM_TO_INTERN(str1, str1)
#define _ISO_INTERN(str1) {;}
#define _INTERN_OEM(str1) INTERN_TO_OEM(str1, str1)
#define _INTERN_ISO(str1) {;}

/* The following "OEM vs. ISO Zip entry names" code has been copied from UnZip.
 * It should be applicable to the generic Zip code. However, currently only
 * the Win32 port of Zip supplies the required charset conversion functions.
 * (The Win32 port uses conversion functions supplied by the OS.)
 */
/* Convert filename (and file comment string) into "internal" charset.
 * This macro assumes that Zip entry filenames are coded in OEM (IBM DOS)
 * codepage when made on
 *  -> DOS (this includes 16-bit Windows 3.1)  (FS_FAT_)
 *  -> OS/2                                    (FS_HPFS_)
 *  -> Win95/WinNT with Nico Mak's WinZip      (FS_NTFS_ && hostver == "5.0")
 * EXCEPTIONS:
 *  PKZIP for Windows 2.5, 2.6, and 4.0 flag their entries as "FS_FAT_", but
 *  the filename stored in the local header is coded in Windows ANSI (CP 1252
 *  resp. ISO 8859-1 on US and western Europe locale settings).
 *  Likewise, PKZIP for UNIX 2.51 flags its entries as "FS_FAT_", but the
 *  filenames stored in BOTH the local and the central header are coded
 *  in the local system's codepage (usually ANSI codings like ISO 8859-1,
 *  but could also be UTF-8 on "modern" setups...).
 *
 * All other ports are assumed to code zip entry filenames in ISO (8859-1
 * on "Western" localisations).
 */
#define FS_FAT_           0    /* filesystem used by MS-DOS, OS/2, Win32 */
#define FS_HPFS_          6    /* filesystem used by OS/2 (and NT 3.x) */
#define FS_NTFS_          11   /* filesystem used by Windows NT */

#define Ext_ASCII_TO_Native(string, hostnum, hostver, isuxatt, islochdr) \
    if (((hostnum) == FS_FAT_ && \
         !(((islochdr) || (isuxatt)) && \
           ((hostver) == 25 || (hostver) == 26 || (hostver) == 40))) || \
        (hostnum) == FS_HPFS_ || \
        ((hostnum) == FS_NTFS_ && (hostver) == 50)) { \
        _OEM_INTERN((string)); \
    } else { \
        _ISO_INTERN((string)); \
    }

#include <stdlib.h>
#include <mbstring.h>

#define MATCH dosmatch          /* use DOS style wildcard matching */

#define MATCHW dosmatchw


/* Up to now, all versions of Microsoft C runtime libraries lack the support
 * for customized (non-US) switching rules between daylight saving time and
 * standard time in the TZ environment variable string.
 * But non-US timezone rules are correctly supported when timezone information
 * is read from the OS system settings in the Win32 registry.
 * The following work-around deletes any TZ environment setting from
 * the process environment.  This results in a fallback of the RTL time
 * handling code to the (correctly interpretable) OS system settings, read
 * from the registry.
 */
#   define iz_w32_prepareTZenv()

/* This patch of stat() is useful for at least three compilers.  It is   */
/* difficult to take a stat() of a root directory under Windows95, so  */
/* zstat_zipwin32() detects that case and fills in suitable values.    */
#ifndef __RSXNT__
#  ifndef W32_STATROOT_FIX
#    define W32_STATROOT_FIX
#  endif
#endif /* !__RSXNT__ */

#if (defined(NT_TZBUG_WORKAROUND) || defined(W32_STATROOT_FIX))
#  define W32_STAT_BANDAID
#  ifdef LARGE_FILE_SUPPORT         /* E. Gordon 9/12/03 */
   int zstat_zipwin32(const char *path, z_stat *buf);
#  else
   int zstat_zipwin32(const char *path, struct stat *buf);
#  endif
#  ifdef UNICODE_SUPPORT
#   ifdef LARGE_FILE_SUPPORT
     int zstat_zipwin32w(const wchar_t *pathw, struct _stati64 *buf);
#   else
     int zstat_zipwin32w(const wchar_t *pathw, struct _stat *buf);
#   endif
#  endif
#  ifdef SSTAT
#    undef SSTAT
#  endif
#  define SSTAT zstat_zipwin32
#  ifdef UNICODE_SUPPORT
#    define SSTATW zstat_zipwin32w
#  endif
#endif /* NT_TZBUG_WORKAROUND || W32_STATROOT_FIX */

int getch_win32(void);

#ifdef __GNUC__
# define IZ_PACKED      __attribute__((packed))
#else
# define IZ_PACKED
#endif

/* for some (all ?) versions of IBM C Set/2 and IBM C Set++ */
#ifndef S_IFMT
#  define S_IFMT 0xF000
#endif /* !S_IFMT */

#ifdef __WATCOMC__
#  include <stdio.h>    /* PATH_MAX is defined here */
#  define NO_MKTEMP

/* Get asm routines to link properly without using "__cdecl": */
#  ifdef __386__
#    ifdef ASMV
#      pragma aux match_init    "_*" parm caller [] modify []
#      pragma aux longest_match "_*" parm caller [] value [eax] \
                                      modify [eax ecx edx]
#    endif
#    if defined(ASM_CRC) && !defined(USE_ZLIB)
#      pragma aux crc32         "_*" parm caller [] value [eax] modify [eax]
#      pragma aux get_crc_table "_*" parm caller [] value [eax] \
                                      modify [eax ecx edx]
#    endif /* ASM_CRC && !USE_ZLIB */
#  endif /* __386__ */
   /* Watcom C (like the other Win32 C compiler systems) does not support
    * symlinks on Win32, but defines the S_IFLNK symbol nevertheless.
    * However, the existence of this symbol is used as "symlinks supported"
    * indicator in the generic Zip code (see tailor.h). So, for a simple
    * work-around, this symbol is undefined here. */
#  ifdef S_IFLNK
#    undef S_IFLNK
#  endif
#  ifdef UNICODE_SUPPORT
     /* Watcom C does not supply wide-char definitions in the "standard"
      * headers like MSC; so we have to pull in a wchar-specific header.
      */
#    include <wchar.h>
#  endif
#endif /* __WATCOMC__ */
