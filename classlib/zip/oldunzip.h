#define DIR_BLKSIZ 16384   /* use more memory, to reduce long-range seeks */
/*---------------------------------------------------------------------------

  unzip.h (new)

  Copyright (c) 1990-2009 Info-ZIP.  All rights reserved.

  This header file contains the public macros and typedefs required by
  both the UnZip sources and by any application using the UnZip API.  If
  UNZIP_INTERNAL is defined, it includes unzpriv.h (containing includes,
  prototypes and extern variables used by the actual UnZip sources).

  ---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------
This is version 2009-Jan-02 of the Info-ZIP license.
The definitive version of this document should be available at
ftp://ftp.info-zip.org/pub/infozip/license.html indefinitely and
a copy at http://www.info-zip.org/pub/infozip/license.html.


Copyright (c) 1990-2009 Info-ZIP.  All rights reserved.

For the purposes of this copyright and license, "Info-ZIP" is defined as
the following set of individuals:

   Mark Adler, John Bush, Karl Davis, Harald Denker, Jean-Michel Dubois,
   Jean-loup Gailly, Hunter Goatley, Ed Gordon, Ian Gorman, Chris Herborth,
   Dirk Haase, Greg Hartwig, Robert Heath, Jonathan Hudson, Paul Kienitz,
   David Kirschbaum, Johnny Lee, Onno van der Linden, Igor Mandrichenko,
   Steve P. Miller, Sergio Monesi, Keith Owens, George Petrov, Greg Roelofs,
   Kai Uwe Rommel, Steve Salisbury, Dave Smith, Steven M. Schweda,
   Christian Spieler, Cosmin Truta, Antoine Verheijen, Paul von Behren,
   Rich Wales, Mike White.

This software is provided "as is," without warranty of any kind, express
or implied.  In no event shall Info-ZIP or its contributors be held liable
for any direct, indirect, incidental, special or consequential damages
arising out of the use of or inability to use this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the above disclaimer and the following restrictions:

    1. Redistributions of source code (in whole or in part) must retain
       the above copyright notice, definition, disclaimer, and this list
       of conditions.

    2. Redistributions in binary form (compiled executables and libraries)
       must reproduce the above copyright notice, definition, disclaimer,
       and this list of conditions in documentation and/or other materials
       provided with the distribution.  Additional documentation is not needed
       for executables where a command line license option provides these and
       a note regarding this option is in the executable's startup banner.  The
       sole exception to this condition is redistribution of a standard
       UnZipSFX binary (including SFXWiz) as part of a self-extracting archive;
       that is permitted without inclusion of this license, as long as the
       normal SFX banner has not been removed from the binary or disabled.

    3. Altered versions--including, but not limited to, ports to new operating
       systems, existing ports with new graphical interfaces, versions with
       modified or added functionality, and dynamic, shared, or static library
       versions not from Info-ZIP--must be plainly marked as sunsigned char and must not
       be misrepresented as being the original source or, if binaries,
       compiled from the original source.  Sunsigned char altered versions also must not
       be misrepresented as being Info-ZIP releases--including, but not
       limited to, labeling of the altered versions with the names "Info-ZIP"
       (or any variation thereof, including, but not limited to, different
       capitalizations), "Pocket UnZip," "WiZ" or "MacZip" without the
       explicit permission of Info-ZIP.  Sunsigned char altered versions are further
       prohibited from misrepresentative use of the Zip-Bugs or Info-ZIP
       e-mail addresses or the Info-ZIP URL(s), sunsigned char as to imply Info-ZIP
       will provide support for the altered versions.

    4. Info-ZIP retains the right to use the names "Info-ZIP," "Zip," "UnZip,"
       "UnZipSFX," "WiZ," "Pocket UnZip," "Pocket Zip," and "MacZip" for its
       own source and binary releases.
  ---------------------------------------------------------------------------*/

#ifndef __unzip_h   /* prevent multiple inclusions */
#define __unzip_h

#include "unzip.h"

extern TUnzip UnzipClass;

#define Trace  UnzipClass.Trace
#define Info   UnzipClass.Info

/*
#define Info(buf,flag,sprf_arg) \
      (*G.message)((void *)&G, (unsigned char *)(buf), (unsigned long)sprintf sprf_arg, (flag))
*/

/*---------------------------------------------------------------------------
    Predefined, machine-specific macros.
  ---------------------------------------------------------------------------*/

/* use prototypes and ANSI libraries if __STDC__, or MS-DOS, or OS/2, or Win32,
 * or IBM C Set/2, or Borland C, or Watcom C, or GNU gcc (emx or Cygwin),
 * or Macintosh, or Sequent, or Atari, or IBM RS/6000, or Silicon Graphics,
 * or Convex?, or AtheOS, or BeOS.
 */

#    define PROTO
#    define MODERN

/*---------------------------------------------------------------------------
    Grab system-dependent definition of EXPENTRY for prototypes below.
  ---------------------------------------------------------------------------*/

