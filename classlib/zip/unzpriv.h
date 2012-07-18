/*
  Copyright (c) 1990-2009 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2009-Jan-02 or later
  (the contents of which are also included in unzip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/*---------------------------------------------------------------------------

  unzpriv.h

  This header file contains private (internal) macros, typedefs, prototypes
  and global-variable declarations used by all of the UnZip source files.
  In a prior life it was part of the main unzip.h header, but now it is only
  included by that header if UNZIP_INTERNAL is defined.

  ---------------------------------------------------------------------------*/

#ifndef __unzpriv_h   /* prevent multiple inclusions */
#define __unzpriv_h

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
#define PutNativeEOL  {*q++ = native(CR); *q++ = native(LF);}

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

#define DIR_BLKSIZ 16384   /* use more memory, to reduce long-range seeks */
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

#define COPYRIGHT_CLEAN

/* File operations--use "b" for binary if allowed or fixed length 512 on VMS */

/*
 * buffer size required to hold the longest legal local filepath
 * (including the trailing '\0')
 */
#define FILNAMSIZ  PATH_MAX

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

/* choice of activities for do_string() */
#define SKIP              0             /* skip header block */
#define DISPLAY           1             /* display archive comment (ASCII) */
#define DISPL_8           5             /* display file comment (ext. ASCII) */
#define DS_FN             2             /* read filename (ext. ASCII, chead) */
#define DS_FN_C           2             /* read filename from central header */
#define DS_FN_L           6             /* read filename from local header */
#define EXTRA_FIELD       3             /* copy extra field into buffer */
#define DS_EF             3

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

#define MAX_BITS    13                 /* used in unshrink() */
#define HSIZE       (1 << MAX_BITS)    /* size of global work area */

#define LF     10        /* '\n' on ASCII machines; must be 10 due to EBCDIC */
#define CR     13        /* '\r' on ASCII machines; must be 13 due to EBCDIC */
#define CTRLZ  26        /* DOS & OS/2 EOF marker (used in fileio.c, vms.c) */

#ifdef EBCDIC
#  define foreign(c)    ascii[(unsigned char)(c)]
#  define native(c)     ebcdic[(unsigned char)(c)]
#  define NATIVE        "EBCDIC"
#  define NOANSIFILT
#endif

#ifndef ENV_UNZIP
#  define ENV_UNZIP       "UNZIP"          /* the standard names */
#  define ENV_ZIPINFO     "ZIPINFO"
#endif
#define ENV_UNZIP2        "UNZIPOPT"     /* alternate names, for zip compat. */
#define ENV_ZIPINFO2      "ZIPINFOOPT"

#if (!defined(QQ) && !defined(NOQQ))
#  define QQ
#endif

#ifdef QQ                         /* Newtware version:  no file */
#  define QCOND     (!uO.qflag)   /*  comments with -vq or -vqq */
#else                             /* Bill Davidsen version:  no way to */
#  define QCOND     (longhdr)     /*  kill file comments when listing */
#endif

#ifdef OLD_QQ
#  define QCOND2    (uO.qflag < 2)
#else
#  define QCOND2    (!uO.qflag)
#endif

#ifdef WILD_STOP_AT_DIR
#  define __WDLPRO  , int sepc
#  define __WDL     , sepc
#  define __WDLDEF  int sepc;
#  define WISEP     , (uO.W_flag ? '/' : '\0')
#else
#  define __WDLPRO
#  define __WDL
#  define __WDLDEF
#  define WISEP
#endif




/**************/
/*  Typedefs  */
/**************/

#ifdef ZIP64_SUPPORT
# ifndef Z_UINT8_DEFINED
#   if (defined(__GNUC__) || defined(__hpux) || defined(__SUNPRO_C))
  typedef unsigned long long    z_uint8;
#   else
  typedef unsigned __int64      z_uint8;
#   endif
#   define Z_UINT8_DEFINED
# endif
#endif
#ifndef Z_UINT4_DEFINED
# if (defined(MODERN) && !defined(NO_LIMITS_H))
#  if (defined(UINT_MAX) && (UINT_MAX == 0xffffffffUL))
     typedef unsigned int       z_uint4;
#    define Z_UINT4_DEFINED
#  else
#  if (defined(ULONG_MAX) && (ULONG_MAX == 0xffffffffUL))
     typedef unsigned long      z_uint4;
#    define Z_UINT4_DEFINED
#  else
#  if (defined(USHRT_MAX) && (USHRT_MAX == 0xffffffffUL))
     typedef unsigned short     z_uint4;
#    define Z_UINT4_DEFINED
#  endif
#  endif
#  endif
# endif /* MODERN && !NO_LIMITS_H */
#endif /* !Z_UINT4_DEFINED */
#ifndef Z_UINT4_DEFINED
  typedef unsigned long                   z_uint4;
# define Z_UINT4_DEFINED
#endif

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
#ifdef ZIP64_SUPPORT
  typedef  z_uint8              zusz_t;     /* zipentry sizes & offsets */
  typedef  z_uint8              zucn_t;     /* archive entry counts */
  typedef  z_uint4              zuvl_t;     /* multivolume numbers */
