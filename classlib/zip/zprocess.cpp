/*
  Copyright (c) 1990-2009 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2009-Jan-02 or later
  (the contents of which are also included in unzip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/*---------------------------------------------------------------------------

  process.c

  This file contains the top-level routines for processing multiple zipfiles.

  Contains:  process_zipfiles()
             free_G_buffers()
             do_seekable()
             file_size()
             rec_find()
             find_ecrec64()
             find_ecrec()
             process_zip_cmmnt()
             process_cdir_file_hdr()
             get_cdir_ent()
             process_local_file_hdr()
             getZip64Data()
             ef_scan_for_izux()
             getRISCOSexfield()

  ---------------------------------------------------------------------------*/


#define UNZIP_INTERNAL
#include "unzip.h"

static int    do_seekable        OF((__GPRO__ int lastchance));
static int    rec_find           OF((__GPRO__ zoff_t, char *, int));
static int    find_ecrec64       OF((__GPRO__ zoff_t searchlen));
static int    find_ecrec         OF((__GPRO__ zoff_t searchlen));
static int    process_zip_cmmnt  OF((__GPRO));
static int    get_cdir_ent       OF((__GPRO));


static const char Far CannotAllocateBuffers[] =
  "error:  cannot allocate unzip buffers\n";

   /* process_zipfiles() strings */
   static const char Far CannotFindWildcardMatch[] =
     "%s:  cannot find any matches for wildcard specification \"%s\".\n";
   static const char Far FilesProcessOK[] =
     "%d archive%s successfully processed.\n";
   static const char Far ArchiveWarning[] =
     "%d archive%s had warnings but no fatal errors.\n";
   static const char Far ArchiveFatalError[] =
     "%d archive%s had fatal errors.\n";
   static const char Far FileHadNoZipfileDir[] =
     "%d file%s had no zipfile directory.\n";
   static const char Far ZipfileWasDir[] = "1 \"zipfile\" was a directory.\n";
   static const char Far ManyZipfilesWereDir[] =
     "%d \"zipfiles\" were directories.\n";
   static const char Far NoZipfileFound[] = "No zipfiles found.\n";

   /* do_seekable() strings */
   static const char Far CannotFindZipfileDirMsg[] =
     "%s:  cannot find zipfile directory in %s,\n\
        %sand cannot find %s, period.\n";
   static const char Far CannotFindEitherZipfile[] =
     "%s:  cannot find either %s or %s.\n";
   extern const char Far Zipnfo[];       /* in unzip.c */
   static const char Far Unzip[] = "UnZip DLL";
   static const char Far MaybeExe[] =
     "note:  %s may be a plain executable, not an archive\n";
   static const char Far CentDirNotInZipMsg[] = "\n\
   [%s]:\n\
     Zipfile is disk %lu of a multi-disk archive, and this is not the disk on\n\
     which the central zipfile directory begins (disk %lu).\n";
   static const char Far EndCentDirBogus[] =
     "\nwarning [%s]:  end-of-central-directory record claims this\n\
  is disk %lu but that the central directory starts on disk %lu; this is a\n\
  contradiction.  Attempting to process anyway.\n";
   static const char Far MaybePakBug[] = "warning [%s]:\
  zipfile claims to be last disk of a multi-part archive;\n\
  attempting to process anyway, assuming all parts have been concatenated\n\
  together in order.  Expect \"errors\" and warnings...true multi-part support\
\n  doesn't exist yet (coming soon).\n";
   static const char Far ExtraBytesAtStart[] =
     "warning [%s]:  %s extra byte%s at beginning or within zipfile\n\
  (attempting to process anyway)\n";

   static const char Far LogInitline[] = "Archive:  %s\n";

static const char Far MissingBytes[] =
  "error [%s]:  missing %s bytes in zipfile\n\
  (attempting to process anyway)\n";
static const char Far NullCentDirOffset[] =
  "error [%s]:  NULL central directory offset\n\
  (attempting to process anyway)\n";
static const char Far ZipfileEmpty[] = "warning [%s]:  zipfile is empty\n";
static const char Far CentDirStartNotFound[] =
  "error [%s]:  start of central directory not found;\n\
  zipfile corrupt.\n%s";
static const char Far Cent64EndSigSearchErr[] =
  "fatal error: read failure while seeking for End-of-centdir-64 signature.\n\
  This zipfile is corrupt.\n";
static const char Far Cent64EndSigSearchOff[] =
  "error: End-of-centdir-64 signature not where expected (prepended bytes?)\n\
  (attempting to process anyway)\n";
   static const char Far CentDirTooLong[] =
     "error [%s]:  reported length of central directory is\n\
  %s bytes too long (Atari STZip zipfile?  J.H.Holm ZIPSPLIT 1.1\n\
  zipfile?).  Compensating...\n";
   static const char Far CentDirEndSigNotFound[] = "\
  End-of-central-directory signature not found.  Either this file is not\n\
  a zipfile, or it constitutes one disk of a multi-part archive.  In the\n\
  latter case the central directory and zipfile comment will be found on\n\
  the last disk(s) of this archive.\n";
static const char Far ZipfileCommTrunc1[] =
  "\ncaution:  zipfile comment truncated\n";
   static const char Far NoZipfileComment[] =
     "There is no zipfile comment.\n";
   static const char Far ZipfileCommentDesc[] =
     "The zipfile comment is %u bytes long and contains the following text:\n";
   static const char Far ZipfileCommBegin[] =
     "======================== zipfile comment begins\
 ==========================\n";
   static const char Far ZipfileCommEnd[] =
     "========================= zipfile comment ends\
 ===========================\n";
   static const char Far ZipfileCommTrunc2[] =
     "\n  The zipfile comment is truncated.\n";



/*******************************/
/* Function process_zipfiles() */
/*******************************/

