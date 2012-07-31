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
# Adapted from Info-ZIP
#
# The Info-ZIP license may be found at:  
# ftp://ftp.info-zip.org/pub/infozip/license.html
#
# unzip.cpp
# Unzip class
#
########################################################################*/

#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h> 

#include "rdos.h"
#include "unzip.h"
#include "zlib.h"

#define     FALSE       0
#define     TRUE        !FALSE

#define UNZIP_VERSION   20

#define LF     10        /* '\n' on ASCII machines; must be 10 due to EBCDIC */
#define CR     13        /* '\r' on ASCII machines; must be 13 due to EBCDIC */
#define CTRLZ  26        /* DOS & OS/2 EOF marker (used in fileio.c, vms.c) */

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

#define CREC_SIZE    42   /*  directory headers, end-of-central-dir */

#define C_VERSION_MADE_BY_0               0
#define C_VERSION_MADE_BY_1               1
#define C_VERSION_NEEDED_TO_EXTRACT_0     2
#define C_VERSION_NEEDED_TO_EXTRACT_1     3
#define C_GENERAL_PURPOSE_BIT_FLAG        4
#define C_COMPRESSION_METHOD              6
#define C_LAST_MOD_DOS_DATETIME           8
#define C_CRC32                           12
#define C_COMPRESSED_SIZE                 16
#define C_UNCOMPRESSED_SIZE               20
#define C_FILENAME_LENGTH                 24
#define C_EXTRA_FIELD_LENGTH              26
#define C_FILE_COMMENT_LENGTH             28
#define C_DISK_NUMBER_START               30
#define C_INTERNAL_FILE_ATTRIBUTES        32
#define C_EXTERNAL_FILE_ATTRIBUTES        34
#define C_RELATIVE_OFFSET_LOCAL_HEADER    38

#define LREC_SIZE    26   /* lengths of local file headers, central */

#define L_VERSION_NEEDED_TO_EXTRACT_0     0
#define L_VERSION_NEEDED_TO_EXTRACT_1     1
#define L_GENERAL_PURPOSE_BIT_FLAG        2
#define L_COMPRESSION_METHOD              4
#define L_LAST_MOD_DOS_DATETIME           6
#define L_CRC32                           10
#define L_COMPRESSED_SIZE                 14
#define L_UNCOMPRESSED_SIZE               18
#define L_FILENAME_LENGTH                 22
#define L_EXTRA_FIELD_LENGTH              24

#define RAND_HEAD_LEN  12       /* length of encryption random header */

#define INBUFSIZ  8192
#define TMPOUTSIZ 0x10000
#define WSIZE   0x8000  /* window size--must be a power of two, and */

/* If BMAX needs to be larger than 16, then h and x[] should be unsigned long. */
#define BMAX 16         /* maximum bit length of any code (16 for explode) */
#define N_MAX 288       /* maximum number of codes in any set */

#define INVALID_CODE 99

#define MAX_BITS    13                 /* used in unshrink() */
#define HSIZE       (1 << MAX_BITS)    /* size of global work area */

/* HSIZE is defined as 2^13 (8192) in unzip.h (resp. unzpriv.h */
#define BOGUSCODE  256
#define CODE_MASK  (HSIZE - 1)   /* 0x1fff (lower bits are parent's index) */
#define FREE_CODE  HSIZE         /* 0x2000 (code is unused or was cleared) */
#define HAS_CHILD  (HSIZE << 1)  /* 0x4000 (code has a child--do not clear) */

#define MAX(a,b)   ((a) > (b) ? (a) : (b))
#define MIN(a,b)   ((a) < (b) ? (a) : (b))

const unsigned *crctab = get_crc_table();

typedef struct
{
    char           *_dest;
    short           _flags;         // flags (see below)
    short           _version;       // structure version # (2.0 --> 200)
    int             _fld_width;     // field width
    int             _prec;          // precision
    int             _output_count;  // # of characters outputted for %n
    int             _n0;            // number of chars to deliver first
    int             _nz0;           // number of zeros to deliver next
    int             _n1;            // number of chars to deliver next
    int             _nz1;           // number of zeros to deliver next
    int             _n2;            // number of chars to deliver next
    int             _nz2;           // number of zeros to deliver next
    char            _character;     // format character
    char            _pad_char;
    char            _padding[2];    // to keep struct aligned
} _SPECS;

typedef void (slib_callback_t)(_SPECS *, int);

extern "C" int 
            __prtf( void  *dest,         /* parm for use by out_putc */
            const char *format,          /* pointer to format string */
            va_list args,                /* pointer to pointer to args*/
            slib_callback_t *out_putc ); /* char output routine */


const unsigned char iso2oem[] = {
    0x3F, 0x3F, 0x27, 0x9F, 0x22, 0x2E, 0xC5, 0xCE,  /* 80 - 87 */
    0x5E, 0x25, 0x53, 0x3C, 0x4F, 0x3F, 0x3F, 0x3F,  /* 88 - 8F */
    0x3F, 0x27, 0x27, 0x22, 0x22, 0x07, 0x2D, 0x2D,  /* 90 - 97 */
    0x7E, 0x54, 0x73, 0x3E, 0x6F, 0x3F, 0x3F, 0x59,  /* 98 - 9F */
    0xFF, 0xAD, 0xBD, 0x9C, 0xCF, 0xBE, 0xDD, 0xF5,  /* A0 - A7 */
    0xF9, 0xB8, 0xA6, 0xAE, 0xAA, 0xF0, 0xA9, 0xEE,  /* A8 - AF */
    0xF8, 0xF1, 0xFD, 0xFC, 0xEF, 0xE6, 0xF4, 0xFA,  /* B0 - B7 */
    0xF7, 0xFB, 0xA7, 0xAF, 0xAC, 0xAB, 0xF3, 0xA8,  /* B8 - BF */
    0xB7, 0xB5, 0xB6, 0xC7, 0x8E, 0x8F, 0x92, 0x80,  /* C0 - C7 */
    0xD4, 0x90, 0xD2, 0xD3, 0xDE, 0xD6, 0xD7, 0xD8,  /* C8 - CF */
    0xD1, 0xA5, 0xE3, 0xE0, 0xE2, 0xE5, 0x99, 0x9E,  /* D0 - D7 */
    0x9D, 0xEB, 0xE9, 0xEA, 0x9A, 0xED, 0xE8, 0xE1,  /* D8 - DF */
    0x85, 0xA0, 0x83, 0xC6, 0x84, 0x86, 0x91, 0x87,  /* E0 - E7 */
    0x8A, 0x82, 0x88, 0x89, 0x8D, 0xA1, 0x8C, 0x8B,  /* E8 - EF */
    0xD0, 0xA4, 0x95, 0xA2, 0x93, 0xE4, 0x94, 0xF6,  /* F0 - F7 */
    0x9B, 0x97, 0xA3, 0x96, 0x81, 0xEC, 0xE7, 0x98   /* F8 - FF */
};

const unsigned char oem2iso[] = {
    0xC7, 0xFC, 0xE9, 0xE2, 0xE4, 0xE0, 0xE5, 0xE7,  /* 80 - 87 */
    0xEA, 0xEB, 0xE8, 0xEF, 0xEE, 0xEC, 0xC4, 0xC5,  /* 88 - 8F */
    0xC9, 0xE6, 0xC6, 0xF4, 0xF6, 0xF2, 0xFB, 0xF9,  /* 90 - 97 */
    0xFF, 0xD6, 0xDC, 0xF8, 0xA3, 0xD8, 0xD7, 0x83,  /* 98 - 9F */
    0xE1, 0xED, 0xF3, 0xFA, 0xF1, 0xD1, 0xAA, 0xBA,  /* A0 - A7 */
    0xBF, 0xAE, 0xAC, 0xBD, 0xBC, 0xA1, 0xAB, 0xBB,  /* A8 - AF */
    0xA6, 0xA6, 0xA6, 0xA6, 0xA6, 0xC1, 0xC2, 0xC0,  /* B0 - B7 */
    0xA9, 0xA6, 0xA6, 0x2B, 0x2B, 0xA2, 0xA5, 0x2B,  /* B8 - BF */
    0x2B, 0x2D, 0x2D, 0x2B, 0x2D, 0x2B, 0xE3, 0xC3,  /* C0 - C7 */
    0x2B, 0x2B, 0x2D, 0x2D, 0xA6, 0x2D, 0x2B, 0xA4,  /* C8 - CF */
    0xF0, 0xD0, 0xCA, 0xCB, 0xC8, 0x69, 0xCD, 0xCE,  /* D0 - D7 */
    0xCF, 0x2B, 0x2B, 0xA6, 0x5F, 0xA6, 0xCC, 0xAF,  /* D8 - DF */
    0xD3, 0xDF, 0xD4, 0xD2, 0xF5, 0xD5, 0xB5, 0xFE,  /* E0 - E7 */
    0xDE, 0xDA, 0xDB, 0xD9, 0xFD, 0xDD, 0xAF, 0xB4,  /* E8 - EF */
    0xAD, 0xB1, 0x3D, 0xBE, 0xB6, 0xA7, 0xF7, 0xB8,  /* F0 - F7 */
    0xB0, 0xA8, 0xB7, 0xB9, 0xB3, 0xB2, 0xA6, 0xA0   /* F8 - FF */
};

/* And'ing with mask_bits[n] masks the lower n bits */
const unsigned near mask_bits[17] = {
    0x0000,
    0x0001, 0x0003, 0x0007, 0x000f, 0x001f, 0x003f, 0x007f, 0x00ff,
    0x01ff, 0x03ff, 0x07ff, 0x0fff, 0x1fff, 0x3fff, 0x7fff, 0xffff
};

/* Tables for length and distance */
static const unsigned short cplen2[] =
        {2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
        18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
        35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
        52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65};
static const unsigned short cplen3[] =
        {3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
        19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
        36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52,
        53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66};
static const unsigned char extra[] =
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        8};
static const unsigned short cpdist4[] =
        {1, 65, 129, 193, 257, 321, 385, 449, 513, 577, 641, 705,
        769, 833, 897, 961, 1025, 1089, 1153, 1217, 1281, 1345, 1409, 1473,
        1537, 1601, 1665, 1729, 1793, 1857, 1921, 1985, 2049, 2113, 2177,
        2241, 2305, 2369, 2433, 2497, 2561, 2625, 2689, 2753, 2817, 2881,
        2945, 3009, 3073, 3137, 3201, 3265, 3329, 3393, 3457, 3521, 3585,
        3649, 3713, 3777, 3841, 3905, 3969, 4033};
static const unsigned short cpdist8[] =
        {1, 129, 257, 385, 513, 641, 769, 897, 1025, 1153, 1281,
        1409, 1537, 1665, 1793, 1921, 2049, 2177, 2305, 2433, 2561, 2689,
        2817, 2945, 3073, 3201, 3329, 3457, 3585, 3713, 3841, 3969, 4097,
        4225, 4353, 4481, 4609, 4737, 4865, 4993, 5121, 5249, 5377, 5505,
        5633, 5761, 5889, 6017, 6145, 6273, 6401, 6529, 6657, 6785, 6913,
        7041, 7169, 7297, 7425, 7553, 7681, 7809, 7937, 8065};

#define NUM_METHODS      17     /* number of known method IDs */

static const unsigned ComprIDs[NUM_METHODS] = {
     STORED, SHRUNK, REDUCED1, REDUCED2, REDUCED3, REDUCED4,
     IMPLODED, TOKENIZED, DEFLATED, ENHDEFLATED, DCLIMPLODED,
     BZIPPED, LZMAED, IBMTERSED, IBMLZ77ED, WAVPACKED, PPMDED
   };

static const char CmprNone[]       = "store";
static const char CmprShrink[]     = "shrink";
static const char CmprReduce[]     = "reduce";
static const char CmprImplode[]    = "implode";
static const char CmprTokenize[]   = "tokenize";
static const char CmprDeflate[]    = "deflate";
static const char CmprDeflat64[]   = "deflate64";
static const char CmprDCLImplode[] = "DCL implode";
static const char CmprBzip[]       = "bzip2";
static const char CmprLZMA[]       = "LZMA";
static const char CmprIBMTerse[]   = "IBM/Terse";
static const char CmprIBMLZ77[]    = "IBM LZ77";
static const char CmprWavPack[]    = "WavPack";
static const char CmprPPMd[]       = "PPMd";

static const char *ComprNames[NUM_METHODS] = {
     CmprNone, CmprShrink, CmprReduce, CmprReduce, CmprReduce, CmprReduce,
     CmprImplode, CmprTokenize, CmprDeflate, CmprDeflat64, CmprDCLImplode,
     CmprBzip, CmprLZMA, CmprIBMTerse, CmprIBMLZ77, CmprWavPack, CmprPPMd
   };


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

static const char OS_FAT[] = "MS-DOS, OS/2 or NT FAT";
static const char OS_Amiga[] = "Amiga";
static const char OS_VMS[] = "VMS";
static const char OS_Unix[] = "Unix";
static const char OS_VMCMS[] = "VM/CMS";
static const char OS_AtariST[] = "Atari ST";
static const char OS_HPFS[] = "OS/2 or NT HPFS";
static const char OS_Macintosh[] = "Macintosh HFS";
static const char OS_ZSystem[] = "Z-System";
static const char OS_CPM[] = "CP/M";
static const char OS_TOPS20[] = "TOPS-20";
static const char OS_NTFS[] = "NTFS";
static const char OS_QDOS[] = "SMS/QDOS";
static const char OS_Acorn[] = "Acorn RISC OS";
static const char OS_MVS[] = "MVS";
static const char OS_VFAT[] = "Win32 VFAT";
static const char OS_AtheOS[] = "AtheOS";
static const char OS_BeOS[] = "BeOS";
static const char OS_Tandem[] = "Tandem NSK";
static const char OS_Theos[] = "Theos";
static const char OS_MacDarwin[] = "Mac OS/X (Darwin)";