#ifdef __cplusplus
extern "C" {
#endif

/*---------------------------------------------------------------------------
    Public typedefs.
  ---------------------------------------------------------------------------*/

/* InputFn is not yet used and is likely to change: */
   typedef int   ( MsgFn)     (void *pG, unsigned char *buf, unsigned long size, int flag);
   typedef int   ( InputFn)   (void *pG, unsigned char *buf, int *size, int flag);
   typedef void  ( PauseFn)   (void *pG, const char *prompt, int flag);
   typedef int   ( PasswdFn)  (void *pG, int *rcnt, char *pwbuf,
                                     int size, const char *zfn,
                                     const char *efn);
   typedef int   ( StatCBFn)  (void *pG, int fnflag, const char *zfn,
                                     const char *efn, const void *details);
   typedef void  ( UsrIniFn)  (void);

typedef struct _UzpBuffer {    /* rxstr */
    unsigned long   strlength;           /* length of string */
    char  *strptr;             /* pointer to string */
} UzpBuffer;

typedef struct _UzpInit {
    unsigned long structlen;             /* length of the struct being passed */

    /* GRR: can we assume that each of these is a 32-bit pointer?  if not,
     * does it matter? add "far" keyword to make sure? */
    MsgFn *msgfn;
    InputFn *inputfn;
    PauseFn *pausefn;
    UsrIniFn *userfn;          /* user init function to be called after */
                               /*  globals constructed and initialized */

    /* pointer to program's environment area or something? */
    /* hooks for performance testing? */
    /* hooks for extra unzip -v output? (detect CPU or other hardware?) */
    /* anything else?  let me (Greg) know... */
} UzpInit;

typedef struct _UzpCB {
    unsigned long structlen;             /* length of the struct being passed */
    /* GRR: can we assume that each of these is a 32-bit pointer?  if not,
     * does it matter? add "far" keyword to make sure? */
    MsgFn *msgfn;
    InputFn *inputfn;
    PauseFn *pausefn;
    PasswdFn *passwdfn;
    StatCBFn *statrepfn;
} UzpCB;

/* the collection of general UnZip option flags and option arguments */
typedef struct _UzpOpts {
    char *exdir;        /* pointer to extraction root directory (-d option) */
    char *pwdarg;       /* pointer to command-line password (-P option) */
    int zipinfo_mode;   /* behave like ZipInfo or like normal UnZip? */
    int aflag;          /* -a: do ASCII-EBCDIC and/or end-of-line translation */
    int cflag;          /* -c: output to stdout */
    int C_flag;         /* -C: match filenames case-insensitively */
    int D_flag;         /* -D: don't restore directory (-DD: any) timestamps */
    int fflag;          /* -f: "freshen" (extract only newer files) */
    int hflag;          /* -h: header line (zipinfo) */
    int jflag;          /* -j: junk pathnames (unzip) */
    int lflag;          /* -12slmv: listing format (zipinfo) */
    int L_flag;         /* -L: convert filenames from some OSes to lowercase */
    int overwrite_none; /* -n: never overwrite files (no prompting) */
    int overwrite_all;  /* -o: OK to overwrite files without prompting */
    int qflag;          /* -q: produce a lot less output */
    int tflag;          /* -t: test (unzip) or totals line (zipinfo) */
    int T_flag;         /* -T: timestamps (unzip) or dec. time fmt (zipinfo) */
    int uflag;          /* -u: "update" (extract only newer/brand-new files) */
    int vflag;          /* -v: (verbosely) list directory */
    int V_flag;         /* -V: don't strip VMS version numbers */
    int W_flag;         /* -W: wildcard '*' won't match '/' dir separator */
    int zflag;          /* -z: display the zipfile comment (only, for unzip) */
    int ddotflag;       /* -:: don't skip over "../" path elements */
} UzpOpts;

/* intended to be a private struct: */
typedef struct _ver {
    unsigned char major;              /* e.g., integer 5 */
    unsigned char minor;              /* e.g., 2 */
    unsigned char patchlevel;         /* e.g., 0 */
    unsigned char not_used;
} _version_type;

typedef struct _UzpVer {
    unsigned long structlen;            /* length of the struct being passed */
    unsigned long flag;                 /* bit 0: is_beta   bit 1: uses_zlib */
    const char *betalevel;   /* e.g. "g BETA" or "" */
    const char *date;        /* e.g. "9 Oct 08" (beta) or "9 October 2008" */
    const char *zlib_version;/* e.g. "1.2.3" or NULL */
    _version_type unzip;      /* current UnZip version */
    _version_type zipinfo;    /* current ZipInfo version */
    _version_type os2dll;     /* OS2DLL version (retained for compatibility */
    _version_type windll;     /* WinDLL version (retained for compatibility */
    _version_type dllapimin;  /* last incompatible change of library API */
} UzpVer;

/* for Visual BASIC access to Windows DLLs: */
typedef struct _UzpVer2 {
    unsigned long structlen;            /* length of the struct being passed */
    unsigned long flag;                 /* bit 0: is_beta   bit 1: uses_zlib */
    char betalevel[10];       /* e.g. "g BETA" or "" */
    char date[20];            /* e.g. "9 Oct 08" (beta) or "9 October 2008" */
    char zlib_version[10];    /* e.g. "1.2.3" or NULL */
    _version_type unzip;      /* current UnZip version */
    _version_type zipinfo;    /* current ZipInfo version */
    _version_type os2dll;     /* OS2DLL version (retained for compatibility */
    _version_type windll;     /* WinDLL version (retained for compatibility */
    _version_type dllapimin;  /* last incompatible change of library API */
} UzpVer2;


typedef struct _Uzp_Siz64 {
    unsigned long lo32;
    unsigned long hi32;
} Uzp_Siz64;

typedef struct _Uzp_cdir_Rec {
    unsigned char version_made_by[2];
    unsigned char version_needed_to_extract[2];
    unsigned short general_purpose_bit_flag;
    unsigned short compression_method;
    unsigned long last_mod_dos_datetime;
    unsigned long crc32;
    Uzp_Siz64 csize;
    Uzp_Siz64 ucsize;
    unsigned short filename_length;
    unsigned short extra_field_length;
    unsigned short file_comment_length;
    unsigned short disk_number_start;
    unsigned short internal_file_attributes;
    unsigned long external_file_attributes;
    Uzp_Siz64 relative_offset_local_header;
} Uzp_cdir_Rec;


#define UZPINIT_LEN   sizeof(UzpInit)
#define UZPVER_LEN    sizeof(UzpVer)
#define cbList(func)  int (*  func)(char *filename, Uzp_cdir_Rec *crec)


/*---------------------------------------------------------------------------
    Return (and exit) values of the public UnZip API functions.
  ---------------------------------------------------------------------------*/

#define IZ_CTRLC          80   /* user hit ^C to terminate */
#define IZ_UNSUP          81   /* no files found: all unsup. compr/encrypt. */
#define IZ_BADPWD         82   /* no files found: all had bad password */
#define IZ_ERRBF          83   /* big-file archive, small-file program */

/* return codes of password fetches (negative = user abort; positive = error) */
#define IZ_PW_ENTERED      0   /* got some password string; use/try it */
#define IZ_PW_CANCEL      -1   /* no password available (for this entry) */
#define IZ_PW_CANCELALL   -2   /* no password, skip any further pwd. request */
#define IZ_PW_ERROR        5   /* = PK_MEM2 : failure (no mem, no tty, ...) */

/* flag values for status callback function */
#define UZ_ST_START_EXTRACT     1       /* no details */
#define UZ_ST_IN_PROGRESS       2       /* no details */
#define UZ_ST_FINISH_MEMBER     3       /* 'details': extracted size */

/* return values of status callback function */
#define UZ_ST_CONTINUE          0
#define UZ_ST_BREAK             1


/*---------------------------------------------------------------------------
    Prototypes for public UnZip API (DLL) functions.
  ---------------------------------------------------------------------------*/

#define  UzpMatch match

int       UzpMain            (int argc, char **argv);
int       UzpAltMain         (int argc, char **argv, UzpInit *init);
const UzpVer *  UzpVersion  (void);
void      UzpFreeMemBuffer   (UzpBuffer *retstr);
int       UzpUnzipToMemory   (char *zip, char *file, UzpOpts *optflgs,
                                       UzpCB *UsrFunc, UzpBuffer *retstr);
int       UzpGrep            (char *archive, char *file,
                                       char *pattern, int cmd, int SkipBin,
                                       UzpCB *UsrFunc);

unsigned  UzpVersion2        (UzpVer2 *version);
int       UzpValidate        (char *archive, int AllCodes);


/* default I/O functions (can be swapped out via UzpAltMain() entry point): */

int       UzpMessageNull   (void *pG, unsigned char *buf, unsigned long size, int flag);
int       UzpPassword      (void *pG, int *rcnt, char *pwbuf,
                                     int size, const char *zfn,
                                     const char *efn);

#ifdef __cplusplus
}
#endif