int process_zipfiles(__G)    /* return PK-type error code */
    __GDEF
{
    char *lastzipfn = (char *)NULL;
    int NumWinFiles, NumLoseFiles, NumWarnFiles;
    int NumMissDirs, NumMissFiles;
    int error=0, error_in_archive=0;


/*---------------------------------------------------------------------------
    Start by allocating buffers and (re)constructing the various PK signature
    strings.
  ---------------------------------------------------------------------------*/

    G.inbuf = (unsigned char *)malloc(INBUFSIZ + 4);    /* 4 extra for hold[] (below) */
    G.outbuf = (unsigned char *)malloc(OUTBUFSIZ + 1);  /* 1 extra for string term. */

    if ((G.inbuf == (unsigned char *)NULL) || (G.outbuf == (unsigned char *)NULL)) {
        Info(slide, 0x401, ((char *)slide,
          LoadFarString(CannotAllocateBuffers)));
        return(PK_MEM);
    }
    G.hold = G.inbuf + INBUFSIZ;     /* to check for boundary-spanning sigs */

    /* finish up initialization of magic signature strings */
    local_hdr_sig[0]  /* = extd_local_sig[0] */ =       /* ASCII 'P', */
      central_hdr_sig[0] = end_central_sig[0] =         /* not EBCDIC */
      end_centloc64_sig[0] = end_central64_sig[0] = 0x50;

    local_hdr_sig[1]  /* = extd_local_sig[1] */ =       /* ASCII 'K', */
      central_hdr_sig[1] = end_central_sig[1] =         /* not EBCDIC */
      end_centloc64_sig[1] = end_central64_sig[1] = 0x4B;

/*---------------------------------------------------------------------------
    Make sure timezone info is set correctly; localtime() returns GMT on some
    OSes (e.g., Solaris 2.x) if this isn't done first.  The ifdefs around
    tzset() were initially copied from dos_to_unix_time() in fileio.c.  They
    may still be too strict; any listed OS that supplies tzset(), regardless
    of whether the function does anything, should be removed from the ifdefs.
  ---------------------------------------------------------------------------*/


/* For systems that do not have tzset() but supply this function using another
   name (_tzset() or something similar), an appropiate "#define tzset ..."
   should be added to the system specifc configuration section.  */
    tzset();

/*---------------------------------------------------------------------------
    Initialize the internal flag holding the mode of processing "overwrite
    existing file" cases.  We do not use the calling interface flags directly
    because the overwrite mode may be changed by user interaction while
    processing archive files.  Such a change should not affect the option
    settings as passed through the DLL calling interface.
    In case of conflicting options, the 'safer' flag uO.overwrite_none takes
    precedence.
  ---------------------------------------------------------------------------*/
    G.overwrite_mode = (uO.overwrite_none ? OVERWRT_NEVER :
                        (uO.overwrite_all ? OVERWRT_ALWAYS : OVERWRT_QUERY));

/*---------------------------------------------------------------------------
    Match (possible) wildcard zipfile specification with existing files and
    attempt to process each.  If no hits, try again after appending ".zip"
    suffix.  If still no luck, give up.
  ---------------------------------------------------------------------------*/

    NumWinFiles = NumLoseFiles = NumWarnFiles = 0;
    NumMissDirs = NumMissFiles = 0;

    while ((G.zipfn = do_wild(__G__ G.wildzipfn)) != (char *)NULL) {
        Trace((stderr, "do_wild( %s ) returns %s\n", G.wildzipfn, G.zipfn));

        lastzipfn = G.zipfn;

        /* print a blank line between the output of different zipfiles */
        if (!uO.qflag  &&  error != PK_NOZIP  &&  error != IZ_DIR
            && (NumWinFiles+NumLoseFiles+NumWarnFiles+NumMissFiles) > 0)
            (*G.message)((void *)&G, (unsigned char *)"\n", 1L, 0);

        if ((error = do_seekable(__G__ 0)) == PK_WARN)
            ++NumWarnFiles;
        else if (error == IZ_DIR)
            ++NumMissDirs;
        else if (error == PK_NOZIP)
            ++NumMissFiles;
        else if (error != PK_OK)
            ++NumLoseFiles;
        else
            ++NumWinFiles;

        Trace((stderr, "do_seekable(0) returns %d\n", error));
        if (error != IZ_DIR && error > error_in_archive)
            error_in_archive = error;

    } /* end while-loop (wildcard zipfiles) */

    if ((NumWinFiles + NumWarnFiles + NumLoseFiles) == 0  &&
        (NumMissDirs + NumMissFiles) == 1  &&  lastzipfn != (char *)NULL)
    {
        if (iswild(G.wildzipfn)) {
            if (iswild(lastzipfn)) {
                NumMissDirs = NumMissFiles = 0;
                error_in_archive = PK_COOL;
                if (uO.qflag < 3)
                    Info(slide, 0x401, ((char *)slide,
                      LoadFarString(CannotFindWildcardMatch),
                      LoadFarStringSmall((uO.zipinfo_mode ? Zipnfo : Unzip)),
                      G.wildzipfn));
            }
        } else
        {
            /* 2004-11-24 SMS.
             * VMS has already tried a default file type of ".zip" in
             * do_wild(), so adding ZSUFX here only causes confusion by
             * corrupting some valid (though nonexistent) file names.
             * Complaining below about "fred;4.zip" is unlikely to be
             * helpful to the victim.
             */
            /* 2005-08-14 Chr. Spieler
             * Although we already "know" the failure result, we call
             * do_seekable() again with the same zipfile name (and the
             * lastchance flag set), just to trigger the error report...
             */
              strcpy(lastzipfn + strlen(lastzipfn), ZSUFX);

            G.zipfn = lastzipfn;

            NumMissDirs = NumMissFiles = 0;
            error_in_archive = PK_COOL;

            error = do_seekable(__G__ 1);
            Trace((stderr, "do_seekable(1) returns %d\n", error));
            switch (error) {
              case PK_WARN:
                ++NumWarnFiles;
                break;
              case IZ_DIR:
                ++NumMissDirs;
                error = PK_NOZIP;
                break;
              case PK_NOZIP:
                /* increment again => bug:
                   "1 file had no zipfile directory." */
                /* ++NumMissFiles */ ;
                break;
              default:
                if (error)
                    ++NumLoseFiles;
                else
                    ++NumWinFiles;
                break;
            }

            if (error > error_in_archive)
                error_in_archive = error;
        }
    }

/*---------------------------------------------------------------------------
    Print summary of all zipfiles, assuming zipfile spec was a wildcard (no
    need for a summary if just one zipfile).
  ---------------------------------------------------------------------------*/

    if (iswild(G.wildzipfn) && uO.qflag < 3)
    {
        if ((NumMissFiles + NumLoseFiles + NumWarnFiles > 0 || NumWinFiles != 1)
            && !(uO.tflag && uO.qflag > 1))
            (*G.message)((void *)&G, (unsigned char *)"\n", 1L, 0x401);
        if ((NumWinFiles > 1) ||
            (NumWinFiles == 1 &&
             NumMissDirs + NumMissFiles + NumLoseFiles + NumWarnFiles > 0))
            Info(slide, 0x401, ((char *)slide, LoadFarString(FilesProcessOK),
              NumWinFiles, (NumWinFiles == 1)? " was" : "s were"));
        if (NumWarnFiles > 0)
            Info(slide, 0x401, ((char *)slide, LoadFarString(ArchiveWarning),
              NumWarnFiles, (NumWarnFiles == 1)? "" : "s"));
        if (NumLoseFiles > 0)
            Info(slide, 0x401, ((char *)slide, LoadFarString(ArchiveFatalError),
              NumLoseFiles, (NumLoseFiles == 1)? "" : "s"));
        if (NumMissFiles > 0)
            Info(slide, 0x401, ((char *)slide,
              LoadFarString(FileHadNoZipfileDir), NumMissFiles,
              (NumMissFiles == 1)? "" : "s"));
        if (NumMissDirs == 1)
            Info(slide, 0x401, ((char *)slide, LoadFarString(ZipfileWasDir)));
        else if (NumMissDirs > 0)
            Info(slide, 0x401, ((char *)slide,
              LoadFarString(ManyZipfilesWereDir), NumMissDirs));
        if (NumWinFiles + NumLoseFiles + NumWarnFiles == 0)
            Info(slide, 0x401, ((char *)slide, LoadFarString(NoZipfileFound)));
    }

    /* free allocated memory */
    free_G_buffers(__G);

    return error_in_archive;

} /* end function process_zipfiles() */