static const char MthdNone[] = "none (stored)";
static const char MthdShrunk[] = "shrunk";
static const char MthdRedF1[] = "reduced (factor 1)";
static const char MthdRedF2[] = "reduced (factor 2)";
static const char MthdRedF3[] = "reduced (factor 3)";
static const char MthdRedF4[] = "reduced (factor 4)";
static const char MthdImplode[] = "imploded";
static const char MthdToken[] = "tokenized";
static const char MthdDeflate[] = "deflated";
static const char MthdDeflat64[] = "deflated (enhanced-64k)";
static const char MthdDCLImplode[] = "imploded (PK DCL)";
static const char MthdBZip2[] = "bzipped";
static const char MthdLZMA[] = "LZMA-ed";
static const char MthdTerse[] = "tersed (IBM)";
static const char MthdLZ77[] = "LZ77-compressed (IBM)";
static const char MthdWavPack[] = "WavPacked";
static const char MthdPPMd[] = "PPMd-ed";

static const char DeflNorm[] = "normal";
static const char DeflMax[] = "maximum";
static const char DeflFast[] = "fast";
static const char DeflSFast[] = "superfast";

/* Define OS-specific attributes for use on ALL platforms--the S_xxxx
 * versions of these are defined differently (or not defined) by different
 * compilers and operating systems. */

#define UNX_IFMT       0170000     /* Unix file type mask */
#define UNX_IFREG      0100000     /* Unix regular file */
#define UNX_IFSOCK     0140000     /* Unix socket (BSD, not SysV or Amiga) */
#define UNX_IFLNK      0120000     /* Unix symbolic link (not SysV, Amiga) */
#define UNX_IFBLK      0060000     /* Unix block special       (not Amiga) */
#define UNX_IFDIR      0040000     /* Unix directory */
#define UNX_IFCHR      0020000     /* Unix character special   (not Amiga) */
#define UNX_IFIFO      0010000     /* Unix fifo    (BCC, not MSC or Amiga) */
#define UNX_ISUID      04000       /* Unix set user id on execution */
#define UNX_ISGID      02000       /* Unix set group id on execution */
#define UNX_ISVTX      01000       /* Unix directory permissions control */
#define UNX_ENFMT      UNX_ISGID   /* Unix record locking enforcement flag */
#define UNX_IRWXU      00700       /* Unix read, write, execute: owner */
#define UNX_IRUSR      00400       /* Unix read permission: owner */
#define UNX_IWUSR      00200       /* Unix write permission: owner */
#define UNX_IXUSR      00100       /* Unix execute permission: owner */
#define UNX_IRWXG      00070       /* Unix read, write, execute: group */
#define UNX_IRGRP      00040       /* Unix read permission: group */
#define UNX_IWGRP      00020       /* Unix write permission: group */
#define UNX_IXGRP      00010       /* Unix execute permission: group */
#define UNX_IRWXO      00007       /* Unix read, write, execute: other */
#define UNX_IROTH      00004       /* Unix read permission: other */
#define UNX_IWOTH      00002       /* Unix write permission: other */
#define UNX_IXOTH      00001       /* Unix execute permission: other */

#define VMS_IRUSR      UNX_IRUSR   /* VMS read/owner */
#define VMS_IWUSR      UNX_IWUSR   /* VMS write/owner */
#define VMS_IXUSR      UNX_IXUSR   /* VMS execute/owner */
#define VMS_IRGRP      UNX_IRGRP   /* VMS read/group */
#define VMS_IWGRP      UNX_IWGRP   /* VMS write/group */
#define VMS_IXGRP      UNX_IXGRP   /* VMS execute/group */
#define VMS_IROTH      UNX_IROTH   /* VMS read/other */
#define VMS_IWOTH      UNX_IWOTH   /* VMS write/other */
#define VMS_IXOTH      UNX_IXOTH   /* VMS execute/other */

#define AMI_IFMT       06000       /* Amiga file type mask */
#define AMI_IFDIR      04000       /* Amiga directory */
#define AMI_IFREG      02000       /* Amiga regular file */
#define AMI_IHIDDEN    00200       /* to be supported in AmigaDOS 3.x */
#define AMI_ISCRIPT    00100       /* executable script (text command file) */
#define AMI_IPURE      00040       /* allow loading into resident memory */
#define AMI_IARCHIVE   00020       /* not modified since bit was last set */
#define AMI_IREAD      00010       /* can be opened for reading */
#define AMI_IWRITE     00004       /* can be opened for writing */
#define AMI_IEXECUTE   00002       /* executable image, a loadable runfile */
#define AMI_IDELETE    00001       /* can be deleted */

#define THS_IFMT    0xF000         /* Theos file type mask */
#define THS_IFIFO   0x1000         /* pipe */
#define THS_IFCHR   0x2000         /* char device */
#define THS_IFSOCK  0x3000         /* socket */
#define THS_IFDIR   0x4000         /* directory */
#define THS_IFLIB   0x5000         /* library */
#define THS_IFBLK   0x6000         /* block device */
#define THS_IFREG   0x8000         /* regular file */
#define THS_IFREL   0x9000         /* relative (direct) */
#define THS_IFKEY   0xA000         /* keyed */
#define THS_IFIND   0xB000         /* indexed */
#define THS_IFRND   0xC000         /* ???? */
#define THS_IFR16   0xD000         /* 16 bit real mode program */
#define THS_IFP16   0xE000         /* 16 bit protected mode prog */
#define THS_IFP32   0xF000         /* 32 bit protected mode prog */
#define THS_IMODF   0x0800         /* modified */
#define THS_INHID   0x0400         /* not hidden */
#define THS_IEUSR   0x0200         /* erase permission: owner */
#define THS_IRUSR   0x0100         /* read permission: owner */
#define THS_IWUSR   0x0080         /* write permission: owner */
#define THS_IXUSR   0x0040         /* execute permission: owner */
#define THS_IROTH   0x0004         /* read permission: other */
#define THS_IWOTH   0x0002         /* write permission: other */
#define THS_IXOTH   0x0001         /* execute permission: other */

static const char TheosFTypLib[] = "Library     ";
static const char TheosFTypDir[] = "Directory   ";
static const char TheosFTypReg[] = "Sequential  ";
static const char TheosFTypRel[] = "Direct      ";
static const char TheosFTypKey[] = "Keyed       ";
static const char TheosFTypInd[] = "Indexed     ";
static const char TheosFTypR16[] = " 86 program ";
static const char TheosFTypP16[] = "286 program ";
static const char TheosFTypP32[] = "386 program ";
static const char TheosFTypUkn[] = "???         ";

/*##########################################################################
#
#   Name       : str2oem
#
#   Purpose....: str2oem conversion
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *str2oem(char *dst, register const char *src)
{
    register unsigned char c;
    register char *dstp = dst;

    do {
        c = (unsigned char)(*src++);
        *dstp++ = (char)(((c & 0x80) && iso2oem) ? iso2oem[c & 0x7f] : c);

    } while (c != '\0');

    return dst;
}

/*##########################################################################
#
#   Name       : strtolower
#
#   Purpose....: convert string to lower-case
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void strtolower(char *str1, char *str2)
{
   char  *p, *q;
   p = (char *)(str1) - 1;
   q = (char *)(str2);
   while (*++p)
       *q++ = (char)(isupper((int)(*p))? tolower((int)(*p)) : *p);
   *q = 0;
}

/*##########################################################################
#
#   Name       : makeword
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned short makeword(const unsigned char *b)
{
    /*
     * Convert Intel style 'short' integer to non-Intel non-16-bit
     * host format.  This routine also takes care of byte-ordering.
     */
    return (unsigned short)((b[1] << 8) | b[0]);
}


/*##########################################################################
#
#   Name       : makelong
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned long makelong(const unsigned char *sig)
{
    /*
     * Convert intel style 'long' variable to non-Intel non-16-bit
     * host format.  This routine also takes care of byte-ordering.
     */
    return (((unsigned long)sig[3]) << 24)
         + (((unsigned long)sig[2]) << 16)
         + (unsigned long)((((unsigned)sig[1]) << 8)
               + ((unsigned)sig[0]));
}


/*##########################################################################
#
#   Name       : makeint64
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned long makeint64(const unsigned char *sig)
{
    if ((sig[7] | sig[6] | sig[5] | sig[4]) != 0)
        return (unsigned long)0xffffffffL;
    else
        return (unsigned long)((((unsigned long)sig[3]) << 24)
                      + (((unsigned long)sig[2]) << 16)
                      + (((unsigned)sig[1]) << 8)
                      + (sig[0]));

}

/*##########################################################################
#
#   Name       : string_putc
#
#   Purpose....: __prtf callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void string_putc( _SPECS *specs, int op_char )
{
    *( specs->_dest++ ) = op_char;
    specs->_output_count++;
}

/*##########################################################################
#
#   Name       : AsciiToNative
#
#   Purpose....: Convert oem to native
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AsciiToNative(char *string)
{
    unsigned char *p;

    for (p=(unsigned char *)(string); *p; p++)
       *p = (*p & 0x80) ? oem2iso[*p & 0x7f] : *p;
}

/*##########################################################################
#
#   Name       : DosToRdosTime
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DosToRdosTime(unsigned long *msb, unsigned long *lsb, unsigned long dos_datetime)
{
    unsigned short dos_date, dos_time;

    dos_date = (unsigned short)(dos_datetime >> 16);
    dos_time = (unsigned short)(dos_datetime & 0xFFFFL);

    RdosDosTimeDateToTics(dos_date, dos_time, msb, lsb);
}

/*##########################################################################
#
#   Name       : FindCompressMethod
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned FindCompressMethod(unsigned compr_methodnum)
{
    unsigned i;

    for (i = 0; i < NUM_METHODS; i++) {
        if (ComprIDs[i] == compr_methodnum) break;
    }
    return i;
}

/*##########################################################################
#
#   Name       : TUnzip::TUnzip
#
#   Purpose....: Constructor for unzip
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzip::TUnzip()
{
    Init();
}

/*##########################################################################
#
#   Name       : TUnzip::~TUnzip
#
#   Purpose....: Destructor for unzip
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzip::~TUnzip()
{
    delete FInBuf;
    delete FTmpOutBuf;
    delete FOutBuf;
}

/*##########################################################################
#
#   Name       : TUnzip::Init
#
#   Purpose....: Init class
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::Init()
{
    OnTrace = 0;
    OnInfo = 0;

    FOutputHandle = 0;

    FInBuf = new char[INBUFSIZ + 4];    /* 4 extra for hold[] (below) */
    FTmpOutBuf = new char[TMPOUTSIZ];
    FOutBuf = new char[WSIZE + 1];

    FCurrFile = &FFileArr[0];
}

/*##########################################################################
#
#   Name       : TUnzip::Trace
#
#   Purpose....: Trace
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::Trace(const char *format, ...)
{
    va_list ap;
    slib_callback_t *tmp;
    int len;

    va_start(ap, format);

    if (OnTrace)
    {
        len = __prtf(FLogBuf, format, ap, string_putc );
        FLogBuf[len] = 0;
        (*OnTrace)(this, FLogBuf);
    }
}

/*##########################################################################
#
#   Name       : TUnzip::Info
#
#   Purpose....: Info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::Info(int code, const char *format, ...)
{
    va_list ap;
    slib_callback_t *tmp;
    int len;

    va_start(ap, format);

    if (OnInfo)
    {
        len = __prtf(FLogBuf, format, ap, string_putc );
        FLogBuf[len] = 0;
        (*OnInfo)(this, code, FLogBuf);
    }
}

/*##########################################################################
#
#   Name       : TUnzip::DisplayHeaderString
#
#   Purpose....: Display info from zip-file at current position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::DisplayHeaderString(int length, int oemconvert)
{
    unsigned comment_bytes_left;
    unsigned int block_len;

    comment_bytes_left = length;
    block_len = WSIZE;       /* for the while statement, first time */

    while (comment_bytes_left > 0 && block_len > 0) {
        char *p = FOutBuf;
        char *q = FOutBuf;

        if ((block_len = ReadBuf(FOutBuf,
                   MIN(WSIZE, comment_bytes_left))) == 0)
            return;

        comment_bytes_left -= block_len;

        /* this is why we allocated an extra byte for outbuf:  terminate
             *  with zero (ASCIIZ) */
        FOutBuf[block_len] = 0;

       /* remove all ASCII carriage returns from comment before printing
       * (since used before A_TO_N(), check for CR instead of '\r')
       */

        while (*p) {
            while (*p == CR)
                ++p;
            *q++ = *p++;
        }
        /* could check whether (p - outbuf) == block_len here */
        *q = 0;

        if (oemconvert) {
        /* translate the text coded in the entry's host-dependent
        "extended ASCII" charset into the compiler's (system's)
        internal text code page */
            AsciiToNative(FOutBuf);
        }

        Info(0, FOutBuf);
    }
    /* add '\n' if not at start of line */
    Info(0, "\n");
}

/*##########################################################################
#
#   Name       : TUnzip::SkipHeaderString
#
#   Purpose....: Skip over header string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::SkipHeaderString(int length)
{
        /* cur_zipfile_bufstart already takes account of extra_bytes, so don't
         * correct for it twice: */
    Seek(FBufStart - FExtraBytes + (FInPtr-FInBuf) + length);
}

/*##########################################################################
#
#   Name       : TUnzip::SetupEncryption
#
#   Purpose....: Set encryption keys
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::SetupEncryption(const char *password)
{
    FKeys[0] = 305419896L;
    FKeys[1] = 591751049L;
    FKeys[2] = 878082192L;
    
    while (*password) {
        UpdateKeys((int)*password);
        password++;
    }
}

/*##########################################################################
#
#   Name       : TUnzip::SetInputFile
#
#   Purpose....: Set input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::SetInputFile(const char *filename)
{
    FInputFileName = filename;
}

/*##########################################################################
#
#   Name       : TUnzip::OpenInputFile
#
#   Purpose....: Open input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::OpenInputFile()    /* return 1 if open failed */
{
    /*
     *  open the zipfile for reading and in BINARY mode to prevent cr/lf
     *  translation, which would corrupt the bitstreams
     */

    FInputHandle = RdosOpenFile(FInputFileName.GetData(), 0);

    if (!FInputHandle)
    {
        Info(0x401, "error:  cannot open zipfile [ %s ]\n",
          FInputFileName.GetData());
        return 1;
    }
    return 0;

}