# define MASK_ZUCN64            (~(zucn_t)0)
/* In case we ever get to support an environment where z_uint8 may be WIDER
   than 64 bit wide, we will have to apply a construct similar to
     #define MASK_ZUCN64        (~(zucn_t)0 & (zucn_t)0xffffffffffffffffULL)
   for the 64-bit mask.
 */
#else
  typedef  unsigned long                  zusz_t;     /* zipentry sizes & offsets */
  typedef  unsigned int         zucn_t;     /* archive entry counts */
  typedef  unsigned short       zuvl_t;     /* multivolume numbers */
# define MASK_ZUCN64            (~(zucn_t)0)
#endif
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

typedef struct min_info {
    long offset;
    zusz_t compr_size;       /* compressed size (needed if extended header) */
    zusz_t uncompr_size;     /* uncompressed size (needed if extended header) */
    unsigned long crc;                 /* crc (needed if extended header) */
    zuvl_t diskstart;        /* no of volume where this entry starts */
    unsigned char hostver;
    unsigned char hostnum;
    unsigned file_attr;      /* local flavor, as used by creat(), chmod()... */
    unsigned encrypted : 1;  /* file encrypted: decrypt before uncompressing */
    unsigned ExtLocHdr : 1;  /* use time instead of CRC for decrypt check */
    unsigned textfile : 1;   /* file is text (according to zip) */
    unsigned textmode : 1;   /* file is to be extracted as text */
    unsigned lcflag : 1;     /* convert filename to lowercase */
    unsigned vollabel : 1;   /* "file" is an MS-DOS volume (disk) label */
    unsigned HasUxAtt : 1;   /* crec ext_file_attr has Unix style mode bits */
    char *cfilname;      /* central header version of filename */
} min_info;

typedef struct VMStimbuf {
    char *revdate;    /* (both roughly correspond to Unix modtime/st_mtime) */
    char *credate;
} VMStimbuf;

/*---------------------------------------------------------------------------
    Zipfile work area declarations.
  ---------------------------------------------------------------------------*/

   union work {
     struct {                 /* unshrink(): */
       int *Parent;          /* pointer to (8192 * sizeof(int)) */
       unsigned char *value;              /* pointer to 8KB char buffer */
       unsigned char *Stack;              /* pointer to another 8KB char buffer */
     } shrink;
     unsigned char *Slide;              /* explode(), inflate(), unreduce() */
   };

#define slide  G.area.Slide

#  define redirSlide G.area.Slide

/*---------------------------------------------------------------------------
    Zipfile layout declarations.  If these headers ever change, make sure the
    xxREC_SIZE defines (above) change with them!
  ---------------------------------------------------------------------------*/

   typedef unsigned char   local_byte_hdr[ LREC_SIZE ];
#      define L_VERSION_NEEDED_TO_EXTRACT_0     0
#      define L_VERSION_NEEDED_TO_EXTRACT_1     1
#      define L_GENERAL_PURPOSE_BIT_FLAG        2
#      define L_COMPRESSION_METHOD              4
#      define L_LAST_MOD_DOS_DATETIME           6
#      define L_CRC32                           10
#      define L_COMPRESSED_SIZE                 14
#      define L_UNCOMPRESSED_SIZE               18
#      define L_FILENAME_LENGTH                 22
#      define L_EXTRA_FIELD_LENGTH              24

   typedef unsigned char   cdir_byte_hdr[ CREC_SIZE ];
#      define C_VERSION_MADE_BY_0               0
#      define C_VERSION_MADE_BY_1               1
#      define C_VERSION_NEEDED_TO_EXTRACT_0     2
#      define C_VERSION_NEEDED_TO_EXTRACT_1     3
#      define C_GENERAL_PURPOSE_BIT_FLAG        4
#      define C_COMPRESSION_METHOD              6
#      define C_LAST_MOD_DOS_DATETIME           8
#      define C_CRC32                           12
#      define C_COMPRESSED_SIZE                 16
#      define C_UNCOMPRESSED_SIZE               20
#      define C_FILENAME_LENGTH                 24
#      define C_EXTRA_FIELD_LENGTH              26
#      define C_FILE_COMMENT_LENGTH             28
#      define C_DISK_NUMBER_START               30
#      define C_INTERNAL_FILE_ATTRIBUTES        32
#      define C_EXTERNAL_FILE_ATTRIBUTES        34
#      define C_RELATIVE_OFFSET_LOCAL_HEADER    38

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