/*---------------------------------------------------------------------------
    Remaining private stuff for UnZip compilation.
  ---------------------------------------------------------------------------*/

#include "rdos.h"

#include <sys/types.h>          /* off_t, time_t, dev_t, ... */
#include <sys/stat.h>
#include <io.h>                 /* read(), open(), etc. */
#include <time.h>
#include <memory.h>
#include <fcntl.h>
#include <stdio.h>
#include <ctype.h>       /* skip for VMS, to use tolower() function? */
#include <errno.h>       /* used in mapname() */
#include <string.h>    /* strcpy, strcmp, memcpy, strchr/strrchr, etc. */
#include <limits.h>    /* MAX/MIN constant symbols for system types... */

#include <stddef.h>
#include <stdlib.h>  /* standard library prototypes, malloc(), etc. */

#include "zlib.h"

#define DIR_END       '\\'      /* OS uses '\\' as directory separator */
#define DIR_END2      '/'       /* also check for '/' (RTL may convert) */
#define lenEOL        2
#define PutNativeEOL  {*q++ = CR; *q++ = LF;}

/* The following compiler systems provide or use a runtime library with a
 * locale-aware isprint() implementation.  For these systems, the "enhanced"
 * unprintable charcode detection in fnfilter() gets enabled.
 */
/* RDOS runs solely on little-endian processors; enable support
 * for the 32-bit optimized CRC-32 C code by default.
 */

#define SCREENWIDTH 80
#define SCREENSIZE(scrrows, scrcols)  screensize(scrrows, scrcols)
int screensize(int *tt_rows, int *tt_cols);

/* on the DOS or NT console screen, line-wraps are always enabled */
#define SCREENLWRAP 1
#define TABSIZE 4

  /* stat struct */

#  define FZOFFT_FMT "l"
#  define FZOFFT_HEX_WID_VALUE "8"


#  define SHORTHDRSTATS "%9lu  %02u%c%02u%c%02u %02u:%02u  %c"
#  define SHORTFILETRAILER " --------                   -------\n%9lu                   %9lu file%s\n"


typedef size_t extent;


/*************/
/*  Defines  */
/*************/

#define UNZIP_VERSION   20   /* compatible with PKUNZIP 2.0 */
#define VMS_UNZIP_VERSION 42   /* if OS-needed-to-extract is VMS:  can do */

#define DATE_FORMAT   DF_YMD  /* defaults to invariant ISO-style */
#define DATE_SEPCHAR  '-'

/* defaults that we hope will take care of most machines in the future */

#define MSG_STDERR(f)  (f & 1)        /* bit 0:  0 = stdout, 1 = stderr */
#define MSG_INFO(f)    ((f & 6) == 0) /* bits 1 and 2:  0 = info */
#define MSG_WARN(f)    ((f & 6) == 2) /* bits 1 and 2:  1 = warning */
#define MSG_ERROR(f)   ((f & 6) == 4) /* bits 1 and 2:  2 = error */
#define MSG_FATAL(f)   ((f & 6) == 6) /* bits 1 and 2:  (3 = fatal error) */
#define MSG_ZFN(f)     (f & 0x0008)   /* bit 3:  1 = print zipfile name */
#define MSG_FN(f)      (f & 0x0010)   /* bit 4:  1 = print filename */
#define MSG_LNEWLN(f)  (f & 0x0020)   /* bit 5:  1 = leading newline if !SOL */
#define MSG_TNEWLN(f)  (f & 0x0040)   /* bit 6:  1 = trailing newline if !SOL */
#define MSG_MNEWLN(f)  (f & 0x0080)   /* bit 7:  1 = trailing NL for prompts */
/* the following are subject to change */
#define MSG_NO_WGUI(f) (f & 0x0100)   /* bit 8:  1 = skip if Windows GUI */
#define MSG_NO_AGUI(f) (f & 0x0200)   /* bit 9:  1 = skip if Acorn GUI */
#define MSG_NO_DLL2(f) (f & 0x0400)   /* bit 10:  1 = skip if OS/2 DLL */
#define MSG_NO_NDLL(f) (f & 0x0800)   /* bit 11:  1 = skip if WIN32 DLL */
#define MSG_NO_WDLL(f) (f & 0x1000)   /* bit 12:  1 = skip if Windows DLL */