/*##########################################################################
#
#   Name       : TUnzip::ReadBuf
#
#   Purpose....: Read from input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned TUnzip::ReadBuf(char *buf, register unsigned size)   /* return number of bytes read into buf */
{
    register unsigned count;
    unsigned n;

    n = size;
    while (size) {
        if (FInCount <= 0) {
            FInCount = RdosReadFile(FInputHandle, FInBuf, INBUFSIZ);
            if (FInCount == 0)
                return (n-size);

            /* buffer ALWAYS starts on a block boundary:  */
            FBufStart += INBUFSIZ;
            FInPtr = FInBuf;
        }
        count = MIN(size, (unsigned)FInCount);
        memcpy(buf, FInPtr, count);
        buf += count;
        FInPtr += count;
        FInCount -= count;
        size -= count;
    }
    return n;

} /* end function readbuf() */

/*##########################################################################
#
#   Name       : TUnzip::UndeferInput
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::UndeferInput()
{
    if (FInCount > 0)
        FDecompSize += FInCount;
    if (FLeftoverCount > 0) {
        FInCount = FLeftoverCount + FDecompSize;
        FInPtr = FLeftoverPtr - FDecompSize;
        FLeftoverCount = 0;
    } else if (FInCount < 0)
        FInCount = 0;
} /* end function undefer_input() */

/*##########################################################################
#
#   Name       : TUnzip::DeferInput
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::DeferInput()
{
    if (FInCount > FDecompSize) {
        if (FDecompSize < 0L)
            FDecompSize = 0L;
        FLeftoverPtr = FInPtr + FDecompSize;
        FLeftoverCount = FInCount - FDecompSize;
        FInCount = FDecompSize;
    } else
        FLeftoverCount = 0;
    FDecompSize -= FInCount;
} /* end function defer_input() */

/*##########################################################################
#
#   Name       : TUnzip::DecryptByte
#
#   Purpose....: Return the next byte in the pseudo-random sequence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::DecryptByte()
{
    unsigned temp;  /* POTENTIAL BUG:  temp*(temp^1) may overflow in an
                     * unpredictable manner on 16-bit systems; not a problem
                     * with any known compiler so far, though */

    temp = ((unsigned)FKeys[2] & 0xffff) | 2;
    return (int)(((temp * (temp ^ 1)) >> 8) & 0xff);
}

/*##########################################################################
#
#   Name       : TUnzip::Decrypt
#
#   Purpose....: Decrypt
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::Decrypt()
{
    unsigned short b;
    int n, r;
    unsigned char h[RAND_HEAD_LEN];

    /* get header once (turn off "encrypted" flag temporarily so we don't
     * try to decrypt the same data twice) */
    FCurrFile->encrypted = FALSE;
    DeferInput();
    
    for (n = 0; n < RAND_HEAD_LEN; n++) {
        b = GetNextByte();
        h[n] = (unsigned char)b;
    }
    UndeferInput();
    FCurrFile->encrypted = TRUE;

    return PK_WARN;

} /* end function decrypt() */


/*##########################################################################
#
#   Name       : TUnzip::UpdateKeys
#
#   Purpose....: Update the encryption keys with the next byte of plain text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::UpdateKeys(int c)
{
   int keyshift;

    FKeys[0] = crctab[(int)(FKeys[0] ^ c) & 0xff] ^ (c >> 8);
    FKeys[1] = (FKeys[1] + FKeys[0] & 0xff) * 134775813L + 1;

    keyshift = FKeys[1] >> 24;
    FKeys[2] = crctab[(int)(FKeys[2] ^ keyshift) & 0xff] ^ (keyshift >> 8);

    return c;
}

/*##########################################################################
#
#   Name       : TUnzip::ZDecode
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::ZDecode(int c)
{
    c ^= DecryptByte();
    return UpdateKeys(c);
}

/*##########################################################################
#
#   Name       : TUnzip::ReadByte
#
#   Purpose....: Read byte input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::ReadByte()   /* refill inbuf and return a byte if available, else EOF */
{
    if (FDecompSize <= 0) {
        FDecompSize--;             /* for tests done after exploding */
        FInCount = 0;
        return EOF;
    }
    if (FInCount <= 0) {
        FInCount = RdosReadFile(FInputHandle, FInBuf, INBUFSIZ);
        if (FInCount == 0)
            return EOF;

        FBufStart += INBUFSIZ; /* always starts on block bndry */
        FInPtr = FInBuf;
        DeferInput();           /* decrements G.csize */
    }

    if (FCurrFile && FCurrFile->encrypted) {
        char *p;
        int n;

        /* This was previously set to decrypt one byte beyond G.csize, when
         * incnt reached that far.  GRR said, "but it's required:  why?"  This
         * was a bug in fillinbuf() -- was it also a bug here?
         */
        for (n = FInCount, p = FInPtr;  n--;  p++)
            *p = ZDecode(*p);
    }

    --FInCount;
    return *FInPtr++;

} /* end function readbyte() */


/*##########################################################################
#
#   Name       : TUnzip::GetNextByte
#
#   Purpose....: Get next byte from input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::GetNextByte()
{
    return (FInCount-- > 0 ? (int)(*FInPtr++) : ReadByte());
}


/*##########################################################################
#
#   Name       : TUnzip::GetInbuf
#
#   Purpose....: Function get inbuf()
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TUnzip::GetInbuf()
{
    return FInBuf;
}

/*##########################################################################
#
#   Name       : TUnzip::FillInbuf
#
#   Purpose....: Function fillinbuf()
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::FillInbuf() /* like readbyte() except returns number of bytes in inbuf */
{
    FInCount = RdosReadFile(FInputHandle, FInBuf, INBUFSIZ);
    if (FInCount <= 0)
        return 0;

    FBufStart += INBUFSIZ;  /* always starts on a block boundary */
    FInPtr = FInBuf;
    DeferInput();           /* decrements G.csize */

    if (FCurrFile && FCurrFile->encrypted) {
        char *p;
        int n;

        for (n = FInCount, p = FInPtr;  n--;  p++)
            *p = ZDecode(*p);
    }

    return FInCount;

} /* end function fillinbuf() */


/*##########################################################################
#
#   Name       : TUnzip::Seek
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::Seek(long abs_offset)
{
/*
 *  Seek to the block boundary of the block which includes abs_offset,
 *  then read block into input buffer and set pointers appropriately.
 *  If block is already in the buffer, just set the pointers.  This function
 *  is used by do_seekable (process.c), extract_or_test_entrylist (extract.c)
 *  and do_string (fileio.c).  Also, a slightly modified version is embedded
 *  within extract_or_test_entrylist (extract.c).  readbyte() and readbuf()
 *  (fileio.c) are compatible.  NOTE THAT abs_offset is intended to be the
 *  "proper offset" (i.e., if there were no extra bytes prepended);
 *  cur_zipfile_bufstart contains the corrected offset.
 *
 *  Since seek_zipf() is never used during decompression, it is safe to
 *  use the slide[] buffer for the error message.
 *
 * returns PK error codes:
 *  PK_BADERR if effective offset in zipfile is negative
 *  PK_EOF if seeking past end of zipfile
 *  PK_OK when seek was successful
 */
    long request = abs_offset + FExtraBytes;
    long inbuf_offset = request % INBUFSIZ;
    long bufstart = request - inbuf_offset;

    if (request < 0)
        return(PK_BADERR);
    
    if (bufstart != FBufStart) {
        RdosSetFilePos(FInputHandle, bufstart);
        FBufStart = RdosGetFilePos(FInputHandle);
        FInCount = RdosReadFile(FInputHandle, FInBuf, INBUFSIZ);
        if (FInCount <= 0)
            return(PK_EOF);
        FInCount -= (int)inbuf_offset;
        FInPtr = FInBuf + (int)inbuf_offset;
    } else {
        FInCount += (FInPtr-FInBuf) - (int)inbuf_offset;
        FInPtr = FInBuf + (int)inbuf_offset;
    }
    return(PK_OK);
} /* end function seek_zipf() */


/*##########################################################################
#
#   Name       : TUnzip::GetFileName
#
#   Purpose....: Get filename from header
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::GetFileName(int length)
{
    int block_len;
    int error = PK_OK;

    if (length >= FILE_NAME_SIZE) {
        Info(0x401, "warning:  filename too long--truncating.\n");

        error = PK_WARN;
        /* remember excess length in block_len */
        block_len = length - (FILE_NAME_SIZE - 1);
        length = FILE_NAME_SIZE - 1;
    } 
    else
        /* no excess size */
        block_len = 0;

    if (ReadBuf(FCurrFileName, length) == 0)
        return PK_EOF;

    FCurrFileName[length] = '\0';      /* terminate w/zero:  ASCIIZ */

    /* translate the Zip entry filename coded in host-dependent "extended
           ASCII" into the compiler's (system's) internal text code page */
    AsciiToNative(FCurrFileName);

    strtolower(FCurrFileName, FCurrFileName);

    if (block_len)         /* no overflow, we're done here */
    {
        Info(0x401, "[ %s ]\n", FCurrFileName);
        SkipHeaderString(block_len);
    }

     return PK_OK;
}

/*##########################################################################
#
#   Name       : TUnzip::DirEntryToFile
#
#   Purpose....: Convert dir-entry to file entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::DirEntryToFile(struct TUnzipFile *file, const char *filename)
{
     unsigned cmpridx;

/*---------------------------------------------------------------------------
    Check central directory info for version/compatibility requirements.
  ---------------------------------------------------------------------------*/

    if (file->version_needed_to_extract[0] > UNZIP_VERSION) {
        Info(0x401, "   skipping: %-22s  need %s compat. v%u.%u (can do v%u.%u)\n",
              filename, "PK",
              file->version_needed_to_extract[0] / 10,
              file->version_needed_to_extract[0] % 10,
              UNZIP_VERSION / 10, UNZIP_VERSION % 10);
        return PK_WARN;
    }

    if ((file->compression_method >= REDUCED1 && file->compression_method <= REDUCED4) ||
        file->compression_method==TOKENIZED ||
        (file->compression_method>DEFLATED))
    {
        cmpridx = FindCompressMethod(file->compression_method);
        if (cmpridx < NUM_METHODS)
            Info(0x401, "   skipping: %-22s  `%s' method not supported\n",
              filename,
              ComprNames[cmpridx]);
        else
            Info(0x401, "   skipping: %-22s  unsupported compression method %u\n",
              filename,
              file->compression_method);
        return PK_WARN;
    }

    /* store a copy of the central header filename for later comparison */
    file->cfilname = new char[strlen(filename) + 1];
    if (file->cfilname == 0) {
        Info(0x401, "%s:  warning, no memory for comparison with local header\n", filename);
    } else
        strcpy(file->cfilname, filename);

    return PK_COOL;

} /* end function store_info() */

/*##########################################################################
#
#   Name       : TUnzip::AddFile
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::AddFile()    /* return PK-type error code */
{
    int error;
    unsigned short filename_length;
    unsigned short extra_field_length;
    unsigned short file_comment_length;
    unsigned long dos_datetime;
    unsigned char byterec[ CREC_SIZE ];
    struct TUnzipFile *file = FCurrFile;

/*---------------------------------------------------------------------------
    Read the next central directory entry and do any necessary machine-type
    conversions (byte ordering, structure padding compensation--do so by
    copying the data from the array into which it was read (byterec) to the
    usable struct (crec)).
  ---------------------------------------------------------------------------*/

    if (ReadBuf((char *)byterec, CREC_SIZE) == 0)
        return PK_EOF;

    file->hostver = byterec[C_VERSION_MADE_BY_0];
    file->hostnum = MIN(byterec[C_VERSION_MADE_BY_1], NUM_HOSTS);

    file->version_needed_to_extract[0] = byterec[C_VERSION_NEEDED_TO_EXTRACT_0];
    file->version_needed_to_extract[1] = byterec[C_VERSION_NEEDED_TO_EXTRACT_1];

    file->general_purpose_bit_flag = makeword(&byterec[C_GENERAL_PURPOSE_BIT_FLAG]);
    file->encrypted = file->general_purpose_bit_flag & 1;   /* bit field */
    file->ExtLocHdr = (file->general_purpose_bit_flag & 8) == 8;  /* bit */

    dos_datetime = makelong(&byterec[C_LAST_MOD_DOS_DATETIME]);
    DosToRdosTime(&file->rdos_msb_time, &file->rdos_lsb_time, dos_datetime);

    file->crc = makelong(&byterec[C_CRC32]);
    file->compr_size = makelong(&byterec[C_COMPRESSED_SIZE]);
    file->uncompr_size = makelong(&byterec[C_UNCOMPRESSED_SIZE]);
    file->compression_method = makeword(&byterec[C_COMPRESSION_METHOD]);

    filename_length = makeword(&byterec[C_FILENAME_LENGTH]);
    extra_field_length = makeword(&byterec[C_EXTRA_FIELD_LENGTH]);
    file_comment_length = makeword(&byterec[C_FILE_COMMENT_LENGTH]);

    file->diskstart = makeword(&byterec[C_DISK_NUMBER_START]);

    file->internal_file_attributes = makeword(&byterec[C_INTERNAL_FILE_ATTRIBUTES]);
    file->external_file_attributes = makelong(&byterec[C_EXTERNAL_FILE_ATTRIBUTES]);  /* LONG, not word! */
    file->textfile = file->internal_file_attributes & 1;    /* bit field */

    file->offset = makelong(&byterec[C_RELATIVE_OFFSET_LOCAL_HEADER]);

/*---------------------------------------------------------------------------
    Get central directory info, save host and method numbers, and set flag
    for lowercase conversion of filename, depending on the OS from which the
    file is coming.
  ---------------------------------------------------------------------------*/

    switch (file->hostnum) {
        case FS_FAT_:     /* PKZIP and zip -k store in uppercase */
        case CPM_:        /* like MS-DOS, right? */
        case VM_CMS_:     /* all caps? */
        case MVS_:        /* all caps? */
        case TANDEM_:
        case TOPS20_:
        case VMS_:        /* our Zip uses lowercase, but ASi's doesn't */
        /*  case Z_SYSTEM_:   ? */
        /*  case QDOS_:       ? */
            file->lcflag = 1;   /* convert filename to lowercase */
            break;

        default:     /* AMIGA_, FS_HPFS_, FS_NTFS_, MAC_, UNIX_, ATARI_, */
            file->lcflag = 0;
            break;   /*  FS_VFAT_, ATHEOS_, BEOS_ (Z_SYSTEM_), THEOS_: */
                         /*  no conversion */
    }

    /* do Amigas (AMIGA_) also have volume labels? */
    if ((file->external_file_attributes & 0x8) &&
        (file->hostnum == FS_FAT_ || file->hostnum == FS_HPFS_ ||
         file->hostnum == FS_NTFS_ || file->hostnum == ATARI_))
    {
        file->vollabel = TRUE;
        file->lcflag = 0;        /* preserve case of volume labels */
    } else
        file->vollabel = FALSE;

    /* this flag is needed to detect archives made by "PKZIP for Unix" when
       deciding which kind of codepage conversion has to be applied to
       strings (see do_string() function in fileio.c) */
    file->HasUxAtt = (file->external_file_attributes & 0xffff0000L) != 0L;

    error = GetFileName(filename_length);
    if (error != PK_COOL)
    {
        if (error > PK_WARN) {  /* fatal:  no more left to do */
            Info(0x401,
              "%s:  bad filename length (%s)\n",
              FCurrFileName, "central");
        }
        return error;
    }

    SkipHeaderString(extra_field_length);
    SkipHeaderString(file_comment_length);

    error = DirEntryToFile(file, FCurrFileName);

    return error;
}

