/*
  Copyright (c) 1990-2009 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2009-Jan-02 or later
  (the contents of which are also included in unzip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/*---------------------------------------------------------------------------

  fileio.c

  This file contains routines for doing direct but relatively generic input/
  output, file-related sorts of things, plus some miscellaneous stuff.  Most
  of the stuff has to do with opening, closing, reading and/or writing files.

  Contains:  open_input_file()
             open_outfile()           (not: VMS, AOS/VS, CMSMVS, MACOS, TANDEM)
             undefer_input()
             defer_leftover_input()
             readbuf()
             readbyte()
             fillinbuf()
             seek_zipf()
             flush()                  (non-VMS)
             is_vms_varlen_txt()      (non-VMS, VMS_TEXT_CONV only)
             disk_error()             (non-VMS)
             UzpMessagePrnt()
             UzpMessageNull()         (DLL only)
             UzpInput()
             UzpMorePause()
             UzpPassword()            (non-WINDLL)
             handler()
             dos_to_unix_time()       (non-VMS, non-VM/CMS, non-MVS)
             check_for_newer()        (non-VMS, non-OS/2, non-VM/CMS, non-MVS)
             do_string()
             makeword()
             makelong()
             makeint64()
             fzofft()
             str2oem()                (CRYPT && NEED_STR2OEM, only)
             memset()                 (ZMEM only)
             memcpy()                 (ZMEM only)
             zstrnicmp()              (NO_STRNICMP only)
             zstat()                  (REGULUS only)
             plastchar()              (_MBCS only)
             uzmbclen()               (_MBCS && NEED_UZMBCLEN, only)
             uzmbschr()               (_MBCS && NEED_UZMBSCHR, only)
             uzmbsrchr()              (_MBCS && NEED_UZMBSRCHR, only)
             fLoadFarString()         (SMALL_MEM only)
             fLoadFarStringSmall()    (SMALL_MEM only)
             fLoadFarStringSmall2()   (SMALL_MEM only)
             zfstrcpy()               (SMALL_MEM only)
             zfstrcmp()               (SMALL_MEM && !(SFX || FUNZIP) only)

  ---------------------------------------------------------------------------*/


#define __FILEIO_C      /* identifies this source module */
#define UNZIP_INTERNAL
#include "unzip.h"
#include "crc32.h"
#include "crypt.h"
#include "ttyio.h"

/* setup of codepage conversion for decryption passwords */
#    define IZ_ISO2OEM_ARRAY            /* pull in iso2oem[] table */
#include "ebcdic.h"   /* definition/initialization of ebcdic[] */

/*
   2005-09-16 SMS.
   On VMS, when output is redirected to a file, as in a command like
   "PIPE UNZIP -v > X.OUT", the output file is created with VFC record
   format, and multiple calls to write() or fwrite() will produce multiple
   records, even when there's no newline terminator in the buffer.
   The result is unsightly output with spurious newlines.  Using fprintf()
   instead of write() here, and disabling a fflush(stdout) in UzpMessagePrnt()
   below, together seem to solve the problem.

   According to the C RTL manual, "The write and decc$record_write
   functions always generate at least one record."  Also, "[T]he fwrite
   function always generates at least <number_items> records."  So,
   "fwrite(buf, len, 1, strm)" is munsigned char better ("1" record) than
   "fwrite(buf, 1, len, strm)" ("len" (1-character) records, _really_
   ugly), but neither is better than write().  Similarly, "The fflush
   function always generates a record if there is unwritten data in the
   buffer."  Apparently fprintf() buffers the stuff somewhere, and puts
   out a record (only) when it sees a newline.
*/

static int disk_error OF((__GPRO));


/****************************/
/* Strings used in fileio.c */
/****************************/

static const char CannotOpenZipfile[] =
  "error:  cannot open zipfile [ %s ]\n        %s\n";

static const char CannotCreateFile[] =
  "error:  cannot create %s\n        %s\n";

static const char ReadError[] = "error:  zipfile read error\n";
static const char FilenameTooLongTrunc[] =
  "warning:  filename too long--truncating.\n";

static const char ExtraFieldTooLong[] =
  "warning:  extra field too long (%d).  Ignoring...\n";

   static const char DiskFullQuery[] =
     "%s:  write error (disk full?).  Continue? (y/n/^C) ";
   static const char ZipfileCorrupt[] =
     "error:  zipfile probably corrupt (%s)\n";
   static const char MorePrompt[] = "--More--(%lu)";
   static const char QuitPrompt[] =
     "--- Press `Q' to quit, or any other key to continue ---";
   static const char HidePrompt[] = /* "\r                       \r"; */
     "\r                                                         \r";
     static const char PasswPrompt[] = "[%s] %s password: ";
     static const char PasswPrompt2[] = "Enter password: ";
     static const char PasswRetry[] = "password incorrect--reenter: ";





/******************************/
/* Function open_input_file() */
/******************************/