/* The following structs are used to hold all header data of a zip entry.
   Traditionally, the structs' layouts followed the data layout of the
   corresponding zipfile header structures.  However, the zipfile header
   layouts were designed in the old ages of 16-bit CPUs, they are subject
   to structure padding and/or alignment issues on newer systems with a
   "natural word width" of more than 2 bytes.
   Please note that the structure members are now reordered by size
   (top-down), to prevent internal padding and optimize memory usage!
 */
   typedef struct local_file_header {                 /* LOCAL */
       zusz_t csize;
       zusz_t ucsize;
       unsigned long last_mod_dos_datetime;
       unsigned long crc32;
       unsigned char version_needed_to_extract[2];
       unsigned short general_purpose_bit_flag;
       unsigned short compression_method;
       unsigned short filename_length;
       unsigned short extra_field_length;
   } local_file_hdr;

   typedef struct central_directory_file_header {     /* CENTRAL */
       zusz_t csize;
       zusz_t ucsize;
       zusz_t relative_offset_local_header;
       unsigned long last_mod_dos_datetime;
       unsigned long crc32;
       unsigned long external_file_attributes;
       zuvl_t disk_number_start;
       unsigned short internal_file_attributes;
       unsigned char version_made_by[2];
       unsigned char version_needed_to_extract[2];
       unsigned short general_purpose_bit_flag;
       unsigned short compression_method;
       unsigned short filename_length;
       unsigned short extra_field_length;
       unsigned short file_comment_length;
   } cdir_file_hdr;

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


/* Huffman code lookup table entry--this entry is four bytes for machines
   that have 16-bit pointers (e.g. PC's in the small or medium model).
   Valid extra bits are 0..16.  e == 31 is EOB (end of block), e == 32
   means that v is a literal, 32 < e < 64 means that v is a pointer to
   the next table, which codes (e & 31)  bits, and lastly e == 99 indicates
   an unused code.  If a code with e == 99 is looked up, this implies an
   error in the data. */

struct huft {
    unsigned char e;                /* number of extra bits or operation */
    unsigned char b;                /* number of bits in this code or subcode */
    union {
        unsigned short n;            /* literal, length base, or distance base */
        struct huft *t;   /* pointer to next level of table */
    } v;
};


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
   int    unzip                  OF((__GPRO__ int argc, char **argv));
   int    uz_opts                OF((__GPRO__ int *pargc, char ***pargv));
   int    usage                  OF((__GPRO__ int error));

/*---------------------------------------------------------------------------
    Functions in process.c (main driver routines):
  ---------------------------------------------------------------------------*/

int      process_zipfiles        OF((__GPRO));
void     free_G_buffers          OF((__GPRO));
/* static int    do_seekable     OF((__GPRO__ int lastchance)); */
/* static int    find_ecrec      OF((__GPRO__ long searchlen)); */
/* static int    process_central_comment OF((__GPRO)); */
int      process_cdir_file_hdr   OF((__GPRO));
int      process_local_file_hdr  OF((__GPRO));
int      getZip64Data            OF((__GPRO__ const unsigned char *ef_buf,
                                     unsigned ef_len));
unsigned ef_scan_for_izux        OF((const unsigned char *ef_buf, unsigned ef_len,
                                     int ef_is_c, unsigned long dos_mdatetime,
                                     iztimes *z_utim, unsigned long *z_uidgid));

/*---------------------------------------------------------------------------
    Functions in zipinfo.c (`zipinfo-style' listing routines):
  ---------------------------------------------------------------------------*/

#ifndef NO_ZIPINFO
#ifndef WINDLL
   int   zi_opts                 OF((__GPRO__ int *pargc, char ***pargv));
#endif
void     zi_end_central          OF((__GPRO));
int      zipinfo                 OF((__GPRO));
/* static int      zi_long       OF((__GPRO__ zusz_t *pEndprev)); */
/* static int      zi_short      OF((__GPRO)); */
/* static char    *zi_time       OF((__GPRO__ const unsigned long *datetimez,
                                     const time_t *modtimez, char *d_t_str));*/
#endif /* !NO_ZIPINFO */

/*---------------------------------------------------------------------------
    Functions in list.c (generic zipfile-listing routines):
  ---------------------------------------------------------------------------*/

int      list_files              OF((__GPRO));
int      ratio                   OF((zusz_t uc, zusz_t c));
void     fnprint                 OF((__GPRO));

/*---------------------------------------------------------------------------
    Functions in fileio.c:
  ---------------------------------------------------------------------------*/

int      open_input_file      OF((__GPRO));
int      open_outfile         OF((__GPRO));                    /* also vms.c */
void     undefer_input        OF((__GPRO));
void     defer_leftover_input OF((__GPRO));
unsigned readbuf              OF((__GPRO__ char *buf, register unsigned len));
int      readbyte             OF((__GPRO));
int      fillinbuf            OF((__GPRO));
int      seek_zipf            OF((__GPRO__ long abs_offset));
   int   flush                OF((__GPRO__ unsigned char *buf, unsigned long size, int unshrink));
/* static int  disk_error     OF((__GPRO)); */
void     handler              OF((int signal));
time_t   dos_to_unix_time     OF((unsigned long dos_datetime));
int      check_for_newer      OF((__GPRO__ char *filename)); /* os2,vmcms,vms */
int      do_string            OF((__GPRO__ unsigned int length, int option));
unsigned short      makeword             OF((const unsigned char *b));
unsigned long      makelong             OF((const unsigned char *sig));
zusz_t   makeint64            OF((const unsigned char *sig));
char    *fzofft               OF((__GPRO__ long val,
                                  const char *pre, const char *post));
   char *str2iso              OF((char *dst, const char *src));
   char *str2oem              OF((char *dst, const char *src));