/*##########################################################################
#
#   Name       : TUnzip::SeekFile
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::SeekFile(struct TUnzipFile *file)    /* return PK-type error code */
{
    long bufstart, inbuf_offset, request;
    int error;
    char sig[4];
    static const char SeekMsg[] =  "error [%s]:  attempt to seek before beginning of zipfile\n";
    static const char OffsetMsg[] = "bad zipfile offset (%s):  %ld\n";
    static char local_hdr_sig[4]     = {0x50, 0x4B, 0x03, 0x04};

    /* if the target position is not within the current input buffer
     * (either haven't yet read enough, or (maybe) skipping back-
     * ward), skip to the target position and reset readbuf(). */

    /* seek_zipf(pInfo->offset);  */
    request = file->offset + FExtraBytes;
    inbuf_offset = request % INBUFSIZ;
    bufstart = request - inbuf_offset;

    if (request < 0) {
        Info(0x401, SeekMsg, FInputFileName.GetData());
        if (file == &FFileArr[0] && FExtraBytes != 0L) {
            FOldExtraBytes =  FExtraBytes;
            FExtraBytes = 0L;
            request = file->offset;  /* could also check if != 0 */
            inbuf_offset = request % INBUFSIZ;
            bufstart = request - inbuf_offset;
            /* try again */
            if (request < 0) {
                Info(0x401, SeekMsg, FInputFileName.GetData());
                return PK_BADERR;
            }
        } else {
            return PK_BADERR;
        }
    }

    if (bufstart != FBufStart) {
        RdosSetFilePos(FInputHandle, bufstart);
        FBufStart = RdosGetFilePos(FInputHandle);
        FInCount = RdosReadFile(FInputHandle, FInBuf, INBUFSIZ);
        if (FInCount <= 0)
        {
            Info(0x401, OffsetMsg, "lseek", bufstart);
            return PK_BADERR;
        }
        FInPtr = FInBuf + (int)inbuf_offset;
        FInCount -= (int)inbuf_offset;
    } else {
        FInCount += (int)(FInPtr-FInBuf) - (int)inbuf_offset;
        FInPtr = FInBuf + (int)inbuf_offset;
    }

    /* should be in proper position now, so check for sig */
    if (ReadBuf(sig, 4) == 0) {  /* bad offset */
        Info(0x401, OffsetMsg, "EOF", request);
        return PK_BADERR;
    }

    if (memcmp(sig, local_hdr_sig, 4)) {
        Info(0x401, OffsetMsg, "signature", request);
        if ((file == &FFileArr[0] &&  FExtraBytes != 0L) ||
                ( FExtraBytes == 0L && FOldExtraBytes != 0L)) {
            if (FExtraBytes) {
                FOldExtraBytes = FExtraBytes;
                FExtraBytes = 0L;
            } else
                FExtraBytes = FOldExtraBytes; /* third attempt */

            error = Seek(file->offset);
            if ((error != PK_OK) || (ReadBuf(sig, 4) == 0)) {  /* bad offset */
                if (error != PK_BADERR)
                    Info(0x401, OffsetMsg, "EOF", request);
                return PK_BADERR;
            }
            if (memcmp(sig, local_hdr_sig, 4)) {
                Info(0x401, OffsetMsg, "signature", request);
                return PK_BADERR;
            }
        } else
            return PK_ERR;
    }
    return PK_COOL;
}

/*##########################################################################
#
#   Name       : TUnzip::ProcessFile
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::ProcessFile()
{
    unsigned long dos_datetime;
    unsigned char byterec[ LREC_SIZE ];
    int error;
    long bufstart;
    char *inptr;
    int incnt;
    unsigned long csize;
    unsigned long ucsize;
    unsigned long rdos_msb_time;
    unsigned long rdos_lsb_time;
    unsigned long crc32;
    unsigned char version_needed_to_extract[2];
    unsigned short general_purpose_bit_flag;
    unsigned short compression_method;
    unsigned short filename_length;
    unsigned short extra_field_length;

    bufstart = FBufStart;
    inptr = FInPtr;
    incnt = FInCount;
    
    error = SeekFile(FCurrFile);

    if (error == PK_COOL)
    {

/*---------------------------------------------------------------------------
    Read the next local file header and do any necessary machine-type con-
    versions (byte ordering, structure padding compensation--do so by copy-
    ing the data from the array into which it was read (byterec) to the
    usable struct (lrec)).
  ---------------------------------------------------------------------------*/

        if (ReadBuf((char *)byterec, LREC_SIZE) == 0)
            error = PK_EOF;
        else
        {
            version_needed_to_extract[0] = byterec[L_VERSION_NEEDED_TO_EXTRACT_0];
            version_needed_to_extract[1] = byterec[L_VERSION_NEEDED_TO_EXTRACT_1];

            general_purpose_bit_flag = makeword(&byterec[L_GENERAL_PURPOSE_BIT_FLAG]);
            compression_method = makeword(&byterec[L_COMPRESSION_METHOD]);

            dos_datetime = makelong(&byterec[L_LAST_MOD_DOS_DATETIME]);
            DosToRdosTime(&rdos_msb_time, &rdos_lsb_time, dos_datetime);

            crc32 = makelong(&byterec[L_CRC32]);
            csize = makelong(&byterec[L_COMPRESSED_SIZE]);
            ucsize = makelong(&byterec[L_UNCOMPRESSED_SIZE]);
            filename_length = makeword(&byterec[L_FILENAME_LENGTH]);
            extra_field_length = makeword(&byterec[L_EXTRA_FIELD_LENGTH]);

            if ((general_purpose_bit_flag & 8) != 0) {
                /* can't trust local header, use central directory: */
        /*       FCurrFile.crc32 = G.pInfo->crc;
                FCurrFile.csize = G.pInfo->compr_size;
                FCurrFile.ucsize = G.pInfo->uncompr_size; */
            }
        }
    }

    if (error == PK_COOL)
        error = GetFileName(filename_length);

    if (error != PK_COOL)
        Info(0x421, "bad local header\n");

    if (error == PK_COOL)
    {
        SkipHeaderString(extra_field_length);
        FCurrFile->file_data_offset = FBufStart - FExtraBytes + (FInPtr-FInBuf);
    }

    RdosSetFilePos(FInputHandle, bufstart);
    FBufStart = RdosGetFilePos(FInputHandle);
    RdosReadFile(FInputHandle, FInBuf, INBUFSIZ);  /* been here before... */
    FInPtr = inptr;
    FInCount = incnt;

    return error;
}

/*##########################################################################
#
#   Name       : TUnzip::OpenOutputFile
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::OpenOutputFile()           /* return 1 if fail */
{
    FCurrCrcVal = 0;
    FCrLast = FALSE;

    FOutputHandle = RdosCreateFile(FCurrFile->cfilname, 0);
    if (!FOutputHandle) {
        Info(0x401, "error:  cannot create %s\n", FCurrFile->cfilname);
        return 1;
    }
    return 0;

} /* end function open_outfile() */

/*##########################################################################
#
#   Name       : TUnzip::CloseOutputFile
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::CloseOutputFile()
{
    RdosCloseFile(FOutputHandle);
    FOutputHandle = 0;

} /* end function close_outfile() */


/*##########################################################################
#
#   Name       : TUnzip::CloseAndSetTime
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::CloseAndSetTime()
{
    RdosSetFileTime(FOutputHandle, FCurrFile->rdos_msb_time, FCurrFile->rdos_lsb_time);
    RdosCloseFile(FOutputHandle);
}

/*##########################################################################
#
#   Name       : TUnzip::DiskError
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::DiskError()
{
/*    Info(0x4a1, DiskFullQuery,
      FnFilter1(UnzipClass.FCurrFile->cfilname));

    fgets(G.answerbuf, sizeof(G.answerbuf), stdin);
    if (*G.answerbuf == 'y')
        G.disk_full = 1;    
    else
        G.disk_full = 2;    
*/

    FDiskFull = 1;

    return PK_DISK;
} /* end function disk_error() */



/*##########################################################################
#
#   Name       : TUnzip::Flush
#
#   Purpose....: returns PK error codes:
#                 if tflag => always 0; PK_DISK if write error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::Flush(char *rawbuf, int size)
{
    char *p;
    char *q;

/*---------------------------------------------------------------------------
    Compute the CRC first; if testing or if disk is full, that's it.
  ---------------------------------------------------------------------------*/

    FCurrCrcVal = crc32(FCurrCrcVal, (unsigned char *)rawbuf, size);

    if (!FOutputHandle || size == 0L)  /* testing or nothing to write:  all done */
        return PK_OK;

    if (FDiskFull)
        return PK_DISK;         /* disk already full:  ignore rest of file */

/*---------------------------------------------------------------------------
    Write the bytes rawbuf[0..size-1] to the output device, first converting
    end-of-lines and ASCII/EBCDIC as needed.  If SMALL_MEM or MED_MEM are NOT
    defined, outbuf is assumed to be at least as large as rawbuf and is not
    necessarily checked for overflow.
  ---------------------------------------------------------------------------*/

    if (FCurrFile && FCurrFile->textfile) {

    /*-----------------------------------------------------------------------
        Algorithm:  CR/LF => native; lone CR => native; lone LF => native.
        This routine is only for non-raw-VMS, non-raw-VM/CMS files (i.e.,
        stream-oriented files, not record-oriented).
      -----------------------------------------------------------------------*/

        p = rawbuf;
        if (*p == LF && FCrLast)
            ++p;
        FCrLast = FALSE;
        for (q = FTmpOutBuf;  (p-rawbuf) < size;  ++p) {
            if (*p == CR) {           /* lone CR or CR/LF: treat as EOL  */
                *q++ = CR; 
                *q++ = LF;
                if (p-rawbuf == size-1)
                    /* last char in buffer */
                    FCrLast = TRUE;
                else if (p[1] == LF)  /* get rid of accompanying LF */
                    ++p;
            } else if (*p == LF)      /* lone LF */
            {
                *q++ = CR; 
                *q++ = LF;
            }
            else
            if (*p != CTRLZ)          /* lose all ^Z's */
                *q++ = *p;

        }

    /*-----------------------------------------------------------------------
        Done translating:  write whatever we've got to file (or screen).
      -----------------------------------------------------------------------*/

        if (q > FTmpOutBuf) {
            if (!RdosWriteFile(FOutputHandle, FTmpOutBuf, q-FTmpOutBuf))
                return DiskError();
        }
    } else {   /* binary mode:  aflag is false */

        /* write raw binary data */
        /* GRR:  note that for standard MS-DOS compilers, size argument to
         * fwrite() can never be more than 65534, so WriteError macro will
         * have to be rewritten if size can ever be that large.  For now,
         * never more than 32K.  Also note that write() returns an int, which
         * doesn't necessarily limit size to 32767 bytes if write() is used
         * on 16-bit systems but does make it more of a pain; however, because
         * at least MSC 5.1 has a lousy implementation of fwrite() (as does
         * DEC Ultrix cc), write() is used anyway.
         */
        if (!RdosWriteFile(FOutputHandle, rawbuf, size))
            return DiskError();
    }

    return PK_OK;

} /* end function flush() [resp. partflush() for 16-bit Deflate64 support] */


/*##########################################################################
#
#   Name       : TUnzip::ExplodeGetTree
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::ExplodeGetTree(unsigned *l, unsigned n)
/* Get the bit lengths for a code representation from the compressed
   stream.  If get_tree() returns 4, then there is an error in the data.
   Otherwise zero is returned. */
{
  unsigned i;           /* bytes remaining in list */
  unsigned k;           /* lengths entered */
  unsigned j;           /* number of codes */
  unsigned b;           /* bit length for those codes */


  /* get bit lengths */
  i = GetNextByte() + 1;                     /* length/count pairs to read */
  k = 0;                                /* next code */
  do {
    b = ((j = GetNextByte()) & 0xf) + 1;     /* bits in code (1..16) */
    j = ((j & 0xf0) >> 4) + 1;          /* codes with those bits (1..16) */
    if (k + j > n)
      return 4;                         /* don't overflow l[] */
    do {
      l[k++] = b;
    } while (--j);
  } while (--i);
  return k != n ? 4 : 0;                /* should have read n of them */
}