int open_input_file(__G)    /* return 1 if open failed */
    __GDEF
{
    /*
     *  open the zipfile for reading and in BINARY mode to prevent cr/lf
     *  translation, which would corrupt the bitstreams
     */

    G.zipfd = RdosOpenFile(G.zipfn, 0);

    if (!G.zipfd)
    {
        Info(slide, 0x401, ((char *)slide, CannotOpenZipfile,
          G.zipfn, strerror(errno)));
        return 1;
    }
    return 0;

} /* end function open_input_file() */



/***************************/
/* Function open_outfile() */
/***************************/

int open_outfile(__G)           /* return 1 if fail */
    __GDEF
{
    Trace((stderr, "open_outfile:  doing fopen(%s) for writing\n",
      FnFilter1(G.filename)));
    {
        G.outfile = RdosCreateFile(G.filename, 0);
    }
    if (!G.outfile) {
        Info(slide, 0x401, ((char *)slide, CannotCreateFile,
          FnFilter1(G.filename), strerror(errno)));
        return 1;
    }
    Trace((stderr, "open_outfile:  fopen(%s) for writing succeeded\n",
      FnFilter1(G.filename)));

    return 0;

} /* end function open_outfile() */




/*
 * These functions allow NEXTBYTE to function without needing two bounds
 * checks.  Call defer_leftover_input() if you ever have filled G.inbuf
 * by some means other than readbyte(), and you then want to start using
 * NEXTBYTE.  When going back to processing bytes without NEXTBYTE, call
 * undefer_input().  For example, extract_or_test_member brackets its
 * central section that does the decompression with these two functions.
 * If you need to check the number of bytes remaining in the current
 * file while using NEXTBYTE, check (G.csize + G.incnt), not G.csize.
 */

/****************************/
/* function undefer_input() */
/****************************/

void undefer_input(__G)
    __GDEF
{
    if (G.incnt > 0)
        G.csize += G.incnt;
    if (G.incnt_leftover > 0) {
        /* We know that "(G.csize < MAXINT)" so we can cast G.csize to int:
         * This condition was checked when G.incnt_leftover was set > 0 in
         * defer_leftover_input(), and it is NOT allowed to tounsigned char G.csize
         * before calling undefer_input() when (G.incnt_leftover > 0)
         * (single exception: see read_byte()'s  "G.csize <= 0" handling) !!
         */
        G.incnt = G.incnt_leftover + (int)G.csize;
        G.inptr = G.inptr_leftover - (int)G.csize;
        G.incnt_leftover = 0;
    } else if (G.incnt < 0)
        G.incnt = 0;
} /* end function undefer_input() */





/***********************************/
/* function defer_leftover_input() */
/***********************************/

void defer_leftover_input(__G)
    __GDEF
{
    if ((zoff_t)G.incnt > G.csize) {
        /* (G.csize < MAXINT), we can safely cast it to int !! */
        if (G.csize < 0L)
            G.csize = 0L;
        G.inptr_leftover = G.inptr + (int)G.csize;
        G.incnt_leftover = G.incnt - (int)G.csize;
        G.incnt = (int)G.csize;
    } else
        G.incnt_leftover = 0;
    G.csize -= G.incnt;
} /* end function defer_leftover_input() */





/**********************/
/* Function readbuf() */
/**********************/

unsigned readbuf(char *buf, register unsigned size)   /* return number of bytes read into buf */
{
    register unsigned count;
    unsigned n;

    n = size;
    while (size) {
        if (G.incnt <= 0) {
            if ((G.incnt = RdosReadFile(G.zipfd, (char *)G.inbuf, INBUFSIZ)) == 0)
                return (n-size);
            else if (G.incnt < 0) {
                /* another hack, but no real harm copying same thing twice */
                (*G.message)((void *)&G,
                  (unsigned char *)ReadError,  /* CANNOT use slide */
                  (unsigned long)strlen(ReadError), 0x401);
                return 0;  /* discarding some data; better than lock-up */
            }
            /* buffer ALWAYS starts on a block boundary:  */
            G.cur_zipfile_bufstart += INBUFSIZ;
            G.inptr = G.inbuf;
        }
        count = MIN(size, (unsigned)G.incnt);
        memcpy(buf, G.inptr, count);
        buf += count;
        G.inptr += count;
        G.incnt -= count;
        size -= count;
    }
    return n;

} /* end function readbuf() */





/***********************/
/* Function readbyte() */
/***********************/

int readbyte(__G)   /* refill inbuf and return a byte if available, else EOF */
    __GDEF
{
    if (G.mem_mode)
        return EOF;
    if (G.csize <= 0) {
        G.csize--;             /* for tests done after exploding */
        G.incnt = 0;
        return EOF;
    }
    if (G.incnt <= 0) {
        if ((G.incnt = RdosReadFile(G.zipfd, (char *)G.inbuf, INBUFSIZ)) == 0) {
            return EOF;
        } else if (G.incnt < 0) {  /* "fail" (abort, retry, ...) returns this */
            /* another hack, but no real harm copying same thing twice */
            (*G.message)((void *)&G,
              (unsigned char *)ReadError,
              (unsigned long)strlen(ReadError), 0x401);
            echon();
            DESTROYGLOBALS();
            exit(PK_BADERR);    /* totally bailing; better than lock-up */
        }
        G.cur_zipfile_bufstart += INBUFSIZ; /* always starts on block bndry */
        G.inptr = G.inbuf;
        defer_leftover_input(__G);           /* decrements G.csize */
    }

    if (G.pInfo->encrypted) {
        unsigned char *p;
        int n;

        /* This was previously set to decrypt one byte beyond G.csize, when
         * incnt reached that far.  GRR said, "but it's required:  why?"  This
         * was a bug in fillinbuf() -- was it also a bug here?
         */
        for (n = G.incnt, p = G.inptr;  n--;  p++)
            zdecode(*p);
    }

    --G.incnt;
    return *G.inptr++;

} /* end function readbyte() */