#ifdef NO_STRNICMP
   int   zstrnicmp            OF((register const char *s1,
                                  register const char *s2,
                                  register unsigned n));
#endif
#ifdef REGULUS
   int   zstat                OF((const char *p, struct stat *s));
#endif
#ifdef ZMEM   /* MUST be ifdef'd because of conflicts with the standard def. */
   void *memset OF((register void *, register int, register unsigned int));
   int    memcmp OF((register const void*, register const void *,
                     register unsigned int));
   void *memcpy OF((register void *, register const void *,
                     register unsigned int));
#endif
#ifdef NEED_UZMBCLEN
   extent uzmbclen          OF((const unsigned char *ptr));
#endif
#ifdef NEED_UZMBSCHR
   unsigned char *uzmbschr  OF((const unsigned char *str, unsigned int c));
#endif
#ifdef NEED_UZMBSRCHR
   unsigned char *uzmbsrchr OF((const unsigned char *str, unsigned int c));
#endif
#ifdef SMALL_MEM
   char *fLoadFarString       OF((__GPRO__ const char *sz));
   char *fLoadFarStringSmall  OF((__GPRO__ const char *sz));
   char *fLoadFarStringSmall2 OF((__GPRO__ const char *sz));
   #ifndef zfstrcpy
     char * zfstrcpy  OF((char *s1, const char *s2));
   #endif
   #if (!defined(SFX) && !defined(zfstrcmp))
     int zfstrcmp         OF((const char *s1, const char *s2));
   #endif
#endif


/*---------------------------------------------------------------------------
    Functions in extract.c:
  ---------------------------------------------------------------------------*/

int    extract_or_test_files     OF((__GPRO));
/* static int   store_info          OF((void)); */
/* static int   extract_or_test_member   OF((__GPRO)); */
/* static int   TestExtraField   OF((__GPRO__ unsigned char *ef, unsigned ef_len)); */
/* static int   test_OS2         OF((__GPRO__ unsigned char *eb, unsigned eb_size)); */
/* static int   test_NT          OF((__GPRO__ unsigned char *eb, unsigned eb_size)); */
#ifndef SFX
  unsigned find_compr_idx        OF((unsigned compr_methodnum));
#endif
int    memextract                OF((__GPRO__ unsigned char *tgt, unsigned long tgtsize,
                                     const unsigned char *src, unsigned long srcsize));
int    memflush                  OF((__GPRO__ const unsigned char *rawbuf, unsigned long size));
#if (defined(VMS) || defined(VMS_TEXT_CONV))
   unsigned char   *extract_izvms_block    OF((__GPRO__ const unsigned char *ebdata,
                                     unsigned size, unsigned *retlen,
                                     const unsigned char *init, unsigned needlen));
#endif
char  *fnfilter                  OF((const char *raw, unsigned char *space,
                                     extent size));

/*---------------------------------------------------------------------------
    Decompression functions:
  ---------------------------------------------------------------------------*/

#if (!defined(SFX) && !defined(FUNZIP))
int    explode                   OF((__GPRO));                  /* explode.c */
#endif
int    huft_free                 OF((struct huft *t));          /* inflate.c */
int    huft_build                OF((__GPRO__ const unsigned *b, unsigned n,
                                     unsigned s, const unsigned short *d, const unsigned char *e,
                                     struct huft **t, unsigned *m));
   int    UZinflate              OF((__GPRO__ int is_defl64));  /* inflate.c */
#  define inflate_free(x)        inflateEnd(&((Uz_Globs *)(&G))->dstrm)
#if (!defined(SFX) && !defined(FUNZIP))
#ifndef COPYRIGHT_CLEAN
   int    unreduce               OF((__GPRO));                 /* unreduce.c */
/* static void  LoadFollowers    OF((__GPRO__ f_array *follower, unsigned char *Slen));
                                                                * unreduce.c */
#endif /* !COPYRIGHT_CLEAN */
#ifndef LZW_CLEAN
   int    unshrink               OF((__GPRO));                 /* unshrink.c */
/* static void  partial_clear    OF((__GPRO));                  * unshrink.c */
#endif /* !LZW_CLEAN */
#endif /* !SFX && !FUNZIP */
#ifdef USE_BZIP2
   int    UZbunzip2              OF((__GPRO));                  /* extract.c */
   void   bz_internal_error      OF((int bzerrcode));           /* ubz2err.c */
#endif

/*---------------------------------------------------------------------------
    Internal API functions (only included in DLL versions):
  ---------------------------------------------------------------------------*/