/*##########################################################################
#
#   Name       : TUnzip::BuildHuft
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::BuildHuft(const unsigned *b, unsigned n, unsigned s, const unsigned short *d, const unsigned char *e, TUnzipHuft **t, unsigned *m)
/* Given a list of code lengths and a maximum table size, make a set of
   tables to decode that set of codes.  Return zero on success, one if
   the given code set is incomplete (the tables are still built in this
   case), two if the input is invalid (all zero length codes or an
   oversubscribed set of lengths), and three if not enough memory.
   The code with value 256 is special, and the tables are constructed
   so that no bits beyond that code are fetched when that code is
   decoded. */
{
  unsigned a;                   /* counter for codes of length k */
  unsigned c[BMAX+1];           /* bit length count table */
  unsigned el;                  /* length of EOB code (value 256) */
  unsigned f;                   /* i repeats in table every f entries */
  int g;                        /* maximum code length */
  int h;                        /* table level */
  register unsigned i;          /* counter, current code */
  register unsigned j;          /* counter */
  register int k;               /* number of bits in current code */
  int lx[BMAX+1];               /* memory for l[-1..BMAX-1] */
  int *l = lx+1;                /* stack of bits per table */
  register unsigned *p;         /* pointer into c[], b[], or v[] */
  register TUnzipHuft *q;      /* points to current table */
  struct TUnzipHuft r;                /* table entry for structure assignment */
  struct TUnzipHuft *u[BMAX];         /* table stack */
  unsigned v[N_MAX];            /* values in order of bit length */
  register int w;               /* bits before this table == (l * h) */
  unsigned x[BMAX+1];           /* bit offsets, then code stack */
  unsigned *xp;                 /* pointer into x */
  int y;                        /* number of dummy codes added */
  unsigned z;                   /* number of entries in current table */


  /* Generate counts for each bit length */
  el = n > 256 ? b[256] : BMAX; /* set length of EOB code, if any */
  memset((char *)c, 0, sizeof(c));
  p = (unsigned *)b;  i = n;
  do {
    c[*p]++; p++;               /* assume all entries <= BMAX */
  } while (--i);
  if (c[0] == n)                /* null input--all zero length codes */
  {
    *t = 0;
    *m = 0;
    return 0;
  }


  /* Find minimum and maximum length, bound *m by those */
  for (j = 1; j <= BMAX; j++)
    if (c[j])
      break;
  k = j;                        /* minimum code length */
  if (*m < j)
    *m = j;
  for (i = BMAX; i; i--)
    if (c[i])
      break;
  g = i;                        /* maximum code length */
  if (*m > i)
    *m = i;


  /* Adjust last length count to fill out codes, if needed */
  for (y = 1 << j; j < i; j++, y <<= 1)
    if ((y -= c[j]) < 0)
      return 2;                 /* bad input: more codes than bits */
  if ((y -= c[i]) < 0)
    return 2;
  c[i] += y;


  /* Generate starting offsets into the value table for each length */
  x[1] = j = 0;
  p = c + 1;  xp = x + 2;
  while (--i) {                 /* note that i == g from above */
    *xp++ = (j += *p++);
  }


  /* Make a table of values in order of bit lengths */
  memset((char *)v, 0, sizeof(v));
  p = (unsigned *)b;  i = 0;
  do {
    if ((j = *p++) != 0)
      v[x[j]++] = i;
  } while (++i < n);
  n = x[g];                     /* set n to length of v */


  /* Generate the Huffman codes and for each, make the table entries */
  x[0] = i = 0;                 /* first Huffman code is zero */
  p = v;                        /* grab values in bit order */
  h = -1;                       /* no tables yet--level -1 */
  w = l[-1] = 0;                /* no bits decoded yet */
  u[0] = 0;                     /* just to keep compilers happy */
  q = 0;                        /* ditto */
  z = 0;                        /* ditto */

  /* go through the bit lengths (k already is bits in shortest code) */
  for (; k <= g; k++)
  {
    a = c[k];
    while (a--)
    {
      /* here i is the Huffman code of length k bits for value *p */
      /* make tables up to required level */
      while (k > w + l[h])
      {
        w += l[h++];            /* add bits already decoded */

        /* compute minimum size table less than or equal to *m bits */
        z = (z = g - w) > *m ? *m : z;                  /* upper limit */
        if ((f = 1 << (j = k - w)) > a + 1)     /* try a k-w bit table */
        {                       /* too few codes for k-w bit table */
          f -= a + 1;           /* deduct codes from patterns left */
          xp = c + k;
          while (++j < z)       /* try smaller tables up to z bits */
          {
            if ((f <<= 1) <= *++xp)
              break;            /* enough codes to use up j bits */
            f -= *xp;           /* else deduct codes from patterns */
          }
        }
        if ((unsigned)w + j > el && (unsigned)w < el)
          j = el - w;           /* make EOB code end at table */
        z = 1 << j;             /* table entries for j-bit table */
        l[h] = j;               /* set table size in stack */

        /* allocate and link in new table */
        q = new struct TUnzipHuft[z + 1];
        if (q == 0)
        {
          if (h)
            FreeHuft(u[0]);
          return 3;             /* not enough memory */
        }

        *t = q + 1;             /* link to list for huft_free() */
        *(t = &(q->v.t)) = 0;
        u[h] = ++q;             /* table starts after link */

        /* connect to last table, if there is one */
        if (h)
        {
          x[h] = i;             /* save pattern for backing up */
          r.b = (unsigned char)l[h-1];    /* bits to dump before this table */
          r.e = (unsigned char)(32 + j);  /* bits in this table */
          r.v.t = q;            /* pointer to this table */
          j = (i & ((1 << w) - 1)) >> (w - l[h-1]);
          u[h-1][j] = r;        /* connect to last table */
        }
      }

      /* set up table entry in r */
      r.b = (unsigned char)(k - w);
      if (p >= v + n)
        r.e = INVALID_CODE;     /* out of values--invalid code */
      else if (*p < s)
      {
        r.e = (unsigned char)(*p < 256 ? 32 : 31);  /* 256 is end-of-block code */
        r.v.n = (unsigned short)*p++;                /* simple code is just the value */
      }
      else
      {
        r.e = e[*p - s];        /* non-simple--look up in lists */
        r.v.n = d[*p++ - s];
      }

      /* fill code-like entries with r */
      f = 1 << (k - w);
      for (j = i >> w; j < z; j += f)
        q[j] = r;

      /* backwards increment the k-bit code i */
      for (j = 1 << (k - 1); i & j; j >>= 1)
        i ^= j;
      i ^= j;

      /* backup over finished tables */
      while ((i & ((1 << w) - 1)) != x[h])
        w -= l[--h];            /* don't need to update q */
    }
  }


  /* return actual size of base table */
  *m = l[0];


  /* Return true (1) if we were given an incomplete table */
  return y != 0 && g != 1;
}


/*##########################################################################
#
#   Name       : TUnzip::FreeHuft
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::FreeHuft(struct TUnzipHuft *t)
/* Free the malloc'ed tables built by huft_build(), which makes a linked
   list of the tables it made, with the links in a dummy first entry of
   each table. */
{
  register struct TUnzipHuft *p, *q;


  /* Go through linked list, freeing from the malloced (t[-1]) address. */
  p = t;
  while (p != 0)
  {
    q = (--p)->v.t;
    delete p;
    p = q;
  }
}

/*##########################################################################
#
#   Explode macros that cannot be integrated!
#
##########################################################################*/

#define GETBITS(n) {while(k<(n)){b|=((unsigned long)GetNextByte())<<k;k+=8;}}
#define ADVANCEBITS(n) {b>>=(n);k-=(n);}

#define DECODEHUFT(htab, bits, mask) {\
  GETBITS((unsigned)(bits))\
  t = (htab) + ((~(unsigned)b)&(mask));\
  while (1) {\
    ADVANCEBITS(t->b)\
    if ((e=t->e) <= 32) break;\
    if (e == INVALID_CODE) return 1;\
    e &= 31;\
    GETBITS(e)\
    t = t->v.t + ((~(unsigned)b)&mask_bits[e]);\
  }\
}

/*##########################################################################
#
#   Name       : TUnzip::ExplodeLit
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::ExplodeLit(struct TUnzipHuft *tb, struct TUnzipHuft *tl, struct TUnzipHuft *td, unsigned bb, unsigned bl, unsigned bd, unsigned bdl)
/* Decompress the imploded data using coded literals and a sliding
   window (of size 2^(6+bdl) bytes). */
{
  unsigned long s;      /* bytes to decompress */
  register unsigned e;  /* table entry flag/number of extra bits */
  unsigned n, d;        /* length and index for copy */
  unsigned w;           /* current window position */
  struct TUnzipHuft *t;       /* pointer to table entry */
  unsigned mb, ml, md;  /* masks for bb, bl, and bd bits */
  unsigned mdl;         /* mask for bdl (distance lower) bits */
  register unsigned long b;       /* bit buffer */
  register unsigned k;  /* number of bits in bit buffer */
  unsigned u;           /* true if unflushed */
  int retval = 0;       /* error code returned: initialized to "no error" */


  /* explode the coded data */
  b = k = w = 0;                /* initialize bit buffer, window */
  u = 1;                        /* buffer unflushed */
  mb = mask_bits[bb];           /* precompute masks for speed */
  ml = mask_bits[bl];
  md = mask_bits[bd];
  mdl = mask_bits[bdl];
  s = FCurrFile->uncompr_size;
  while (s > 0)                 /* do until ucsize bytes uncompressed */
  {
    GETBITS(1)
    if (b & 1)                  /* then literal--decode it */
    {
      ADVANCEBITS(1)
      s--;
      DECODEHUFT(tb, bb, mb)    /* get coded literal */
      FOutBuf[w++] = (unsigned char)t->v.n;
      if (w == WSIZE)
      {
        if ((retval = Flush(FOutBuf, w)) != 0)
          return retval;
        w = u = 0;
      }
    }
    else                        /* else distance/length */
    {
      ADVANCEBITS(1)
      GETBITS(bdl)             /* get distance low bits */
      d = (unsigned)b & mdl;
      ADVANCEBITS(bdl)
      DECODEHUFT(td, bd, md)    /* get coded distance high bits */
      d = w - d - t->v.n;       /* construct offset */
      DECODEHUFT(tl, bl, ml)    /* get coded length */
      n = t->v.n;
      if (e)                    /* get length extra bits */
      {
        GETBITS(8)
        n += (unsigned)b & 0xff;
        ADVANCEBITS(8)
      }

      /* do the copy */
      s = (s > (unsigned long)n ? s - (unsigned long)n : 0);
      do {
          e = WSIZE - ((d &= WSIZE-1) > w ? d : w);
        if (e > n) e = n;
        n -= e;
        if (u && w <= d)
        {
          memset(FOutBuf + w, 0, e);
          w += e;
          d += e;
        }
        else
          if (w - d >= e)       /* (this test assumes unsigned comparison) */
          {
            memcpy(FOutBuf + w, FOutBuf + d, e);
            w += e;
            d += e;
          }
          else                  /* do it slow to avoid memcpy() overlap */
            do {
              FOutBuf[w++] = FOutBuf[d++];
            } while (--e);
        if (w == WSIZE)
        {
          if ((retval = Flush(FOutBuf, w)) != 0)
            return retval;
          w = u = 0;
        }
      } while (n);
    }
  }

  /* flush out redirSlide */
  if ((retval = Flush(FOutBuf, w)) != 0)
    return retval;
  if (FDecompSize + FInCount + (k >> 3))   /* should have read csize bytes, but */
  {                        /* sometimes read one too many:  k>>3 compensates */
    FUsedCSize = FCurrFile->compr_size - FDecompSize - FInCount - (k >> 3);
    return 5;
  }
  return 0;
}

/*##########################################################################
#
#   Name       : TUnzip::ExplodeNolit
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::ExplodeNolit(struct TUnzipHuft *tl, struct TUnzipHuft *td, unsigned bl, unsigned bd, unsigned bdl)
/* Decompress the imploded data using uncoded literals and a sliding
   window (of size 2^(6+bdl) bytes). */
{
  unsigned long s;      /* bytes to decompress */
  register unsigned e;  /* table entry flag/number of extra bits */
  unsigned n, d;        /* length and index for copy */
  unsigned w;           /* current window position */
  struct TUnzipHuft *t; /* pointer to table entry */
  unsigned ml, md;      /* masks for bl and bd bits */
  unsigned mdl;         /* mask for bdl (distance lower) bits */
  register unsigned long b;       /* bit buffer */
  register unsigned k;  /* number of bits in bit buffer */
  unsigned u;           /* true if unflushed */
  int retval = 0;       /* error code returned: initialized to "no error" */


  /* explode the coded data */
  b = k = w = 0;                /* initialize bit buffer, window */
  u = 1;                        /* buffer unflushed */
  ml = mask_bits[bl];           /* precompute masks for speed */
  md = mask_bits[bd];
  mdl = mask_bits[bdl];
  s = FCurrFile->uncompr_size;
  while (s > 0)                 /* do until ucsize bytes uncompressed */
  {
    GETBITS(1)
    if (b & 1)                  /* then literal--get eight bits */
    {
      ADVANCEBITS(1)
      s--;
      GETBITS(8)
      FOutBuf[w++] = (char)b;
      if (w == WSIZE)
      {
        if ((retval = Flush(FOutBuf, w)) != 0)
          return retval;
        w = u = 0;
      }
      ADVANCEBITS(8)
    }
    else                        /* else distance/length */
    {
      ADVANCEBITS(1)
      GETBITS(bdl)             /* get distance low bits */
      d = (unsigned)b & mdl;
      ADVANCEBITS(bdl)
      DECODEHUFT(td, bd, md)    /* get coded distance high bits */
      d = w - d - t->v.n;       /* construct offset */
      DECODEHUFT(tl, bl, ml)    /* get coded length */
      n = t->v.n;
      if (e)                    /* get length extra bits */
      {
        GETBITS(8)
        n += (unsigned)b & 0xff;
        ADVANCEBITS(8)
      }

      /* do the copy */
      s = (s > (unsigned long)n ? s - (unsigned long)n : 0);
      do {
          e = WSIZE - ((d &= WSIZE-1) > w ? d : w);
        if (e > n) e = n;
        n -= e;
        if (u && w <= d)
        {
          memset(FOutBuf + w, 0, e);
          w += e;
          d += e;
        }
        else
          if (w - d >= e)       /* (this test assumes unsigned comparison) */
          {
            memcpy(FOutBuf + w, FOutBuf + d, e);
            w += e;
            d += e;
          }
          else                  /* do it slow to avoid memcpy() overlap */
            do {
              FOutBuf[w++] = FOutBuf[d++];
            } while (--e);
        if (w == WSIZE)
        {
          if ((retval = Flush(FOutBuf, w)) != 0)
            return retval;
          w = u = 0;
        }
      } while (n);
    }
  }

  /* flush out redirSlide */
  if ((retval = Flush(FOutBuf, w)) != 0)
    return retval;
  if (FDecompSize + FInCount + (k >> 3))   /* should have read csize bytes, but */
  {                        /* sometimes read one too many:  k>>3 compensates */
    FUsedCSize = FCurrFile->compr_size - FDecompSize - FInCount - (k >> 3);
    return 5;
  }
  return 0;
}