/*****************************/
/* Function free_G_buffers() */
/*****************************/

void free_G_buffers(__G)     /* releases all memory allocated in global vars */
    __GDEF
{
    unsigned i;

    inflate_free(__G);
    checkdir(__G__ (char *)NULL, END);

   if (G.key != (char *)NULL) {
        free(G.key);
        G.key = (char *)NULL;
   }

   if (G.extra_field != (unsigned char *)NULL) {
        free(G.extra_field);
        G.extra_field = (unsigned char *)NULL;
   }

    /* VMS uses its own buffer scheme for textmode flush() */
    if (G.outbuf2) {
        free(G.outbuf2);   /* malloc'd ONLY if unshrink and -a */
        G.outbuf2 = (unsigned char *)NULL;
    }

    if (G.outbuf)
        free(G.outbuf);
    if (G.inbuf)
        free(G.inbuf);
    G.inbuf = G.outbuf = (unsigned char *)NULL;

    for (i = 0; i < DIR_BLKSIZ; i++) {
        if (G.info[i].cfilname != (char Far *)NULL) {
            zffree(G.info[i].cfilname);
            G.info[i].cfilname = (char Far *)NULL;
        }
    }
} /* end function free_G_buffers() */





/**************************/
/* Function do_seekable() */
/**************************/

static int do_seekable(int lastchance)        /* return PK-type error code */
{
    /* static int no_ecrec = FALSE;  SKM: moved to globals.h */
    int maybe_exe=FALSE;
    int too_weird_to_continue=FALSE;
    int error=0, error_in_archive;


/*---------------------------------------------------------------------------
    Open the zipfile for reading in BINARY mode to prevent CR/LF translation,
    which would corrupt the bit streams.
  ---------------------------------------------------------------------------*/

    if (SSTAT(G.zipfn, &G.statbuf) ||
        (error = S_ISDIR(G.statbuf.st_mode)) != 0)
    {
        if (lastchance && (uO.qflag < 3)) {
            if (G.no_ecrec)
                Info(slide, 0x401, ((char *)slide,
                  LoadFarString(CannotFindZipfileDirMsg),
                  LoadFarStringSmall((uO.zipinfo_mode ? Zipnfo : Unzip)),
                  G.wildzipfn, uO.zipinfo_mode? "  " : "", G.zipfn));
            else
                Info(slide, 0x401, ((char *)slide,
                  LoadFarString(CannotFindEitherZipfile),
                  LoadFarStringSmall((uO.zipinfo_mode ? Zipnfo : Unzip)),
                  G.wildzipfn, G.zipfn));
        }
        return error? IZ_DIR : PK_NOZIP;
    }
    G.ziplen = G.statbuf.st_size;

    if (open_input_file(__G))   /* this should never happen, given */
        return PK_NOZIP;        /*  the stat() test above, but... */


/*---------------------------------------------------------------------------
    Find and process the end-of-central-directory header.  UnZip need only
    check last 65557 bytes of zipfile:  comment may be up to 65535, end-of-
    central-directory record is 18 bytes, and signature itself is 4 bytes;
    add some to allow for appended garbage.  Since ZipInfo is often used as
    a debugging tool, search the whole zipfile if zipinfo_mode is true.
  ---------------------------------------------------------------------------*/

    G.cur_zipfile_bufstart = 0;
    G.inptr = G.inbuf;

    if ( (!uO.zipinfo_mode && !uO.qflag
         )
       )
        Info(slide, 0, ((char *)slide, LoadFarString(LogInitline), G.zipfn));

    if ( (error_in_archive = find_ecrec(__G__
                                        MIN(G.ziplen, 66000L)))
         > PK_WARN )
    {
        CLOSE_INFILE();

        if (maybe_exe)
            Info(slide, 0x401, ((char *)slide, LoadFarString(MaybeExe),
            G.zipfn));
        if (lastchance)
            return error_in_archive;
        else {
            G.no_ecrec = TRUE;    /* assume we found wrong file:  e.g., */
            return PK_NOZIP;       /*  unzip instead of unzip.zip */
        }
    }

    if ((uO.zflag > 0) && !uO.zipinfo_mode) { /* unzip: zflag = comment ONLY */
        CLOSE_INFILE();
        return error_in_archive;
    }

/*---------------------------------------------------------------------------
    Test the end-of-central-directory info for incompatibilities (multi-disk
    archives) or inconsistencies (missing or extra bytes in zipfile).
  ---------------------------------------------------------------------------*/

    error = !uO.zipinfo_mode && (G.ecrec.number_this_disk != 0);

    if (uO.zipinfo_mode &&
        G.ecrec.number_this_disk != G.ecrec.num_disk_start_cdir)
    {
        if (G.ecrec.number_this_disk > G.ecrec.num_disk_start_cdir) {
            Info(slide, 0x401, ((char *)slide,
              LoadFarString(CentDirNotInZipMsg), G.zipfn,
              (ulg)G.ecrec.number_this_disk,
              (ulg)G.ecrec.num_disk_start_cdir));
            error_in_archive = PK_FIND;
            too_weird_to_continue = TRUE;
        } else {
            Info(slide, 0x401, ((char *)slide,
              LoadFarString(EndCentDirBogus), G.zipfn,
              (ulg)G.ecrec.number_this_disk,
              (ulg)G.ecrec.num_disk_start_cdir));
            error_in_archive = PK_WARN;
        }
    }

    if (!too_weird_to_continue) {  /* (relatively) normal zipfile:  go for it */
        if (error) {
            Info(slide, 0x401, ((char *)slide, LoadFarString(MaybePakBug),
              G.zipfn));
            error_in_archive = PK_WARN;
        }
        if ((G.extra_bytes = G.real_ecrec_offset-G.expect_ecrec_offset) <
            (zoff_t)0)
        {
            Info(slide, 0x401, ((char *)slide, LoadFarString(MissingBytes),
              G.zipfn, FmZofft((-G.extra_bytes), NULL, NULL)));
            error_in_archive = PK_ERR;
        } else if (G.extra_bytes > 0) {
            if ((G.ecrec.offset_start_central_directory == 0) &&
                (G.ecrec.size_central_directory != 0))   /* zip 1.5 -go bug */
            {
                Info(slide, 0x401, ((char *)slide,
                  LoadFarString(NullCentDirOffset), G.zipfn));
                G.ecrec.offset_start_central_directory = G.extra_bytes;
                G.extra_bytes = 0;
                error_in_archive = PK_ERR;
            }
            else {
                Info(slide, 0x401, ((char *)slide,
                  LoadFarString(ExtraBytesAtStart), G.zipfn,
                  FmZofft(G.extra_bytes, NULL, NULL),
                  (G.extra_bytes == 1)? "":"s"));
                error_in_archive = PK_WARN;
            }
        }

    /*-----------------------------------------------------------------------
        Check for empty zipfile and exit now if so.
      -----------------------------------------------------------------------*/

        if (G.expect_ecrec_offset==0L && G.ecrec.size_central_directory==0) {
            if (uO.zipinfo_mode)
                Info(slide, 0, ((char *)slide, "%sEmpty zipfile.\n",
                  uO.lflag>9? "\n  " : ""));
            else
                Info(slide, 0x401, ((char *)slide, LoadFarString(ZipfileEmpty),
                                    G.zipfn));
            CLOSE_INFILE();
            return (error_in_archive > PK_WARN)? error_in_archive : PK_WARN;
        }

    /*-----------------------------------------------------------------------
        Compensate for missing or extra bytes, and seek to where the start
        of central directory should be.  If header not found, uncompensate
        and try again (necessary for at least some Atari archives created
        with STZip, as well as archives created by J.H. Holm's ZIPSPLIT 1.1).
      -----------------------------------------------------------------------*/

        error = seek_zipf(__G__ G.ecrec.offset_start_central_directory);
        if (error == PK_BADERR) {
            CLOSE_INFILE();
            return PK_BADERR;
        }
        if ((error != PK_OK) || (readbuf(__G__ G.sig, 4) == 0) ||
            memcmp(G.sig, central_hdr_sig, 4))
        {
            zoff_t tmp = G.extra_bytes;

            G.extra_bytes = 0;
            error = seek_zipf(__G__ G.ecrec.offset_start_central_directory);
            if ((error != PK_OK) || (readbuf(__G__ G.sig, 4) == 0) ||
                memcmp(G.sig, central_hdr_sig, 4))
            {
                if (error != PK_BADERR)
                  Info(slide, 0x401, ((char *)slide,
                    LoadFarString(CentDirStartNotFound), G.zipfn,
                    LoadFarStringSmall(ReportMsg)));
                CLOSE_INFILE();
                return (error != PK_OK ? error : PK_BADERR);
            }
            Info(slide, 0x401, ((char *)slide, LoadFarString(CentDirTooLong),
              G.zipfn, FmZofft((-tmp), NULL, NULL)));
            error_in_archive = PK_ERR;
        }

    /*-----------------------------------------------------------------------
        Seek to the start of the central directory one last time, since we
        have just read the first entry's signature bytes; then list, extract
        or test member files as instructed, and close the zipfile.
      -----------------------------------------------------------------------*/

        error = seek_zipf(__G__ G.ecrec.offset_start_central_directory);
        if (error != PK_OK) {
            CLOSE_INFILE();
            return error;
        }

        Trace((stderr, "about to extract/list files (error = %d)\n",
          error_in_archive));

        {
            if (uO.zipinfo_mode)
                error = zipinfo(__G);                 /* ZIPINFO 'EM */
            else
            if (uO.vflag && !uO.tflag && !uO.cflag)
                error = list_files(__G);              /* LIST 'EM */
            else
                error = extract_or_test_files(__G);   /* EXTRACT OR TEST 'EM */

            Trace((stderr, "done with extract/list files (error = %d)\n",
                   error));
        }

        if (error > error_in_archive)   /* don't overwrite stronger error */
            error_in_archive = error;   /*  with (for example) a warning */
    } /* end if (!too_weird_to_continue) */

    CLOSE_INFILE();
    return error_in_archive;

} /* end function do_seekable() */