#define WSIZE   0x8000  /* window size--must be a power of two, and */
#define INBUFSIZ  8192  /* larger buffers for real OSes */

/* Logic for case of small memory, length of EOL > 1:  if OUTBUFSIZ == 2048,
 * OUTBUFSIZ>>1 == 1024 and OUTBUFSIZ>>7 == 16; therefore rawbuf is 1008 bytes
 * and transbuf 1040 bytes.  Have room for 32 extra EOL chars; 1008/32 == 31.5
 * chars/line, smaller than estimated 35-70 characters per line for C source
 * and normal text.  Hence difference is sufficient for most "average" files.
 * (Argument scales for larger OUTBUFSIZ.)
 */
#define OUTBUFSIZ (lenEOL*WSIZE) /* more efficient text conversion */
#define TRANSBUFSIZ (lenEOL*OUTBUFSIZ)
#define RAWBUFSIZ OUTBUFSIZ

/* File operations--use "b" for binary if allowed or fixed length 512 on VMS */

/*
 * buffer size required to hold the longest legal local filepath
 * (including the trailing '\0')
 */

#define TRUE      1   /* sort of obvious */
#define FALSE     0

#define S_ISDIR(m)  (((m) & S_IFMT) == S_IFDIR)
#define IS_VOLID(m)  ((m) & 0x08)

/***********************************/
/*  LARGE_FILE_SUPPORT             */
/***********************************/
/* This whole section lifted from Zip 3b tailor.h

 * Types are in OS dependent headers (eg, w32cfg.h)
 *
 * LARGE_FILE_SUPPORT and ZIP64_SUPPORT are automatically
 * set in OS dependent headers (for some ports) based on the port and compiler.
 *
 * Function prototypes are below as OF is defined earlier in this file
 * but after OS dependent header is included.
 *
 * E. Gordon 9/21/2003
 * Updated 1/28/2004
 * Lifted and placed here 6/7/2004 - Myles Bennett
 */
  /* No Large File Support */

/* Default fzofft() format selection. */


#define FZOFFT_HEX_WID ((char *) -1)
#define FZOFFT_HEX_DOT_WID ((char *) -2)

#define FZOFFT_NUM 4            /* Number of chambers. */
#define FZOFFT_LEN 24           /* Number of characters/chamber. */

#define S_TIME_T_MAX  ((time_t)(unsigned long)0x7fffffffL)
#define U_TIME_T_MAX  ((time_t)(unsigned long)0xffffffffL)
#define DOSTIME_2038_01_18 ((unsigned long)0x74320000L)

#define ZSUFX       ".zip"

#define CENTRAL_HDR_SIG   "\001\002"   /* the infamous "PK" signature bytes, */
#define LOCAL_HDR_SIG     "\003\004"   /*  w/o "PK" (so unzip executable not */
#define END_CENTRAL_SIG   "\005\006"   /*  mistaken for zipfile itself) */
#define EXTD_LOCAL_SIG    "\007\010"   /* [ASCII "\113" == EBCDIC "\080" ??] */

/** internal-only return codes **/
#define IZ_DIR            76   /* potential zipfile is a directory */
/* special return codes for mapname() */
#define MPN_OK            0      /* mapname successful */
#define MPN_INF_TRUNC    (1<<8)  /* caution - filename truncated */
#define MPN_INF_SKIP     (2<<8)  /* info  - skipped because nothing to do */
#define MPN_ERR_SKIP     (3<<8)  /* error - entry skipped */
#define MPN_ERR_TOOLONG  (4<<8)  /* error - path too long */
#define MPN_NOMEM        (10<<8) /* error - out of memory, file skipped */
#define MPN_CREATED_DIR  (16<<8) /* directory created: set time & permission */
#define MPN_VOL_LABEL    (17<<8) /* volume label, but can't set on hard disk */
#define MPN_INVALID      (99<<8) /* internal logic error, should never reach */
/* mask for internal mapname&checkdir return codes */
#define MPN_MASK          0x7F00
/* error code for extracting/testing extra field blocks */
#define IZ_EF_TRUNC       79   /* local extra field truncated (PKZIP'd) */


#define DOES_NOT_EXIST    -1   /* return values for check_for_newer() */
#define EXISTS_AND_OLDER  0
#define EXISTS_AND_NEWER  1

#define OVERWRT_QUERY     0    /* status values for G.overwrite_mode */
#define OVERWRT_ALWAYS    1
#define OVERWRT_NEVER     2

#define IS_OVERWRT_ALL    (G.overwrite_mode == OVERWRT_ALWAYS)
#define IS_OVERWRT_NONE   (G.overwrite_mode == OVERWRT_NEVER)

#define ROOT              0    /* checkdir() extract-to path:  called once */
#define INIT              1    /* allocate buildpath:  called once per member */
#define APPEND_DIR        2    /* append a dir comp.:  many times per member */
#define APPEND_NAME       3    /* append actual filename:  once per member */
#define GETPATH           4    /* retrieve the complete path and free it */
#define END               5    /* free root path prior to exiting program */