#ifdef DLL
   void     setFileNotFound       OF((__GPRO));                     /* api.c */
   int      unzipToMemory         OF((__GPRO__ char *zip, char *file,
                                      UzpBuffer *retstr));          /* api.c */
   int      redirect_outfile      OF((__GPRO));                     /* api.c */
   int      writeToMemory         OF((__GPRO__ const unsigned char *rawbuf,
                                      extent size));                /* api.c */
   int      close_redirect        OF((__GPRO));                     /* api.c */
   /* this obsolescent entry point kept for compatibility: */
   int      UzpUnzip              OF((int argc, char **argv));/* use UzpMain */
#ifdef OS2DLL
   int      varmessage            OF((__GPRO__ const unsigned char *buf, unsigned long size));
   int      varputchar            OF((__GPRO__ int c));         /* rexxapi.c */
   int      finish_REXX_redirect  OF((__GPRO));                 /* rexxapi.c */
#endif
#ifdef API_DOC
   void     APIhelp               OF((__GPRO__ int argc, char **argv));
#endif                                                          /* apihelp.c */
#endif /* DLL */

/*---------------------------------------------------------------------------
    MSDOS-only functions:
  ---------------------------------------------------------------------------*/

#ifdef MSDOS
#if (!defined(FUNZIP) && !defined(SFX) && !defined(WINDLL))
   void     check_for_windows     OF((const char *app));         /* msdos.c */
#endif
#if (defined(__GO32__) || defined(__EMX__))
   unsigned _dos_getcountryinfo(void *);                          /* msdos.c */
#if (!defined(__DJGPP__) || (__DJGPP__ < 2))
   unsigned _dos_setftime(int, unsigned, unsigned);               /* msdos.c */
   unsigned _dos_setfileattr(const char *, unsigned);             /* msdos.c */
   unsigned _dos_creat(const char *, unsigned, int *);            /* msdos.c */
   void _dos_getdrive(unsigned *);                                /* msdos.c */
   unsigned _dos_close(int);                                      /* msdos.c */
#endif /* !__DJGPP__ || (__DJGPP__ < 2) */
#endif /* __GO32__ || __EMX__ */
#endif

/*---------------------------------------------------------------------------
    OS/2-only functions:
  ---------------------------------------------------------------------------*/

#ifdef OS2   /* GetFileTime conflicts with something in Win32 header files */
#if (defined(REENTRANT) && defined(USETHREADID))
   unsigned long   GetThreadId          OF((void));
#endif
   int   GetCountryInfo       OF((void));                           /* os2.c */
   long  GetFileTime          OF((const char *name));              /* os2.c */
/* static void  SetPathAttrTimes OF((__GPRO__ int flags, int dir));    os2.c */
/* static int   SetEAs        OF((__GPRO__ const char *path,
                                  void *eablock));                     os2.c */
/* static int   SetACL        OF((__GPRO__ const char *path,
                                  void *eablock));                     os2.c */
/* static int   IsFileNameValid OF((const char *name));                os2.c */
/* static void  map2fat       OF((char *pathcomp, char **pEndFAT));    os2.c */
/* static int   SetLongNameEA OF((char *name, char *longname));        os2.c */
/* static void  InitNLS       OF((void));                              os2.c */
   int   IsUpperNLS           OF((int nChr));                       /* os2.c */
   int   ToLowerNLS           OF((int nChr));                       /* os2.c */
   void  DebugMalloc          OF((void));                           /* os2.c */
#endif

/*---------------------------------------------------------------------------
    QDOS-only functions:
  ---------------------------------------------------------------------------*/

#ifdef QDOS
   int    QMatch              (unsigned char, unsigned char);
   void   QFilename           (__GPRO__ char *);
   char  *Qstrfix             (char *);
   int    QReturn             (int zip_error);
#endif

/*---------------------------------------------------------------------------
    TOPS20-only functions:
  ---------------------------------------------------------------------------*/

#ifdef TOPS20
   int    upper               OF((char *s));                     /* tops20.c */
   int    enquote             OF((char *s));                     /* tops20.c */
   int    dequote             OF((char *s));                     /* tops20.c */
   int    fnlegal             OF(()); /* error if prototyped? */ /* tops20.c */
#endif

/*---------------------------------------------------------------------------
    VM/CMS- and MVS-only functions:
  ---------------------------------------------------------------------------*/

#ifdef CMS_MVS
   extent getVMMVSexfield     OF((char *type, unsigned char *ef_block, unsigned datalen));
   FILE  *vmmvs_open_infile   OF((__GPRO));                       /* vmmvs.c */
   void   close_infile        OF((__GPRO));                       /* vmmvs.c */
#endif

/*---------------------------------------------------------------------------
    VMS-only functions:
  ---------------------------------------------------------------------------*/

#ifdef VMS
   int    check_format        OF((__GPRO));                         /* vms.c */
/* int    open_outfile        OF((__GPRO));           * (see fileio.c) vms.c */
/* int    flush               OF((__GPRO__ unsigned char *rawbuf, unsigned size,
                                  int final_flag));   * (see fileio.c) vms.c */
   char  *vms_msg_text        OF((void));                           /* vms.c */