/***********************/
/* Function rec_find() */
/***********************/

static int rec_find(zoff_t searchlen, char* signature, int rec_size)
    /* return 0 when rec found, 1 when not found, 2 in case of read error */
{
    int i, numblks, found=FALSE;
    zoff_t tail_len;

/*---------------------------------------------------------------------------
    Zipfile is longer than INBUFSIZ:  may need to loop.  Start with short
    block at end of zipfile (if not TOO short).
  ---------------------------------------------------------------------------*/

    if ((tail_len = G.ziplen % INBUFSIZ) > rec_size) {
        RdosSetFilePos(G.zipfd, G.ziplen-tail_len);
        G.cur_zipfile_bufstart = RdosGetFilePos(G.zipfd);
        if ((G.incnt = RdosReadFile(G.zipfd, (char *)G.inbuf,
            (unsigned int)tail_len)) != (int)tail_len)
            return 2;      /* it's expedient... */

        /* 'P' must be at least (rec_size+4) bytes from end of zipfile */
        for (G.inptr = G.inbuf+(int)tail_len-(rec_size+4);
             G.inptr >= G.inbuf;
             --G.inptr) {
            if ( (*G.inptr == (unsigned char)0x50) &&         /* ASCII 'P' */
                 !memcmp((char *)G.inptr, signature, 4) ) {
                G.incnt -= (int)(G.inptr - G.inbuf);
                found = TRUE;
                break;
            }
        }
        /* sig may span block boundary: */
        memcpy((char *)G.hold, (char *)G.inbuf, 3);
    } else
        G.cur_zipfile_bufstart = G.ziplen - tail_len;

/*-----------------------------------------------------------------------
    Loop through blocks of zipfile data, starting at the end and going
    toward the beginning.  In general, need not check whole zipfile for
    signature, but may want to do so if testing.
  -----------------------------------------------------------------------*/

    numblks = (int)((searchlen - tail_len + (INBUFSIZ-1)) / INBUFSIZ);
    /*               ==amount=   ==done==   ==rounding==    =blksiz=  */

    for (i = 1;  !found && (i <= numblks);  ++i) {
        G.cur_zipfile_bufstart -= INBUFSIZ;
        RdosSetFilePos(G.zipfd, G.cur_zipfile_bufstart);
        if ((G.incnt = RdosReadFile(G.zipfd,(char *)G.inbuf,INBUFSIZ))
            != INBUFSIZ)
            return 2;          /* read error is fatal failure */

        for (G.inptr = G.inbuf+INBUFSIZ-1;  G.inptr >= G.inbuf; --G.inptr)
            if ( (*G.inptr == (unsigned char)0x50) &&         /* ASCII 'P' */
                 !memcmp((char *)G.inptr, signature, 4) ) {
                G.incnt -= (int)(G.inptr - G.inbuf);
                found = TRUE;
                break;
            }
        /* sig may span block boundary: */
        memcpy((char *)G.hold, (char *)G.inbuf, 3);
    }
    return (found ? 0 : 1);
} /* end function rec_find() */



/***************************/
/* Function find_ecrec64() */
/***************************/

