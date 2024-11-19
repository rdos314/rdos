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
#include "zipextr.h"
#include "zipdefl.h"
#include "zipstor.h"
#include "zipunshr.h"
#include "zipexpl.h"
#include "zlib.h"


#define     FALSE       0
#define     TRUE        !FALSE

#define UNZIP_VERSION   20

#define LF     10        /* '\n' on ASCII machines; must be 10 due to EBCDIC */
#define CR     13        /* '\r' on ASCII machines; must be 13 due to EBCDIC */
#define CTRLZ  26        /* DOS & OS/2 EOF marker (used in fileio.c, vms.c) */

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

#define ECREC_SIZE   18   /*  record, zip64 end-of-cent-dir locator */
/*define SIGNATURE                        0   space-holder only */
#define NUMBER_THIS_DISK                  4
#define NUM_DISK_WITH_START_CEN_DIR       6
#define NUM_ENTRIES_CEN_DIR_THS_DISK      8
#define TOTAL_ENTRIES_CENTRAL_DIR         10
#define SIZE_CENTRAL_DIRECTORY            12
#define OFFSET_START_CENTRAL_DIRECTORY    16
#define ZIPFILE_COMMENT_LENGTH            20

#define RAND_HEAD_LEN  12       /* length of encryption random header */

#define INBUFSIZ  8192
#define TMPOUTSIZ 0x10000

#define MAX(a,b)   ((a) > (b) ? (a) : (b))
#define MIN(a,b)   ((a) < (b) ? (a) : (b))

static const unsigned *crctab = get_crc_table();

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
#   Name       : TUnzipFile::TUnzipFile
#
#   Purpose....: Constructor for unzipfile
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipFile::TUnzipFile(TUnzip *unzip)
{
    FUnzip = unzip;

    FSkipped = FALSE;
    FOk = ProcessDirEntry();

    if (FOk)
        FOk = ProcessFileHeader();
}

/*##########################################################################
#
#   Name       : TUnzipFile::~TUnzipFile
#
#   Purpose....: Destructor for unzipfile
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipFile::~TUnzipFile()
{
}

/*##########################################################################
#
#   Name       : TUnzipFile::ProcessDirEntry
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipFile::ProcessDirEntry()
{
    int error;
    unsigned short filename_length;
    unsigned short extra_field_length;
    unsigned short file_comment_length;
    unsigned long dos_datetime;
    unsigned char byterec[ CREC_SIZE ];
    unsigned cmpridx;

/*---------------------------------------------------------------------------
    Read the next central directory entry and do any necessary machine-type
    conversions (byte ordering, structure padding compensation--do so by
    copying the data from the array into which it was read (byterec) to the
    usable struct (crec)).
  ---------------------------------------------------------------------------*/

    if (FUnzip->ReadBuf((char *)byterec, CREC_SIZE) == 0)
        return FALSE;

    hostver = byterec[C_VERSION_MADE_BY_0];
    hostnum = MIN(byterec[C_VERSION_MADE_BY_1], NUM_HOSTS);

    version_needed_to_extract[0] = byterec[C_VERSION_NEEDED_TO_EXTRACT_0];
    version_needed_to_extract[1] = byterec[C_VERSION_NEEDED_TO_EXTRACT_1];

    general_purpose_bit_flag = makeword(&byterec[C_GENERAL_PURPOSE_BIT_FLAG]);
    encrypted = general_purpose_bit_flag & 1;   /* bit field */
    ExtLocHdr = (general_purpose_bit_flag & 8) == 8;  /* bit */

    dos_datetime = makelong(&byterec[C_LAST_MOD_DOS_DATETIME]);
    DosToRdosTime(&rdos_msb_time, &rdos_lsb_time, dos_datetime);

    crc = makelong(&byterec[C_CRC32]);
    compr_size = makelong(&byterec[C_COMPRESSED_SIZE]);
    uncompr_size = makelong(&byterec[C_UNCOMPRESSED_SIZE]);
    compression_method = makeword(&byterec[C_COMPRESSION_METHOD]);

    filename_length = makeword(&byterec[C_FILENAME_LENGTH]);
    extra_field_length = makeword(&byterec[C_EXTRA_FIELD_LENGTH]);
    file_comment_length = makeword(&byterec[C_FILE_COMMENT_LENGTH]);

    diskstart = makeword(&byterec[C_DISK_NUMBER_START]);

    internal_file_attributes = makeword(&byterec[C_INTERNAL_FILE_ATTRIBUTES]);
    external_file_attributes = makelong(&byterec[C_EXTERNAL_FILE_ATTRIBUTES]);  /* LONG, not word! */
    textfile = internal_file_attributes & 1;    /* bit field */

    offset = makelong(&byterec[C_RELATIVE_OFFSET_LOCAL_HEADER]);