#ifdef RETURN_CODES
   void   return_VMS          OF((__GPRO__ int zip_error));         /* vms.c */
#else
   void   return_VMS          OF((int zip_error));                  /* vms.c */
#endif
#ifdef VMSCLI
   unsigned long    vms_unzip_cmdline   OF((int *, char ***));            /* cmdline.c */
   int    VMSCLI_usage        OF((__GPRO__ int error));         /* cmdline.c */
#endif
#endif

/*---------------------------------------------------------------------------
    WIN32-only functions:
  ---------------------------------------------------------------------------*/

#ifdef WIN32
   int   IsWinNT        OF((void));                               /* win32.c */
#ifdef NTSD_EAS
   void  process_defer_NT     OF((__GPRO));                       /* win32.c */
   int   test_NTSD      OF((__GPRO__ unsigned char *eb, unsigned eb_size,
                            unsigned char *eb_ucptr, unsigned long eb_ucsize));       /* win32.c */
#  define TEST_NTSD     test_NTSD
#endif
#ifdef W32_STAT_BANDAID
   int   zstat_win32    OF((__W32STAT_GLOBALS__
                            const char *path, z_stat *buf));      /* win32.c */
#endif
#endif

/*---------------------------------------------------------------------------
    Miscellaneous/shared functions:
  ---------------------------------------------------------------------------*/

Uz_Globs *globalsCtor    OF((void));                            /* globals.c */

int      envargs         OF((int *Pargc, char ***Pargv,
                             const char *envstr, const char *envstr2));
                                                                /* envargs.c */
void     mksargs         OF((int *argcp, char ***argvp));       /* envargs.c */

int      match           OF((const char *s, const char *p,
                             int ic __WDLPRO));                   /* match.c */
int      iswild          OF((const char *p));                    /* match.c */

/* declarations of public CRC-32 functions have been moved into crc32.h
   (free_crc_table(), get_crc_table(), crc32())                      crc32.c */

#ifndef WINDLL
   void  version         OF((__GPRO));                              /* local */
#endif
int      mapattr         OF((__GPRO));                              /* local */
int      mapname         OF((__GPRO__ int renamed));                /* local */
int      checkdir        OF((__GPRO__ char *pathcomp, int flag));   /* local */
char    *do_wild         OF((__GPRO__ const char *wildzipfn));     /* local */
char    *GetLoadPath     OF((__GPRO));                              /* local */
#ifdef OS2_W32
   int   SetFileSize     OF((FILE *file, zusz_t filesize));         /* local */
#endif
#ifndef MTS /* macro in MTS */
   void  close_outfile   OF((__GPRO));                              /* local */
#endif
#ifdef SET_SYMLINK_ATTRIBS
   int  set_symlnk_attribs  OF((__GPRO__ slinkentry *slnk_entry));  /* local */
#endif
   int   defer_dir_attribs  OF((__GPRO__ direntry **pd));           /* local */
   int   set_direc_attribs  OF((__GPRO__ direntry *d));             /* local */
#ifdef NEED_ISO_OEM_INIT
   void  prepare_ISO_OEM_translat   OF((__GPRO));                   /* local */
#endif
#ifdef SYSTEM_SPECIFIC_CTOR
   void  SYSTEM_SPECIFIC_CTOR   OF((__GPRO));                       /* local */
#endif
#ifdef SYSTEM_SPECIFIC_DTOR
   void  SYSTEM_SPECIFIC_DTOR   OF((__GPRO));                       /* local */
#endif





/************/
/*  Macros  */
/************/

#ifndef MAX
#  define MAX(a,b)   ((a) > (b) ? (a) : (b))
#endif
#ifndef MIN
#  define MIN(a,b)   ((a) < (b) ? (a) : (b))
#endif

#ifdef DEBUG
#  if (defined(THEOS) && defined(NO_BOGUS_SPC))
#    define NO_DEBUG_IN_MACROS
#    define Trace(x)   _fprintf x
#  else
#    define Trace(x)   fprintf x
#  endif
#else
#  define Trace(x)
#endif

#ifdef DEBUG_TIME
#  define TTrace(x)  fprintf x
#else
#  define TTrace(x)
#endif

#ifdef NO_DEBUG_IN_MACROS
#  define MTrace(x)
#else
#  define MTrace(x)  Trace(x)
#endif

#if (defined(UNIX) || defined(T20_VMS)) /* generally old systems */
#  define ToLower(x)   ((char)(isupper((int)x)? tolower((int)x) : x))
#else
#  define ToLower      tolower          /* assumed "smart"; used in match() */
#endif

#ifdef USE_STRM_INPUT
   /* ``Replace'' the unbuffered UNIX style I/O function with similar
    * standard C functions from <stdio.h>.
    */
#  define read(fd,buf,n) fread((buf),1,(n),(FILE *)(fd))
#  ifdef zlseek
#    undef zlseek
#  endif
#  define zlseek(fd,o,w) zfseeko((FILE *)(fd),(o),(w))
#  define close(fd) fclose((FILE *)(fd))
#endif /* USE_STRM_INPUT */