/*##########################################################################
#
#   Name       : TUnzip::Explode
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::Explode()
/* Explode an imploded compressed stream.  Based on the general purpose
   bit flag, decide on coded or uncoded literals, and an 8K or 4K sliding
   window.  Construct the literal (if any), length, and distance codes and
   the tables needed to decode them (using huft_build() from inflate.c),
   and call the appropriate routine for the type of data in the remainder
   of the stream.  The four routines are nearly identical, differing only
   in whether the literal is decoded or simply read in, and in how many
   bits are read in, uncoded, for the low distance bits. */
{
  unsigned r;           /* return codes */
  struct TUnzipHuft *tb;      /* literal code table */
  struct TUnzipHuft *tl;      /* length code table */
  struct TUnzipHuft *td;      /* distance code table */
  unsigned bb;          /* bits for tb */
  unsigned bl;          /* bits for tl */
  unsigned bd;          /* bits for td */
  unsigned bdl;         /* number of uncoded lower distance bits */
  unsigned l[256];      /* bit lengths for codes */

  /* Tune base table sizes.  Note: I thought that to truly optimize speed,
     I would have to select different bl, bd, and bb values for different
     compressed file sizes.  I was surprised to find out that the values of
     7, 7, and 9 worked best over a very wide range of sizes, except that
     bd = 8 worked marginally better for large compressed sizes. */
  bl = 7;
  bd = (FDecompSize + FInCount) > 200000L ? 8 : 7;

  if (FCurrFile->general_purpose_bit_flag & 4)
  /* With literal tree--minimum match length is 3 */
  {
    bb = 9;                     /* base table size for literals */
    if ((r = ExplodeGetTree(l, 256)) != 0)
      return (int)r;
    if ((r = BuildHuft(l, 256, 256, NULL, NULL, &tb, &bb)) != 0)
    {
      if (r == 1)
        FreeHuft(tb);
      return (int)r;
    }
    if ((r = ExplodeGetTree(l, 64)) != 0) {
      FreeHuft(tb);
      return (int)r;
    }
    if ((r = BuildHuft(l, 64, 0, cplen3, extra, &tl, &bl)) != 0)
    {
      if (r == 1)
        FreeHuft(tl);
      FreeHuft(tb);
      return (int)r;
    }
  }
  else
  /* No literal tree--minimum match length is 2 */
  {
    tb = 0;
    if ((r = ExplodeGetTree(l, 64)) != 0)
      return (int)r;
    if ((r = BuildHuft(l, 64, 0, cplen2, extra, &tl, &bl)) != 0)
    {
      if (r == 1)
        FreeHuft(tl);
      return (int)r;
    }
  }

  if ((r = ExplodeGetTree(l, 64)) != 0) {
    FreeHuft(tl);
    if (tb != 0) FreeHuft(tb);
    return (int)r;
  }
  if (FCurrFile->general_purpose_bit_flag & 2)      /* true if 8K */
  {
    bdl = 7;
    r = BuildHuft(l, 64, 0, cpdist8, extra, &td, &bd);
  }
  else                                          /* else 4K */
  {
    bdl = 6;
    r = BuildHuft(l, 64, 0, cpdist4, extra, &td, &bd);
  }
  if (r != 0)
  {
    if (r == 1)
      FreeHuft(td);
    FreeHuft(tl);
    if (tb != 0) FreeHuft(tb);
    return (int)r;
  }

  if (tb != NULL) {
    r = ExplodeLit(tb, tl, td, bb, bl, bd, bdl);
    FreeHuft(tb);
  } else {
    r = ExplodeNolit(tl, td, bl, bd, bdl);
  }

  FreeHuft(td);
  FreeHuft(tl);
  return (int)r;
}

/*##########################################################################
#
#   Unshrink macros that cannot be integrated!
#
##########################################################################*/

#define READBITS(nbits,zdest) {if(nbits>FBitsLeft) {int temp; FZipeof=1;\
  while (FBitsLeft<=8*(int)(sizeof(FBitBuf)-1) && (temp=GetNextByte())!=EOF) {\
  FBitBuf|=(unsigned long)temp<<FBitsLeft; FBitsLeft+=8; FZipeof=0;}}\
  zdest=(int)((unsigned)FBitBuf&mask_bits[nbits]);FBitBuf>>=nbits;\
  FBitsLeft-=nbits;}

/*##########################################################################
#
#   Name       : TUnzip::UnshrinkPartialClear
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::UnshrinkPartialClear(int lastcodeused)
{
    register int code;

    /* clear all nodes which have no children (i.e., leaf nodes only) */

    /* first loop:  mark each parent as such */
    for (code = BOGUSCODE+1;  code <= lastcodeused;  ++code) {
        register int cparent = (int)(FShrinkParent[code] & CODE_MASK);

        if (cparent > BOGUSCODE)
            FShrinkParent[cparent] |= HAS_CHILD;   /* set parent's child-bit */
    }

    /* second loop:  clear all nodes *not* marked as parents; reset flag bits */
    for (code = BOGUSCODE+1;  code <= lastcodeused;  ++code) {
        if (FShrinkParent[code] & HAS_CHILD)    /* just clear child-bit */
            FShrinkParent[code] &= ~HAS_CHILD;
        else {                              /* leaf:  lose it */
            FShrinkParent[code] = FREE_CODE;
        }
    }
}

/*##########################################################################
#
#   Name       : TUnzip::Unshrink
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::Unshrink()
{
    unsigned char *stacktop;
    register unsigned char *newstr;
    unsigned char finalval;
    int codesize=9, len, error;
    int code, oldcode, curcode;
    int lastfreecode;
    unsigned char *p;

    FZipeof = 0;
    FBitsLeft = 0;
    FBitBuf = 0;

/*---------------------------------------------------------------------------
    Initialize various variables.
  ---------------------------------------------------------------------------*/

    lastfreecode = BOGUSCODE;

    FShrinkParent = new int[HSIZE];
    FShrinkValue = new unsigned char[HSIZE];
    FShrinkStack = new unsigned char[HSIZE];

    stacktop = FShrinkStack + (HSIZE - 1);
    
    for (code = 0;  code < BOGUSCODE;  ++code) {
        FShrinkValue[code] = (unsigned char)code;
        FShrinkParent[code] = BOGUSCODE;
    }
    for (code = BOGUSCODE+1;  code < HSIZE;  ++code)
        FShrinkParent[code] = FREE_CODE;

    FOutPtr = FOutBuf;
    FOutCount = 0;

/*---------------------------------------------------------------------------
    Get and output first code, then loop over remaining ones.
  ---------------------------------------------------------------------------*/

    READBITS(codesize, oldcode)
    if (FZipeof)
        return PK_OK;

    finalval = (unsigned char)oldcode;
    *FOutPtr++ = finalval;
    ++FOutCount;

    while (TRUE) {
        READBITS(codesize, code)
        if (FZipeof)
            break;
        if (code == BOGUSCODE) {   /* possible to have consecutive escapes? */
            READBITS(codesize, code)
            if (FZipeof)
                break;
            if (code == 1) {
                ++codesize;
                if (codesize > MAX_BITS) return PK_ERR;
            } else if (code == 2) {
                /* clear leafs (nodes with no children) */
                UnshrinkPartialClear(lastfreecode);
                lastfreecode = BOGUSCODE; /* reset start of free-node search */
            }
            continue;
        }

    /*-----------------------------------------------------------------------
        Translate code:  traverse tree from leaf back to root.
      -----------------------------------------------------------------------*/

        newstr = stacktop;
        curcode = code;

        if (FShrinkParent[code] == FREE_CODE) {
            /* or (FLAG_BITS[code] & FREE_CODE)? */
            *newstr-- = finalval;
            code = oldcode;
        }

        while (code != BOGUSCODE) {
            if (newstr < FShrinkStack) {
                /* Bogus compression stream caused buffer underflow! */
                return PK_ERR;
            }
            if (FShrinkParent[code] == FREE_CODE) {
                /* or (FLAG_BITS[code] & FREE_CODE)? */
                *newstr-- = finalval;
                code = oldcode;
            } else {
                *newstr-- = FShrinkValue[code];
                code = (int)(FShrinkParent[code] & CODE_MASK);
            }
        }

        len = (int)(stacktop - newstr++);
        finalval = *newstr;

    /*-----------------------------------------------------------------------
        Write expanded string in reverse order to output buffer.
      -----------------------------------------------------------------------*/

        for (p = newstr;  p < newstr+len;  ++p) {
            *FOutPtr++ = *p;
            if (++FOutCount == WSIZE) {
                if ((error = Flush(FOutBuf, FOutCount)) != 0) {
                    return error;
                }
                FOutPtr = FOutBuf;
                FOutCount = 0;
            }
        }

    /*-----------------------------------------------------------------------
        Add new leaf (first character of newstr) to tree as child of oldcode.
      -----------------------------------------------------------------------*/

        /* search for freecode */
        code = (int)(lastfreecode + 1);
        /* add if-test before loop for speed? */
        while ((code < HSIZE) && (FShrinkParent[code] != FREE_CODE))
            ++code;
        lastfreecode = code;
        if (code >= HSIZE)
            /* invalid compressed data caused max-code overflow! */
            return PK_ERR;

        FShrinkValue[code] = finalval;
        FShrinkParent[code] = oldcode;
        oldcode = curcode;

    }

/*---------------------------------------------------------------------------
    Flush any remaining data and return to sender...
  ---------------------------------------------------------------------------*/

    if (FOutCount > 0) {
        if ((error = Flush(FOutBuf, FOutCount)) != 0) {
            return error;
        }
    }

    delete FShrinkParent;
    delete FShrinkValue;
    delete FShrinkStack;

    return PK_OK;

} /* end function unshrink() */


/*##########################################################################
#
#  zlib callback interface for inflate
#
###########################################################################*/
static unsigned zlib_inCB(void *pG, unsigned char ** pInbuf)
{
    TUnzip *unzip = (TUnzip *)pG;
    
    *pInbuf = (unsigned char *)unzip->GetInbuf();
    return unzip->FillInbuf();
}

static int zlib_outCB(void *pG, unsigned char *outbuf, unsigned outcnt)
{
    TUnzip *unzip = (TUnzip *)pG;
    
    return unzip->Flush((char *)outbuf, outcnt);
}


/*##########################################################################
#
#   Name       : TUnzip::Deflate
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::Deflate()
/* decompress an inflated entry using the zlib routines */
{
    int retval = 0;     /* return code: 0 = "no error" */
    int err=Z_OK;
    z_stream dstrm;           /* inflate decompression stream */

    dstrm.zalloc = (alloc_func)Z_NULL;
    dstrm.zfree = (free_func)Z_NULL;

    {
        /* For the callback interface, inflate initialization has to
           be called before each decompression call.
         */
        {
            unsigned i;
            int windowBits;
            /* windowBits = log2(WSIZE) */
            for (i = (unsigned)WSIZE, windowBits = 0;
                 !(i & 1);  i >>= 1, ++windowBits);
            if ((unsigned)windowBits > (unsigned)15)
                windowBits = 15;
            else if (windowBits < 8)
                windowBits = 8;

            err = inflateBackInit(&dstrm, windowBits, (unsigned char *)FOutBuf);

            if (err == Z_MEM_ERROR)
                return 3;
            else if (err != Z_OK) {
                return 2;
            }
        }

        dstrm.next_in = (unsigned char *)FInPtr;
        dstrm.avail_in = FInCount;

        err = inflateBack(&dstrm, zlib_inCB, this, zlib_outCB, this);
        if (err != Z_STREAM_END) {
            if (err == Z_DATA_ERROR || err == Z_STREAM_ERROR) {
                retval = 2;
            } else if (err == Z_MEM_ERROR) {
                retval = 3;
            } else if (err == Z_BUF_ERROR) {
                if (dstrm.next_in == Z_NULL) {
                    /* input failure */
                    retval = 2;
                } else {
                    /* output write failure */
                    retval = PK_DISK;
                }
            } else {
                retval = 2;
            }
        }
        if (dstrm.next_in != NULL) {
            FInPtr = (char *)dstrm.next_in;
            FInCount = dstrm.avail_in;
        }

        err = inflateBackEnd(&dstrm);
        if (err != Z_OK) {
            if (retval == 0)
                retval = 2;
        }
    }

    inflateEnd(&dstrm);

    return retval;
}