/*---------------------------------------------------------------------------
    Get central directory info, save host and method numbers, and set flag
    for lowercase conversion of filename, depending on the OS from which the
    file is coming.
  ---------------------------------------------------------------------------*/

    switch (hostnum) {
        case FS_FAT_:     /* PKZIP and zip -k store in uppercase */
        case CPM_:        /* like MS-DOS, right? */
        case VM_CMS_:     /* all caps? */
        case MVS_:        /* all caps? */
        case TANDEM_:
        case TOPS20_:
        case VMS_:        /* our Zip uses lowercase, but ASi's doesn't */
        /*  case Z_SYSTEM_:   ? */
        /*  case QDOS_:       ? */
            lcflag = 1;   /* convert filename to lowercase */
            break;

        default:     /* AMIGA_, FS_HPFS_, FS_NTFS_, MAC_, UNIX_, ATARI_, */
            lcflag = 0;
            break;   /*  FS_VFAT_, ATHEOS_, BEOS_ (Z_SYSTEM_), THEOS_: */
                         /*  no conversion */
    }

    /* do Amigas (AMIGA_) also have volume labels? */
    if ((external_file_attributes & 0x8) &&
        (hostnum == FS_FAT_ || hostnum == FS_HPFS_ ||
         hostnum == FS_NTFS_ || hostnum == ATARI_))
    {
        vollabel = TRUE;
        lcflag = 0;        /* preserve case of volume labels */
    } else
        vollabel = FALSE;

    /* this flag is needed to detect archives made by "PKZIP for Unix" when
       deciding which kind of codepage conversion has to be applied to
       strings (see do_string() function in fileio.c) */
    HasUxAtt = (external_file_attributes & 0xffff0000L) != 0L;

    /* store a copy of the central header filename for later comparison */
    cfilname = new char[filename_length + 1];

    if (!FUnzip->GetFileName(cfilname, filename_length))
    {
        FUnzip->Info(0x401,
          "%s:  bad filename length \n",
          "central");
        return FALSE;
    }

    FUnzip->SkipHeaderString(extra_field_length);
    FUnzip->SkipHeaderString(file_comment_length);

/*---------------------------------------------------------------------------
    Check central directory info for version/compatibility requirements.
  ---------------------------------------------------------------------------*/

    if (version_needed_to_extract[0] > UNZIP_VERSION) {
        FUnzip->Info(0x401, "   skipping: %-22s  need %s compat. v%u.%u (can do v%u.%u)\n",
              cfilname, "PK",
              version_needed_to_extract[0] / 10,
              version_needed_to_extract[0] % 10,
              UNZIP_VERSION / 10, UNZIP_VERSION % 10);
        return FALSE;
    }

    if ((compression_method >= REDUCED1 && compression_method <= REDUCED4) ||
        compression_method==TOKENIZED ||
        (compression_method>DEFLATED))
    {
        cmpridx = FindCompressMethod(compression_method);
        if (cmpridx < NUM_METHODS)
            FUnzip->Info(0x401, "   skipping: %-22s  `%s' method not supported\n",
              cfilname,
              ComprNames[cmpridx]);
        else
            FUnzip->Info(0x401, "   skipping: %-22s  unsupported compression method %u\n",
              cfilname,
              compression_method);
        return FALSE;
    }

    return TRUE;
}

/*##########################################################################
#
#   Name       : TUnzipFile::ProcessFileHeader
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipFile::ProcessFileHeader()
{
    int ok;
    unsigned long dos_datetime;
    unsigned char byterec[ LREC_SIZE ];
    long bufstart;
    char *inptr;
    int incnt;
    unsigned long csize;
    unsigned long ucsize;
    unsigned long crc32;
    unsigned char ve[2];
    unsigned short general_purpose_bit_flag;
    unsigned short filename_length;
    unsigned short extra_field_length;

    bufstart = FUnzip->FBufStart;
    inptr = FUnzip->FInPtr;
    incnt = FUnzip->FInCount;
    
    ok = FUnzip->SeekFile(this);

    if (ok)
    {

/*---------------------------------------------------------------------------
    Read the next local file header and do any necessary machine-type con-
    versions (byte ordering, structure padding compensation--do so by copy-
    ing the data from the array into which it was read (byterec) to the
    usable struct (lrec)).
  ---------------------------------------------------------------------------*/

        if (FUnzip->ReadBuf((char *)byterec, LREC_SIZE) == 0)
            ok = FALSE;
        else
        {
            ve[0] = byterec[L_VERSION_NEEDED_TO_EXTRACT_0];
            ve[1] = byterec[L_VERSION_NEEDED_TO_EXTRACT_1];

            if (version_needed_to_extract[0] < ve[0])
            {
                version_needed_to_extract[0] = ve[0];
                version_needed_to_extract[1] = ve[1];
            }

            general_purpose_bit_flag |= makeword(&byterec[L_GENERAL_PURPOSE_BIT_FLAG]);
            
            dos_datetime = makelong(&byterec[L_LAST_MOD_DOS_DATETIME]);
            DosToRdosTime(&rdos_msb_time, &rdos_lsb_time, dos_datetime);

            crc32 = makelong(&byterec[L_CRC32]);
            csize = makelong(&byterec[L_COMPRESSED_SIZE]);
            ucsize = makelong(&byterec[L_UNCOMPRESSED_SIZE]);
            filename_length = makeword(&byterec[L_FILENAME_LENGTH]);
            extra_field_length = makeword(&byterec[L_EXTRA_FIELD_LENGTH]);

            if ((general_purpose_bit_flag & 8) == 0) {
                crc = crc32;
                compr_size = csize;
                uncompr_size = ucsize;
            }
            
            if (compression_method != makeword(&byterec[L_COMPRESSION_METHOD])) {
                FUnzip->Info(0x421, "header incompability\n");
                ok = FALSE;
            }
        }
    }

    if (ok)
    {
        char *buf = new char[filename_length + 1];
        ok = FUnzip->GetFileName(buf, filename_length);

        if (ok)
        {
            if (strcmp(buf, cfilname))
            {
                FUnzip->Info(0x421, "filenames differ between headers\n");
                ok = FALSE;
            }
        }
        delete buf;
    }

    if (!ok)
        FUnzip->Info(0x421, "bad local header\n");

    if (ok)
    {
        FUnzip->SkipHeaderString(extra_field_length);
        file_data_offset = FUnzip->FBufStart - FUnzip->FExtraBytes + (FUnzip->FInPtr-FUnzip->FInBuf);
        abs_data_offset = FUnzip->FBufStart + (FUnzip->FInPtr-FUnzip->FInBuf);
    }

    RdosSetHandlePos(FUnzip->FInputHandle, bufstart);
    FUnzip->FBufStart = RdosGetHandlePos(FUnzip->FInputHandle);
    RdosReadHandle(FUnzip->FInputHandle, FUnzip->FInBuf, INBUFSIZ);  /* been here before... */
    FUnzip->FInPtr = inptr;
    FUnzip->FInCount = incnt;

    return ok;
}

