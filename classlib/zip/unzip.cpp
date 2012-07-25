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
    delete FInBuf;
    delete FTmpOutBuf;
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

    FInBuf = new char[INBUFSIZ + 4];    /* 4 extra for hold[] (below) */
    FTmpOutBuf = new char[TMPOUTSIZ];
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
    if (FMemMode)
        return EOF;

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
    if (FMemMode)
        return 0;

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
int TUnzip::Flush(char *rawbuf, int size, int output)
{
    char *p;
    char *q;

/*---------------------------------------------------------------------------
    Compute the CRC first; if testing or if disk is full, that's it.
  ---------------------------------------------------------------------------*/

    FCurrCrcVal = crc32(FCurrCrcVal, (unsigned char *)rawbuf, size);

    if (!output || size == 0L)  /* testing or nothing to write:  all done */
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