/*##########################################################################
#
#   Name       : TUnzip::Store
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::Store()
{
    int b;
    int r, error=PK_COOL;
    
    FOutPtr = FOutBuf;
    FOutCount = 0;

    while ((b = GetNextByte()) != EOF) {
        *FOutPtr++ = b;
        if (++FOutCount == WSIZE) {
            error = Flush(FOutBuf, FOutCount);
            FOutPtr = FOutBuf;
            FOutCount = 0;
            if (error != PK_COOL || FDiskFull) break;
        }
    }

    if (FOutCount) {        /* flush final (partial) buffer */
        r = Flush(FOutBuf, FOutCount);
        if (error < r) error = r;
    }

    return error;
}

/*##########################################################################
#
#   Name       : TUnzip::Extract
#
#   Purpose....: Extract current file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::Extract()
{
    char *extract_msg = "%8sing: %s";
    int error;

    if (OpenOutputFile())
        return PK_DISK;

/*---------------------------------------------------------------------------
    Unpack the file.
  ---------------------------------------------------------------------------*/

    DeferInput();    /* so NEXTBYTE bounds check will work */
    switch (FCurrFile->compression_method) {
        case STORED:
            Info(0, extract_msg, "extract", FCurrFile->cfilname);
            error = Store();
            break;

        case SHRUNK:
            Info(0, extract_msg, "unshrink", FCurrFile->cfilname);
            error = Unshrink();
            break;

        case IMPLODED:
            Info(0, extract_msg, "explod", FCurrFile->cfilname);

            error = Explode();
            if (error == 5) { /* treat 5 specially */
                int warning = FUsedCSize <= FCurrFile->compr_size;
                error = warning ? PK_WARN : PK_ERR;
            }
            break;

        case DEFLATED:
            Info(0, extract_msg, "inflat", FCurrFile->cfilname);
            error = Deflate();
            break;

        default:   /* should never get to this point */
            Info(0x401, "%s:  unknown compression method\n", FCurrFile->cfilname);
            UndeferInput();
            return PK_WARN;

    } /* end switch (compression method) */

/*---------------------------------------------------------------------------
    Close the file and set its date and time (not necessarily in that order),
    and make sure the CRC checked out OK.  Logical-AND the CRC for 64-bit
    machines (redundant on 32-bit machines).
  ---------------------------------------------------------------------------*/

    CloseAndSetTime();

    if (FDiskFull) {            /* set by flush() */
        if (FDiskFull > 1) {
            /* warn user about the incomplete file */
            Info(0x421, "warning:  %s is probably truncated\n", FCurrFile->cfilname);
            error = PK_DISK;
        } else {
            error = PK_WARN;
        }
    }

    if (error > PK_WARN) {/* don't print redundant CRC error if error already */
        UndeferInput();
        return error;
    }

    if (FCurrCrcVal != FCurrFile->crc) {
        /* if quiet enough, we haven't output the filename yet:  do it */
        Info(0x401, "%-22s ", FCurrFile->cfilname);
        Info(0x401, " bad CRC %08lx  (should be %08lx)\n", FCurrCrcVal, FCurrFile->crc);
        if (FCurrFile && FCurrFile->encrypted)
            Info(0x401, "   (may instead be incorrect password)\n");
        error = PK_ERR;
    } else
        Info(0, "\n");

    UndeferInput();

    return error;
}


/*##########################################################################
#
#   Name       : TUnzip::CheckForNewer
#
#   Purpose....: Check if file is newer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::CheckForNewer(const char *filename)
{
    unsigned long msb, lsb;
    int handle;

    handle = RdosOpenFile(filename, 0);

    if (handle)
    {
        RdosGetFileTime(handle, &msb, &lsb);
        RdosAddSec(&msb, &lsb, 2);
        RdosCloseFile(handle);

        if (msb == FCurrFile->rdos_msb_time)
            return lsb >= FCurrFile->rdos_msb_time;
        else
            return msb >= FCurrFile->rdos_lsb_time;
    }
    else
        return DOES_NOT_EXIST;

} /* end function check_for_newer() */

/*##########################################################################
#
#   Name       : TUnzip::CreateTimeStr
#
#   Purpose....: Create time string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::CreateTimeStr(struct TUnzipFile *file, char *str)
{
    int yr, mo, dy, hh, mm, ss, ms, us;

    RdosDecodeMsbTics(file->rdos_msb_time, &yr, &mo, &dy, &hh);
    RdosDecodeLsbTics(file->rdos_lsb_time, &mm, &ss, &ms, &us); 

    sprintf(str, "%04u-%02u-%02u %02u:%02u", yr, mo, dy, hh, mm);
}

/*##########################################################################
#
#   Name       : TUnzip::ShowVerbose
#
#   Purpose....: Show verbose info about file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::ShowVerbose(struct TUnzipFile *file)
{
    int  error;
    unsigned  hostnum, hostver, extnum, extver, methid, methnum, xattr;
    char workspace[12], attribs[22];
    const char *varmsg_str;
    char unkn[16];
    static const char *os[NUM_HOSTS] = {
        OS_FAT, OS_Amiga, OS_VMS, OS_Unix, OS_VMCMS, OS_AtariST, OS_HPFS,
        OS_Macintosh, OS_ZSystem, OS_CPM, OS_TOPS20, OS_NTFS, OS_QDOS,
        OS_Acorn, OS_VFAT, OS_MVS, OS_BeOS, OS_Tandem, OS_Theos, OS_MacDarwin,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        OS_AtheOS
    };
    static const char *method[NUM_METHODS] = {
        MthdNone, MthdShrunk, MthdRedF1, MthdRedF2, MthdRedF3, MthdRedF4,
        MthdImplode, MthdToken, MthdDeflate, MthdDeflat64, MthdDCLImplode,
        MthdBZip2, MthdLZMA, MthdTerse, MthdLZ77, MthdWavPack, MthdPPMd
    };
    static const char *dtypelng[4] = {
        DeflNorm, DeflMax, DeflFast, DeflSFast
    };

/*---------------------------------------------------------------------------
    Print out various interesting things about the compressed file.
  ---------------------------------------------------------------------------*/

    hostnum = (unsigned)(file->hostnum);
    hostver = (unsigned)(file->hostver);
    extnum = (unsigned)MIN(file->version_needed_to_extract[1], NUM_HOSTS);
    extver = (unsigned)file->version_needed_to_extract[0];
    methid = (unsigned)file->compression_method;
    methnum = FindCompressMethod(file->compression_method);

    Info(0, "  ");  
    Info(0, file->cfilname);
    Info(0, "\n");

    Info(0, "\n  offset of local header from start of archive:   %u (%Xh) bytes\n",
      file->offset,
      file->offset);

    if (hostnum >= NUM_HOSTS) {
        sprintf(unkn, "unknown (%d)",
                (int)file->hostnum);
        varmsg_str = unkn;
    } else {
        varmsg_str = os[hostnum];
    }
    Info(0, "  file system or operating system of origin:      %s\n", varmsg_str);
    Info(0, "  version of encoding software:                   %u.%u\n", hostver/10, hostver%10);

    if ((extnum >= NUM_HOSTS) || (os[extnum] == NULL)) {
        sprintf(unkn, "unknown (%d)",
                (int)file->version_needed_to_extract[1]);
        varmsg_str = unkn;
    } else {
        varmsg_str = os[extnum];
    }
    Info(0, "  minimum file system compatibility required:     %s\n", varmsg_str);
    Info(0, "  minimum software version required to extract:   %u.%u\n", extver/10, extver%10);

    if (methnum >= NUM_METHODS) {
        sprintf(unkn, "unknown (%d)", file->compression_method);
        varmsg_str = unkn;
    } else {
        varmsg_str = method[methnum];
    }
    Info(0, "  compression method:                             %s\n", varmsg_str);
    if (methid == IMPLODED) {
        Info(0, "  size of sliding dictionary (implosion):         %cK\n",
          (file->general_purpose_bit_flag & 2)? '8' : '4');
        Info(0, "  number of Shannon-Fano trees (implosion):       %c\n",
          (file->general_purpose_bit_flag & 4)? '3' : '2');
    } else if (methid == DEFLATED || methid == ENHDEFLATED) {
        unsigned short  dnum=(unsigned short)((file->general_purpose_bit_flag>>1) & 3);

        Info(0, "  compression sub-type (deflation):               %s\n", dtypelng[dnum]);
    }

    Info(0, "  file security status:                           %sencrypted\n",
      (file->general_purpose_bit_flag & 1) ? "" : "not ");
    Info(0, "  extended local header:                          %s\n",
      (file->general_purpose_bit_flag & 8) ? "yes" : "no");
    /* print upper 3 bits for amusement? */

    /* For printing of date & time, a "char d_t_buf[21]" is required.
     * To save stack space, we reuse the "char attribs[22]" buffer which
     * is not used yet.
     */

    CreateTimeStr(file, attribs);
    Info(0, "  file last modified on (DOS date/time):          %s\n", 
      attribs);
    
    Info(0, "  32-bit CRC value (hex):                         %.8lx\n", 
      file->crc);
    Info(0, "  compressed size:                                %u bytes\n",
      file->compr_size);
    Info(0, "  uncompressed size:                              %u bytes\n",
      file->uncompr_size);
    Info(0, "  apparent file type:                             %s\n",
      (file->internal_file_attributes & 1)? "text"
         : (file->internal_file_attributes & 2)? "ebcdic"
              : "binary");             /* changed to accept EBCDIC */
    xattr = (unsigned)((file->external_file_attributes >> 16) & 0xFFFF);
    if (hostnum == VMS_) {
        char   *p=attribs, *q=attribs+1;
        int    i, j, k;

        for (k = 0;  k < 12;  ++k)
            workspace[k] = 0;
        if (xattr & VMS_IRUSR)
            workspace[0] = 'R';
        if (xattr & VMS_IWUSR) {
            workspace[1] = 'W';
            workspace[3] = 'D';
        }
        if (xattr & VMS_IXUSR)
            workspace[2] = 'E';
        if (xattr & VMS_IRGRP)
            workspace[4] = 'R';
        if (xattr & VMS_IWGRP) {
            workspace[5] = 'W';
            workspace[7] = 'D';
        }
        if (xattr & VMS_IXGRP)
            workspace[6] = 'E';
        if (xattr & VMS_IROTH)
            workspace[8] = 'R';
        if (xattr & VMS_IWOTH) {
            workspace[9] = 'W';
            workspace[11] = 'D';
        }
        if (xattr & VMS_IXOTH)
            workspace[10] = 'E';

        *p++ = '(';
        for (k = j = 0;  j < 3;  ++j) {    /* loop over groups of permissions */
            for (i = 0;  i < 4;  ++i, ++k)  /* loop over perms within a group */
                if (workspace[k])
                    *p++ = workspace[k];
            *p++ = ',';                       /* group separator */
            if (j == 0)
                while ((*p++ = *q++) != ',')
                    ;                         /* system, owner perms are same */
        }
        *p-- = '\0';
        *p = ')';   /* overwrite last comma */
        Info(0, "  VMS file attributes (%06o octal):             %s\n", xattr, attribs);

    } else if (hostnum == AMIGA_) {
        switch (xattr & AMI_IFMT) {
            case AMI_IFDIR:  attribs[0] = 'd';  break;
            case AMI_IFREG:  attribs[0] = '-';  break;
            default:         attribs[0] = '?';  break;
        }
        attribs[1] = (xattr & AMI_IHIDDEN)?   'h' : '-';
        attribs[2] = (xattr & AMI_ISCRIPT)?   's' : '-';
        attribs[3] = (xattr & AMI_IPURE)?     'p' : '-';
        attribs[4] = (xattr & AMI_IARCHIVE)?  'a' : '-';
        attribs[5] = (xattr & AMI_IREAD)?     'r' : '-';
        attribs[6] = (xattr & AMI_IWRITE)?    'w' : '-';
        attribs[7] = (xattr & AMI_IEXECUTE)?  'e' : '-';
        attribs[8] = (xattr & AMI_IDELETE)?   'd' : '-';
        attribs[9] = 0;   /* better dlm the string */
        Info(0, "  Amiga file attributes (%06o octal):           %s\n", xattr, attribs);

    } else if (hostnum == THEOS_) {
        const char *fpFtyp;

        switch (xattr & THS_IFMT) {
            case THS_IFLIB:  fpFtyp = TheosFTypLib;  break;
            case THS_IFDIR:  fpFtyp = TheosFTypDir;  break;
            case THS_IFREG:  fpFtyp = TheosFTypReg;  break;
            case THS_IFREL:  fpFtyp = TheosFTypRel;  break;
            case THS_IFKEY:  fpFtyp = TheosFTypKey;  break;
            case THS_IFIND:  fpFtyp = TheosFTypInd;  break;
            case THS_IFR16:  fpFtyp = TheosFTypR16;  break;
            case THS_IFP16:  fpFtyp = TheosFTypP16;  break;
            case THS_IFP32:  fpFtyp = TheosFTypP32;  break;
            default:         fpFtyp = TheosFTypUkn;  break;
        }
        strcpy(attribs, fpFtyp);
        attribs[12] = (xattr & THS_INHID) ? '.' : 'H';
        attribs[13] = (xattr & THS_IMODF) ? '.' : 'M';
        attribs[14] = (xattr & THS_IWOTH) ? '.' : 'W';
        attribs[15] = (xattr & THS_IROTH) ? '.' : 'R';
        attribs[16] = (xattr & THS_IEUSR) ? '.' : 'E';
        attribs[17] = (xattr & THS_IXUSR) ? '.' : 'X';
        attribs[18] = (xattr & THS_IWUSR) ? '.' : 'W';
        attribs[19] = (xattr & THS_IRUSR) ? '.' : 'R';
        attribs[20] = 0;
        Info(0, "  Theos file attributes (%04X hex):               %s\n", xattr, attribs);


    } else if ((hostnum != FS_FAT_) && (hostnum != FS_HPFS_) &&
               (hostnum != FS_NTFS_) && (hostnum != FS_VFAT_) &&
               (hostnum != ACORN_) &&
               (hostnum != VM_CMS_) && (hostnum != MVS_))
    {                                 /* assume Unix-like */
        switch ((unsigned)(xattr & UNX_IFMT)) {
            case (unsigned)UNX_IFDIR:   attribs[0] = 'd';  break;
            case (unsigned)UNX_IFREG:   attribs[0] = '-';  break;
            case (unsigned)UNX_IFLNK:   attribs[0] = 'l';  break;
            case (unsigned)UNX_IFBLK:   attribs[0] = 'b';  break;
            case (unsigned)UNX_IFCHR:   attribs[0] = 'c';  break;
            case (unsigned)UNX_IFIFO:   attribs[0] = 'p';  break;
            case (unsigned)UNX_IFSOCK:  attribs[0] = 's';  break;
            default:          attribs[0] = '?';  break;
        }
        attribs[1] = (xattr & UNX_IRUSR)? 'r' : '-';
        attribs[4] = (xattr & UNX_IRGRP)? 'r' : '-';
        attribs[7] = (xattr & UNX_IROTH)? 'r' : '-';

        attribs[2] = (xattr & UNX_IWUSR)? 'w' : '-';
        attribs[5] = (xattr & UNX_IWGRP)? 'w' : '-';
        attribs[8] = (xattr & UNX_IWOTH)? 'w' : '-';

        if (xattr & UNX_IXUSR)
            attribs[3] = (xattr & UNX_ISUID)? 's' : 'x';
        else
            attribs[3] = (xattr & UNX_ISUID)? 'S' : '-';   /* S = undefined */
        if (xattr & UNX_IXGRP)
            attribs[6] = (xattr & UNX_ISGID)? 's' : 'x';   /* == UNX_ENFMT */
        else
            attribs[6] = (xattr & UNX_ISGID)? 'l' : '-';
        if (xattr & UNX_IXOTH)
            attribs[9] = (xattr & UNX_ISVTX)? 't' : 'x';   /* "sticky bit" */
        else
            attribs[9] = (xattr & UNX_ISVTX)? 'T' : '-';   /* T = undefined */
        attribs[10] = 0;

        Info(0, "  Unix file attributes (%06o octal):            %s\n", xattr, attribs);

    } else {
        Info(0, "  non-MSDOS external file attributes:             %06lX hex\n", file->external_file_attributes >> 8);

    } /* endif (hostnum: external attributes format) */

    if ((xattr=(unsigned)(file->external_file_attributes & 0xFF)) == 0)
        Info(0, "  MS-DOS file attributes (%02X hex):                none\n", xattr);
    else if (xattr == 1)
        Info(0, "  MS-DOS file attributes (%02X hex):                read-only\n", xattr);
    else
        Info(0, "  MS-DOS file attributes (%02X hex):                %s%s%s%s%s%s%s%s\n",
          xattr, (xattr&1)? "rdo " : "",
          (xattr&2)? "hid " : "",
          (xattr&4)? "sys " : "",
          (xattr&8)? "lab " : "",
          (xattr&16)? "dir " : "",
          (xattr&32)? "arc " : "",
          (xattr&64)? "lnk " : "",
          (xattr&128)? "exe" : "");

} /* end function zi_long() */