/************************/
/* Function fillinbuf() */
/************************/

int fillinbuf(__G) /* like readbyte() except returns number of bytes in inbuf */
    __GDEF
{
    if (G.mem_mode ||
                  (G.incnt = RdosReadFile(G.zipfd, (char *)G.inbuf, INBUFSIZ)) <= 0)
        return 0;
    G.cur_zipfile_bufstart += INBUFSIZ;  /* always starts on a block boundary */
    G.inptr = G.inbuf;
    defer_leftover_input(__G);           /* decrements G.csize */

    if (G.pInfo->encrypted) {
        unsigned char *p;
        int n;

        for (n = G.incnt, p = G.inptr;  n--;  p++)
            zdecode(*p);
    }

    return G.incnt;

} /* end function fillinbuf() */




/************************/
/* Function seek_zipf() */
/************************/

int seek_zipf(zoff_t abs_offset)
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
    zoff_t request = abs_offset + G.extra_bytes;
    zoff_t inbuf_offset = request % INBUFSIZ;
    zoff_t bufstart = request - inbuf_offset;

    if (request < 0) {
        Info(slide, 1, ((char *)slide, SeekMsg,
             G.zipfn, ReportMsg));
        return(PK_BADERR);
    } else if (bufstart != G.cur_zipfile_bufstart) {
        Trace((stderr,
          "fpos_zip: abs_offset = %s, G.extra_bytes = %s\n",
          FmZofft(abs_offset, NULL, NULL),
          FmZofft(G.extra_bytes, NULL, NULL)));

        RdosSetFilePos(G.zipfd, bufstart);
        G.cur_zipfile_bufstart = RdosGetFilePos(G.zipfd);
        Trace((stderr,
          "       request = %s, (abs+extra) = %s, inbuf_offset = %s\n",
          FmZofft(request, NULL, NULL),
          FmZofft((abs_offset+G.extra_bytes), NULL, NULL),
          FmZofft(inbuf_offset, NULL, NULL)));
        Trace((stderr, "       bufstart = %s, cur_zipfile_bufstart = %s\n",
          FmZofft(bufstart, NULL, NULL),
          FmZofft(G.cur_zipfile_bufstart, NULL, NULL)));
        if ((G.incnt = RdosReadFile(G.zipfd, (char *)G.inbuf, INBUFSIZ)) <= 0)
            return(PK_EOF);
        G.incnt -= (int)inbuf_offset;
        G.inptr = G.inbuf + (int)inbuf_offset;
    } else {
        G.incnt += (G.inptr-G.inbuf) - (int)inbuf_offset;
        G.inptr = G.inbuf + (int)inbuf_offset;
    }
    return(PK_OK);
} /* end function seek_zipf() */




/********************/
/* Function flush() */   /* returns PK error codes: */
/********************/   /* if tflag => always 0; PK_DISK if write error */