/*##########################################################################
#
#   Name       : TUnzipFile::GetFileName
#
#   Purpose....: Get filename of entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TUnzipFile::GetFileName()
{
    return cfilname;
}

/*##########################################################################
#
#   Name       : TUnzipFile::Skip
#
#   Purpose....: Skip file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipFile::Skip()
{
    FSkipped = TRUE;
}

/*##########################################################################
#
#   Name       : TUnzipFile::IsOk
#
#   Purpose....: Check if file is ok
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipFile::IsOk()
{
    return FOk;
}

/*##########################################################################
#
#   Name       : TUnzipFile::IsSkipped
#
#   Purpose....: Check if file is skipped
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipFile::IsSkipped()
{
    return FSkipped;
}

/*##########################################################################
#
#   Name       : TUnzipFile::Extract
#
#   Purpose....: Extract file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipFile::Extract(const char *filename)
{
    char *extract_msg = "%8sing: %s";
    int ok;
    TUnzipExtractor *extractor = 0;

    switch (compression_method) {
        case STORED:
            FUnzip->Info(0, extract_msg, "extract", filename);
            extractor = new TUnzipStoreExtractor(FUnzip->FInputHandle, this, filename);
            break;

        case DEFLATED:
            FUnzip->Info(0, extract_msg, "extract", filename);
            extractor = new TUnzipDeflateExtractor(FUnzip->FInputHandle, this, filename);
            break;

        case SHRUNK:
            FUnzip->Info(0, extract_msg, "unshrink", filename);
            extractor = new TUnzipUnshrinkExtractor(FUnzip->FInputHandle, this, filename);
            break;

        case IMPLODED:
            FUnzip->Info(0, extract_msg, "explod", filename);
            extractor = new TUnzipExplodeExtractor(FUnzip->FInputHandle, this, filename);
            break;

        default:   /* should never get to this point */
            FUnzip->Info(0x401, "%s:  unknown compression method\n", filename);
            ok = FALSE;
            break;

    } /* end switch (compression method) */

    if (extractor)
    {
        extractor->Extract();
        ok = extractor->FOk;

        if (ok)
        {
            if (extractor->FCurrCrcVal != crc) {
            /* if quiet enough, we haven't output the filename yet:  do it */
                FUnzip->Info(0x401, "%-22s ", filename);
                FUnzip->Info(0x401, " bad CRC %08lx  (should be %08lx)\n", extractor->FCurrCrcVal, crc);
                if (encrypted)
                    FUnzip->Info(0x401, "   (may instead be incorrect password)\n");
                ok = FALSE;
            } else
                FUnzip->Info(0, "\n");
        }
        else
            FUnzip->Info(0x401, " extract failed %d\n");

        delete extractor;
    }

    return ok;
}


/*##########################################################################
#
#   Name       : TUnzipFile::CheckForNewer
#
#   Purpose....: Check if file is newer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipFile::CheckForNewer(const char *filename)
{
    unsigned long msb, lsb;
    int handle;

    handle = RdosOpenHandle(filename, O_RDWR);

    if (handle > 0)
    {
        RdosGetHandleModifyTime(handle, &msb, &lsb);
        RdosAddSec(&msb, &lsb, 2);
        RdosCloseHandle(handle);

        if (msb == rdos_msb_time)
            return lsb >= rdos_msb_time;
        else
            return msb >= rdos_lsb_time;
    }
    else
        return DOES_NOT_EXIST;

} /* end function check_for_newer() */


/*##########################################################################
#
#   Name       : TUnzipFile::NeedUpdate
#
#   Purpose....: Check if file need to be updated
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipFile::NeedUpdate(const char *filename)
{
    unsigned long msb, lsb;
    int handle;
    unsigned long long old_time;
    unsigned long long new_time;
    long long diff_time;
    char *buf;
    int size;
    unsigned long old_crc;
    RdosDirInfo dinf;

    handle = RdosOpenHandle(filename, O_RDWR);

    if (handle > 0)
    {
        RdosGetHandleAccessTime(handle, &msb, &lsb);

        old_time = ((long long)msb << 32) + lsb;
        new_time = ((long long)rdos_msb_time << 32) + rdos_lsb_time;
        diff_time = new_time - old_time;

        if (diff_time < 0)
            diff_time = -diff_time;

        if (diff_time > 2 * 1193)
        {
            RdosCloseHandle(handle);
            return TRUE;
        }

        if (RdosGetHandleSize(handle) != uncompr_size)
        {
            RdosCloseHandle(handle);
            return TRUE;
        }

        buf = new char[WSIZE];
        old_crc = 0;

        for (;;)
        {
            size = RdosReadHandle(handle, buf, WSIZE);

            if (size)
                old_crc = crc32(old_crc, (unsigned char *)buf, size);
            else
                break;
        }

        RdosCloseHandle(handle);
        delete buf;

        if (old_crc == crc)
            return FALSE;
        else
            return TRUE;               
        
    }
    else
    {
        size = strlen(filename);
        if (size)
        {
            if (filename[size - 1] == '/' || filename[size - 1] == '\\')
                return FALSE;
            else
            {
                handle = RdosOpenDir(filename, &dinf);
                if (handle)
                {
                    RdosCloseDir(handle);
                    return FALSE;
                }
                else
                    return TRUE;
            }
        }
        else
            return FALSE;
    }

} /* end function check_for_newer() */

