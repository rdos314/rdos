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

#include "rdos.h"
#include "unzip.h"
#include "zlib.h"

#define     FALSE       0
#define     TRUE        !FALSE

#define LF     10        /* '\n' on ASCII machines; must be 10 due to EBCDIC */
#define CR     13        /* '\r' on ASCII machines; must be 13 due to EBCDIC */
#define CTRLZ  26        /* DOS & OS/2 EOF marker (used in fileio.c, vms.c) */

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
#   Name       : TUnzip::DisplayZipInfo
#
#   Purpose....: Display info from zip-file at current position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzip::DisplayZipInfo(int length, int oemconvert)
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

    if (FEncrypted) {
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

    if (FEncrypted) {
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

    FOutputHandle = RdosCreateFile(FCurrFileName, 0);
    if (!FOutputHandle) {
        Info(0x401, "error:  cannot create %s\n", FCurrFileName);
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
void TUnzip::CloseAndSetTime(unsigned long dos_datetime)
{
    unsigned long msb, lsb;
    unsigned short dos_date, dos_time;

    dos_date = (unsigned short)(dos_datetime >> 16);
    dos_time = (unsigned short)(dos_datetime & 0xFFFFL);

    RdosDosTimeDateToTics(dos_date, dos_time, &msb, &lsb);
    RdosSetFileTime(FOutputHandle, msb, lsb);

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
      FnFilter1(UnzipClass.FCurrFileName));

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

    if (FTextMode) {

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
  s = FCurrFile.ucsize;
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
    FUsedCSize = FCurrFile.csize - FDecompSize - FInCount - (k >> 3);
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
  s = FCurrFile.ucsize;
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
    FUsedCSize = FCurrFile.csize - FDecompSize - FInCount - (k >> 3);
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

  if (FCurrFile.general_purpose_bit_flag & 4)
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
  if (FCurrFile.general_purpose_bit_flag & 2)      /* true if 8K */
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