int flush(unsigned char *rawbuf, unsigned long size, int unshrink)
{
    register unsigned char *p;
    register unsigned char *q;
    unsigned char *transbuf;
    /* static int didCRlast = FALSE;    moved to globals.h */


/*---------------------------------------------------------------------------
    Compute the CRC first; if testing or if disk is full, that's it.
  ---------------------------------------------------------------------------*/

    G.crc32val = crc32(G.crc32val, rawbuf, (extent)size);


    if (uO.tflag || size == 0L)  /* testing or nothing to write:  all done */
        return PK_OK;

    if (G.disk_full)
        return PK_DISK;         /* disk already full:  ignore rest of file */

/*---------------------------------------------------------------------------
    Write the bytes rawbuf[0..size-1] to the output device, first converting
    end-of-lines and ASCII/EBCDIC as needed.  If SMALL_MEM or MED_MEM are NOT
    defined, outbuf is assumed to be at least as large as rawbuf and is not
    necessarily checked for overflow.
  ---------------------------------------------------------------------------*/

    if (!G.pInfo->textmode) {   /* write raw binary data */
        /* GRR:  note that for standard MS-DOS compilers, size argument to
         * fwrite() can never be more than 65534, so WriteError macro will
         * have to be rewritten if size can ever be that large.  For now,
         * never more than 32K.  Also note that write() returns an int, which
         * doesn't necessarily limit size to 32767 bytes if write() is used
         * on 16-bit systems but does make it more of a pain; however, because
         * at least MSC 5.1 has a lousy implementation of fwrite() (as does
         * DEC Ultrix cc), write() is used anyway.
         */
        if (!uO.cflag && !RdosWriteFile(G.outfile, rawbuf, size))
            return disk_error(__G);
        else if (uO.cflag && (*G.message)((void *)&G, rawbuf, size, 0))
            return PK_OK;
    } else {   /* textmode:  aflag is true */
        if (unshrink) {
            /* rawbuf = outbuf */
            transbuf = G.outbuf2;
        } else {
            /* rawbuf = slide */
            transbuf = G.outbuf;
        }
        if (G.newfile) {
            G.didCRlast = FALSE;         /* no previous buffers written */
            G.newfile = FALSE;
        }


    /*-----------------------------------------------------------------------
        Algorithm:  CR/LF => native; lone CR => native; lone LF => native.
        This routine is only for non-raw-VMS, non-raw-VM/CMS files (i.e.,
        stream-oriented files, not record-oriented).
      -----------------------------------------------------------------------*/

        /* else not VMS text */ {
            p = rawbuf;
            if (*p == LF && G.didCRlast)
                ++p;
            G.didCRlast = FALSE;
            for (q = transbuf;  (extent)(p-rawbuf) < (extent)size;  ++p) {
                if (*p == CR) {           /* lone CR or CR/LF: treat as EOL  */
                    PutNativeEOL
                    if ((extent)(p-rawbuf) == (extent)size-1)
                        /* last char in buffer */
                        G.didCRlast = TRUE;
                    else if (p[1] == LF)  /* get rid of accompanying LF */
                        ++p;
                } else if (*p == LF)      /* lone LF */
                    PutNativeEOL
                else
                if (*p != CTRLZ)          /* lose all ^Z's */
                    *q++ = native(*p);

            }
        }

    /*-----------------------------------------------------------------------
        Done translating:  write whatever we've got to file (or screen).
      -----------------------------------------------------------------------*/

        Trace((stderr, "p - rawbuf = %u   q-transbuf = %u   size = %lu\n",
          (unsigned)(p-rawbuf), (unsigned)(q-transbuf), size));
        if (q > transbuf) {
            if (!uO.cflag && !RdosWriteFile(G.outfile, transbuf, (extent)(q-transbuf)))
                return disk_error(__G);
            else if (uO.cflag && (*G.message)((void *)&G, transbuf,
                (unsigned long)(q-transbuf), 0))
                return PK_OK;
        }
    }

    return PK_OK;

} /* end function flush() [resp. partflush() for 16-bit Deflate64 support] */




/*************************/
/* Function disk_error() */
/*************************/

static int disk_error(__G)
    __GDEF
{
    /* OK to use slide[] here because this file is finished regardless */
    Info(slide, 0x4a1, ((char *)slide, DiskFullQuery,
      FnFilter1(G.filename)));

    fgets(G.answerbuf, sizeof(G.answerbuf), stdin);
    if (*G.answerbuf == 'y')   /* stop writing to this file */
        G.disk_full = 1;       /*  (outfile bad?), but new OK */
    else
        G.disk_full = 2;       /* no:  exit program */

    return PK_DISK;

} /* end function disk_error() */




/*****************************/
/* Functiln WriteScreen */
/*****************************/

void WriteScreen(char *buf, int size)
{
    int i;

    for (i = 0; i < size; i++)
    {
        if (buf[i] == 0xA)
        {
            RdosWriteChar(0xD);
            RdosWriteChar(0xA);
        }
        else
            RdosWriteChar(buf[i]);
    }
}


/*****************************/
/* Function UzpMessagePrnt() */
/*****************************/