/*##########################################################################
#
#   Name       : TUnzipFile::CreateTimeStr
#
#   Purpose....: Create time string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipFile::CreateTimeStr(char *str)
{
    int yr, mo, dy, hh, mm, ss, ms, us;

    RdosDecodeMsbTics(rdos_msb_time, &yr, &mo, &dy, &hh);
    RdosDecodeLsbTics(rdos_lsb_time, &mm, &ss, &ms, &us); 

    sprintf(str, "%04u-%02u-%02u %02u:%02u", yr, mo, dy, hh, mm);
}

/*##########################################################################
#
#   Name       : TUnzipFile::ShowVerbose
#
#   Purpose....: Show verbose info about file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipFile::ShowVerbose()
{
    int  error;
    unsigned  extnum, extver, methid, methnum, xattr;
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

    extnum = (unsigned)MIN(version_needed_to_extract[1], NUM_HOSTS);
    extver = (unsigned)version_needed_to_extract[0];
    methid = (unsigned)compression_method;
    methnum = FindCompressMethod(compression_method);

    FUnzip->Info(0, "  ");  
    FUnzip->Info(0, cfilname);
    FUnzip->Info(0, "\n");

    FUnzip->Info(0, "\n  offset of local header from start of archive:   %u (%Xh) bytes\n",
      offset,
      offset);

    if (hostnum >= NUM_HOSTS) {
        sprintf(unkn, "unknown (%d)",
                (int)hostnum);
        varmsg_str = unkn;
    } else {
        varmsg_str = os[hostnum];
    }
    FUnzip->Info(0, "  file system or operating system of origin:      %s\n", varmsg_str);
    FUnzip->Info(0, "  version of encoding software:                   %u.%u\n", hostver/10, hostver%10);

    if ((extnum >= NUM_HOSTS) || (os[extnum] == NULL)) {
        sprintf(unkn, "unknown (%d)",
                (int)version_needed_to_extract[1]);
        varmsg_str = unkn;
    } else {
        varmsg_str = os[extnum];
    }
    FUnzip->Info(0, "  minimum file system compatibility required:     %s\n", varmsg_str);
    FUnzip->Info(0, "  minimum software version required to extract:   %u.%u\n", extver/10, extver%10);

    if (methnum >= NUM_METHODS) {
        sprintf(unkn, "unknown (%d)", compression_method);
        varmsg_str = unkn;
    } else {
        varmsg_str = method[methnum];
    }
    FUnzip->Info(0, "  compression method:                             %s\n", varmsg_str);
    if (methid == IMPLODED) {
        FUnzip->Info(0, "  size of sliding dictionary (implosion):         %cK\n",
          (general_purpose_bit_flag & 2)? '8' : '4');
        FUnzip->Info(0, "  number of Shannon-Fano trees (implosion):       %c\n",
          (general_purpose_bit_flag & 4)? '3' : '2');
    } else if (methid == DEFLATED || methid == ENHDEFLATED) {
        unsigned short  dnum=(unsigned short)((general_purpose_bit_flag>>1) & 3);

        FUnzip->Info(0, "  compression sub-type (deflation):               %s\n", dtypelng[dnum]);
    }

    FUnzip->Info(0, "  file security status:                           %sencrypted\n",
      (general_purpose_bit_flag & 1) ? "" : "not ");
    FUnzip->Info(0, "  extended local header:                          %s\n",
      (general_purpose_bit_flag & 8) ? "yes" : "no");
    /* print upper 3 bits for amusement? */

    /* For printing of date & time, a "char d_t_buf[21]" is required.
     * To save stack space, we reuse the "char attribs[22]" buffer which
     * is not used yet.
     */

    CreateTimeStr(attribs);
    FUnzip->Info(0, "  file last modified on (DOS date/time):          %s\n", 
      attribs);
    
    FUnzip->Info(0, "  32-bit CRC value (hex):                         %.8lx\n", 
      crc);
    FUnzip->Info(0, "  compressed size:                                %u bytes\n",
      compr_size);
    FUnzip->Info(0, "  uncompressed size:                              %u bytes\n",
      uncompr_size);
    FUnzip->Info(0, "  apparent file type:                             %s\n",
      (internal_file_attributes & 1)? "text"
         : (internal_file_attributes & 2)? "ebcdic"
              : "binary");             /* changed to accept EBCDIC */
    xattr = (unsigned)((external_file_attributes >> 16) & 0xFFFF);
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
        FUnzip->Info(0, "  VMS file attributes (%06o octal):             %s\n", xattr, attribs);

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
        FUnzip->Info(0, "  Amiga file attributes (%06o octal):           %s\n", xattr, attribs);

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
        FUnzip->Info(0, "  Theos file attributes (%04X hex):               %s\n", xattr, attribs);


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

        FUnzip->Info(0, "  Unix file attributes (%06o octal):            %s\n", xattr, attribs);

    } else {
        FUnzip->Info(0, "  non-MSDOS external file attributes:             %06lX hex\n", external_file_attributes >> 8);

    } /* endif (hostnum: external attributes format) */

    if ((xattr=(unsigned)(external_file_attributes & 0xFF)) == 0)
        FUnzip->Info(0, "  MS-DOS file attributes (%02X hex):                none\n", xattr);
    else if (xattr == 1)
        FUnzip->Info(0, "  MS-DOS file attributes (%02X hex):                read-only\n", xattr);
    else
        FUnzip->Info(0, "  MS-DOS file attributes (%02X hex):                %s%s%s%s%s%s%s%s\n",
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
#   Name       : TUnzipFile::ShowCompact
#
#   Purpose....: Show compact info about file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipFile::ShowCompact()
{
    int         k;
    unsigned    methid, methnum, xattr;
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

    methid = (unsigned)(compression_method);
    methnum = FindCompressMethod(compression_method);

    strcpy(methbuf, method[methnum]);
    if (methid == IMPLODED) {
        methbuf[1] = (char)((general_purpose_bit_flag & 2)? '8' : '4');
        methbuf[3] = (char)((general_purpose_bit_flag & 4)? '3' : '2');
    } else if (methid == DEFLATED || methid == ENHDEFLATED) {
        unsigned short  dnum=(unsigned short)((general_purpose_bit_flag>>1) & 3);
        methbuf[3] = dtype[dnum];
    } else if (methnum >= NUM_METHODS) {   /* unknown */
        sprintf(&methbuf[1], "%03u", compression_method);
    }

    for (k = 0;  k < 15;  ++k)
        attribs[k] = ' ';
    attribs[15] = 0;

    xattr = (unsigned)((external_file_attributes >> 16) & 0xFFFF);
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
                  ((unsigned)!(external_file_attributes & 1) << 7) |
                  ((unsigned)(external_file_attributes & 0x10) << 2))
               )
            {
                xattr = (unsigned)(external_file_attributes & 0xFF);
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
                else if ((p = strchr(cfilname, '.')) != (char *)NULL) {
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

    FUnzip->Info(0, "%s %s %u ", attribs,
      os[hostnum],
      uncompr_size);
    FUnzip->Info(0, "%c",
      (general_purpose_bit_flag & 1)?
      ((internal_file_attributes & 1)? 'T' : 'B') :  /* encrypted */
      ((internal_file_attributes & 1)? 't' : 'b')); /* plaintext */

    /* For printing of date & time, a "char d_t_buf[16]" is required.
     * To save stack space, we reuse the "char attribs[16]" buffer whose
     * content is no longer needed.
     */
    CreateTimeStr(attribs);
    FUnzip->Info(0, " %s %s ", methbuf, attribs); 

    FUnzip->Info(0, cfilname);
    FUnzip->Info(0, "\n");

} /* end function zi_short() */



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
#   Name       : TUnzip::TUnzip
#
#   Purpose....: Constructor for unzip
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzip::TUnzip(const char *filename)
{
    Init();
    Open(filename);
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
    int i;
    
    delete FInBuf;

    Close();
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

    FFileArr = 0;
    FFileSize = 0;
    FFileCount = 0;

    FInBuf = new char[INBUFSIZ + 4];    /* 4 extra for hold[] (below) */
}

/*##########################################################################
#
#   Name       : TUnzip::Open
#
#   Purpose....: Open zipfile
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::Open(const char *filename)
{
    int ok;

    Close();

    FInputHandle = RdosOpenHandle(filename, O_RDWR);

    if (FInputHandle <= 0)
    {
        Info(0x401, "error:  cannot open zipfile [ %s ]\n", filename);
        return FALSE;
    }

    FZipLen = RdosGetHandleSize(FInputHandle);

    ok = ProcessFiles(filename, TRUE);

    if (!ok)
    {
        RdosCloseHandle(FInputHandle);
        FInputHandle = 0;
    }

    return ok;
} /* end function do_seekable() */

/*##########################################################################
#
#   Name       : TUnzip::OpenNoHeader
#
#   Purpose....: Open zipfile, no info-header
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::OpenNoHeader(const char *filename)
{
    int ok;

    Close();

    FInputHandle = RdosOpenHandle(filename, O_RDWR);

    if (FInputHandle <= 0)
    {
        Info(0x401, "error:  cannot open zipfile [ %s ]\n", filename);
        return FALSE;
    }

    FZipLen = RdosGetHandleSize(FInputHandle);

    ok = ProcessFiles(filename, FALSE);

    if (!ok)
    {
        RdosCloseHandle(FInputHandle);
        FInputHandle = 0;
    }

    return ok;
} /* end function do_seekable() */


/*##########################################################################
#
#   Name       : TUnzip::Close
#
#   Purpose....: Close zip file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::Close()
{
    int i;

    if (FInputHandle)
    {
        RdosCloseHandle(FInputHandle);
        FInputHandle = 0;
    }

    for (i = 0; i < FFileCount; i++)
    {
        if (FFileArr[i])
            delete FFileArr[0];

        delete FFileArr;
        FFileCount = 0;
        FFileSize = 0;
    }
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
    char *buf;

    buf = new char[WSIZE];

    comment_bytes_left = length;
    block_len = WSIZE;       /* for the while statement, first time */

    while (comment_bytes_left > 0 && block_len > 0) {
        char *p = buf;
        char *q = buf;

        if ((block_len = ReadBuf(buf,
                   MIN(WSIZE, comment_bytes_left))) == 0)
            break;
        
        comment_bytes_left -= block_len;

        /* this is why we allocated an extra byte for outbuf:  terminate
             *  with zero (ASCIIZ) */
        buf[block_len] = 0;

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
            AsciiToNative(buf);
        }

        Info(0, buf);
    }
    /* add '\n' if not at start of line */
    Info(0, "\n");

    delete buf;
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
#   Name       : TUnzip::FindRec
#
#   Purpose....: Find record
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::FindRec(long searchlen, char* signature, int rec_size)
    /* return 0 when rec found, 1 when not found, 2 in case of read error */
{
    int i, numblks, found=FALSE;
    long tail_len;

/*---------------------------------------------------------------------------
    Zipfile is longer than INBUFSIZ:  may need to loop.  Start with short
    block at end of zipfile (if not TOO short).
  ---------------------------------------------------------------------------*/

    if ((tail_len = FZipLen % INBUFSIZ) > rec_size) {
        RdosSetHandlePos(FInputHandle, FZipLen-tail_len);
        FBufStart = RdosGetHandlePos(FInputHandle);
        if ((FInCount = RdosReadHandle(FInputHandle, FInBuf,
            (unsigned int)tail_len)) != (int)tail_len)
            return 2;      /* it's expedient... */

        /* 'P' must be at least (rec_size+4) bytes from end of zipfile */
        for (FInPtr = FInBuf+(int)tail_len-(rec_size+4);
             FInPtr >= FInBuf;
             --FInPtr) {
            if ( (*FInPtr == (unsigned char)0x50) &&         /* ASCII 'P' */
                 !memcmp(FInPtr, signature, 4) ) {
                FInCount -= (int)(FInPtr - FInBuf);
                found = TRUE;
                break;
            }
        }
        /* sig may span block boundary: */
        memcpy(FSearchHold, FInBuf, 3);
    } else
        FBufStart = FZipLen - tail_len;

/*-----------------------------------------------------------------------
    Loop through blocks of zipfile data, starting at the end and going
    toward the beginning.  In general, need not check whole zipfile for
    signature, but may want to do so if testing.
  -----------------------------------------------------------------------*/

    numblks = (int)((searchlen - tail_len + (INBUFSIZ-1)) / INBUFSIZ);
    /*               ==amount=   ==done==   ==rounding==    =blksiz=  */

    for (i = 1;  !found && (i <= numblks);  ++i) {
        FBufStart -= INBUFSIZ;
        RdosSetHandlePos(FInputHandle, FBufStart);
        if ((FInCount = RdosReadHandle(FInputHandle,FInBuf,INBUFSIZ))
            != INBUFSIZ)
            return 2;          /* read error is fatal failure */

        for (FInPtr = FInBuf+INBUFSIZ-1;  FInPtr >= FInBuf; --FInPtr)
            if ( (*FInPtr == (unsigned char)0x50) &&         /* ASCII 'P' */
                 !memcmp(FInPtr, signature, 4) ) {
                FInCount -= (int)(FInPtr - FInBuf);
                found = TRUE;
                break;
            }
        /* sig may span block boundary: */
        memcpy(FSearchHold, FInBuf, 3);
    }
    return (found ? 0 : 1);
} /* end function rec_find() */