/* The return value of the Info() "macro function" is never checked in
 * UnZip. Otherwise, to get the same behaviour as for (*G.message)(), the
 * Info() definition for "FUNZIP" would have to be corrected:
 * #define Info(buf,flag,sprf_arg) \
 *      (fputs((char *)(sprintf sprf_arg, (buf)), \
 *             (flag)&1? stderr : stdout) < 0)
 */
#ifndef Info   /* may already have been defined for redirection */
#  ifdef FUNZIP
#    define Info(buf,flag,sprf_arg) \
     fputs((char *)(sprintf sprf_arg, (buf)), (flag)&1? stderr : stdout)
#  else
#      define Info(buf,flag,sprf_arg) \
       (*G.message)((void *)&G, (unsigned char *)(buf), (unsigned long)sprintf sprf_arg, (flag))
#  endif
#endif /* !Info */

/*  This wrapper macro around fzofft() is just defined to "hide" the
 *  argument needed to reference the global storage buffers.
 */
#define FmZofft(val, pre, post) fzofft(__G__ val, pre, post)

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

#  define CRCVAL_INITIAL  0L

#ifndef TEST_NTSD               /* "NTSD valid?" checking function */
#  define TEST_NTSD     NULL    /*   ... is not available */
#endif

#define SKIP_(length) if(length&&((error=do_string(__G__ length,SKIP))!=0))\
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


#  define FLUSH(w)  ((G.mem_mode) ? memflush(__G__ redirSlide,(unsigned long)(w)) \
                                  : flush(__G__ redirSlide,(unsigned long)(w),0))
#  define NEXTBYTE  (G.incnt-- > 0 ? (int)(*G.inptr++) : readbyte(__G))


#define READBITS(nbits,zdest) {if(nbits>G.bits_left) {int temp; G.zipeof=1;\
  while (G.bits_left<=8*(int)(sizeof(G.bitbuf)-1) && (temp=NEXTBYTE)!=EOF) {\
  G.bitbuf|=(unsigned long)temp<<G.bits_left; G.bits_left+=8; G.zipeof=0;}}\
  zdest=(int)((unsigned)G.bitbuf&mask_bits[nbits]);G.bitbuf>>=nbits;\
  G.bits_left-=nbits;}

/*
 * macro READBITS(nbits,zdest)    * only used by unreduce and unshrink *
 *  {
 *      if (nbits > G.bits_left) {  * fill G.bitbuf, 8*sizeof(unsigned long) bits *
 *          int temp;
 *
 *          G.zipeof = 1;
 *          while (G.bits_left <= 8*(int)(sizeof(G.bitbuf)-1) &&
 *                 (temp = NEXTBYTE) != EOF) {
 *              G.bitbuf |= (unsigned long)temp << G.bits_left;
 *              G.bits_left += 8;
 *              G.zipeof = 0;
 *          }
 *      }
 *      zdest = (int)((unsigned)G.bitbuf & mask_bits[nbits]);
 *      G.bitbuf >>= nbits;
 *      G.bits_left -= nbits;
 *  }
 *
 */


/* GRR:  should use StringLower for STRLOWER macro if possible */

/*
 *  Copy the zero-terminated string in str1 into str2, converting any
 *  uppercase letters to lowercase as we go.  str2 gets zero-terminated
 *  as well, of course.  str1 and str2 may be the same character array.
 */
#  define STRLOWER(str1, str2) \
   { \
       char  *p, *q; \
       p = (char *)(str1) - 1; \
       q = (char *)(str2); \
       while (*++p) \
           *q++ = (char)(isupper((int)(*p))? tolower((int)(*p)) : *p); \
       *q = '\0'; \
   }
/*
 *  NOTES:  This macro makes no assumptions about the characteristics of
 *    the tolower() function or macro (beyond its existence), nor does it
 *    make assumptions about the structure of the character set (i.e., it
 *    should work on EBCDIC machines, too).  The fact that either or both
 *    of isupper() and tolower() may be macros has been taken into account;
 *    watch out for "side effects" (in the C sense) when modifying this
 *    macro.
 */

#ifndef foreign
#  define foreign(c)  (c)
#endif

#ifndef native
#  define native(c)   (c)
#  define A_TO_N(str1)
#else
#  ifndef NATIVE
#    define NATIVE     "native chars"
#  endif
#  define A_TO_N(str1) {register unsigned char *p;\
     for (p=(unsigned char *)(str1); *p; p++) *p=native(*p);}
#endif
/*
 *  Translate the zero-terminated string in str1 from ASCII to the native
 *  character set. The translation is performed in-place and uses the
 *  "native" macro to translate each character.
 *
 *  NOTE:  Using the "native" macro means that is it the only part of unzip
 *    which knows which translation table (if any) is actually in use to
 *    produce the native character set.  This makes adding new character set
 *    translation tables easy, insoas all that is needed is an appropriate
 *    "native" macro definition and the translation table itself.  Currently,
 *    the only non-ASCII native character set implemented is EBCDIC, but this
 *    may not always be so.
 */


