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
#include "oldunzip.h"

const unsigned char oem2iso_850[] = {
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

const unsigned char *oem2iso = oem2iso_850;  /* backward compatibility default */

void Ext_ASCII_TO_Native(char *string, int hostnum, int hostver, int isuxatt, int islochdr)
{
    if (((hostnum) == FS_FAT_ &&
         !(((islochdr) || (isuxatt)) &&
           ((hostver) == 25 || (hostver) == 26 || (hostver) == 40))) ||
        (hostnum) == FS_HPFS_ ||
        ((hostnum) == FS_NTFS_ && (hostver) == 50)) {
       if (oem2iso) {register unsigned char *p;
           for (p=(unsigned char *)(string); *p; p++)
             *p = (*p & 0x80) ? oem2iso[*p & 0x7f] : *p;
       }
    }
}


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

static int disk_error OF(());


/****************************/
/* Strings used in fileio.c */
/****************************/

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



/***************************/
/* Function open_outfile() */
/***************************/

int open_outfile()           /* return 1 if fail */
{
    Trace("open_outfile:  doing fopen(%s) for writing\n",
      FnFilter1(G.filename));
    {
        G.outfile = RdosCreateFile(G.filename, 0);
    }
    if (!G.outfile) {
        Info(0x401, CannotCreateFile,
          FnFilter1(G.filename), strerror(errno));
        return 1;
    }
    Trace("open_outfile:  fopen(%s) for writing succeeded\n",
      FnFilter1(G.filename));

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




/************************/
/* Function seek_zipf() */
/************************/

int seek_zipf(long abs_offset)
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
    long request = abs_offset + G.extra_bytes;
    long inbuf_offset = request % INBUFSIZ;
    long bufstart = request - inbuf_offset;

    if (request < 0) {
        Info(1, SeekMsg,
             UnzipClass.FInputFileName.GetData(), ReportMsg);
        return(PK_BADERR);
    } else if (bufstart != UnzipClass.FBufStart) {
        Trace("fpos_zip: abs_offset = %s, G.extra_bytes = %s\n",
          fzofft(abs_offset, NULL, NULL),
          fzofft(G.extra_bytes, NULL, NULL));

        RdosSetFilePos(UnzipClass.FInputHandle, bufstart);
        UnzipClass.FBufStart = RdosGetFilePos(UnzipClass.FInputHandle);
        Trace("       request = %s, (abs+extra) = %s, inbuf_offset = %s\n",
          fzofft(request, NULL, NULL),
          fzofft((abs_offset+G.extra_bytes), NULL, NULL),
          fzofft(inbuf_offset, NULL, NULL));
        Trace("       bufstart = %s, cur_zipfile_bufstart = %s\n",
          fzofft(bufstart, NULL, NULL),
          fzofft(UnzipClass.FBufStart, NULL, NULL));
        if ((UnzipClass.FInCount = RdosReadFile(UnzipClass.FInputHandle, UnzipClass.FInBuf, INBUFSIZ)) <= 0)
            return(PK_EOF);
        UnzipClass.FInCount -= (int)inbuf_offset;
        UnzipClass.FInPtr = UnzipClass.FInBuf + (int)inbuf_offset;
    } else {
        UnzipClass.FInCount += (UnzipClass.FInPtr-UnzipClass.FInBuf) - (int)inbuf_offset;
        UnzipClass.FInPtr = UnzipClass.FInBuf + (int)inbuf_offset;
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
            return disk_error();
        else if (uO.cflag)
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
                    *q++ = *p;

            }
        }

    /*-----------------------------------------------------------------------
        Done translating:  write whatever we've got to file (or screen).
      -----------------------------------------------------------------------*/

        Trace("p - rawbuf = %u   q-transbuf = %u   size = %lu\n",
          (unsigned)(p-rawbuf), (unsigned)(q-transbuf), size);
        if (q > transbuf) {
            if (!uO.cflag && !RdosWriteFile(G.outfile, transbuf, (extent)(q-transbuf)))
                return disk_error();
            else if (uO.cflag)
                return PK_OK;
        }
    }

    return PK_OK;

} /* end function flush() [resp. partflush() for 16-bit Deflate64 support] */