/* version_made_by codes (central dir):  make sure these */
/*  are not defined on their respective systems!! */
#define FS_FAT_           0    /* filesystem used by MS-DOS, OS/2, Win32 */
#define AMIGA_            1
#define VMS_              2
#define UNIX_             3
#define VM_CMS_           4
#define ATARI_            5    /* what if it's a minix filesystem? [cjh] */
#define FS_HPFS_          6    /* filesystem used by OS/2 (and NT 3.x) */
#define MAC_              7    /* HFS filesystem used by MacOS */
#define Z_SYSTEM_         8
#define CPM_              9
#define TOPS20_           10
#define FS_NTFS_          11   /* filesystem used by Windows NT */
#define QDOS_             12
#define ACORN_            13   /* Archimedes Acorn RISC OS */
#define FS_VFAT_          14   /* filesystem used by Windows 95, NT */
#define MVS_              15
#define BEOS_             16   /* hybrid POSIX/database filesystem */
#define TANDEM_           17   /* Tandem NSK */
#define THEOS_            18   /* THEOS */
#define MAC_OSX_          19   /* Mac OS/X (Darwin) */
#define ATHEOS_           30   /* AtheOS */
#define NUM_HOSTS         31   /* index of last system + 1 */
/* don't forget to update zipinfo.c appropiately if NUM_HOSTS changes! */

#define STORED            0    /* compression methods */
#define SHRUNK            1
#define REDUCED1          2
#define REDUCED2          3
#define REDUCED3          4
#define REDUCED4          5
#define IMPLODED          6
#define TOKENIZED         7
#define DEFLATED          8
#define ENHDEFLATED       9
#define DCLIMPLODED      10
#define BZIPPED          12
#define LZMAED           14
#define IBMTERSED        18
#define IBMLZ77ED        19
#define WAVPACKED        97
#define PPMDED           98
#define NUM_METHODS      17     /* number of known method IDs */
/* don't forget to update list.c (list_files()), extract.c and zipinfo.c
 * appropriately if NUM_METHODS changes */

/* (the PK-class error codes are public and have been moved into unzip.h) */

#define DF_MDY            0    /* date format 10/26/91 (USA only) */
#define DF_DMY            1    /* date format 26/10/91 (most of the world) */
#define DF_YMD            2    /* date format 91/10/26 (a few countries) */

/*---------------------------------------------------------------------------
    Extra-field block ID values and offset info.
  ---------------------------------------------------------------------------*/
/* extra-field ID values, all little-endian: */
#define EF_PKSZ64    0x0001    /* PKWARE's 64-bit filesize extensions */
#define EF_AV        0x0007    /* PKWARE's authenticity verification */
#define EF_EFS       0x0008    /* PKWARE's extended language encoding */
#define EF_OS2       0x0009    /* OS/2 extended attributes */
#define EF_PKW32     0x000a    /* PKWARE's Win95/98/WinNT filetimes */
#define EF_PKVMS     0x000c    /* PKWARE's VMS */
#define EF_PKUNIX    0x000d    /* PKWARE's Unix */
#define EF_PKFORK    0x000e    /* PKWARE's future stream/fork descriptors */
#define EF_PKPATCH   0x000f    /* PKWARE's patch descriptor */
#define EF_PKPKCS7   0x0014    /* PKWARE's PKCS#7 store for X.509 Certs */
#define EF_PKFX509   0x0015    /* PKWARE's file X.509 Cert&Signature ID */
#define EF_PKCX509   0x0016    /* PKWARE's central dir X.509 Cert ID */
#define EF_PKENCRHD  0x0017    /* PKWARE's Strong Encryption header */
#define EF_PKRMCTL   0x0018    /* PKWARE's Record Management Controls*/
#define EF_PKLSTCS7  0x0019    /* PKWARE's PKCS#7 Encr. Recipient Cert List */
#define EF_PKIBM     0x0065    /* PKWARE's IBM S/390 & AS/400 attributes */
#define EF_PKIBM2    0x0066    /* PKWARE's IBM S/390 & AS/400 compr. attribs */
#define EF_IZVMS     0x4d49    /* Info-ZIP's VMS ("IM") */
#define EF_IZUNIX    0x5855    /* Info-ZIP's first Unix[1] ("UX") */
#define EF_IZUNIX2   0x7855    /* Info-ZIP's second Unix[2] ("Ux") */
#define EF_IZUNIX3   0x7875    /* Info-ZIP's newest Unix[3] ("ux") */
#define EF_TIME      0x5455    /* universal timestamp ("UT") */
#define EF_UNIPATH   0x7075    /* Info-ZIP Unicode Path ("up") */
#define EF_UNICOMNT  0x6375    /* Info-ZIP Unicode Comment ("uc") */
#define EF_MAC3      0x334d    /* Info-ZIP's new Macintosh (= "M3") */
#define EF_JLMAC     0x07c8    /* Johnny Lee's old Macintosh (= 1992) */
#define EF_ZIPIT     0x2605    /* Thomas Brown's Macintosh (ZipIt) */
#define EF_ZIPIT2    0x2705    /* T. Brown's Mac (ZipIt) v 1.3.8 and newer ? */
#define EF_SMARTZIP  0x4d63    /* Mac SmartZip by Marco Bambini */
#define EF_VMCMS     0x4704    /* Info-ZIP's VM/CMS ("\004G") */
#define EF_MVS       0x470f    /* Info-ZIP's MVS ("\017G") */
#define EF_ACL       0x4c41    /* (OS/2) access control list ("AL") */
#define EF_NTSD      0x4453    /* NT security descriptor ("SD") */
#define EF_ATHEOS    0x7441    /* AtheOS ("At") */
#define EF_BEOS      0x6542    /* BeOS ("Be") */
#define EF_QDOS      0xfb4a    /* SMS/QDOS ("J\373") */
#define EF_AOSVS     0x5356    /* AOS/VS ("VS") */
#define EF_SPARK     0x4341    /* David Pilling's Acorn/SparkFS ("AC") */
#define EF_TANDEM    0x4154    /* Tandem NSK ("TA") */
#define EF_THEOS     0x6854    /* Jean-Michel Dubois' Theos "Th" */
#define EF_THEOSO    0x4854    /* old Theos port */
#define EF_MD5       0x4b46    /* Fred Kantor's MD5 ("FK") */
#define EF_ASIUNIX   0x756e    /* ASi's Unix ("nu") */