int  UzpMessagePrnt(void *pG, unsigned char *buf, unsigned long size, int flag)
{
    /* IMPORTANT NOTE:
     *    The name of the first parameter of UzpMessagePrnt(), which passes
     *    the "Uz_Globs" address, >>> MUST <<< be identical to the string
     *    expansion of the __G__ macro in the REENTRANT case (see globals.h).
     *    This name identity is mandatory for the LoadFarString() macro
     *    (in the SMALL_MEM case) !!!
     */
    int error;
    unsigned char *q=buf, *endbuf=buf+(unsigned)size;
    unsigned char *p=buf;
    int islinefeed = FALSE;


/*---------------------------------------------------------------------------
    These tests are here to allow fine-tuning of UnZip's output messages,
    but none of them will do anything without setting the appropriate bit
    in the flag argument of every Info() statement which is to be turned
    *off*.  That is, all messages are currently turned on for all ports.
    To turn off *all* messages, use the UzpMessageNull() function instead
    of this one.
  ---------------------------------------------------------------------------*/


    if (MSG_TNEWLN(flag)) {   /* again assumes writable buffer:  fragile... */
        if ((!size && !((Uz_Globs *)pG)->sol) ||
            (size && (endbuf[-1] != '\n')))
        {
            *endbuf++ = '\r';
            *endbuf++ = '\n';
            ++size;
        }
    }

    /* room for --More-- and one line of overlap: */
    SCREENSIZE(&((Uz_Globs *)pG)->height, &((Uz_Globs *)pG)->width);
    ((Uz_Globs *)pG)->height -= 2;

    if (MSG_LNEWLN(flag) && !((Uz_Globs *)pG)->sol) {
        /* not at start of line:  want newline */
            RdosWriteChar(0xd);
            RdosWriteChar(0xa);
            if (((Uz_Globs *)pG)->M_flag)
            {
                ((Uz_Globs *)pG)->chars = 0;
                ++((Uz_Globs *)pG)->numlines;
                ++((Uz_Globs *)pG)->lines;
                if (((Uz_Globs *)pG)->lines >= ((Uz_Globs *)pG)->height)
                    (*((Uz_Globs *)pG)->mpause)((void *)pG,
                      MorePrompt, 1);
            }
            if (MSG_STDERR(flag) && ((Uz_Globs *)pG)->UzO.tflag &&
                !isatty(1) && isatty(2))
            {
                /* error output from testing redirected:  also send to stderr */
                putc('\n', stderr);
                fflush(stderr);
            }
        ((Uz_Globs *)pG)->sol = TRUE;
    }

    /* put zipfile name, filename and/or error/warning keywords here */

    if (((Uz_Globs *)pG)->M_flag)
    {
        while (p < endbuf) {
            if (*p == '\n') {
                islinefeed = TRUE;
            } else if (SCREENLWRAP) {
                if (*p == '\r') {
                    ((Uz_Globs *)pG)->chars = 0;
                } else {
                    if (*p == '\t')
                        ((Uz_Globs *)pG)->chars +=
                            (TABSIZE - (((Uz_Globs *)pG)->chars % TABSIZE));
                    else
                        ++((Uz_Globs *)pG)->chars;

                    if (((Uz_Globs *)pG)->chars >= ((Uz_Globs *)pG)->width)
                        islinefeed = TRUE;
                }
            }
            if (islinefeed) {
                islinefeed = FALSE;
                ((Uz_Globs *)pG)->chars = 0;
                ++((Uz_Globs *)pG)->numlines;
                ++((Uz_Globs *)pG)->lines;
                if (((Uz_Globs *)pG)->lines >= ((Uz_Globs *)pG)->height)
                {
                    WriteScreen((char *)q, p-q+1);
                    ((Uz_Globs *)pG)->sol = TRUE;
                    q = p + 1;
                    (*((Uz_Globs *)pG)->mpause)((void *)pG,
                      MorePrompt, 1);
                }
            }
            INCSTR(p);
        } /* end while */
        size = (unsigned long)(p - q);   /* remaining text */
    }

    if (size) {
            WriteScreen((char *)q, size);
        ((Uz_Globs *)pG)->sol = (endbuf[-1] == '\n');
    }
    return 0;

} /* end function UzpMessagePrnt() */






/***********************/
/* Function UzpInput() */   /* GRR:  this is a placeholder for now */
/***********************/

int  UzpInput(void *pG, unsigned char *buf, int *size, int flag)
{
    /* tell picky compilers to shut up about "unused variable" warnings */
    pG = pG; buf = buf; flag = flag;

    *size = 0;
    return 0;

} /* end function UzpInput() */




/***************************/
/* Function UzpMorePause() */
/***************************/

void  UzpMorePause(void *pG, const char *prompt, int flag)
{
    unsigned char c;

/*---------------------------------------------------------------------------
    Print a prompt and wait for the user to press a key, then erase prompt
    if possible.
  ---------------------------------------------------------------------------*/

    if (!((Uz_Globs *)pG)->sol)
        fprintf(stderr, "\n");
    /* numlines may or may not be used: */
    fprintf(stderr, prompt, ((Uz_Globs *)pG)->numlines);
    fflush(stderr);
    if (flag & 1) {
        do {
            c = (unsigned char)FGETCH(0);
        } while (
                 c != '\r' && c != '\n' && c != ' ' && c != 'q' && c != 'Q');
    } else
        c = (unsigned char)FGETCH(0);

    /* newline was not echoed, so cover up prompt line */
    fprintf(stderr, HidePrompt);
    fflush(stderr);

    if (
        (ToLower(c) == 'q')) {
        DESTROYGLOBALS();
        exit(PK_COOL);
    }

    ((Uz_Globs *)pG)->sol = TRUE;

    /* space for another screen, enter for another line. */
    if ((flag & 1) && c == ' ')
        ((Uz_Globs *)pG)->lines = 0;

} /* end function UzpMorePause() */


/**************************/
/* Function UzpPassword() */
/**************************/

int  UzpPassword (void *pG, int *rcnt, char *pwbuf, int size, const char *zfn, const char *efn)
{
    int r = IZ_PW_ENTERED;
    char *m;
    char *prompt;

    if (*rcnt == 0) {           /* First call for current entry */
        *rcnt = 2;
        if ((prompt = (char *)malloc(2*FILNAMSIZ + 15)) != (char *)NULL) {
            sprintf(prompt, PasswPrompt,
                    FnFilter1(zfn), FnFilter2(efn));
            m = prompt;
        } else
            m = (char *)PasswPrompt;
    } else {                    /* Retry call, previous password was wrong */
        (*rcnt)--;
        prompt = NULL;
        m = (char *)PasswRetry;
    }

    m = getp(__G__ m, pwbuf, size);
    if (prompt != (char *)NULL) {
        free(prompt);
    }
    if (m == (char *)NULL) {
        r = IZ_PW_ERROR;
    }
    else if (*pwbuf == '\0') {
        r = IZ_PW_CANCELALL;
    }
    return r;


} /* end function UzpPassword() */





