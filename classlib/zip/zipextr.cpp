/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# Adapted from Info-ZIP
#
# The Info-ZIP license may be found at:  
# ftp://ftp.info-zip.org/pub/infozip/license.html
#
# zipextr
# Extractor base class
#
########################################################################*/

#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h> 

#include "rdos.h"
#include "zipextr.h"
#include "unzip.h"
#include "zlib.h"

#define     FALSE       0
#define     TRUE        !FALSE

#define RAND_HEAD_LEN  12       /* length of encryption random header */

#define LF     10        /* '\n' on ASCII machines; must be 10 due to EBCDIC */
#define CR     13        /* '\r' on ASCII machines; must be 13 due to EBCDIC */
#define CTRLZ  26        /* DOS & OS/2 EOF marker (used in fileio.c, vms.c) */

#define INBUFSIZ  8192
#define TMPOUTSIZ 0x10000

static const unsigned *crctab = get_crc_table();

/*##########################################################################
#
#   Name       : TUnzipExtractor::TUnzipExtractor
#
#   Purpose....: Constructor for unzipextractor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipExtractor::TUnzipExtractor(int InputFileHandle, TUnzipFile *File, const char *DestFileName)
{
    char filename[256];    
    const char *srcptr;
    char *destptr;
    int dirhandle;
    FInBuf = new char[INBUFSIZ + 4];    /* 4 extra for hold[] (below) */
    FOutBuf = new char[WSIZE + 1];
    FTmpOutBuf = 0;
    RdosDirInfo dinf;

    FCurrCrcVal = 0;

    srcptr = DestFileName;
    destptr = filename;
    
    while (*srcptr)
    {
        if (*srcptr == '\\' || *srcptr == '/')
        {
            *destptr = 0;
            dirhandle = RdosOpenDir(filename, &dinf);
            if (dirhandle)
                RdosCloseDir(dirhandle);
            else
                RdosMakeDir(filename);
        }
        *destptr = *srcptr;            
        srcptr++;
        destptr++;
    }    

    FInputHandle = RdosDupHandle(InputFileHandle);
    FOutputHandle = RdosOpenHandle(DestFileName, O_CREAT | O_RDWR);

    if (FInputHandle < 0)
        FInputHandle = 0;

    if (FOutputHandle < 0)
        FOutputHandle = 0;

    FFile = File;    
}

/*##########################################################################
#
#   Name       : TUnzipExtractor::~TUnzipExtractor
#
#   Purpose....: Destructor for unzipextractor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipExtractor::~TUnzipExtractor()
{
    RdosSetHandleModifyTime(FOutputHandle, FFile->rdos_msb_time, FFile->rdos_lsb_time);
    RdosCloseHandle(FOutputHandle);
    RdosCloseHandle(FInputHandle);

    delete FOutBuf;
    delete FInBuf;

    if (FTmpOutBuf)
        delete FTmpOutBuf;
}

/*##########################################################################
#
#   Name       : TUnzipExtractor::IsFileOpen
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExtractor::IsFileOpen()
{
    return FOutputHandle != 0;
}

/*##########################################################################
#
#   Name       : TUnzipExtractor::SetupEncryption
#
#   Purpose....: Set encryption keys
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipExtractor::SetupEncryption(const char *password)
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
#   Name       : TUnzipExtractor::Seek
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExtractor::Seek(long abs_offset)
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
 */
    long request = abs_offset;
    long inbuf_offset = request % INBUFSIZ;
    long bufstart = request - inbuf_offset;

    if (request < 0)
        return FALSE;

    RdosSetHandlePos(FInputHandle, bufstart);
    FInCount = RdosReadHandle(FInputHandle, FInBuf, INBUFSIZ);
    if (FInCount <= 0)
        return FALSE;

    FInCount -= (int)inbuf_offset;
    FInPtr = FInBuf + (int)inbuf_offset;

    return TRUE;
} /* end function seek_zipf() */

/*##########################################################################
#
#   Name       : TUnzipExtractor::Decrypt
#
#   Purpose....: Setup decrypt
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExtractor::Decrypt()
{
    unsigned short b;
    int n;
    unsigned char h[RAND_HEAD_LEN];

    /* get header once (turn off "encrypted" flag temporarily so we don't
     * try to decrypt the same data twice) */

    FDoDecrypt = FALSE;

    DeferInput();
    
    for (n = 0; n < RAND_HEAD_LEN; n++) {
        b = GetNextByte();
        h[n] = (unsigned char)b;
    }
    UndeferInput();

    FDoDecrypt = TRUE;

    return TRUE;

} /* end function decrypt() */

/*##########################################################################
#
#   Name       : TUnzipExtractor::UndeferInput
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipExtractor::UndeferInput()
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
#   Name       : TUnzipExtractor::DeferInput
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipExtractor::DeferInput()
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
#   Name       : TUnzipExtractor::DecryptByte
#
#   Purpose....: Return the next byte in the pseudo-random sequence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExtractor::DecryptByte()
{
    unsigned temp;  /* POTENTIAL BUG:  temp*(temp^1) may overflow in an
                     * unpredictable manner on 16-bit systems; not a problem
                     * with any known compiler so far, though */

    temp = ((unsigned)FKeys[2] & 0xffff) | 2;
    return (int)(((temp * (temp ^ 1)) >> 8) & 0xff);
}