/*##########################################################################
#
#   Name       : TUnzip::GetCentralHeader
#
#   Purpose....: Get central header
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::GetCentralHeader(const char *filename, long searchlen, int verbose)
{
    int found = FALSE;
    int ok;
    int result;
    unsigned char byterec[ECREC_SIZE+4];
    static char end_central_sig[4]   = {0x50, 0x4B, 0x05, 0x06};

/*---------------------------------------------------------------------------
    Treat case of short zipfile separately.
  ---------------------------------------------------------------------------*/

    if (FZipLen <= INBUFSIZ) {
        RdosSetHandlePos(FInputHandle, 0L);
        FInCount = RdosReadHandle(FInputHandle, FInBuf, FZipLen);
        if (FInCount == FZipLen)

            /* 'P' must be at least (ECREC_SIZE+4) bytes from end of zipfile */
            for (FInPtr = FInBuf+FZipLen-(ECREC_SIZE+4);
                 FInPtr >= FInBuf;
                 --FInPtr) {
                if ( (*FInPtr == (unsigned char)0x50) &&         /* ASCII 'P' */
                     !memcmp(FInPtr, end_central_sig, 4)) {
                    FInCount -= (int)(FInPtr - FInBuf);
                    found = TRUE;
                    break;
                }
            }

/*---------------------------------------------------------------------------
    Zipfile is longer than INBUFSIZ:

    MB - this next block of code moved to rec_find so that same code can be
    used to look for zip64 ec record.  No need to include code above since
    a zip64 ec record will only be looked for if it is a BIG file.
  ---------------------------------------------------------------------------*/

    } else {
        found =
          (FindRec(searchlen, end_central_sig, ECREC_SIZE) == 0
           ? TRUE : FALSE);
    } /* end if (ziplen > INBUFSIZ) */

