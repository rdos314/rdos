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


#include "oldunzip.h"

static int    do_seekable        OF((int lastchance));
static int    rec_find           OF((long, char *, int));
static int    process_zip_cmmnt  OF(());


static const char CannotAllocateBuffers[] =
  "error:  cannot allocate unzip buffers\n";

   /* process_zipfiles() strings */
   static const char CannotFindWildcardMatch[] =
     "%s:  cannot find any matches for wildcard specification \"%s\".\n";
   static const char FilesProcessOK[] =
     "%d archive%s successfully processed.\n";
   static const char ArchiveWarning[] =
     "%d archive%s had warnings but no fatal errors.\n";
   static const char ArchiveFatalError[] =
     "%d archive%s had fatal errors.\n";
   static const char FileHadNoZipfileDir[] =
     "%d file%s had no zipfile directory.\n";
   static const char ZipfileWasDir[] = "1 \"zipfile\" was a directory.\n";
   static const char ManyZipfilesWereDir[] =
     "%d \"zipfiles\" were directories.\n";
   static const char NoZipfileFound[] = "No zipfiles found.\n";

   /* do_seekable() strings */
   static const char CannotFindZipfileDirMsg[] =
     "%s:  cannot find zipfile directory in %s,\n\
        %sand cannot find %s, period.\n";
   static const char CannotFindEitherZipfile[] =
     "%s:  cannot find either %s or %s.\n";
   extern const char Zipnfo[];       /* in unzip.c */
   static const char Unzip[] = "UnZip DLL";
   static const char MaybeExe[] =
     "note:  %s may be a plain executable, not an archive\n";
   static const char CentDirNotInZipMsg[] = "\n\
   [%s]:\n\
     Zipfile is disk %lu of a multi-disk archive, and this is not the disk on\n\
     which the central zipfile directory begins (disk %lu).\n";
   static const char EndCentDirBogus[] =
     "\nwarning [%s]:  end-of-central-directory record claims this\n\
  is disk %lu but that the central directory starts on disk %lu; this is a\n\
  contradiction.  Attempting to process anyway.\n";
   static const char MaybePakBug[] = "warning [%s]:\
  zipfile claims to be last disk of a multi-part archive;\n\
  attempting to process anyway, assuming all parts have been concatenated\n\
  together in order.  Expect \"errors\" and warnings...true multi-part support\
\n  doesn't exist yet (coming soon).\n";
   static const char ExtraBytesAtStart[] =
     "warning [%s]:  %s extra byte%s at beginning or within zipfile\n\
  (attempting to process anyway)\n";

   static const char LogInitline[] = "Archive:  %s\n";

static const char MissingBytes[] =
  "error [%s]:  missing %s bytes in zipfile\n\
  (attempting to process anyway)\n";
static const char NullCentDirOffset[] =
  "error [%s]:  NULL central directory offset\n\
  (attempting to process anyway)\n";
static const char ZipfileEmpty[] = "warning [%s]:  zipfile is empty\n";
static const char CentDirStartNotFound[] =
  "error [%s]:  start of central directory not found;\n\
  zipfile corrupt.\n%s";
static const char Cent64EndSigSearchErr[] =
  "fatal error: read failure while seeking for End-of-centdir-64 signature.\n\
  This zipfile is corrupt.\n";
static const char Cent64EndSigSearchOff[] =
  "error: End-of-centdir-64 signature not where expected (prepended bytes?)\n\
  (attempting to process anyway)\n";
   static const char CentDirTooLong[] =
     "error [%s]:  reported length of central directory is\n\
  %s bytes too long (Atari STZip zipfile?  J.H.Holm ZIPSPLIT 1.1\n\
  zipfile?).  Compensating...\n";
   static const char CentDirEndSigNotFound[] = "\
  End-of-central-directory signature not found.  Either this file is not\n\
  a zipfile, or it constitutes one disk of a multi-part archive.  In the\n\
  latter case the central directory and zipfile comment will be found on\n\
  the last disk(s) of this archive.\n";