#define EB_HEADSIZE       4    /* length of extra field block header */
#define EB_ID             0    /* offset of block ID in header */
#define EB_LEN            2    /* offset of data length field in header */
#define EB_UCSIZE_P       0    /* offset of ucsize field in compr. data */
#define EB_CMPRHEADLEN    6    /* lenght of compression header */

#define EB_UX_MINLEN      8    /* minimal "UX" field contains atime, mtime */
#define EB_UX_FULLSIZE    12   /* full "UX" field (atime, mtime, uid, gid) */
#define EB_UX_ATIME       0    /* offset of atime in "UX" extra field data */
#define EB_UX_MTIME       4    /* offset of mtime in "UX" extra field data */
#define EB_UX_UID         8    /* byte offset of UID in "UX" field data */
#define EB_UX_GID         10   /* byte offset of GID in "UX" field data */

#define EB_UX2_MINLEN     4    /* minimal "Ux" field contains UID/GID */
#define EB_UX2_UID        0    /* byte offset of UID in "Ux" field data */
#define EB_UX2_GID        2    /* byte offset of GID in "Ux" field data */
#define EB_UX2_VALID      (1 << 8)      /* UID/GID present */

#define EB_UX3_MINLEN     7    /* minimal "ux" field size (2-byte UID/GID) */

#define EB_UT_MINLEN      1    /* minimal UT field contains Flags byte */
#define EB_UT_FLAGS       0    /* byte offset of Flags field */
#define EB_UT_TIME1       1    /* byte offset of 1st time value */
#define EB_UT_FL_MTIME    (1 << 0)      /* mtime present */
#define EB_UT_FL_ATIME    (1 << 1)      /* atime present */
#define EB_UT_FL_CTIME    (1 << 2)      /* ctime present */

#define EB_FLGS_OFFS      4    /* offset of flags area in generic compressed
                                  extra field blocks (BEOS, MAC, and others) */
#define EB_OS2_HLEN       4    /* size of OS2/ACL compressed data header */
#define EB_BEOS_HLEN      5    /* length of BeOS&AtheOS e.f attribute header */
#define EB_BE_FL_UNCMPR   0x01 /* "BeOS&AtheOS attribs uncompr." bit flag */
#define EB_MAC3_HLEN      14   /* length of Mac3 attribute block header */
#define EB_SMARTZIP_HLEN  64   /* fixed length of the SmartZip extra field */
#define EB_M3_FL_DATFRK   0x01 /* "this entry is data fork" flag */
#define EB_M3_FL_UNCMPR   0x04 /* "Mac3 attributes uncompressed" bit flag */
#define EB_M3_FL_TIME64   0x08 /* "Mac3 time fields are 64 bit wide" flag */
#define EB_M3_FL_NOUTC    0x10 /* "Mac3 timezone offset fields missing" flag */

#define EB_NTSD_C_LEN     4    /* length of central NT security data */
#define EB_NTSD_L_LEN     5    /* length of minimal local NT security data */
#define EB_NTSD_VERSION   4    /* offset of NTSD version byte */
#define EB_NTSD_MAX_VER   (0)  /* maximum version # we know how to handle */

#define EB_ASI_CRC32      0    /* offset of ASI Unix field's crc32 checksum */
#define EB_ASI_MODE       4    /* offset of ASI Unix permission mode field */

#define EB_IZVMS_HLEN     12   /* length of IZVMS attribute block header */
#define EB_IZVMS_FLGS     4    /* offset of compression type flag */
#define EB_IZVMS_UCSIZ    6    /* offset of ucsize field in IZVMS header */
#define EB_IZVMS_BCMASK   07   /* 3 bits for compression type */
#define EB_IZVMS_BCSTOR   0    /*  Stored */
#define EB_IZVMS_BC00     1    /*  0byte -> 0bit compression */
#define EB_IZVMS_BCDEFL   2    /*  Deflated */


/*---------------------------------------------------------------------------
    True sizes of the various headers (excluding their 4-byte signatures),
    as defined by PKWARE--so it is not likely that these will ever change.
    But if they do, make sure both these defines AND the typedefs below get
    updated accordingly.

    12/27/2006
    The Zip64 End Of Central Directory record is variable size and now
    comes in two flavors, version 1 and the new version 2 that supports
    central directory encryption.  We only use the old fields at the
    top of the Zip64 EOCDR, and this block is a fixed size still, but
    need to be aware of the stuff following.
  ---------------------------------------------------------------------------*/
#define LREC_SIZE    26   /* lengths of local file headers, central */
#define CREC_SIZE    42   /*  directory headers, end-of-central-dir */
#define ECREC_SIZE   18   /*  record, zip64 end-of-cent-dir locator */
#define ECLOC64_SIZE 16   /*  and zip64 end-of-central-dir record,  */
#define ECREC64_SIZE 52   /*  respectively                          */

#define LF     10        /* '\n' on ASCII machines; must be 10 due to EBCDIC */
#define CR     13        /* '\r' on ASCII machines; must be 13 due to EBCDIC */
#define CTRLZ  26        /* DOS & OS/2 EOF marker (used in fileio.c, vms.c) */

#define ENV_UNZIP       "UNZIP"          /* the standard names */
#define ENV_ZIPINFO     "ZIPINFO"
#define ENV_UNZIP2      "UNZIPOPT"     /* alternate names, for zip compat. */
#define ENV_ZIPINFO2    "ZIPINFOOPT"