/*---------------------------------------------------------------------------
    Searched through whole region where signature should be without finding
    it.  Print informational message and die a horrible death.
  ---------------------------------------------------------------------------*/

    if (!found) {
        Info(0x401, "[%s]\n", filename);
        Info(0x401, "End-of-central-directory signature not found. Probably no zip archive\n");
        return FALSE;   /* failed */
    }

/*---------------------------------------------------------------------------
    Found the signature, so get the end-central data before returning.  Do
    any necessary machine-type conversions (byte ordering, structure padding
    compensation) by reading data into character array and copying to struct.
  ---------------------------------------------------------------------------*/

    FRealHeaderOffset = FBufStart + (FInPtr-FInBuf);

    if (ReadBuf((char *)byterec, ECREC_SIZE+4) == 0)
        return FALSE;

    FHeader.number_this_disk = makeword(&byterec[NUMBER_THIS_DISK]);
    FHeader.num_disk_start_cdir = makeword(&byterec[NUM_DISK_WITH_START_CEN_DIR]);
    FHeader.num_entries_centrl_dir_ths_disk = makeword(&byterec[NUM_ENTRIES_CEN_DIR_THS_DISK]);
    FHeader.total_entries_central_dir = makeword(&byterec[TOTAL_ENTRIES_CENTRAL_DIR]);
    FHeader.size_central_directory = makelong(&byterec[SIZE_CENTRAL_DIRECTORY]);
    FHeader.offset_start_central_directory = makelong(&byterec[OFFSET_START_CENTRAL_DIRECTORY]);
    FHeader.zipfile_comment_length = makeword(&byterec[ZIPFILE_COMMENT_LENGTH]);

    if (verbose)
        DisplayHeaderString(FHeader.zipfile_comment_length, FALSE);
    else
        SkipHeaderString(FHeader.zipfile_comment_length);

    FExpectHeaderOffset = FHeader.offset_start_central_directory +
                            FHeader.size_central_directory;

    return TRUE;

} /* end function find_ecrec() */

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
            FInCount = RdosReadHandle(FInputHandle, FInBuf, INBUFSIZ);
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
 */
    long request = abs_offset + FExtraBytes;
    long inbuf_offset = request % INBUFSIZ;
    long bufstart = request - inbuf_offset;

    if (request < 0)
        return FALSE;
    
    if (bufstart != FBufStart) {
        RdosSetHandlePos(FInputHandle, bufstart);
        FBufStart = RdosGetHandlePos(FInputHandle);
        FInCount = RdosReadHandle(FInputHandle, FInBuf, INBUFSIZ);
        if (FInCount <= 0)
            return FALSE;
        FInCount -= (int)inbuf_offset;
        FInPtr = FInBuf + (int)inbuf_offset;
    } else {
        FInCount += (FInPtr-FInBuf) - (int)inbuf_offset;
        FInPtr = FInBuf + (int)inbuf_offset;
    }
    return TRUE;
} /* end function seek_zipf() */