static int find_ecrec64(zoff_t searchlen)         /* return PK-class error */
{
    ec_byte_rec64 byterec;          /* buf for ecrec64 */
    ec_byte_loc64 byterecL;         /* buf for ecrec64 locator */
    zoff_t ecloc64_start_offset;    /* start offset of ecrec64 locator */
    zusz_t ecrec64_start_offset;    /* start offset of ecrec64 */
    zuvl_t ecrec64_start_disk;      /* start disk of ecrec64 */
    zuvl_t ecloc64_total_disks;     /* total disks */
    zuvl_t ecrec64_disk_cdstart;    /* disk number of central dir start */
    zucn_t ecrec64_this_entries;    /* entries on disk with ecrec64 */
    zucn_t ecrec64_tot_entries;     /* total number of entries */
    zusz_t ecrec64_cdirsize;        /* length of central dir */
    zusz_t ecrec64_offs_cdstart;    /* offset of central dir start */

    /* First, find the ecrec64 locator.  By definition, this must be before
       ecrec with nothing in between.  We back up the size of the ecrec64
       locator and check.  */

    ecloc64_start_offset = G.real_ecrec_offset - (ECLOC64_SIZE+4);
    if (ecloc64_start_offset < 0)
      /* Seeking would go past beginning, so probably empty archive */
      return PK_COOL;

    RdosSetFilePos(G.zipfd, ecloc64_start_offset);
    G.cur_zipfile_bufstart = RdosGetFilePos(G.zipfd);

    if ((G.incnt = RdosReadFile(G.zipfd, (char *)byterecL, ECLOC64_SIZE+4))
        != (ECLOC64_SIZE+4)) {
      if (uO.qflag || uO.zipinfo_mode)
          Info(slide, 0x401, ((char *)slide, "[%s]\n", G.zipfn));
      Info(slide, 0x401, ((char *)slide,
        LoadFarString(Cent64EndSigSearchErr)));
      return PK_ERR;
    }

    if (memcmp((char *)byterecL, end_centloc64_sig, 4) ) {
      /* not found */
      return PK_COOL;
    }

    /* Read the locator. */
    ecrec64_start_disk = (zuvl_t)makelong(&byterecL[NUM_DISK_START_EOCDR64]);
    ecrec64_start_offset = (zusz_t)makeint64(&byterecL[OFFSET_START_EOCDR64]);
    ecloc64_total_disks = (zuvl_t)makelong(&byterecL[NUM_THIS_DISK_LOC64]);

    /* Check for consistency */
#ifdef TEST
    fprintf(stdout,"\nnumber of disks (ECR) %u, (ECLOC64) %lu\n",
            G.ecrec.number_this_disk, ecloc64_total_disks); fflush(stdout);
#endif
    if ((G.ecrec.number_this_disk != 0xFFFF) &&
        (G.ecrec.number_this_disk != ecloc64_total_disks - 1)) {
      /* Note: For some unknown reason, the developers at PKWARE decided to
         store the "zip64 total disks" value as a counter starting from 1,
         whereas all other "split/span volume" related fields use 0-based
         volume numbers. Sigh... */
      /* When the total number of disks as found in the traditional ecrec
         is not 0xFFFF, the disk numbers in ecrec and ecloc64 must match.
         When this is not the case, the found ecrec64 locator cannot be valid.
         -> This is not a Zip64 archive.
       */
      Trace((stderr,
             "\ninvalid ECLOC64, differing disk# (ECR %u, ECL64 %lu)\n",
             G.ecrec.number_this_disk, ecloc64_total_disks - 1));
      return PK_COOL;
    }

    /* If found locator, look for ecrec64 where the locator says it is. */

    /* For now assume that ecrec64 is on the same disk as ecloc64 and ecrec,
       which is usually the case and is how Zip writes it.  To do this right,
       however, we should allow the ecrec64 to be on another disk since
       the AppNote allows it and the ecrec64 can be large, especially if
       Version 2 is used (AppNote uses 8 bytes for the size of this record). */

    /* FIX BELOW IF ADD SUPPORT FOR MULTIPLE DISKS */

    if (ecrec64_start_offset > (zusz_t)ecloc64_start_offset) {
      /* ecrec64 has to be before ecrec64 locator */
      if (uO.qflag || uO.zipinfo_mode)
          Info(slide, 0x401, ((char *)slide, "[%s]\n", G.zipfn));
      Info(slide, 0x401, ((char *)slide,
        LoadFarString(Cent64EndSigSearchErr)));
      return PK_ERR;
    }


    RdosSetFilePos(G.zipfd, ecrec64_start_offset);
    G.cur_zipfile_bufstart = RdosGetFilePos(G.zipfd);

    if ((G.incnt = RdosReadFile(G.zipfd, (char *)byterec, ECREC64_SIZE+4))
        != (ECREC64_SIZE+4)) {
      if (uO.qflag || uO.zipinfo_mode)
          Info(slide, 0x401, ((char *)slide, "[%s]\n", G.zipfn));
      Info(slide, 0x401, ((char *)slide,
        LoadFarString(Cent64EndSigSearchErr)));
      return PK_ERR;
    }

    if (memcmp((char *)byterec, end_central64_sig, 4) ) {
      /* Zip64 EOCD Record not found */
      /* Since we already have seen the Zip64 EOCD Locator, it's
         possible we got here because there are bytes prepended
         to the archive, like the sfx prefix. */

      /* Make a guess as to where the Zip64 EOCD Record might be */
      ecrec64_start_offset = ecloc64_start_offset - ECREC64_SIZE - 4;

      RdosSetFilePos(G.zipfd, ecrec64_start_offset);
      G.cur_zipfile_bufstart = RdosGetFilePos(G.zipfd);

      if ((G.incnt = RdosReadFile(G.zipfd, (char *)byterec, ECREC64_SIZE+4))
          != (ECREC64_SIZE+4)) {
        if (uO.qflag || uO.zipinfo_mode)
            Info(slide, 0x401, ((char *)slide, "[%s]\n", G.zipfn));
        Info(slide, 0x401, ((char *)slide,
          LoadFarString(Cent64EndSigSearchErr)));
        return PK_ERR;
      }

      if (memcmp((char *)byterec, end_central64_sig, 4) ) {
        /* Zip64 EOCD Record not found */
        /* Probably something not so easy to handle so exit */
        if (uO.qflag || uO.zipinfo_mode)
            Info(slide, 0x401, ((char *)slide, "[%s]\n", G.zipfn));
        Info(slide, 0x401, ((char *)slide,
          LoadFarString(Cent64EndSigSearchErr)));
        return PK_ERR;
      }

      if (uO.qflag || uO.zipinfo_mode)
          Info(slide, 0x401, ((char *)slide, "[%s]\n", G.zipfn));
      Info(slide, 0x401, ((char *)slide,
        LoadFarString(Cent64EndSigSearchOff)));
    }

    /* Check consistency of found ecrec64 with ecloc64 (and ecrec): */
    if ( (zuvl_t)makelong(&byterec[NUMBER_THIS_DSK_REC64])
         != ecrec64_start_disk )
        /* found ecrec64 does not match ecloc64 info -> no Zip64 archive */
        return PK_COOL;
    /* Read all relevant ecrec64 fields and compare them to the corresponding
       ecrec fields unless those are set to "all-ones".
     */
    ecrec64_disk_cdstart =
      (zuvl_t)makelong(&byterec[NUM_DISK_START_CEN_DIR64]);
    if ( (G.ecrec.num_disk_start_cdir != 0xFFFF) &&
         (G.ecrec.num_disk_start_cdir != ecrec64_disk_cdstart) )
        return PK_COOL;
    ecrec64_this_entries
      = makeint64(&byterec[NUM_ENTRIES_CEN_DIR_THS_DISK64]);
    if ( (G.ecrec.num_entries_centrl_dir_ths_disk != 0xFFFF) &&
         (G.ecrec.num_entries_centrl_dir_ths_disk != ecrec64_this_entries) )
        return PK_COOL;
    ecrec64_tot_entries
      = makeint64(&byterec[TOTAL_ENTRIES_CENTRAL_DIR64]);
    if ( (G.ecrec.total_entries_central_dir != 0xFFFF) &&
         (G.ecrec.total_entries_central_dir != ecrec64_tot_entries) )
        return PK_COOL;
    ecrec64_cdirsize
      = makeint64(&byterec[SIZE_CENTRAL_DIRECTORY64]);
    if ( (G.ecrec.size_central_directory != 0xFFFFFFFFL) &&
         (G.ecrec.size_central_directory != ecrec64_cdirsize) )
        return PK_COOL;
    ecrec64_offs_cdstart
      = makeint64(&byterec[OFFSET_START_CENTRAL_DIRECT64]);
    if ( (G.ecrec.offset_start_central_directory != 0xFFFFFFFFL) &&
         (G.ecrec.offset_start_central_directory != ecrec64_offs_cdstart) )
        return PK_COOL;

    /* Now, we are (almost) sure that we have a Zip64 archive. */
    G.ecrec.have_ecr64 = 1;

    /* Update the "end-of-central-dir offset" for later checks. */
    G.real_ecrec_offset = ecrec64_start_offset;

    /* Update all ecdir_rec data that are flagged to be invalid
       in Zip64 mode.  Set the ecrec64-mandatory flag when such a
       case is found. */
    if (G.ecrec.number_this_disk == 0xFFFF) {
      G.ecrec.number_this_disk = ecrec64_start_disk;
      if (ecrec64_start_disk != 0xFFFF) G.ecrec.is_zip64_archive = TRUE;
    }
    if (G.ecrec.num_disk_start_cdir == 0xFFFF) {
      G.ecrec.num_disk_start_cdir = ecrec64_disk_cdstart;
      if (ecrec64_disk_cdstart != 0xFFFF) G.ecrec.is_zip64_archive = TRUE;
    }
    if (G.ecrec.num_entries_centrl_dir_ths_disk == 0xFFFF) {
      G.ecrec.num_entries_centrl_dir_ths_disk = ecrec64_this_entries;
      if (ecrec64_this_entries != 0xFFFF) G.ecrec.is_zip64_archive = TRUE;
    }
    if (G.ecrec.total_entries_central_dir == 0xFFFF) {
      G.ecrec.total_entries_central_dir = ecrec64_tot_entries;
      if (ecrec64_tot_entries != 0xFFFF) G.ecrec.is_zip64_archive = TRUE;
    }
    if (G.ecrec.size_central_directory == 0xFFFFFFFFL) {
      G.ecrec.size_central_directory = ecrec64_cdirsize;
      if (ecrec64_cdirsize != 0xFFFFFFFF) G.ecrec.is_zip64_archive = TRUE;
    }
    if (G.ecrec.offset_start_central_directory == 0xFFFFFFFFL) {
      G.ecrec.offset_start_central_directory = ecrec64_offs_cdstart;
      if (ecrec64_offs_cdstart != 0xFFFFFFFF) G.ecrec.is_zip64_archive = TRUE;
    }

    return PK_COOL;
} /* end function find_ecrec64() */