/**********************/
/* Function handler() */
/**********************/

void handler(int signal)   /* upon interrupt, turn on echo and exit cleanly */
{
    GETGLOBALS();

    (*G.message)((void *)&G, slide, 0L, 0x41); /*  start of line (to stderr; */

    echon();

    /* probably ctrl-C */
    DESTROYGLOBALS();
    exit(IZ_CTRLC);       /* was EXIT(0), then EXIT(PK_ERR) */
}


/* also used in amiga/filedate.c and win32/win32.c */
const unsigned short ydays[] =
    { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365 };

/*******************************/
/* Function dos_to_unix_time() */ /* used for freshening/updating/timestamps */
/*******************************/

time_t dos_to_unix_time(unsigned long dosdatetime)
{
    time_t m_time;
    int yr, mo, dy, hh, mm, ss;
#   define YRBASE  1970
    int leap;
    unsigned days;
    struct tm *tm;

    /* dissect date */
    yr = ((int)(dosdatetime >> 25) & 0x7f) + (1980 - YRBASE);
    mo = ((int)(dosdatetime >> 21) & 0x0f) - 1;
    dy = ((int)(dosdatetime >> 16) & 0x1f) - 1;

    /* dissect time */
    hh = (int)((unsigned)dosdatetime >> 11) & 0x1f;
    mm = (int)((unsigned)dosdatetime >> 5) & 0x3f;
    ss = (int)((unsigned)dosdatetime & 0x1f) * 2;


/*---------------------------------------------------------------------------
    Calculate the number of seconds since the epoch, usually 1 January 1970.
  ---------------------------------------------------------------------------*/

    /* leap = # of leap yrs from YRBASE up to but not including current year */
    leap = ((yr + YRBASE - 1) / 4);   /* leap year base factor */

    /* calculate days from BASE to this year and add expired days this year */
    days = (yr * 365) + (leap - 492) + ydays[mo];

    /* if year is a leap year and month is after February, add another day */
    if ((mo > 1) && ((yr+YRBASE)%4 == 0) && ((yr+YRBASE) != 2100))
        ++days;                 /* OK through 2199 */

    /* convert date & time to seconds relative to 00:00:00, 01/01/YRBASE */
    m_time = (time_t)((unsigned long)(days + dy) * 86400L +
                      (unsigned long)hh * 3600L +
                      (unsigned long)(mm * 60 + ss));
      /* - 1;   MS-DOS times always rounded up to nearest even second */
    TTrace((stderr, "dos_to_unix_time:\n"));
    TTrace((stderr, "  m_time before timezone = %lu\n", (unsigned long)m_time));

/*---------------------------------------------------------------------------
    Adjust for local standard timezone offset.
  ---------------------------------------------------------------------------*/

    /* tzset was already called at start of process_zipfiles() */
    /* tzset(); */              /* set `timezone' variable */
    m_time += timezone;         /* seconds WEST of GMT:  add */
    TTrace((stderr, "  m_time after timezone =  %lu\n", (unsigned long)m_time));

/*---------------------------------------------------------------------------
    Adjust for local daylight savings (summer) time.
  ---------------------------------------------------------------------------*/

    if ( (dosdatetime >= DOSTIME_2038_01_18) &&
         (m_time < (time_t)0x70000000L) )
        m_time = U_TIME_T_MAX;  /* saturate in case of (unsigned) overflow */
    if (m_time < (time_t)0L)    /* a converted DOS time cannot be negative */
        m_time = S_TIME_T_MAX;  /*  -> saturate at max signed time_t value */
    if (((tm = localtime((time_t *)&m_time)) != NULL) && tm->tm_isdst)
        m_time -= 60L * 60L;    /* adjust for daylight savings time */
    TTrace((stderr, "  m_time after DST =       %lu\n", (unsigned long)m_time));

    if ( (dosdatetime >= DOSTIME_2038_01_18) &&
         (m_time < (time_t)0x70000000L) )
        m_time = U_TIME_T_MAX;  /* saturate in case of (unsigned) overflow */
    if (m_time < (time_t)0L)    /* a converted DOS time cannot be negative */
        m_time = S_TIME_T_MAX;  /*  -> saturate at max signed time_t value */

    return m_time;

} /* end function dos_to_unix_time() */


/******************************/
/* Function check_for_newer() */  /* used for overwriting/freshening/updating */
/******************************/