/*##########################################################################
#
#   Name       : TUnzip::GetFile
#
#   Purpose....: Get file class
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipFile *TUnzip::GetFile(int id)
{
    return FFileArr[id];
}

/*##########################################################################
#
#   Name       : TUnzip::GetFileCount
#
#   Purpose....: Get file count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::GetFileCount()
{
    return FFileCount;
}

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
int TUnzip::GetFileName(char *buf, int length)
{
    int block_len;

    if (length >= FILE_NAME_SIZE) {
        Info(0x401, "warning:  filename too long--truncating.\n");

        /* remember excess length in block_len */
        block_len = length - (FILE_NAME_SIZE - 1);
        length = FILE_NAME_SIZE - 1;
    } 
    else
        /* no excess size */
        block_len = 0;

    if (ReadBuf(buf, length) == 0)
        return FALSE;

    buf[length] = '\0';      /* terminate w/zero:  ASCIIZ */

    /* translate the Zip entry filename coded in host-dependent "extended
           ASCII" into the compiler's (system's) internal text code page */
    AsciiToNative(buf);

    strtolower(buf, buf);

    if (block_len)         /* no overflow, we're done here */
    {
        Info(0x401, "[ %s ]\n", buf);
        SkipHeaderString(block_len);
    }

     return TRUE;
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
int TUnzip::SeekFile(TUnzipFile *file)  
{
    long bufstart, inbuf_offset, request;
    int ok;
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
        Info(0x401, SeekMsg, file->cfilname);
        if (FFileArr) {
            if (file == FFileArr[0] && FExtraBytes != 0L) {
                FOldExtraBytes =  FExtraBytes;
                FExtraBytes = 0L;
                request = file->offset;  /* could also check if != 0 */
                inbuf_offset = request % INBUFSIZ;
                bufstart = request - inbuf_offset;
                /* try again */
                if (request < 0) {
                    Info(0x401, SeekMsg, file->cfilname);
                    return FALSE;
                }
            } else {
                return FALSE;
            }
        } else {
            return FALSE;
        }
    }

    if (bufstart != FBufStart) {
        RdosSetHandlePos(FInputHandle, bufstart);
        FBufStart = RdosGetHandlePos(FInputHandle);
        FInCount = RdosReadHandle(FInputHandle, FInBuf, INBUFSIZ);
        if (FInCount <= 0)
        {
            Info(0x401, OffsetMsg, "lseek", bufstart);
            return FALSE;
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
        return FALSE;
    }

    if (memcmp(sig, local_hdr_sig, 4)) {
        Info(0x401, OffsetMsg, "signature", request);
        if (FFileArr) {
            if ((file == FFileArr[0] &&  FExtraBytes != 0L) ||
                    ( FExtraBytes == 0L && FOldExtraBytes != 0L)) {
                if (FExtraBytes) {
                    FOldExtraBytes = FExtraBytes;
                    FExtraBytes = 0L;
                } else
                    FExtraBytes = FOldExtraBytes; /* third attempt */

                ok = Seek(file->offset);
                if (!ok || ReadBuf(sig, 4) == 0) {  /* bad offset */
                    if (!ok)
                        Info(0x401, OffsetMsg, "EOF", request);
                    return FALSE;
                }
                if (memcmp(sig, local_hdr_sig, 4)) {
                    Info(0x401, OffsetMsg, "signature", request);
                    return FALSE;
                }
            } else {
                return FALSE;
            }
        } else {
            return FALSE;
        }
    }
        
    return TRUE;
}

/*##########################################################################
#
#   Name       : TUnzip::ProcessNextFile
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipFile *TUnzip::ProcessNextFile()
{
    char sig[4];
    TUnzipFile *file;
    static char central_hdr_sig[4]     = {0x50, 0x4B, 0x01, 0x02};
    
    FOldExtraBytes = 0;

    if (ReadBuf(sig, 4) == 0)
        return 0;

    if (memcmp(sig, central_hdr_sig, 4)) {  /* is it a new entry? */
        return 0;

       /* no new central directory entry
        * -> is the number of processed entries compatible with the
        *    number of entries as stored in the end_central record?
        */