static const char ZipfileCommTrunc1[] =
  "\ncaution:  zipfile comment truncated\n";
   static const char NoZipfileComment[] =
     "There is no zipfile comment.\n";
   static const char ZipfileCommentDesc[] =
     "The zipfile comment is %u bytes long and contains the following text:\n";
   static const char ZipfileCommBegin[] =
     "======================== zipfile comment begins\
 ==========================\n";
   static const char ZipfileCommEnd[] =
     "========================= zipfile comment ends\
 ===========================\n";
   static const char ZipfileCommTrunc2[] =
     "\n  The zipfile comment is truncated.\n";



/*******************************/
/* Function process_zipfiles() */
/*******************************/

int process_zipfiles()    /* return PK-type error code */
{
    char *lastzipfn = (char *)NULL;
    int NumWinFiles, NumLoseFiles, NumWarnFiles;
    int NumMissDirs, NumMissFiles;
    int error=0, error_in_archive=0;


/*---------------------------------------------------------------------------
    Start by allocating buffers and (re)constructing the various PK signature
    strings.
  ---------------------------------------------------------------------------*/

    UnzipClass.FSearchHold = UnzipClass.FInBuf + INBUFSIZ;     /* to check for boundary-spanning sigs */

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

    char *inputfn;

    while ((inputfn = do_wild(G.wildzipfn)) != 0) {
        UnzipClass.SetInputFile(inputfn);
        Trace("do_wild( %s ) returns %s\n", G.wildzipfn, inputfn);

        lastzipfn = inputfn;

        /* print a blank line between the output of different zipfiles */
        if (!uO.qflag  &&  error != PK_NOZIP  &&  error != IZ_DIR
            && (NumWinFiles+NumLoseFiles+NumWarnFiles+NumMissFiles) > 0)
            Info(0, "\n");

        if ((error = do_seekable(0)) == PK_WARN)
            ++NumWarnFiles;
        else if (error == IZ_DIR)
            ++NumMissDirs;
        else if (error == PK_NOZIP)
            ++NumMissFiles;
        else if (error != PK_OK)
            ++NumLoseFiles;
        else
            ++NumWinFiles;

        Trace("do_seekable(0) returns %d\n", error);
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
                    Info(0x401, CannotFindWildcardMatch,
                      (uO.zipinfo_mode ? Zipnfo : Unzip),
                      G.wildzipfn);
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

            UnzipClass.SetInputFile(lastzipfn);

            NumMissDirs = NumMissFiles = 0;
            error_in_archive = PK_COOL;

            error = do_seekable(1);
            Trace("do_seekable(1) returns %d\n", error);
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
            Info(0x401, "\n");
        if ((NumWinFiles > 1) ||
            (NumWinFiles == 1 &&
             NumMissDirs + NumMissFiles + NumLoseFiles + NumWarnFiles > 0))
            Info(0x401, FilesProcessOK,
              NumWinFiles, (NumWinFiles == 1)? " was" : "s were");
        if (NumWarnFiles > 0)
            Info(0x401, ArchiveWarning,
              NumWarnFiles, (NumWarnFiles == 1)? "" : "s");
        if (NumLoseFiles > 0)
            Info(0x401, ArchiveFatalError,
              NumLoseFiles, (NumLoseFiles == 1)? "" : "s");
        if (NumMissFiles > 0)
            Info(0x401, FileHadNoZipfileDir, NumMissFiles,
              (NumMissFiles == 1)? "" : "s");
        if (NumMissDirs == 1)
            Info(0x401, ZipfileWasDir);
        else if (NumMissDirs > 0)
            Info(0x401, ManyZipfilesWereDir, NumMissDirs);
        if (NumWinFiles + NumLoseFiles + NumWarnFiles == 0)
            Info(0x401, NoZipfileFound);
    }

    /* free allocated memory */
    free_G_buffers();

    return error_in_archive;

} /* end function process_zipfiles() */





/*****************************/
/* Function free_G_buffers() */
/*****************************/