/*************************/
/* Function disk_error() */
/*************************/

static int disk_error()
{
    /* OK to use slide[] here because this file is finished regardless */
    Info(0x4a1, DiskFullQuery,
      FnFilter1(G.filename));

    fgets(G.answerbuf, sizeof(G.answerbuf), stdin);
    if (*G.answerbuf == 'y')   /* stop writing to this file */
        G.disk_full = 1;       /*  (outfile bad?), but new OK */
    else
        G.disk_full = 2;       /* no:  exit program */

    return PK_DISK;

} /* end function disk_error() */



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

    m = getp(m, pwbuf, size);
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
    /* probably ctrl-C */
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

    Trace("check_for_newer:  doing stat(%s)\n", FnFilter1(filename));
    if (stat(filename, &G.statbuf)) {
        Trace("check_for_newer:  stat(%s) returns %d:  file does not exist\n",
          FnFilter1(filename), stat(filename, &G.statbuf));
        return DOES_NOT_EXIST;
    }
    Trace("check_for_newer:  stat(%s) returns 0:  file exists\n",
      FnFilter1(filename));


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

            if ((block_len = UnzipClass.ReadBuf((char *)G.outbuf,
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
            }

            Info(0, (char *)G.outbuf);
        }
        /* add '\n' if not at start of line */
        Info(0, "\n");
        break;

    /*
     * Second case:  read string into filename[] array.  The filename should
     * never ever be longer than FILNAMSIZ-1 (1024), but for now we'll check,
     * just to be sure.
     */

    case DS_FN:
    case DS_FN_L:
        if (length >= FILNAMSIZ) {
            Info(0x401,
              FilenameTooLongTrunc);
            error = PK_WARN;
            /* remember excess length in block_len */
            block_len = length - (FILNAMSIZ - 1);
            length = FILNAMSIZ - 1;
        } else
            /* no excess size */
            block_len = 0;
        if (UnzipClass.ReadBuf(G.filename, length) == 0)
            return PK_EOF;
        G.filename[length] = '\0';      /* terminate w/zero:  ASCIIZ */

        /* translate the Zip entry filename coded in host-dependent "extended
           ASCII" into the compiler's (system's) internal text code page */
        Ext_ASCII_TO_Native(G.filename, G.pInfo->hostnum, G.pInfo->hostver,
                            G.pInfo->HasUxAtt, (option == DS_FN_L));

        if (G.pInfo->lcflag)      /* replace with lowercase filename */
            strtolower(G.filename, G.filename);

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
        Info(0x401, "[ %s ]\n", FnFilter1(G.filename));
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
        seek_zipf(UnzipClass.FBufStart - G.extra_bytes +
                  (UnzipClass.FInPtr-UnzipClass.FInBuf) + length);
        break;

    /*
     * Fourth case:  assume we're at the start of an "extra field"; malloc
     * storage for it and read data into the allocated space.
     */

    case EXTRA_FIELD:
        if (G.extra_field != (unsigned char *)NULL)
            free(G.extra_field);
        if ((G.extra_field = (unsigned char *)malloc(length)) == (unsigned char *)NULL) {
            Info(0x401, ExtraFieldTooLong,
              length);
            /* cur_zipfile_bufstart already takes account of extra_bytes,
             * so don't correct for it twice: */
            seek_zipf(UnzipClass.FBufStart - G.extra_bytes +
                      (UnzipClass.FInPtr-UnzipClass.FInBuf) + length);
        } else {
            if (UnzipClass.ReadBuf((char *)G.extra_field, length) == 0)
                return PK_EOF;
            /* Looks like here is where extra fields are read */
            getZip64Data(G.extra_field, length);
        }
        break;


    } /* end switch (option) */

    return error;

} /* end function do_string() */







/*********************/
/* Function fzofft() */
/*********************/

/* Format a zoff_t value in a cylindrical buffer set. */
char *fzofft(long val, const char *pre, const char *post)
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