/*##########################################################################
#
#   Name       : TUnzip::ShowCompact
#
#   Purpose....: Show compact info about file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::ShowCompact(struct TUnzipFile *file)
{
    int         k, error, error_in_archive=PK_COOL;
    unsigned    hostnum, hostver, methid, methnum, xattr;
    char        *p, workspace[12], attribs[16];
    char        methbuf[5];
    static const char dtype[5]="NXFS"; /* normal, maximum, fast, superfast */
    static const char os[NUM_HOSTS+1][4] = {
        "fat", "ami", "vms", "unx", "cms", "atr", "hpf", "mac", "zzz",
        "cpm", "t20", "ntf", "qds", "aco", "vft", "mvs", "be ", "nsk",
        "ths", "osx", "???", "???", "???", "???", "???", "???", "???",
        "???", "???", "???", "ath", "???"
    };
    static const char method[NUM_METHODS+1][5] = {
        "stor", "shrk", "re:1", "re:2", "re:3", "re:4", "i#:#", "tokn",
        "def#", "d64#", "dcli", "bzp2", "lzma", "ters", "lz77", "wavp",
        "ppmd", "u###"
    };


/*---------------------------------------------------------------------------
    Print out various interesting things about the compressed file.
  ---------------------------------------------------------------------------*/

    methid = (unsigned)(file->compression_method);
    methnum = FindCompressMethod(file->compression_method);
    hostnum = (unsigned)(file->hostnum);
    hostver = (unsigned)(file->hostver);

    strcpy(methbuf, method[methnum]);
    if (methid == IMPLODED) {
        methbuf[1] = (char)((file->general_purpose_bit_flag & 2)? '8' : '4');
        methbuf[3] = (char)((file->general_purpose_bit_flag & 4)? '3' : '2');
    } else if (methid == DEFLATED || methid == ENHDEFLATED) {
        unsigned short  dnum=(unsigned short)((file->general_purpose_bit_flag>>1) & 3);
        methbuf[3] = dtype[dnum];
    } else if (methnum >= NUM_METHODS) {   /* unknown */
        sprintf(&methbuf[1], "%03u", file->compression_method);
    }

    for (k = 0;  k < 15;  ++k)
        attribs[k] = ' ';
    attribs[15] = 0;

    xattr = (unsigned)((file->external_file_attributes >> 16) & 0xFFFF);
    switch (hostnum) {
        case VMS_:
            {   int    i, j;

                for (k = 0;  k < 12;  ++k)
                    workspace[k] = 0;
                if (xattr & VMS_IRUSR)
                    workspace[0] = 'R';
                if (xattr & VMS_IWUSR) {
                    workspace[1] = 'W';
                    workspace[3] = 'D';
                }
                if (xattr & VMS_IXUSR)
                    workspace[2] = 'E';
                if (xattr & VMS_IRGRP)
                    workspace[4] = 'R';
                if (xattr & VMS_IWGRP) {
                    workspace[5] = 'W';
                    workspace[7] = 'D';
                }
                if (xattr & VMS_IXGRP)
                  workspace[6] = 'E';
                if (xattr & VMS_IROTH)
                    workspace[8] = 'R';
                if (xattr & VMS_IWOTH) {
                    workspace[9] = 'W';
                    workspace[11] = 'D';
                }
                if (xattr & VMS_IXOTH)
                    workspace[10] = 'E';

                p = attribs;
                for (k = j = 0;  j < 3;  ++j) {     /* groups of permissions */
                    for (i = 0;  i < 4;  ++i, ++k)  /* perms within a group */
                        if (workspace[k])
                            *p++ = workspace[k];
                    *p++ = ',';                     /* group separator */
                }
                *--p = ' ';   /* overwrite last comma */
                if ((p - attribs) < 12)
                    sprintf(&attribs[12], "%u.%u", hostver/10, hostver%10);
            }
            break;

        case AMIGA_:
            switch (xattr & AMI_IFMT) {
                case AMI_IFDIR:  attribs[0] = 'd';  break;
                case AMI_IFREG:  attribs[0] = '-';  break;
                default:         attribs[0] = '?';  break;
            }
            attribs[1] = (xattr & AMI_IHIDDEN)?   'h' : '-';
            attribs[2] = (xattr & AMI_ISCRIPT)?   's' : '-';
            attribs[3] = (xattr & AMI_IPURE)?     'p' : '-';
            attribs[4] = (xattr & AMI_IARCHIVE)?  'a' : '-';
            attribs[5] = (xattr & AMI_IREAD)?     'r' : '-';
            attribs[6] = (xattr & AMI_IWRITE)?    'w' : '-';
            attribs[7] = (xattr & AMI_IEXECUTE)?  'e' : '-';
            attribs[8] = (xattr & AMI_IDELETE)?   'd' : '-';
            sprintf(&attribs[12], "%u.%u", hostver/10, hostver%10);
            break;

        case THEOS_:
            switch (xattr & THS_IFMT) {
                case THS_IFLIB: *attribs = 'L'; break;
                case THS_IFDIR: *attribs = 'D'; break;
                case THS_IFCHR: *attribs = 'C'; break;
                case THS_IFREG: *attribs = 'S'; break;
                case THS_IFREL: *attribs = 'R'; break;
                case THS_IFKEY: *attribs = 'K'; break;
                case THS_IFIND: *attribs = 'I'; break;
                case THS_IFR16: *attribs = 'P'; break;
                case THS_IFP16: *attribs = '2'; break;
                case THS_IFP32: *attribs = '3'; break;
                default:        *attribs = '?'; break;
            }
            attribs[1] = (xattr & THS_INHID) ? '.' : 'H';
            attribs[2] = (xattr & THS_IMODF) ? '.' : 'M';
            attribs[3] = (xattr & THS_IWOTH) ? '.' : 'W';
            attribs[4] = (xattr & THS_IROTH) ? '.' : 'R';
            attribs[5] = (xattr & THS_IEUSR) ? '.' : 'E';
            attribs[6] = (xattr & THS_IXUSR) ? '.' : 'X';
            attribs[7] = (xattr & THS_IWUSR) ? '.' : 'W';
            attribs[8] = (xattr & THS_IRUSR) ? '.' : 'R';
            sprintf(&attribs[12], "%u.%u", hostver/10, hostver%10);
            break;

        case FS_VFAT_:
        case FS_FAT_:
        case FS_HPFS_:
        case FS_NTFS_:
        case VM_CMS_:
        case MVS_:
        case ACORN_:
            if (hostnum != FS_FAT_ ||
                (unsigned)(xattr & 0700) !=
                 ((unsigned)0400 |
                  ((unsigned)!(file->external_file_attributes & 1) << 7) |
                  ((unsigned)(file->external_file_attributes & 0x10) << 2))
               )
            {
                xattr = (unsigned)(file->external_file_attributes & 0xFF);
                sprintf(attribs, ".r.-...     %u.%u", hostver/10, hostver%10);
                attribs[2] = (xattr & 0x01)? '-' : 'w';
                attribs[5] = (xattr & 0x02)? 'h' : '-';
                attribs[6] = (xattr & 0x04)? 's' : '-';
                attribs[4] = (xattr & 0x20)? 'a' : '-';
                if (xattr & 0x10) {
                    attribs[0] = 'd';
                    attribs[3] = 'x';
                } else
                    attribs[0] = '-';
                if (xattr & 0x8)
                    attribs[0] = 'V';
                else if ((p = strchr(file->cfilname, '.')) != (char *)NULL) {
                    ++p;
                    if (strnicmp(p, "com", 3) == 0 ||
                        strnicmp(p, "exe", 3) == 0 ||
                        strnicmp(p, "btm", 3) == 0 ||
                        strnicmp(p, "cmd", 3) == 0 ||
                        strnicmp(p, "bat", 3) == 0)
                        attribs[3] = 'x';
                }
                break;
            } /* else: fall through! */

        default:   /* assume Unix-like */
            switch ((unsigned)(xattr & UNX_IFMT)) {
                case (unsigned)UNX_IFDIR:   attribs[0] = 'd';  break;
                case (unsigned)UNX_IFREG:   attribs[0] = '-';  break;
                case (unsigned)UNX_IFLNK:   attribs[0] = 'l';  break;
                case (unsigned)UNX_IFBLK:   attribs[0] = 'b';  break;
                case (unsigned)UNX_IFCHR:   attribs[0] = 'c';  break;
                case (unsigned)UNX_IFIFO:   attribs[0] = 'p';  break;
                case (unsigned)UNX_IFSOCK:  attribs[0] = 's';  break;
                default:          attribs[0] = '?';  break;
            }
            attribs[1] = (xattr & UNX_IRUSR)? 'r' : '-';
            attribs[4] = (xattr & UNX_IRGRP)? 'r' : '-';
            attribs[7] = (xattr & UNX_IROTH)? 'r' : '-';
            attribs[2] = (xattr & UNX_IWUSR)? 'w' : '-';
            attribs[5] = (xattr & UNX_IWGRP)? 'w' : '-';
            attribs[8] = (xattr & UNX_IWOTH)? 'w' : '-';

            if (xattr & UNX_IXUSR)
                attribs[3] = (xattr & UNX_ISUID)? 's' : 'x';
            else
                attribs[3] = (xattr & UNX_ISUID)? 'S' : '-';  /* S==undefined */
            if (xattr & UNX_IXGRP)
                attribs[6] = (xattr & UNX_ISGID)? 's' : 'x';  /* == UNX_ENFMT */
            else
                /* attribs[6] = (xattr & UNX_ISGID)? 'l' : '-';  real 4.3BSD */
                attribs[6] = (xattr & UNX_ISGID)? 'S' : '-';  /* SunOS 4.1.x */
            if (xattr & UNX_IXOTH)
                attribs[9] = (xattr & UNX_ISVTX)? 't' : 'x';  /* "sticky bit" */
            else
                attribs[9] = (xattr & UNX_ISVTX)? 'T' : '-';  /* T==undefined */

            sprintf(&attribs[12], "%u.%u", hostver/10, hostver%10);
            break;

    } /* end switch (hostnum: external attributes format) */

    Info(0, "%s %s %u ", attribs,
      os[hostnum],
      file->uncompr_size);
    Info(0, "%c",
      (file->general_purpose_bit_flag & 1)?
      ((file->internal_file_attributes & 1)? 'T' : 'B') :  /* encrypted */
      ((file->internal_file_attributes & 1)? 't' : 'b')); /* plaintext */

    /* For printing of date & time, a "char d_t_buf[16]" is required.
     * To save stack space, we reuse the "char attribs[16]" buffer whose
     * content is no longer needed.
     */
    CreateTimeStr(file, attribs);
    Info(0, " %s %s ", methbuf, attribs); 

    Info(0, file->cfilname);
    Info(0, "\n");

} /* end function zi_short() */