void free_G_buffers()     /* releases all memory allocated in global vars */
{
    unsigned i;

   if (G.key != (char *)NULL) {
        free(G.key);
        G.key = (char *)NULL;
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

    if (stat(UnzipClass.FInputFileName.GetData(), &G.statbuf) ||
        (error = S_ISDIR(G.statbuf.st_mode)) != 0)
    {
        if (lastchance && (uO.qflag < 3)) {
            if (G.no_ecrec)
                Info(0x401, CannotFindZipfileDirMsg,
                  (uO.zipinfo_mode ? Zipnfo : Unzip),
                  G.wildzipfn, uO.zipinfo_mode? "  " : "", UnzipClass.FInputFileName.GetData());
            else
                Info(0x401, CannotFindEitherZipfile,
                  (uO.zipinfo_mode ? Zipnfo : Unzip),
                  G.wildzipfn, UnzipClass.FInputFileName.GetData());
        }
        return error? IZ_DIR : PK_NOZIP;
    }
    UnzipClass.FZipLen = G.statbuf.st_size;

    if (UnzipClass.OpenInputFile())   /* this should never happen, given */
        return PK_NOZIP;        /*  the stat() test above, but... */


/*---------------------------------------------------------------------------
    Find and process the end-of-central-directory header.  UnZip need only
    check last 65557 bytes of zipfile:  comment may be up to 65535, end-of-
    central-directory record is 18 bytes, and signature itself is 4 bytes;
    add some to allow for appended garbage.  Since ZipInfo is often used as
    a debugging tool, search the whole zipfile if zipinfo_mode is true.
  ---------------------------------------------------------------------------*/

    UnzipClass.FBufStart = 0;
    UnzipClass.FInPtr = UnzipClass.FInBuf;

    if ( (!uO.zipinfo_mode && !uO.qflag
         )
       )
        Info(0, LogInitline, UnzipClass.FInputFileName.GetData());

    if ( (error_in_archive = UnzipClass.GetCentralHeader(MIN(UnzipClass.FZipLen, 66000L)))
         > PK_WARN )
    {
        RdosCloseFile(UnzipClass.FInputHandle);

        if (maybe_exe)
            Info(0x401, MaybeExe, UnzipClass.FInputFileName.GetData());
        if (lastchance)
            return error_in_archive;
        else {
            G.no_ecrec = TRUE;    /* assume we found wrong file:  e.g., */
            return PK_NOZIP;       /*  unzip instead of unzip.zip */
        }
    }

    if ((uO.zflag > 0) && !uO.zipinfo_mode) { /* unzip: zflag = comment ONLY */
        RdosCloseFile(UnzipClass.FInputHandle);
        return error_in_archive;
    }

/*---------------------------------------------------------------------------
    Test the end-of-central-directory info for incompatibilities (multi-disk
    archives) or inconsistencies (missing or extra bytes in zipfile).
  ---------------------------------------------------------------------------*/

    error = !uO.zipinfo_mode && (UnzipClass.FHeader.number_this_disk != 0);

    if (uO.zipinfo_mode &&
        UnzipClass.FHeader.number_this_disk != UnzipClass.FHeader.num_disk_start_cdir)
    {
        if (UnzipClass.FHeader.number_this_disk > UnzipClass.FHeader.num_disk_start_cdir) {
            Info(0x401, CentDirNotInZipMsg, UnzipClass.FInputFileName.GetData(),
              (unsigned long)UnzipClass.FHeader.number_this_disk,
              (unsigned long)UnzipClass.FHeader.num_disk_start_cdir);
            error_in_archive = PK_FIND;
            too_weird_to_continue = TRUE;
        } else {
            Info(0x401, EndCentDirBogus, UnzipClass.FInputFileName.GetData(),
              (unsigned long)UnzipClass.FHeader.number_this_disk,
              (unsigned long)UnzipClass.FHeader.num_disk_start_cdir);
            error_in_archive = PK_WARN;
        }
    }

    if (!too_weird_to_continue) {  /* (relatively) normal zipfile:  go for it */
        if (error) {
            Info(0x401, MaybePakBug, UnzipClass.FInputFileName.GetData());
            error_in_archive = PK_WARN;
        }
        if ((UnzipClass.FExtraBytes = UnzipClass.FRealHeaderOffset-UnzipClass.FExpectHeaderOffset) <
            (long)0)
        {
            Info(0x401, MissingBytes,
              UnzipClass.FInputFileName.GetData(), fzofft((-UnzipClass.FExtraBytes), NULL, NULL));
            error_in_archive = PK_ERR;
        } else if (UnzipClass.FExtraBytes > 0) {
            if ((UnzipClass.FHeader.offset_start_central_directory == 0) &&
                (UnzipClass.FHeader.size_central_directory != 0))   /* zip 1.5 -go bug */
            {
                Info(0x401, NullCentDirOffset, UnzipClass.FInputFileName.GetData());
                UnzipClass.FHeader.offset_start_central_directory = UnzipClass.FExtraBytes;
                UnzipClass.FExtraBytes = 0;
                error_in_archive = PK_ERR;
            }
            else {
                Info(0x401, ExtraBytesAtStart, UnzipClass.FInputFileName.GetData(),
                  fzofft(UnzipClass.FExtraBytes, NULL, NULL),
                  (UnzipClass.FExtraBytes == 1)? "":"s");
                error_in_archive = PK_WARN;
            }
        }

    /*-----------------------------------------------------------------------
        Check for empty zipfile and exit now if so.
      -----------------------------------------------------------------------*/

        if (G.expect_ecrec_offset==0L && UnzipClass.FHeader.size_central_directory==0) {
            if (uO.zipinfo_mode)
                Info(0, "%sEmpty zipfile.\n",
                  uO.lflag>9? "\n  " : "");
            else
                Info(0x401, ZipfileEmpty, UnzipClass.FInputFileName.GetData());
            RdosCloseFile(UnzipClass.FInputHandle);
            return (error_in_archive > PK_WARN)? error_in_archive : PK_WARN;
        }

    /*-----------------------------------------------------------------------
        Compensate for missing or extra bytes, and seek to where the start
        of central directory should be.  If header not found, uncompensate
        and try again (necessary for at least some Atari archives created
        with STZip, as well as archives created by J.H. Holm's ZIPSPLIT 1.1).
      -----------------------------------------------------------------------*/

        error = UnzipClass.Seek(UnzipClass.FHeader.offset_start_central_directory);
        if (error == PK_BADERR) {
            RdosCloseFile(UnzipClass.FInputHandle);
            return PK_BADERR;
        }
        if ((error != PK_OK) || (UnzipClass.ReadBuf(G.sig, 4) == 0) ||
            memcmp(G.sig, central_hdr_sig, 4))
        {
            long tmp = UnzipClass.FExtraBytes;

            UnzipClass.FExtraBytes = 0;
            error = UnzipClass.Seek(UnzipClass.FHeader.offset_start_central_directory);
            if ((error != PK_OK) || (UnzipClass.ReadBuf(G.sig, 4) == 0) ||
                memcmp(G.sig, central_hdr_sig, 4))
            {
                if (error != PK_BADERR)
                  Info(0x401, CentDirStartNotFound, UnzipClass.FInputFileName.GetData(), ReportMsg);
                RdosCloseFile(UnzipClass.FInputHandle);
                return (error != PK_OK ? error : PK_BADERR);
            }
            Info(0x401, CentDirTooLong,
              UnzipClass.FInputFileName.GetData(), fzofft((-tmp), NULL, NULL));
            error_in_archive = PK_ERR;
        }

    /*-----------------------------------------------------------------------
        Seek to the start of the central directory one last time, since we
        have just read the first entry's signature bytes; then list, extract
        or test member files as instructed, and close the zipfile.
      -----------------------------------------------------------------------*/

        error = UnzipClass.Seek(UnzipClass.FHeader.offset_start_central_directory);
        if (error != PK_OK) {
            RdosCloseFile(UnzipClass.FInputHandle);
            return error;
        }

        Trace("about to extract/list files (error = %d)\n",
          error_in_archive);

        {
            error = extract_or_test_files();   /* EXTRACT OR TEST 'EM */

            Trace("done with extract/list files (error = %d)\n",
                   error);
        }

        if (error > error_in_archive)   /* don't overwrite stronger error */
            error_in_archive = error;   /*  with (for example) a warning */
    } /* end if (!too_weird_to_continue) */

    RdosCloseFile(UnzipClass.FInputHandle);
    return error_in_archive;

} /* end function do_seekable() */




