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

#include "unzip.h"

#define     FALSE       0
#define     TRUE        !FALSE

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