int check_for_newer(char *filename)  /* return 1 if existing file is newer */
{
    time_t existing, archive;

    Trace((stderr, "check_for_newer:  doing stat(%s)\n", FnFilter1(filename)));
    if (SSTAT(filename, &G.statbuf)) {
        Trace((stderr,
          "check_for_newer:  stat(%s) returns %d:  file does not exist\n",
          FnFilter1(filename), SSTAT(filename, &G.statbuf)));
        return DOES_NOT_EXIST;
    }
    Trace((stderr, "check_for_newer:  stat(%s) returns 0:  file exists\n",
      FnFilter1(filename)));


    /* round up existing filetime to nearest 2 seconds for comparison,
     * but saturate in case of arithmetic overflow
     */
    existing = ((G.statbuf.st_mtime & 1) &&
                (G.statbuf.st_mtime + 1 > G.statbuf.st_mtime)) ?
               G.statbuf.st_mtime + 1 : G.statbuf.st_mtime;
    archive  = dos_to_unix_time(G.lrec.last_mod_dos_datetime);

    TTrace((stderr, "check_for_newer:  existing %lu, archive %lu, e-a %ld\n",
      (unsigned long)existing, (unsigned long)archive, (long)(existing-archive)));

    return (existing >= archive);

} /* end function check_for_newer() */


/************************/
/* Function do_string() */
/************************/

int do_string(unsigned int length, int option)   /* return PK-type error code */
{
    unsigned comment_bytes_left;
    unsigned int block_len;
    int error=PK_OK;


/*---------------------------------------------------------------------------
    This function processes arbitrary-length (well, usually) strings.  Four
    major options are allowed:  SKIP, wherein the string is skipped (pretty
    logical, eh?); DISPLAY, wherein the string is printed to standard output
    after undergoing any necessary or unnecessary character conversions;
    DS_FN, wherein the string is put into the filename[] array after under-
    going appropriate conversions (including case-conversion, if that is
    indicated: see the global variable pInfo->lcflag); and EXTRA_FIELD,
    wherein the `string' is assumed to be an extra field and is copied to
    the (freshly malloced) buffer G.extra_field.  The third option should
    be OK since filename is dimensioned at 1025, but we check anyway.

    The string, by the way, is assumed to start at the current file-pointer
    position; its length is given by 'length'.  So start off by checking the
    length of the string:  if zero, we're already done.
  ---------------------------------------------------------------------------*/

    if (!length)
        return PK_COOL;

    switch (option) {

    /*
     * First normal case:  print string on standard output.  First set loop
     * variables, then loop through the comment in chunks of OUTBUFSIZ bytes,
     * converting formats and printing as we go.  The second half of the
     * loop conditional was added because the file might be truncated, in
     * which case comment_bytes_left will remain at some non-zero value for
     * all time.  outbuf and slide are used as scratch buffers because they
     * are available (we should be either before or in between any file pro-
     * cessing).
     */

    case DISPLAY:
    case DISPL_8:
        comment_bytes_left = length;
        block_len = OUTBUFSIZ;       /* for the while statement, first time */
        while (comment_bytes_left > 0 && block_len > 0) {
            register unsigned char *p = G.outbuf;
            register unsigned char *q = G.outbuf;

            if ((block_len = readbuf(__G__ (char *)G.outbuf,
                   MIN((unsigned)OUTBUFSIZ, comment_bytes_left))) == 0)
                return PK_EOF;
            comment_bytes_left -= block_len;

            /* this is why we allocated an extra byte for outbuf:  terminate
             *  with zero (ASCIIZ) */
            G.outbuf[block_len] = '\0';

            /* remove all ASCII carriage returns from comment before printing
             * (since used before A_TO_N(), check for CR instead of '\r')
             */
            while (*p) {
                while (*p == CR)
                    ++p;
                *q++ = *p++;
            }
            /* could check whether (p - outbuf) == block_len here */
            *q = '\0';

            if (option == DISPL_8) {
                /* translate the text coded in the entry's host-dependent
                   "extended ASCII" charset into the compiler's (system's)
                   internal text code page */
                Ext_ASCII_TO_Native((char *)G.outbuf, G.pInfo->hostnum,
                                    G.pInfo->hostver, G.pInfo->HasUxAtt,
                                    FALSE);
            } else {
                A_TO_N(G.outbuf);   /* translate string to native */
            }

            (*G.message)((void *)&G, G.outbuf, (unsigned long)(q-G.outbuf), 0);
        }
        /* add '\n' if not at start of line */
        (*G.message)((void *)&G, slide, 0L, 0x40);
        break;

    /*
     * Second case:  read string into filename[] array.  The filename should
     * never ever be longer than FILNAMSIZ-1 (1024), but for now we'll check,
     * just to be sure.
     */

    case DS_FN:
    case DS_FN_L:
        if (length >= FILNAMSIZ) {
            Info(slide, 0x401, ((char *)slide,
              FilenameTooLongTrunc));
            error = PK_WARN;
            /* remember excess length in block_len */
            block_len = length - (FILNAMSIZ - 1);
            length = FILNAMSIZ - 1;
        } else
            /* no excess size */
            block_len = 0;
        if (readbuf(__G__ G.filename, length) == 0)
            return PK_EOF;
        G.filename[length] = '\0';      /* terminate w/zero:  ASCIIZ */

        /* translate the Zip entry filename coded in host-dependent "extended
           ASCII" into the compiler's (system's) internal text code page */
        Ext_ASCII_TO_Native(G.filename, G.pInfo->hostnum, G.pInfo->hostver,
                            G.pInfo->HasUxAtt, (option == DS_FN_L));

        if (G.pInfo->lcflag)      /* replace with lowercase filename */
            STRLOWER(G.filename, G.filename);

        if (G.pInfo->vollabel && length > 8 && G.filename[8] == '.') {
            char *p = G.filename+8;
            while (*p++)
                p[-1] = *p;  /* disk label, and 8th char is dot:  remove dot */
        }

        if (!block_len)         /* no overflow, we're done here */
            break;

        /*
         * We truncated the filename, so print what's left and then fall
         * through to the SKIP routine.
         */
        Info(slide, 0x401, ((char *)slide, "[ %s ]\n", FnFilter1(G.filename)));
        length = block_len;     /* SKIP the excess bytes... */
        /*  FALL THROUGH...  */

    /*
     * Third case:  skip string, adjusting readbuf's internal variables
     * as necessary (and possibly skipping to and reading a new block of
     * data).
     */

    case SKIP:
        /* cur_zipfile_bufstart already takes account of extra_bytes, so don't
         * correct for it twice: */
        seek_zipf(__G__ G.cur_zipfile_bufstart - G.extra_bytes +
                  (G.inptr-G.inbuf) + length);
        break;

    /*
     * Fourth case:  assume we're at the start of an "extra field"; malloc
     * storage for it and read data into the allocated space.
     */

    case EXTRA_FIELD:
        if (G.extra_field != (unsigned char *)NULL)
            free(G.extra_field);
        if ((G.extra_field = (unsigned char *)malloc(length)) == (unsigned char *)NULL) {
            Info(slide, 0x401, ((char *)slide, ExtraFieldTooLong,
              length));
            /* cur_zipfile_bufstart already takes account of extra_bytes,
             * so don't correct for it twice: */
            seek_zipf(__G__ G.cur_zipfile_bufstart - G.extra_bytes +
                      (G.inptr-G.inbuf) + length);
        } else {
            if (readbuf(__G__ (char *)G.extra_field, length) == 0)
                return PK_EOF;
            /* Looks like here is where extra fields are read */
            getZip64Data(__G__ G.extra_field, length);
        }
        break;


    } /* end switch (option) */

    return error;

} /* end function do_string() */