#  define CRTL_CP_IS_ISO


/*  Translate "extended ASCII" chars (OEM coding for DOS and OS/2; else
 *  ISO-8859-1 [ISO Latin 1, Win Ansi,...]) into the internal "native"
 *  code page.  As with A_TO_N(), conversion is done in place.
 */
#ifndef _ISO_INTERN
#  ifdef CRTL_CP_IS_OEM
#    ifndef IZ_ISO2OEM_ARRAY
#      define IZ_ISO2OEM_ARRAY
#    endif
#    define _ISO_INTERN(str1) if (iso2oem) {register unsigned char *p;\
       for (p=(unsigned char *)(str1); *p; p++)\
         *p = native((*p & 0x80) ? iso2oem[*p & 0x7f] : *p);}
#  else
#    define _ISO_INTERN(str1)   A_TO_N(str1)
#  endif
#endif

#ifndef _OEM_INTERN
#  ifdef CRTL_CP_IS_OEM
#    define _OEM_INTERN(str1)   A_TO_N(str1)
#  else
#    ifndef IZ_OEM2ISO_ARRAY
#      define IZ_OEM2ISO_ARRAY
#    endif
#    define _OEM_INTERN(str1) if (oem2iso) {register unsigned char *p;\
       for (p=(unsigned char *)(str1); *p; p++)\
         *p = native((*p & 0x80) ? oem2iso[*p & 0x7f] : *p);}
#  endif
#endif

#ifndef STR_TO_OEM
#  ifdef CRTL_CP_IS_OEM
#    define STR_TO_OEM          strcpy
#  else
#    define STR_TO_OEM          str2oem
#    define NEED_STR2OEM
#  endif
#endif

#if (!defined(INTERN_TO_ISO) && !defined(ASCII2ISO))
#  ifdef CRTL_CP_IS_OEM
     /* know: "ASCII" is "OEM" */
#    define ASCII2ISO(c) \
       ((((c) & 0x80) && oem2iso) ? oem2iso[(c) & 0x7f] : (c))
#    if (defined(NEED_STR2ISO) && !defined(CRYP_USES_OEM2ISO))
#      define CRYP_USES_OEM2ISO
#    endif
#  else
     /* assume: "ASCII" is "ISO-ANSI" */
#    define ASCII2ISO(c) (c)
#  endif
#endif

#if (!defined(INTERN_TO_OEM) && !defined(ASCII2OEM))
#  ifdef CRTL_CP_IS_OEM
     /* know: "ASCII" is "OEM" */
#    define ASCII2OEM(c) (c)
#  else
     /* assume: "ASCII" is "ISO-ANSI" */
#    define ASCII2OEM(c) \
       ((((c) & 0x80) && iso2oem) ? iso2oem[(c) & 0x7f] : (c))
#    if (defined(NEED_STR2OEM) && !defined(CRYP_USES_ISO2OEM))
#      define CRYP_USES_ISO2OEM
#    endif
#  endif
#endif

/* codepage conversion setup for testp() in crypt.c */
#  ifndef STR_TO_CP2
#    define STR_TO_CP2  STR_TO_OEM
#  endif


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
 *  in the local system's codepage (usually ANSI codings like ISO 8859-1).
 *
 * All other ports are assumed to code zip entry filenames in ISO 8859-1.
 */
#ifndef Ext_ASCII_TO_Native
#  define Ext_ASCII_TO_Native(string, hostnum, hostver, isuxatt, islochdr) \
    if (((hostnum) == FS_FAT_ && \
         !(((islochdr) || (isuxatt)) && \
           ((hostver) == 25 || (hostver) == 26 || (hostver) == 40))) || \
        (hostnum) == FS_HPFS_ || \
        ((hostnum) == FS_NTFS_ && (hostver) == 50)) { \
        _OEM_INTERN((string)); \
    } else { \
        _ISO_INTERN((string)); \
    }
#endif



/**********************/
/*  Global constants  */
/**********************/

   extern const unsigned near mask_bits[17];
   extern const char *fnames[2];

#ifdef EBCDIC
   extern const unsigned char ebcdic[];
#endif
#ifdef IZ_ISO2OEM_ARRAY
   extern const unsigned char *iso2oem;
   extern const unsigned char iso2oem_850[];
#endif
#ifdef IZ_OEM2ISO_ARRAY
   extern const unsigned char *oem2iso;
   extern const unsigned char oem2iso_850[];
#endif

   extern const char  VersionDate[];
   extern const char  CentSigMsg[];
   extern const char  EndSigMsg[];
   extern const char  SeekMsg[];
   extern const char  FilenameNotMatched[];
   extern const char  ExclFilenameNotMatched[];
   extern const char  ReportMsg[];

   extern const char  Zipnfo[];
   extern const char  CompiledWith[];



/***********************************/
/*  Global (shared?) RTL variables */
/***********************************/

#ifdef DECLARE_ERRNO
   extern int             errno;
#endif

#endif /* !__unzpriv_h */