//        if ((members_processed
//            & (G.ecrec.have_ecr64 ? MASK_ZUCN64 : MASK_ZUCN16))
//            == G.ecrec.total_entries_central_dir) {
            /* yes, so look if we ARE back at the end_central record
             */
//                no_endsig_found =
//                      ( (memcmp(G.sig,
//                      (G.ecrec.have_ecr64 ?
//                      end_central64_sig : end_central_sig),
//                      4) != 0)
//                      && (!G.ecrec.is_zip64_archive)
//                       && (memcmp(G.sig, end_central_sig, 4) != 0)
//               );
//        } else {
            /* no; we have found an error in the central directory
             * -> report it and stop searching for more Zip entries
             */
//            Info(0x401, CentSigMsg, j + blknum*DIR_BLKSIZ + 1);
//            Info(0x401, ReportMsg);
//        }
    }

    file = new TUnzipFile(this);

    return file;
}

/*##########################################################################
#
#   Name       : TUnzip::ProcessFiles
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzip::ProcessFiles(const char *filename, int verbose)
{
    int ok;
    int i;
    TUnzipFile **newarr;
    TUnzipFile *file;
    char sig[4];
    static char central_hdr_sig[4]     = {0x50, 0x4B, 0x01, 0x02};

    FSearchHold = FInBuf + INBUFSIZ;     /* to check for boundary-spanning sigs */

/*---------------------------------------------------------------------------
    Find and process the end-of-central-directory header.  UnZip need only
    check last 65557 bytes of zipfile:  comment may be up to 65535, end-of-
    central-directory record is 18 bytes, and signature itself is 4 bytes;
    add some to allow for appended garbage.  Since ZipInfo is often used as
    a debugging tool, search the whole zipfile if zipinfo_mode is true.
  ---------------------------------------------------------------------------*/

    FBufStart = 0;
    FInPtr = FInBuf;

    if (verbose)
        Info(0, "Archive:  %s\n", filename);

    ok = GetCentralHeader(filename, MIN(FZipLen, 66000L), verbose);

    if (!ok)
        return ok;

/*---------------------------------------------------------------------------
    Test the end-of-central-directory info for incompatibilities (multi-disk
    archives) or inconsistencies (missing or extra bytes in zipfile).
  ---------------------------------------------------------------------------*/

    if (FHeader.number_this_disk != 0)
        return FALSE;

    FExtraBytes = FRealHeaderOffset - FExpectHeaderOffset;
    if (FExtraBytes < 0)
    {
        Info(0x401, "error [%s]:  missing %u bytes in zipfile\n", filename, -FExtraBytes);
            ok = FALSE;
    } else if (FExtraBytes > 0) {
        if ((FHeader.offset_start_central_directory == 0) &&
                (FHeader.size_central_directory != 0))   /* zip 1.5 -go bug */
        {
            Info(0x401, "error [%s]:  NULL central directory offset\n", filename);
            FHeader.offset_start_central_directory = FExtraBytes;
            FExtraBytes = 0;
            ok = FALSE;
        }
        else {
            Info(0x401, "warning [%s]:  %d extra byte(s) at beginning or within zipfile\n", 
              filename, FExtraBytes);
        }
    }

    if (!ok)
        return ok;

    /*-----------------------------------------------------------------------
        Check for empty zipfile and exit now if so.
      -----------------------------------------------------------------------*/

    if (FExpectHeaderOffset == 0 && FHeader.size_central_directory==0) {
        Info(0x401, "warning [%s]:  zipfile is empty\n", filename);
        return TRUE;
    }

    /*-----------------------------------------------------------------------
        Compensate for missing or extra bytes, and seek to where the start
        of central directory should be.  If header not found, uncompensate
        and try again (necessary for at least some Atari archives created
        with STZip, as well as archives created by J.H. Holm's ZIPSPLIT 1.1).
      -----------------------------------------------------------------------*/

    ok = Seek(FHeader.offset_start_central_directory);
    
    if (!ok || (ReadBuf(sig, 4) == 0) ||
        memcmp(sig, central_hdr_sig, 4))
    {
        long tmp = FExtraBytes;

        FExtraBytes = 0;
        ok = Seek(FHeader.offset_start_central_directory);
        if (!ok || (ReadBuf(sig, 4) == 0) ||
            memcmp(sig, central_hdr_sig, 4))
        {
            if (!ok)
                Info(0x401, "error [%s]:  start of central directory not found\n", filename);
            return FALSE;
        }

        Info(0x401, "error [%s]:  reported length of central directory too long\n", filename);
        return FALSE;
    }

    /*-----------------------------------------------------------------------
        Seek to the start of the central directory one last time, since we
        have just read the first entry's signature bytes; then list, extract
        or test member files as instructed, and close the zipfile.
      -----------------------------------------------------------------------*/

    ok = Seek(FHeader.offset_start_central_directory);
    if (!ok) {
        return FALSE;
    }

    for (;;)
    {
        file = ProcessNextFile();

        if (file)
        {
            if (FFileSize == FFileCount)
            {
                FFileSize = 3 * FFileSize / 2 + 1;
                newarr = new TUnzipFile *[FFileSize];

                for (i = 0; i < FFileCount; i++)
                    newarr[i] = FFileArr[i];

                for (i = FFileCount; i < FFileSize; i++)
                    newarr[i] = 0;

                if (FFileArr)
                    delete FFileArr;

                FFileArr = newarr;                
            }

            FFileArr[FFileCount] = file;
            FFileCount++;
        }
        else
            break;
    }

    return TRUE;
}