/***********************/
/* Function makeword() */
/***********************/

unsigned short makeword(const unsigned char *b)
{
    /*
     * Convert Intel style 'short' integer to non-Intel non-16-bit
     * host format.  This routine also takes care of byte-ordering.
     */
    return (unsigned short)((b[1] << 8) | b[0]);
}





/***********************/
/* Function makelong() */
/***********************/

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





/************************/
/* Function makeint64() */
/************************/

zusz_t makeint64(const unsigned char *sig)
{
    if ((sig[7] | sig[6] | sig[5] | sig[4]) != 0)
        return (zusz_t)0xffffffffL;
    else
        return (zusz_t)((((unsigned long)sig[3]) << 24)
                      + (((unsigned long)sig[2]) << 16)
                      + (((unsigned)sig[1]) << 8)
                      + (sig[0]));

}





/*********************/
/* Function fzofft() */
/*********************/

/* Format a zoff_t value in a cylindrical buffer set. */
char *fzofft(zoff_t val, const char *pre, const char *post)
{
    /* Storage cylinder. (now in globals.h) */
    /*static char fzofft_buf[FZOFFT_NUM][FZOFFT_LEN];*/
    /*static int fzofft_index = 0;*/

    /* Temporary format string storage. */
    char fmt[16];

    /* Assemble the format string. */
    fmt[0] = '%';
    fmt[1] = '\0';             /* Start after initial "%". */
    if (pre == FZOFFT_HEX_WID)  /* Special hex width. */
    {
        strcat(fmt, FZOFFT_HEX_WID_VALUE);
    }
    else if (pre == FZOFFT_HEX_DOT_WID) /* Special hex ".width". */
    {
        strcat(fmt, ".");
        strcat(fmt, FZOFFT_HEX_WID_VALUE);
    }
    else if (pre != NULL)       /* Caller's prefix (width). */
    {
        strcat(fmt, pre);
    }

    strcat(fmt, FZOFFT_FMT);   /* Long or long-long or whatever. */

    if (post == NULL)
        strcat(fmt, "d");      /* Default radix = decimal. */
    else
        strcat(fmt, post);     /* Caller's radix. */

    /* Advance the cylinder. */
    G.fzofft_index = (G.fzofft_index + 1) % FZOFFT_NUM;

    /* Write into the current chamber. */
    sprintf(G.fzofft_buf[G.fzofft_index], fmt, val);

    /* Return a pointer to this chamber. */
    return G.fzofft_buf[G.fzofft_index];
}



/**********************/
/* Function str2oem() */
/**********************/

char *str2oem(char *dst, register const char *src)
{
    register unsigned char c;
    register char *dstp = dst;

    do {
        c = (unsigned char)foreign(*src++);
        *dstp++ = (char)ASCII2OEM(c);
    } while (c != '\0');

    return dst;
}