/*************************/
/* Function find_ecrec() */
/*************************/

static int find_ecrec(zoff_t searchlen)          /* return PK-class error */
{
    int found = FALSE;
    int error_in_archive;
    int result;
    ec_byte_rec byterec;

/*---------------------------------------------------------------------------
    Treat case of short zipfile separately.
  ---------------------------------------------------------------------------*/

    if (G.ziplen <= INBUFSIZ) {
        RdosSetFilePos(G.zipfd, 0L);
        if ((G.incnt = RdosReadFile(G.zipfd,(char *)G.inbuf,(unsigned int)G.ziplen))
            == (int)G.ziplen)

            /* 'P' must be at least (ECREC_SIZE+4) bytes from end of zipfile */
            for (G.inptr = G.inbuf+(int)G.ziplen-(ECREC_SIZE+4);
                 G.inptr >= G.inbuf;
                 --G.inptr) {
                if ( (*G.inptr == (unsigned char)0x50) &&         /* ASCII 'P' */
                     !memcmp((char *)G.inptr, end_central_sig, 4)) {
                    G.incnt -= (int)(G.inptr - G.inbuf);
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
          (rec_find(__G__ searchlen, end_central_sig, ECREC_SIZE) == 0
           ? TRUE : FALSE);
    } /* end if (ziplen > INBUFSIZ) */

/*---------------------------------------------------------------------------
    Searched through whole region where signature should be without finding
    it.  Print informational message and die a horrible death.
  ---------------------------------------------------------------------------*/

    if (!found) {
        if (uO.qflag || uO.zipinfo_mode)
            Info(slide, 0x401, ((char *)slide, "[%s]\n", G.zipfn));
        Info(slide, 0x401, ((char *)slide,
          LoadFarString(CentDirEndSigNotFound)));
        return PK_ERR;   /* failed */
    }

/*---------------------------------------------------------------------------
    Found the signature, so get the end-central data before returning.  Do
    any necessary machine-type conversions (byte ordering, structure padding
    compensation) by reading data into character array and copying to struct.
  ---------------------------------------------------------------------------*/

    G.real_ecrec_offset = G.cur_zipfile_bufstart + (G.inptr-G.inbuf);
#ifdef TEST
    printf("\n  found end-of-central-dir signature at offset %s (%sh)\n",
      FmZofft(G.real_ecrec_offset, NULL, NULL),
      FmZofft(G.real_ecrec_offset, FZOFFT_HEX_DOT_WID, "X"));
    printf("    from beginning of file; offset %d (%.4Xh) within block\n",
      G.inptr-G.inbuf, G.inptr-G.inbuf);
#endif

    if (readbuf(__G__ (char *)byterec, ECREC_SIZE+4) == 0)
        return PK_EOF;

    G.ecrec.number_this_disk =
      makeword(&byterec[NUMBER_THIS_DISK]);
    G.ecrec.num_disk_start_cdir =
      makeword(&byterec[NUM_DISK_WITH_START_CEN_DIR]);
    G.ecrec.num_entries_centrl_dir_ths_disk =
      makeword(&byterec[NUM_ENTRIES_CEN_DIR_THS_DISK]);
    G.ecrec.total_entries_central_dir =
      makeword(&byterec[TOTAL_ENTRIES_CENTRAL_DIR]);
    G.ecrec.size_central_directory =
      makelong(&byterec[SIZE_CENTRAL_DIRECTORY]);
    G.ecrec.offset_start_central_directory =
      makelong(&byterec[OFFSET_START_CENTRAL_DIRECTORY]);
    G.ecrec.zipfile_comment_length =
      makeword(&byterec[ZIPFILE_COMMENT_LENGTH]);

    /* Now, we have to read the archive comment, BEFORE the file pointer
       is moved away backwards to seek for a Zip64 ECLOC64 structure.
     */
    if ( (error_in_archive = process_zip_cmmnt(__G)) > PK_WARN )
        return error_in_archive;

    /* Next: Check for existence of Zip64 end-of-cent-dir locator
       ECLOC64. This structure must reside on the same volume as the
       classic ECREC, at exactly (ECLOC64_SIZE+4) bytes in front
       of the ECREC.
       The ECLOC64 structure directs to the longer ECREC64 structure
       A ECREC64 will ALWAYS exist for a proper Zip64 archive, as
       the "Version Needed To Extract" field is required to be set
       to 4.5 or higher whenever any Zip64 features are used anywhere
       in the archive, so just check for that to see if this is a
       Zip64 archive.
     */
    result = find_ecrec64(__G__ searchlen+76);
        /* 76 bytes for zip64ec & zip64 locator */
    if (result != PK_COOL) {
        if (error_in_archive < result)
            error_in_archive = result;
        return error_in_archive;
    }

    G.expect_ecrec_offset = G.ecrec.offset_start_central_directory +
                            G.ecrec.size_central_directory;

    if (uO.zipinfo_mode) {
        /* In ZipInfo mode, additional info about the data found in the
           end-of-central-directory areas is printed out.
         */
        zi_end_central(__G);
    }

    return error_in_archive;

} /* end function find_ecrec() */





/********************************/
/* Function process_zip_cmmnt() */
/********************************/

static int process_zip_cmmnt(__G)       /* return PK-type error code */
    __GDEF
{
    int error = PK_COOL;


/*---------------------------------------------------------------------------
    Get the zipfile comment (up to 64KB long), if any, and print it out.
  ---------------------------------------------------------------------------*/

    /* ZipInfo, verbose format */
    if (uO.zipinfo_mode && uO.lflag > 9) {
        /*-------------------------------------------------------------------
            Get the zipfile comment, if any, and print it out.
            (Comment may be up to 64KB long.  May the fleas of a thousand
            camels infest the arm-pits of anyone who actually takes advantage
            of this fact.)
          -------------------------------------------------------------------*/

        if (!G.ecrec.zipfile_comment_length)
            Info(slide, 0, ((char *)slide, LoadFarString(NoZipfileComment)));
        else {
            Info(slide, 0, ((char *)slide, LoadFarString(ZipfileCommentDesc),
              G.ecrec.zipfile_comment_length));
            Info(slide, 0, ((char *)slide, LoadFarString(ZipfileCommBegin)));
            if (do_string(__G__ G.ecrec.zipfile_comment_length, DISPLAY))
                error = PK_WARN;
            Info(slide, 0, ((char *)slide, LoadFarString(ZipfileCommEnd)));
            if (error)
                Info(slide, 0, ((char *)slide,
                  LoadFarString(ZipfileCommTrunc2)));
        } /* endif (comment exists) */

    /* ZipInfo, non-verbose mode:  print zipfile comment only if requested */
    } else if (G.ecrec.zipfile_comment_length &&
               (uO.zflag > 0) && uO.zipinfo_mode) {
        if (do_string(__G__ G.ecrec.zipfile_comment_length, DISPLAY)) {
            Info(slide, 0x401, ((char *)slide,
              LoadFarString(ZipfileCommTrunc1)));
            error = PK_WARN;
        }
    } else
    if ( G.ecrec.zipfile_comment_length &&
         (uO.zflag > 0
          || (uO.zflag == 0
              && !uO.zipinfo_mode
              && !uO.qflag)
         ) )
    {
        if (do_string(__G__ G.ecrec.zipfile_comment_length,
                      DISPLAY
                     ))
        {
            Info(slide, 0x401, ((char *)slide,
              LoadFarString(ZipfileCommTrunc1)));
            error = PK_WARN;
        }
    }
    return error;

} /* end function process_zip_cmmnt() */





/************************************/
/* Function process_cdir_file_hdr() */
/************************************/

int process_cdir_file_hdr(__G)    /* return PK-type error code */
    __GDEF
{
    int error;


/*---------------------------------------------------------------------------
    Get central directory info, save host and method numbers, and set flag
    for lowercase conversion of filename, depending on the OS from which the
    file is coming.
  ---------------------------------------------------------------------------*/

    if ((error = get_cdir_ent(__G)) != 0)
        return error;

    G.pInfo->hostver = G.crec.version_made_by[0];
    G.pInfo->hostnum = MIN(G.crec.version_made_by[1], NUM_HOSTS);
/*  extnum = MIN(crec.version_needed_to_extract[1], NUM_HOSTS); */

    G.pInfo->lcflag = 0;
    if (uO.L_flag == 1)       /* name conversion for monocase systems */
        switch (G.pInfo->hostnum) {
            case FS_FAT_:     /* PKZIP and zip -k store in uppercase */
            case CPM_:        /* like MS-DOS, right? */
            case VM_CMS_:     /* all caps? */
            case MVS_:        /* all caps? */
            case TANDEM_:
            case TOPS20_:
            case VMS_:        /* our Zip uses lowercase, but ASi's doesn't */
        /*  case Z_SYSTEM_:   ? */
        /*  case QDOS_:       ? */
                G.pInfo->lcflag = 1;   /* convert filename to lowercase */
                break;

            default:     /* AMIGA_, FS_HPFS_, FS_NTFS_, MAC_, UNIX_, ATARI_, */
                break;   /*  FS_VFAT_, ATHEOS_, BEOS_ (Z_SYSTEM_), THEOS_: */
                         /*  no conversion */
        }
    else if (uO.L_flag > 1)   /* let -LL force lower case for all names */
        G.pInfo->lcflag = 1;

    /* do Amigas (AMIGA_) also have volume labels? */
    if (IS_VOLID(G.crec.external_file_attributes) &&
        (G.pInfo->hostnum == FS_FAT_ || G.pInfo->hostnum == FS_HPFS_ ||
         G.pInfo->hostnum == FS_NTFS_ || G.pInfo->hostnum == ATARI_))
    {
        G.pInfo->vollabel = TRUE;
        G.pInfo->lcflag = 0;        /* preserve case of volume labels */
    } else
        G.pInfo->vollabel = FALSE;

    /* this flag is needed to detect archives made by "PKZIP for Unix" when
       deciding which kind of codepage conversion has to be applied to
       strings (see do_string() function in fileio.c) */
    G.pInfo->HasUxAtt = (G.crec.external_file_attributes & 0xffff0000L) != 0L;

    return PK_COOL;

} /* end function process_cdir_file_hdr() */





/***************************/
/* Function get_cdir_ent() */
/***************************/

static int get_cdir_ent(__G)    /* return PK-type error code */
    __GDEF
{
    cdir_byte_hdr byterec;


/*---------------------------------------------------------------------------
    Read the next central directory entry and do any necessary machine-type
    conversions (byte ordering, structure padding compensation--do so by
    copying the data from the array into which it was read (byterec) to the
    usable struct (crec)).
  ---------------------------------------------------------------------------*/

    if (readbuf(__G__ (char *)byterec, CREC_SIZE) == 0)
        return PK_EOF;

    G.crec.version_made_by[0] = byterec[C_VERSION_MADE_BY_0];
    G.crec.version_made_by[1] = byterec[C_VERSION_MADE_BY_1];
    G.crec.version_needed_to_extract[0] =
      byterec[C_VERSION_NEEDED_TO_EXTRACT_0];
    G.crec.version_needed_to_extract[1] =
      byterec[C_VERSION_NEEDED_TO_EXTRACT_1];

    G.crec.general_purpose_bit_flag =
      makeword(&byterec[C_GENERAL_PURPOSE_BIT_FLAG]);
    G.crec.compression_method =
      makeword(&byterec[C_COMPRESSION_METHOD]);
    G.crec.last_mod_dos_datetime =
      makelong(&byterec[C_LAST_MOD_DOS_DATETIME]);
    G.crec.crc32 =
      makelong(&byterec[C_CRC32]);
    G.crec.csize =
      makelong(&byterec[C_COMPRESSED_SIZE]);
    G.crec.ucsize =
      makelong(&byterec[C_UNCOMPRESSED_SIZE]);
    G.crec.filename_length =
      makeword(&byterec[C_FILENAME_LENGTH]);
    G.crec.extra_field_length =
      makeword(&byterec[C_EXTRA_FIELD_LENGTH]);
    G.crec.file_comment_length =
      makeword(&byterec[C_FILE_COMMENT_LENGTH]);
    G.crec.disk_number_start =
      makeword(&byterec[C_DISK_NUMBER_START]);
    G.crec.internal_file_attributes =
      makeword(&byterec[C_INTERNAL_FILE_ATTRIBUTES]);
    G.crec.external_file_attributes =
      makelong(&byterec[C_EXTERNAL_FILE_ATTRIBUTES]);  /* LONG, not word! */
    G.crec.relative_offset_local_header =
      makelong(&byterec[C_RELATIVE_OFFSET_LOCAL_HEADER]);

    return PK_COOL;

} /* end function get_cdir_ent() */





/*************************************/
/* Function process_local_file_hdr() */
/*************************************/

int process_local_file_hdr(__G)    /* return PK-type error code */
    __GDEF
{
    local_byte_hdr byterec;


/*---------------------------------------------------------------------------
    Read the next local file header and do any necessary machine-type con-
    versions (byte ordering, structure padding compensation--do so by copy-
    ing the data from the array into which it was read (byterec) to the
    usable struct (lrec)).
  ---------------------------------------------------------------------------*/

    if (readbuf(__G__ (char *)byterec, LREC_SIZE) == 0)
        return PK_EOF;

    G.lrec.version_needed_to_extract[0] =
      byterec[L_VERSION_NEEDED_TO_EXTRACT_0];
    G.lrec.version_needed_to_extract[1] =
      byterec[L_VERSION_NEEDED_TO_EXTRACT_1];

    G.lrec.general_purpose_bit_flag =
      makeword(&byterec[L_GENERAL_PURPOSE_BIT_FLAG]);
    G.lrec.compression_method = makeword(&byterec[L_COMPRESSION_METHOD]);
    G.lrec.last_mod_dos_datetime = makelong(&byterec[L_LAST_MOD_DOS_DATETIME]);
    G.lrec.crc32 = makelong(&byterec[L_CRC32]);
    G.lrec.csize = makelong(&byterec[L_COMPRESSED_SIZE]);
    G.lrec.ucsize = makelong(&byterec[L_UNCOMPRESSED_SIZE]);
    G.lrec.filename_length = makeword(&byterec[L_FILENAME_LENGTH]);
    G.lrec.extra_field_length = makeword(&byterec[L_EXTRA_FIELD_LENGTH]);

    if ((G.lrec.general_purpose_bit_flag & 8) != 0) {
        /* can't trust local header, use central directory: */
        G.lrec.crc32 = G.pInfo->crc;
        G.lrec.csize = G.pInfo->compr_size;
        G.lrec.ucsize = G.pInfo->uncompr_size;
    }

    G.csize = G.lrec.csize;

    return PK_COOL;

} /* end function process_local_file_hdr() */


/*******************************/
/* Function getZip64Data() */
/*******************************/

int getZip64Data(const unsigned char *ef_buf, unsigned ef_len)
{
    unsigned eb_id;
    unsigned eb_len;

/*---------------------------------------------------------------------------
    This function scans the extra field for zip64 information, ie 8-byte
    versions of compressed file size, uncompressed file size, relative offset
    and a 4-byte version of disk start number.
    Sets both local header and central header fields.  Not terribly clever,
    but it means that this procedure is only called in one place.
  ---------------------------------------------------------------------------*/

    if (ef_len == 0 || ef_buf == NULL)
        return PK_COOL;

    Trace((stderr,"\ngetZip64Data: scanning extra field of length %u\n",
      ef_len));

    while (ef_len >= EB_HEADSIZE) {
        eb_id = makeword(EB_ID + ef_buf);
        eb_len = makeword(EB_LEN + ef_buf);

        if (eb_len > (ef_len - EB_HEADSIZE)) {
            /* discovered some extra field inconsistency! */
            Trace((stderr,
              "getZip64Data: block length %u > rest ef_size %u\n", eb_len,
              ef_len - EB_HEADSIZE));
            break;
        }
        if (eb_id == EF_PKSZ64) {

          int offset = EB_HEADSIZE;

          if (G.crec.ucsize == 0xffffffff || G.lrec.ucsize == 0xffffffff){
            G.lrec.ucsize = G.crec.ucsize = makeint64(offset + ef_buf);
            offset += sizeof(G.crec.ucsize);
          }
          if (G.crec.csize == 0xffffffff || G.lrec.csize == 0xffffffff){
            G.csize = G.lrec.csize = G.crec.csize = makeint64(offset + ef_buf);
            offset += sizeof(G.crec.csize);
          }
          if (G.crec.relative_offset_local_header == 0xffffffff){
            G.crec.relative_offset_local_header = makeint64(offset + ef_buf);
            offset += sizeof(G.crec.relative_offset_local_header);
          }
          if (G.crec.disk_number_start == 0xffff){
            G.crec.disk_number_start = (zuvl_t)makelong(offset + ef_buf);
            offset += sizeof(G.crec.disk_number_start);
          }
        }

        /* Skip this extra field block */
        ef_buf += (eb_len + EB_HEADSIZE);
        ef_len -= (eb_len + EB_HEADSIZE);
    }

    return PK_COOL;
} /* end function getZip64Data() */