/**************/
/*  Typedefs  */
/**************/

/* The following three user-defined unsigned integer types are used for
   holding zipfile entities (required widths without / with Zip64 support):
   a) sizes and offset of zipfile entries
      (4 bytes / 8 bytes)
   b) enumeration and counts of zipfile entries
      (2 bytes / 8 bytes)
      Remark: internally, we use 4 bytes for archive member counting in the
              No-Zip64 case, because UnZip supports more than 64k entries for
              classic Zip archives without Zip64 extensions.
   c) enumeration and counts of zipfile volumes of multivolume archives
      (2 bytes / 4 bytes)
 */
  typedef  unsigned long        zusz_t;     /* zipentry sizes & offsets */
  typedef  unsigned int         zucn_t;     /* archive entry counts */
  typedef  unsigned short       zuvl_t;     /* multivolume numbers */

#define MASK_ZUCN64            (~(zucn_t)0)
#define MASK_ZUCN16             ((zucn_t)0xFFFF)

#ifdef NO_UID_GID
#  ifdef UID_USHORT
     typedef unsigned short  uid_t;    /* TI SysV.3 */
     typedef unsigned short  gid_t;
#  else
     typedef unsigned int    uid_t;    /* SCO Xenix */
     typedef unsigned int    gid_t;
#  endif
#endif

typedef struct iztimes {
   time_t atime;             /* new access time */
   time_t mtime;             /* new modification time */
   time_t ctime;             /* used for creation time; NOT same as st_ctime */
} iztimes;

   typedef struct direntry {    /* head of system-specific struct holding */
       struct direntry *next;   /*  defered directory attributes info */
       char *fn;                /* filename of directory */
       char buf[1];             /* start of system-specific internal data */
   } direntry;


typedef struct VMStimbuf {
    char *revdate;    /* (both roughly correspond to Unix modtime/st_mtime) */
    char *credate;
} VMStimbuf;

/*---------------------------------------------------------------------------
    Zipfile work area declarations.
  ---------------------------------------------------------------------------*/

   union work {
     unsigned char *Slide;              /* explode(), inflate(), unreduce() */
   };

#define slide  G.area.Slide

#  define redirSlide G.area.Slide

/*---------------------------------------------------------------------------
    Zipfile layout declarations.  If these headers ever change, make sure the
    xxREC_SIZE defines (above) change with them!
  ---------------------------------------------------------------------------*/

   typedef unsigned char   ec_byte_rec[ ECREC_SIZE+4 ];
/*     define SIGNATURE                         0   space-holder only */
#      define NUMBER_THIS_DISK                  4
#      define NUM_DISK_WITH_START_CEN_DIR       6
#      define NUM_ENTRIES_CEN_DIR_THS_DISK      8
#      define TOTAL_ENTRIES_CENTRAL_DIR         10
#      define SIZE_CENTRAL_DIRECTORY            12
#      define OFFSET_START_CENTRAL_DIRECTORY    16
#      define ZIPFILE_COMMENT_LENGTH            20

   typedef unsigned char   ec_byte_loc64[ ECLOC64_SIZE+4 ];
#      define NUM_DISK_START_EOCDR64            4
#      define OFFSET_START_EOCDR64              8
#      define NUM_THIS_DISK_LOC64               16

   typedef unsigned char   ec_byte_rec64[ ECREC64_SIZE+4 ];
#      define ECREC64_LENGTH                    4
#      define EC_VERSION_MADE_BY_0              12
#      define EC_VERSION_NEEDED_0               14
#      define NUMBER_THIS_DSK_REC64             16
#      define NUM_DISK_START_CEN_DIR64          20
#      define NUM_ENTRIES_CEN_DIR_THS_DISK64    24
#      define TOTAL_ENTRIES_CENTRAL_DIR64       32
#      define SIZE_CENTRAL_DIRECTORY64          40
#      define OFFSET_START_CENTRAL_DIRECT64     48


   typedef struct end_central_dir_record {            /* END CENTRAL */
       zusz_t size_central_directory;
       zusz_t offset_start_central_directory;
       zucn_t num_entries_centrl_dir_ths_disk;
       zucn_t total_entries_central_dir;
       zuvl_t number_this_disk;
       zuvl_t num_disk_start_cdir;
       int have_ecr64;                  /* valid Zip64 ecdir-record exists */
       int is_zip64_archive;            /* Zip64 ecdir-record is mandatory */
       unsigned short zipfile_comment_length;
   } ecdir_rec;


typedef struct _APIDocStruct {
    char *compare;
    char *function;
    char *syntax;
    char *purpose;
} APIDocStruct;




/*************/
/*  Globals  */
/*************/

#include "globals.h"



/*************************/
/*  Function Prototypes  */
/*************************/

/*---------------------------------------------------------------------------
    Functions in unzip.c (initialization routines):
  ---------------------------------------------------------------------------*/

   int    MAIN                   OF((int argc, char **argv));
   int    unzip                  OF((int argc, char **argv));
   int    uz_opts                OF((int *pargc, char ***pargv));
   int    usage                  OF((int error));

/*---------------------------------------------------------------------------
    Functions in process.c (main driver routines):
  ---------------------------------------------------------------------------*/

int      process_zipfiles        OF(());
void     free_G_buffers          OF(());
/* static int    do_seekable     OF((int lastchance)); */
/* static int    find_ecrec      OF((long searchlen)); */
/* static int    process_central_comment OF(()); */
int      process_cdir_file_hdr   OF(());
unsigned ef_scan_for_izux        OF((const unsigned char *ef_buf, unsigned ef_len,
                                     int ef_is_c, unsigned long dos_mdatetime,
                                     iztimes *z_utim, unsigned long *z_uidgid));

/*---------------------------------------------------------------------------
    Functions in zipinfo.c (`zipinfo-style' listing routines):
  ---------------------------------------------------------------------------*/