/*##########################################################################
#
#   Name       : TUnzipExtractor::UpdateKeys
#
#   Purpose....: Update the encryption keys with the next byte of plain text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExtractor::UpdateKeys(int c)
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
#   Name       : TUnzipExtractor::ZDecode
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExtractor::ZDecode(int c)
{
    c ^= DecryptByte();
    return UpdateKeys(c);
}

/*##########################################################################
#
#   Name       : TUnzipExtractor::ReadByte
#
#   Purpose....: Read byte input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExtractor::ReadByte()   /* refill inbuf and return a byte if available, else EOF */
{
    if (FDecompSize <= 0) {
        FDecompSize--;             /* for tests done after exploding */
        FInCount = 0;
        return EOF;
    }
    if (FInCount <= 0) {
        FInCount = RdosReadHandle(FInputHandle, FInBuf, INBUFSIZ);
        if (FInCount == 0)
            return EOF;

        FInPtr = FInBuf;
        DeferInput();           /* decrements G.csize */
    }

    if (FDoDecrypt) {
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
#   Name       : TUnzipExtractor::GetNextByte
#
#   Purpose....: Get next byte from input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExtractor::GetNextByte()
{
    return (FInCount-- > 0 ? (int)(*FInPtr++) : ReadByte());
}

/*##########################################################################
#
#   Name       : TUnzipExtractor::GetInbuf
#
#   Purpose....: Function get inbuf()
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TUnzipExtractor::GetInbuf()
{
    return FInBuf;
}

/*##########################################################################
#
#   Name       : TUnzipExtractor::FillInbuf
#
#   Purpose....: Function fillinbuf()
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExtractor::FillInbuf() /* like readbyte() except returns number of bytes in inbuf */
{
    FInCount = RdosReadHandle(FInputHandle, FInBuf, INBUFSIZ);
    if (FInCount <= 0)
        return 0;

    FInPtr = FInBuf;
    DeferInput();           /* decrements G.csize */

    if (FDoDecrypt) {
        char *p;
        int n;

        for (n = FInCount, p = FInPtr;  n--;  p++)
            *p = ZDecode(*p);
    }

    return FInCount;

} /* end function fillinbuf() */

/*##########################################################################
#
#   Name       : TUnzipExtractor::Flush
#
#   Purpose....: returns PK error codes:
#                 if tflag => always 0; PK_DISK if write error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExtractor::Flush(char *rawbuf, int size)
{
    char *p;
    char *q;

/*---------------------------------------------------------------------------
    Compute the CRC first; if testing or if disk is full, that's it.
  ---------------------------------------------------------------------------*/

    FCurrCrcVal = crc32(FCurrCrcVal, (unsigned char *)rawbuf, size);

    if (!FOutputHandle || size == 0L)  /* testing or nothing to write:  all done */
        return TRUE;

/*---------------------------------------------------------------------------
    Write the bytes rawbuf[0..size-1] to the output device, first converting
    end-of-lines and ASCII/EBCDIC as needed.  If SMALL_MEM or MED_MEM are NOT
    defined, outbuf is assumed to be at least as large as rawbuf and is not
    necessarily checked for overflow.
  ---------------------------------------------------------------------------*/

    if (FDoText) {

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
            if (!RdosWriteHandle(FOutputHandle, FTmpOutBuf, q-FTmpOutBuf))
                return FALSE;
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
        if (!RdosWriteHandle(FOutputHandle, rawbuf, size))
            return FALSE;
    }

    return TRUE;

} /* end function flush() [resp. partflush() for 16-bit Deflate64 support] */

/*##########################################################################
#
#   Name       : TUnzipExtractor::Extract
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExtractor::Extract()
{    
    FOk = TRUE;

    if (!IsFileOpen())
        return FALSE;

    FDoDecrypt = FALSE;
    FDoText = FFile->textfile;

    if (FDoText)
        FTmpOutBuf = new char[TMPOUTSIZ];

    if (!Seek(FFile->abs_data_offset))
        return FALSE;

    /* Size consistency checks must come after reading in the local extra
     * field, so that any Zip64 extension local e.f. block has already
     * been processed.
     */
    if (FFile->compression_method == STORED) {
        unsigned long csiz_decrypted = FFile->compr_size;

        if (FFile->encrypted)
            csiz_decrypted -= 12;
        if (FFile->uncompr_size != csiz_decrypted) {
            FFile->uncompr_size = csiz_decrypted;
        }
    }

    if (FFile->encrypted) {
        if (!Decrypt())
            FOk = FALSE;
    }

    if (FOk) {
        FDecompSize = FFile->compr_size;

        DeferInput();    /* so NEXTBYTE bounds check will work */
    
        Execute();
    }

    if (FTmpOutBuf)
    {
        delete FTmpOutBuf;
        FTmpOutBuf = 0;
    }

    return FOk;
}
