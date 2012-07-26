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

void AsciiToNative(char *str);

/****************************/
/* Strings used in fileio.c */
/****************************/

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
        if ((prompt = (char *)malloc(2*FILE_NAME_SIZE + 15)) != (char *)NULL) {
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
    archive  = dos_to_unix_time(UnzipClass.FCurrFile.last_mod_dos_datetime);

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


    /*
     * Second case:  read string into filename[] array.  The filename should
     * never ever be longer than FILNAMSIZ-1 (1024), but for now we'll check,
     * just to be sure.
     */

    case DS_FN:
    case DS_FN_L:
        if (length >= FILE_NAME_SIZE) {
            Info(0x401,
              FilenameTooLongTrunc);
            error = PK_WARN;
            /* remember excess length in block_len */
            block_len = length - (FILE_NAME_SIZE - 1);
            length = FILE_NAME_SIZE - 1;
        } else
            /* no excess size */
            block_len = 0;
        if (UnzipClass.ReadBuf(UnzipClass.FCurrFileName, length) == 0)
            return PK_EOF;
        UnzipClass.FCurrFileName[length] = '\0';      /* terminate w/zero:  ASCIIZ */

        /* translate the Zip entry filename coded in host-dependent "extended
           ASCII" into the compiler's (system's) internal text code page */
        AsciiToNative(UnzipClass.FCurrFileName);

        if (G.pInfo->lcflag)      /* replace with lowercase filename */
            strtolower(UnzipClass.FCurrFileName, UnzipClass.FCurrFileName);

        if (G.pInfo->vollabel && length > 8 && UnzipClass.FCurrFileName[8] == '.') {
            char *p = UnzipClass.FCurrFileName+8;
            while (*p++)
                p[-1] = *p;  /* disk label, and 8th char is dot:  remove dot */
        }

        if (!block_len)         /* no overflow, we're done here */
            break;

        /*
         * We truncated the filename, so print what's left and then fall
         * through to the SKIP routine.
         */
        Info(0x401, "[ %s ]\n", FnFilter1(UnzipClass.FCurrFileName));
        length = block_len;     /* SKIP the excess bytes... */
        /*  FALL THROUGH...  */

    /*
     * Third case:  skip string, adjusting readbuf's internal variables
     * as necessary (and possibly skipping to and reading a new block of
     * data).
     */

    /*
     * Fourth case:  assume we're at the start of an "extra field"; malloc
     * storage for it and read data into the allocated space.
     */

    case EXTRA_FIELD:
        if (UnzipClass.FExtraField != 0)
            delete UnzipClass.FExtraField;
        UnzipClass.FExtraField = new char[length];
        if (UnzipClass.FExtraField == 0) {
            Info(0x401, ExtraFieldTooLong,
              length);
            /* cur_zipfile_bufstart already takes account of extra_bytes,
             * so don't correct for it twice: */
            UnzipClass.Seek(UnzipClass.FBufStart - UnzipClass.FExtraBytes +
                      (UnzipClass.FInPtr-UnzipClass.FInBuf) + length);
        } else {
            if (UnzipClass.ReadBuf(UnzipClass.FExtraField, length) == 0)
                return PK_EOF;
            /* Looks like here is where extra fields are read */
            getZip64Data((unsigned char *)UnzipClass.FExtraField, length);
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