int   zi_opts                    OF((int *pargc, char ***pargv));
void     zi_end_central          OF(());
int      zipinfo                 OF(());
/* static int      zi_long       OF((zusz_t *pEndprev)); */
/* static int      zi_short      OF(()); */
/* static char    *zi_time       OF((const unsigned long *datetimez,
                                     const time_t *modtimez, char *d_t_str));*/

/*---------------------------------------------------------------------------
    Functions in list.c (generic zipfile-listing routines):
  ---------------------------------------------------------------------------*/

int      ratio                   OF((zusz_t uc, zusz_t c));
void     fnprint                 OF(());

/*---------------------------------------------------------------------------
    Functions in fileio.c:
  ---------------------------------------------------------------------------*/

/* static int  disk_error     OF(()); */
void     handler              OF((int signal));
int      check_for_newer      OF((char *filename)); /* os2,vmcms,vms */
unsigned short      makeword             OF((const unsigned char *b));
unsigned long      makelong             OF((const unsigned char *sig));
zusz_t   makeint64            OF((const unsigned char *sig));
char    *fzofft               OF((long val,
                                  const char *pre, const char *post));
   char *str2iso              OF((char *dst, const char *src));
   char *str2oem              OF((char *dst, const char *src));
#ifdef ZMEM   /* MUST be ifdef'd because of conflicts with the standard def. */
   void *memset OF((register void *, register int, register unsigned int));
   int    memcmp OF((register const void*, register const void *,
                     register unsigned int));
   void *memcpy OF((register void *, register const void *,
                     register unsigned int));
#endif

/*---------------------------------------------------------------------------
    Functions in extract.c:
  ---------------------------------------------------------------------------*/

int    extract_or_test_files     OF(());
/* static int   store_info          OF((void)); */
/* static int   extract_or_test_member   OF(()); */
/* static int   TestExtraField   OF((unsigned char *ef, unsigned ef_len)); */
/* static int   test_OS2         OF((unsigned char *eb, unsigned eb_size)); */
/* static int   test_NT          OF((unsigned char *eb, unsigned eb_size)); */
unsigned find_compr_idx          OF((unsigned compr_methodnum));
int    memextract                OF((unsigned char *tgt, unsigned long tgtsize,
                                     const unsigned char *src, unsigned long srcsize));
int    memflush                  OF((const unsigned char *rawbuf, unsigned long size));
char  *fnfilter                  OF((const char *raw, unsigned char *space,
                                     extent size));

/*---------------------------------------------------------------------------
    Miscellaneous/shared functions:
  ---------------------------------------------------------------------------*/

Uz_Globs *globalsCtor    OF((void));                            /* globals.c */

int      envargs         OF((int *Pargc, char ***Pargv,
                             const char *envstr, const char *envstr2));
                                                                /* envargs.c */
void     mksargs         OF((int *argcp, char ***argvp));       /* envargs.c */

int      match           OF((const char *s, const char *p,
                             int ic));                   /* match.c */
int      iswild          OF((const char *p));                    /* match.c */

/* declarations of public CRC-32 functions have been moved into crc32.h
   (free_crc_table(), get_crc_table(), crc32())                      crc32.c */

void     version         OF(());                              /* local */
int      mapattr         OF(());                              /* local */
int      mapname         OF((int renamed));                /* local */
int      checkdir        OF((char *pathcomp, int flag));   /* local */
char    *do_wild         OF((const char *wildzipfn));     /* local */
char    *GetLoadPath     OF(());                              /* local */
int   defer_dir_attribs  OF((direntry **pd));           /* local */
int   set_direc_attribs  OF((direntry *d));             /* local */

char *getp(const char *m, char *p, int n);

/************/
/*  Macros  */
/************/

#define MAX(a,b)   ((a) > (b) ? (a) : (b))
#define MIN(a,b)   ((a) < (b) ? (a) : (b))

#define MTrace(x)  Trace(x)
#  define TTrace(x)

/*  The following macro wrappers around the fnfilter function are used many
 *  times to prepare archive entry names or name components for displaying
 *  listings and (warning/error) messages. They use sections in the upper half
 *  of 'slide' as buffer, since their output is normally fed through the
 *  Info() macro with 'slide' (the start of this area) as message buffer.
 */
#define FnFilter1(fname) \
        fnfilter((fname), slide + (extent)(WSIZE>>1), (extent)(WSIZE>>2))
#define FnFilter2(fname) \
        fnfilter((fname), slide + (extent)((WSIZE>>1) + (WSIZE>>2)),\
                 (extent)(WSIZE>>2))

#  define MESSAGE(str,len,flag)  (*G.message)((void *)&G,(str),(len),(flag))

#define SKIP_(length) if(length&&((error=do_string(length,SKIP))!=0))\
  {error_in_archive=error; if(error>1) return error;}

/*
 *  Skip a variable-length field, and report any errors.  Used in zipinfo.c
 *  and unzip.c in several functions.
 *
 *  macro SKIP_(length)
 *      ush length;
 *  {
 *      if (length && ((error = do_string(length, SKIP)) != 0)) {
 *          error_in_archive = error;   /-* might be warning *-/
 *          if (error > 1)              /-* fatal *-/
 *              return (error);
 *      }
 *  }
 *
 */


/**********************/
/*  Global constants  */
/**********************/

   extern const unsigned near mask_bits[17];
   extern const char *fnames[2];

   extern const char  VersionDate[];
   extern const char  CentSigMsg[];
   extern const char  EndSigMsg[];
   extern const char  SeekMsg[];
   extern const char  FilenameNotMatched[];
   extern const char  ExclFilenameNotMatched[];
   extern const char  ReportMsg[];

   extern const char  Zipnfo[];
   extern const char  CompiledWith[];



#endif /* !__unzip_h */
