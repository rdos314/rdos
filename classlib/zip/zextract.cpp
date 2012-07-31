/*
  Copyright (c) 1990-2009 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2009-Jan-02 or later
  (the contents of which are also included in unzip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/*---------------------------------------------------------------------------

  extract.c

  This file contains the high-level routines ("driver routines") for extrac-
  ting and testing zipfile members.  It calls the low-level routines in files
  explode.c, inflate.c, unreduce.c and unshrink.c.

  Contains:  extract_or_test_files()
             store_info()
             find_compr_idx()
             extract_or_test_entrylist()
             extract_or_test_member()
             memflush()
             extract_izvms_block()    (VMS or VMS_TEXT_CONV)
             set_deferred_symlink()   (SYMLINKS only)
             fnfilter()
             dircomp()                (SET_DIR_ATTRIB only)
             UZbunzip2()              (USE_BZIP2 only)

  ---------------------------------------------------------------------------*/


#define __EXTRACT_C     /* identifies this source module */
#include "oldunzip.h"

#define NEWLINE "\r\n"

#define GRRDUMP(buf,len) { \
    int i, j; \
 \
    for (j = 0;  j < (len)/16;  ++j) { \
        printf("        "); \
        for (i = 0;  i < 16;  ++i) \
            printf("%02x ", (unsigned char)(buf)[i+(j<<4)]); \
        printf("\n        "); \
        for (i = 0;  i < 16;  ++i) { \
            char c = (char)(buf)[i+(j<<4)]; \
 \
            if (c == '\n') \
                printf("\\n "); \
            else if (c == '\r') \
                printf("\\r "); \
            else \
                printf(" %c ", c); \
        } \
        printf("\n"); \
    } \
    if ((len) % 16) { \
        printf("        "); \
        for (i = j<<4;  i < (len);  ++i) \
            printf("%02x ", (unsigned char)(buf)[i]); \
        printf("\n        "); \
        for (i = j<<4;  i < (len);  ++i) { \
            char c = (char)(buf)[i]; \
 \
            if (c == '\n') \
                printf("\\n "); \
            else if (c == '\r') \
                printf("\\r "); \
            else \
                printf(" %c ", c); \
        } \
        printf("\n"); \
    } \
}

static int extract_or_test_entrylist OF((unsigned numchunk,
                unsigned long *pfilnum, unsigned long *pnum_bad_pwd, long *pold_extra_bytes,
                unsigned *pnum_dirs, direntry **pdirlist,
                int error_in_archive));
static int extract_or_test_member OF(());
   static int test_compr_eb OF((unsigned char *eb, unsigned eb_size,
        unsigned compr_offset,
        int (*test_uc_ebdata)(unsigned char *eb, unsigned eb_size,
                              unsigned char *eb_ucptr, unsigned long eb_ucsize)));
   static int dircomp OF((const void *a, const void *b));



/*******************************/
/*  Strings used in extract.c  */
/*******************************/

static const char VersionMsg[] =
  "   skipping: %-22s  need %s compat. v%u.%u (can do v%u.%u)\n";
static const char ComprMsgNum[] =
  "   skipping: %-22s  unsupported compression method %u\n";
   static const char ComprMsgName[] =
     "   skipping: %-22s  `%s' method not supported\n";
static const char FilNamMsg[] =
  "%s:  bad filename length (%s)\n";
   static const char WarnNoMemCFName[] =
     "%s:  warning, no memory for comparison with local header\n";
   static const char LvsCFNamMsg[] =
     "%s:  mismatching \"local\" filename (%s),\n\
         continuing with \"central\" filename version\n";
static const char WrnStorUCSizCSizDiff[] =
  "%s:  ucsize %s <> csize %s for STORED entry\n\
         continuing with \"compressed\" size value\n";
static const char ExtFieldMsg[] =
  "%s:  bad extra field length (%s)\n";
static const char OffsetMsg[] =
  "file #%lu:  bad zipfile offset (%s):  %ld\n";
static const char ExtractMsg[] =
  "%8sing: %-22s  %s%s";
   static const char LengthMsg[] =
     "%s  %s:  %s bytes required to uncompress to %s bytes;\n    %s\
      supposed to require %s bytes%s%s%s\n";

static const char BadFileCommLength[] = "%s:  bad file comment length\n";
static const char LocalHdrSig[] = "local header sig";
static const char BadLocalHdr[] = "file #%lu:  bad local header\n";
static const char AttemptRecompensate[] =
  "  (attempting to re-compensate)\n";
   static const char BackslashPathSep[] =
     "warning:  %s appears to use backslashes as path separators\n";
static const char AbsolutePathWarning[] =
  "warning:  stripped absolute path spec from %s\n";
static const char SkipVolumeLabel[] =
  "   skipping: %-22s  %svolume label\n";

   static const char DirlistEntryNoMem[] =
     "warning:  cannot alloc memory for dir times/permissions/UID/GID\n";
   static const char DirlistSortNoMem[] =
     "warning:  cannot alloc memory to sort dir times/perms/etc.\n";
   static const char DirlistSetAttrFailed[] =
     "warning:  set times/attribs failed for %s\n";
   static const char DirlistFailAttrSum[] =
     "     failed setting times/attribs for %lu dir entries";

   static const char ReplaceQuery[] =
     "replace %s? [y]es, [n]o, [A]ll, [N]one, [r]ename: ";
   static const char AssumeNone[] =
     " NULL\n(EOF or read error, treating as \"[N]one\" ...)\n";
   static const char NewNameQuery[] = "new name: ";
   static const char InvalidResponse[] =
     "error:  invalid response [%s]\n";

static const char ErrorInArchive[] =
  "At least one %serror was detected in %s.\n";
static const char ZeroFilesTested[] =
  "Caution:  zero files tested in %s.\n";

   static const char VMSFormatQuery[] =
     "\n%s:  stored in VMS format.  Extract anyway? (y/n) ";

   static const char SkipCannotGetPasswd[] =
     "   skipping: %-22s  unable to get password\n";
   static const char SkipIncorrectPasswd[] =
     "   skipping: %-22s  incorrect password\n";
   static const char FilesSkipBadPasswd[] =
     "%lu file%s skipped because of incorrect password.\n";
   static const char MaybeBadPasswd[] =
     "    (may instead be incorrect password)\n";

static const char NoErrInCompData[] =
  "No errors detected in compressed data of %s.\n";
static const char NoErrInTestedFiles[] =
  "No errors detected in %s for the %lu file%s tested.\n";
static const char FilesSkipped[] =
  "%lu file%s skipped because of unsupported compression or encoding.\n";

static const char ErrUnzipFile[] = "  error:  %s%s %s\n";
static const char ErrUnzipNoFile[] = "\n  error:  %s%s\n";
static const char NotEnoughMem[] = "not enough memory to ";
static const char InvalidComprData[] = "invalid compressed data to ";
static const char Inflate[] = "inflate";

   static const char Explode[] = "explode";
   static const char Unshrink[] = "unshrink";

   static const char FileTruncated[] =
     "warning:  %s is probably truncated\n";

static const char FileUnknownCompMethod[] =
  "%s:  unknown compression method\n";
static const char BadCRC[] = " bad CRC %08lx  (should be %08lx)\n";

      /* TruncEAs[] also used in OS/2 mapname(), close_outfile() */
char const TruncEAs[] = " compressed EA data missing (%d bytes)%s";
char const TruncNTSD[] =
  " compressed WinNT security data missing (%d bytes)%s";

   static const char InconsistEFlength[] = "bad extra-field entry:\n \
     EF block length (%u bytes) exceeds remaining EF data (%u bytes)\n";
   static const char InvalidComprDataEAs[] =
     " invalid compressed data for EAs\n";
   static const char UnsuppNTSDVersEAs[] =
     " unsupported NTSD EAs version %d\n";
   static const char BadCRC_EAs[] = " bad CRC for extended attributes\n";
   static const char UnknComprMethodEAs[] =
     " unknown compression method for EAs (%u)\n";
   static const char NotEnoughMemEAs[] =
     " out of memory while inflating EAs\n";
   static const char UnknErrorEAs[] =
     " unknown error on extended attributes\n";

static const char UnsupportedExtraField[] =
  "\nerror:  unsupported extra-field compression type (%u)--skipping\n";
static const char BadExtraFieldCRC[] =
  "error [%s]:  bad extra-field CRC %08lx (should be %08lx)\n";





/**************************************/
/*  Function extract_or_test_files()  */
/**************************************/

int extract_or_test_files()    /* return PK-type error code */
{
    unsigned i, j;
    long cd_bufstart;
    unsigned char *cd_inptr;
    int cd_incnt;
    unsigned long filnum=0L, blknum=0L;
    int reached_end;
    int no_endsig_found;
    int error, error_in_archive=PK_COOL;
    int *fn_matched=NULL, *xn_matched=NULL;
    zucn_t members_processed;
    unsigned long num_skipped=0L, num_bad_pwd=0L;
    long old_extra_bytes = 0L;
    unsigned num_dirs=0;
    direntry *dirlist=(direntry *)NULL;
    direntry **sorted_dirlist=(direntry **)NULL;

    /*
     * First, two general initializations are applied. These have been moved
     * here from process_zipfiles() because they are only needed for accessing
     * and/or extracting the data content of the zip archive.
     */

    /* b) check out if specified extraction root directory exists */
    if (uO.exdir != (char *)NULL && G.extract_flag) {
        G.create_dirs = !uO.fflag;
        if ((error = checkdir(uO.exdir, ROOT)) > MPN_INF_SKIP) {
            /* out of memory, or file in way */
            return (error == MPN_NOMEM ? PK_MEM : PK_ERR);
        }
    }

/*---------------------------------------------------------------------------
    The basic idea of this function is as follows.  Since the central di-
    rectory lies at the end of the zipfile and the member files lie at the
    beginning or middle or wherever, it is not very desirable to simply
    read a central directory entry, jump to the member and extract it, and
    then jump back to the central directory.  In the case of a large zipfile
    this would lead to a whole lot of disk-grinding, especially if each mem-
    ber file is small.  Instead, we read from the central directory the per-
    tinent information for a block of files, then go extract/test the whole
    block.  Thus this routine contains two small(er) loops within a very
    large outer loop:  the first of the small ones reads a block of files
    from the central directory; the second extracts or tests each file; and
    the outer one loops over blocks.  There's some file-pointer positioning
    stuff in between, but that's about it.  Btw, it's because of this jump-
    ing around that we can afford to be lenient if an error occurs in one of
    the member files:  we should still be able to go find the other members,
    since we know the offset of each from the beginning of the zipfile.
  ---------------------------------------------------------------------------*/

    UnzipClass.FCurrFile = &UnzipClass.FFileArr[0];

    G.newzip = TRUE;
    G.reported_backslash = FALSE;

    /* malloc space for check on unmatched filespecs (OK if one or both NULL) */
    if (G.filespecs > 0  &&
        (fn_matched=(int *)malloc(G.filespecs*sizeof(int))) != (int *)NULL)
        for (i = 0;  i < G.filespecs;  ++i)
            fn_matched[i] = FALSE;
    if (G.xfilespecs > 0  &&
        (xn_matched=(int *)malloc(G.xfilespecs*sizeof(int))) != (int *)NULL)
        for (i = 0;  i < G.xfilespecs;  ++i)
            xn_matched[i] = FALSE;

/*---------------------------------------------------------------------------
    Begin main loop over blocks of member files.  We know the entire central
    directory is on this disk:  we would not have any of this information un-
    less the end-of-central-directory record was on this disk, and we would
    not have gotten to this routine unless this is also the disk on which
    the central directory starts.  In practice, this had better be the ONLY
    disk in the archive, but we'll add multi-disk support soon.
  ---------------------------------------------------------------------------*/

    members_processed = 0;
    no_endsig_found = FALSE;
    reached_end = FALSE;
    while (!reached_end) {
        j = 0;

        /*
         * Loop through files in central directory, storing offsets, file
         * attributes, case-conversion and text-conversion flags until block
         * size is reached.
         */

        while ((j < DIR_BLKSIZ)) {
            UnzipClass.FCurrFile = &UnzipClass.FFileArr[j];

            if (UnzipClass.ReadBuf(G.sig, 4) == 0) {
                error_in_archive = PK_EOF;
                reached_end = TRUE;     /* ...so no more left to do */
                break;
            }
            if (memcmp(G.sig, central_hdr_sig, 4)) {  /* is it a new entry? */
                /* no new central directory entry
                 * -> is the number of processed entries compatible with the
                 *    number of entries as stored in the end_central record?
                 */
                if ((members_processed
                     & (G.ecrec.have_ecr64 ? MASK_ZUCN64 : MASK_ZUCN16))
                    == G.ecrec.total_entries_central_dir) {
                    /* yes, so look if we ARE back at the end_central record
                     */
                    no_endsig_found =
                      ( (memcmp(G.sig,
                                (G.ecrec.have_ecr64 ?
                                 end_central64_sig : end_central_sig),
                                4) != 0)
                       && (!G.ecrec.is_zip64_archive)
                       && (memcmp(G.sig, end_central_sig, 4) != 0)
                      );
                } else {
                    /* no; we have found an error in the central directory
                     * -> report it and stop searching for more Zip entries
                     */
                    Info(0x401, CentSigMsg, j + blknum*DIR_BLKSIZ + 1);
                    Info(0x401, ReportMsg);
                    error_in_archive = PK_BADERR;
                }
                reached_end = TRUE;     /* ...so no more left to do */
                break;
            }

            error = UnzipClass.AddFile();
            if (error != PK_COOL)
                break;

            if (G.process_all_files) {
                ++j;  /* file is OK; info[] stored; continue with next */
            } else {
                int   do_this_file;

                if (G.filespecs == 0)
                    do_this_file = TRUE;
                else {  /* check if this entry matches an `include' argument */
                    do_this_file = FALSE;
                    for (i = 0; i < G.filespecs; i++)
                        if (match(UnzipClass.FCurrFileName, G.pfnames[i], uO.C_flag)) {
                            do_this_file = TRUE;  /* ^-- ignore case or not? */
                            if (fn_matched)
                                fn_matched[i] = TRUE;
                            break;       /* found match, so stop looping */
                        }
                }
                if (do_this_file) {  /* check if this is an excluded file */
                    for (i = 0; i < G.xfilespecs; i++)
                        if (match(UnzipClass.FCurrFileName, G.pxnames[i], uO.C_flag)) {
                            do_this_file = FALSE; /* ^-- ignore case or not? */
                            if (xn_matched)
                                xn_matched[i] = TRUE;
                            break;
                        }
                }
                if (do_this_file) {
                    ++j;            /* file is OK */
                }
            } /* end if (process_all_files) */

            members_processed++;

        } /* end while-loop (adding files to current block) */

        /* save position in central directory so can come back later */
        cd_bufstart = UnzipClass.FBufStart;
        cd_inptr = (unsigned char *)UnzipClass.FInPtr;
        cd_incnt = UnzipClass.FInCount;

    /*-----------------------------------------------------------------------
        Second loop:  process files in current block, extracting or testing
        each one.
      -----------------------------------------------------------------------*/

        error = extract_or_test_entrylist(j,
                        &filnum, &num_bad_pwd, &old_extra_bytes,
                        &num_dirs, &dirlist,
                        error_in_archive);
        if (error != PK_COOL) {
            if (error > error_in_archive)
                error_in_archive = error;
            /* ...and keep going (unless disk full or user break) */
            if (UnzipClass.FDiskFull > 1 || error_in_archive == IZ_CTRLC) {
                /* clear reached_end to signal premature stop ... */
                reached_end = FALSE;
                /* ... and cancel scanning the central directory */
                break;
            }
        }


        /*
         * Jump back to where we were in the central directory, then go and do
         * the next batch of files.
         */

        RdosSetFilePos(UnzipClass.FInputHandle, cd_bufstart);
        UnzipClass.FBufStart = RdosGetFilePos(UnzipClass.FInputHandle);
        RdosReadFile(UnzipClass.FInputHandle, UnzipClass.FInBuf, INBUFSIZ);  /* been here before... */
        UnzipClass.FInPtr = (char *)cd_inptr;
        UnzipClass.FInCount = cd_incnt;
        ++blknum;

    } /* end while-loop (blocks of files in central directory) */

/*---------------------------------------------------------------------------
    Go back through saved list of directories, sort and set times/perms/UIDs
    and GIDs from the deepest level on up.
  ---------------------------------------------------------------------------*/

    if (num_dirs > 0) {
        sorted_dirlist = (direntry **)malloc(num_dirs*sizeof(direntry *));
        if (sorted_dirlist == (direntry **)NULL) {
            Info(0x401, DirlistSortNoMem);
            while (dirlist != (direntry *)NULL) {
                direntry *d = dirlist;

                dirlist = dirlist->next;
                free(d);
            }
        } else {
            unsigned long ndirs_fail = 0;

            if (num_dirs == 1)
                sorted_dirlist[0] = dirlist;
            else {
                for (i = 0;  i < num_dirs;  ++i) {
                    sorted_dirlist[i] = dirlist;
                    dirlist = dirlist->next;
                }
                qsort((char *)sorted_dirlist, num_dirs, sizeof(direntry *),
                  dircomp);
            }

            Trace("setting directory times/perms/attributes\n");
            for (i = 0;  i < num_dirs;  ++i) {
                direntry *d = sorted_dirlist[i];

                Trace("dir = %s\n", d->fn);
                if ((error = set_direc_attribs(d)) != PK_OK) {
                    ndirs_fail++;
                    Info(0x201,DirlistSetAttrFailed, d->fn);
                    if (!error_in_archive)
                        error_in_archive = error;
                }
                free(d);
            }
            free(sorted_dirlist);
            if (!uO.tflag && !uO.qflag) {
                if (ndirs_fail > 0)
                    Info(0, DirlistFailAttrSum, ndirs_fail);
            }
        }
    }

/*---------------------------------------------------------------------------
    Check for unmatched filespecs on command line and print warning if any
    found.  Free allocated memory.  (But suppress check when central dir
    scan was interrupted prematurely.)
  ---------------------------------------------------------------------------*/

    if (fn_matched) {
        if (reached_end) for (i = 0;  i < G.filespecs;  ++i)
            if (!fn_matched[i]) {
                Info(1, FilenameNotMatched, G.pfnames[i]);
                if (error_in_archive <= PK_WARN)
                    error_in_archive = PK_FIND;   /* some files not found */
            }
        free((void *)fn_matched);
    }
    if (xn_matched) {
        if (reached_end) for (i = 0;  i < G.xfilespecs;  ++i)
            if (!xn_matched[i])
                Info(0x401, ExclFilenameNotMatched, G.pxnames[i]);
        free((void *)xn_matched);
    }

/*---------------------------------------------------------------------------
    Now, all locally allocated memory has been released.  When the central
    directory processing has been interrupted prematurely, it is safe to
    return immediately.  All completeness checks and summary messages are
    skipped in this case.
  ---------------------------------------------------------------------------*/
    if (!reached_end)
        return error_in_archive;

/*---------------------------------------------------------------------------
    Double-check that we're back at the end-of-central-directory record, and
    print quick summary of results, if we were just testing the archive.  We
    send the summary to stdout so that people doing the testing in the back-
    ground and redirecting to a file can just do a "tail" on the output file.
  ---------------------------------------------------------------------------*/

    if (no_endsig_found) {                      /* just to make sure */
        Info(0x401, EndSigMsg);
        Info(0x401, ReportMsg);
        if (!error_in_archive)       /* don't overwrite stronger error */
            error_in_archive = PK_WARN;
    }
    if (uO.tflag) {
        unsigned long num = filnum - num_bad_pwd;

        if (uO.qflag < 2) {        /* GRR 930710:  was (uO.qflag == 1) */
            if (error_in_archive)
                Info(0, ErrorInArchive,
                  (error_in_archive == PK_WARN)? "warning-" : "", UnzipClass.FInputFileName.GetData());
            else if (num == 0L)
                Info(0, ZeroFilesTested, UnzipClass.FInputFileName.GetData());
            else if (G.process_all_files && (num_skipped+num_bad_pwd == 0L))
                Info(0, NoErrInCompData, UnzipClass.FInputFileName.GetData());
            else
                Info(0, NoErrInTestedFiles, UnzipClass.FInputFileName.GetData(), num, (num==1L)? "":"s");
            if (num_skipped > 0L)
                Info(0, FilesSkipped, num_skipped, (num_skipped==1L)? "":"s");
            if (num_bad_pwd > 0L)
                Info(0, FilesSkipBadPasswd, num_bad_pwd, (num_bad_pwd==1L)? "":"s");
        }
    }

    /* give warning if files not tested or extracted (first condition can still
     * happen if zipfile is empty and no files specified on command line) */

    if ((filnum == 0) && error_in_archive <= PK_WARN) {
        if (num_skipped > 0L)
            error_in_archive = IZ_UNSUP; /* unsupport. compression/encryption */
        else
            error_in_archive = PK_FIND;  /* no files found at all */
    }
    else if ((filnum == num_bad_pwd) && error_in_archive <= PK_WARN)
        error_in_archive = IZ_BADPWD;    /* bad passwd => all files skipped */
    else if ((num_skipped > 0L) && error_in_archive <= PK_WARN)
        error_in_archive = IZ_UNSUP;     /* was PK_WARN; Jean-loup complained */
    else if ((num_bad_pwd > 0L) && !error_in_archive)
        error_in_archive = PK_WARN;

    return error_in_archive;

} /* end function extract_or_test_files() */







/******************************************/
/*  Function extract_or_test_entrylist()  */
/******************************************/

static int extract_or_test_entrylist(unsigned numchunk,
                unsigned long *pfilnum, unsigned long *pnum_bad_pwd, long *pold_extra_bytes,
                unsigned *pnum_dirs, direntry **pdirlist,
                int error_in_archive)    /* return PK-type error code */
{
    unsigned i;
    int renamed, query;
    int skip_entry;
    long bufstart, inbuf_offset, request;
    int error, errcode;

/* possible values for local skip_entry flag: */
#define SKIP_NO         0       /* do not skip this entry */
#define SKIP_Y_EXISTING 1       /* skip this entry, do not overwrite file */
#define SKIP_Y_NONEXIST 2       /* skip this entry, do not create new file */

    /*-----------------------------------------------------------------------
        Second loop:  process files in current block, extracting or testing
        each one.
      -----------------------------------------------------------------------*/

    for (i = 0; i < numchunk; ++i) {
        (*pfilnum)++;   /* *pfilnum = i + blknum*DIR_BLKSIZ + 1; */
        UnzipClass.FCurrFile = &UnzipClass.FFileArr[i];

        /* if the target position is not within the current input buffer
         * (either haven't yet read enough, or (maybe) skipping back-
         * ward), skip to the target position and reset readbuf(). */

        /* seek_zipf(pInfo->offset);  */
        request = UnzipClass.FCurrFile->offset + UnzipClass.FExtraBytes;
        inbuf_offset = request % INBUFSIZ;
        bufstart = request - inbuf_offset;

        Trace("\ndebug: request = %ld, inbuf_offset = %ld\n",
          (long)request, (long)inbuf_offset);
        Trace("debug: bufstart = %ld, cur_zipfile_bufstart = %ld\n",
          (long)bufstart, (long)UnzipClass.FBufStart);
        if (request < 0) {
            Info(0x401, SeekMsg,
              UnzipClass.FInputFileName.GetData(), ReportMsg);
            error_in_archive = PK_ERR;
            if (*pfilnum == 1 && UnzipClass.FExtraBytes != 0L) {
                Info(0x401, AttemptRecompensate);
                *pold_extra_bytes =  UnzipClass.FExtraBytes;
                 UnzipClass.FExtraBytes = 0L;
                request = UnzipClass.FCurrFile->offset;  /* could also check if != 0 */
                inbuf_offset = request % INBUFSIZ;
                bufstart = request - inbuf_offset;
                Trace("debug: request = %ld, inbuf_offset = %ld\n",
                  (long)request, (long)inbuf_offset);
                Trace("debug: bufstart = %ld, cur_zipfile_bufstart = %ld\n",
                  (long)bufstart, (long)UnzipClass.FBufStart);
                /* try again */
                if (request < 0) {
                    Trace("debug: recompensated request still < 0\n");
                    Info(0x401, SeekMsg,
                      UnzipClass.FInputFileName.GetData(), ReportMsg);
                    error_in_archive = PK_BADERR;
                    continue;
                }
            } else {
                error_in_archive = PK_BADERR;
                continue;  /* this one hosed; try next */
            }
        }

        if (bufstart != UnzipClass.FBufStart) {
            Trace("debug: bufstart != cur_zipfile_bufstart\n");

            RdosSetFilePos(UnzipClass.FInputHandle, bufstart);
            UnzipClass.FBufStart = RdosGetFilePos(UnzipClass.FInputHandle);
            if ((UnzipClass.FInCount = RdosReadFile(UnzipClass.FInputHandle, UnzipClass.FInBuf, INBUFSIZ)) <= 0)
            {
                Info(0x401, OffsetMsg,
                  *pfilnum, "lseek", (long)bufstart);
                error_in_archive = PK_BADERR;
                continue;   /* can still do next file */
            }
            UnzipClass.FInPtr = UnzipClass.FInBuf + (int)inbuf_offset;
            UnzipClass.FInCount -= (int)inbuf_offset;
        } else {
            UnzipClass.FInCount += (int)(UnzipClass.FInPtr-UnzipClass.FInBuf) - (int)inbuf_offset;
            UnzipClass.FInPtr = UnzipClass.FInBuf + (int)inbuf_offset;
        }

        /* should be in proper position now, so check for sig */
        if (UnzipClass.ReadBuf(G.sig, 4) == 0) {  /* bad offset */
            Info(0x401, OffsetMsg,
              *pfilnum, "EOF", (long)request);
            error_in_archive = PK_BADERR;
            continue;   /* but can still try next one */
        }
        if (memcmp(G.sig, local_hdr_sig, 4)) {
            Info(0x401, OffsetMsg,
              *pfilnum, LocalHdrSig, (long)request);
            /*
                GRRDUMP(G.sig, 4)
                GRRDUMP(local_hdr_sig, 4)
             */
            error_in_archive = PK_ERR;
            if ((*pfilnum == 1 &&  UnzipClass.FExtraBytes != 0L) ||
                ( UnzipClass.FExtraBytes == 0L && *pold_extra_bytes != 0L)) {
                Info(0x401, AttemptRecompensate);
                if (UnzipClass.FExtraBytes) {
                    *pold_extra_bytes = UnzipClass.FExtraBytes;
                    UnzipClass.FExtraBytes = 0L;
                } else
                    UnzipClass.FExtraBytes = *pold_extra_bytes; /* third attempt */
                if (((error = UnzipClass.Seek(UnzipClass.FCurrFile->offset)) != PK_OK) ||
                    (UnzipClass.ReadBuf(G.sig, 4) == 0)) {  /* bad offset */
                    if (error != PK_BADERR)
                      Info(0x401, OffsetMsg, *pfilnum, "EOF",
                        (long)request);
                    error_in_archive = PK_BADERR;
                    continue;   /* but can still try next one */
                }
                if (memcmp(G.sig, local_hdr_sig, 4)) {
                    Info(0x401,
                      OffsetMsg, *pfilnum,
                      LocalHdrSig, (long)request);
                    error_in_archive = PK_BADERR;
                    continue;
                }
            } else
                continue;  /* this one hosed; try next */
        }
        error = UnzipClass.GetFileHeader();
        if (error == PK_COOL)
            error = UnzipClass.GetFileName(UnzipClass.FCurrFileHeader.filename_length);
        if (error != PK_COOL) {
            Info(0x421, BadLocalHdr, *pfilnum);
            error_in_archive = error;   /* only PK_EOF defined */
            continue;   /* can still try next one */
        }
        UnzipClass.SkipHeaderString(UnzipClass.FCurrFileHeader.extra_field_length);
        /* Filename consistency checks must come after reading in the local
         * extra field, so that a UTF-8 entry name e.f. block has already
         * been processed.
         */
        if (UnzipClass.FCurrFile->cfilname != 0) {
            if (strcmp(UnzipClass.FCurrFile->cfilname, UnzipClass.FCurrFileName) != 0) {
                Info(0x401, LvsCFNamMsg,
                  FnFilter2(UnzipClass.FCurrFile->cfilname), FnFilter1(UnzipClass.FCurrFileName));
                strcpy(UnzipClass.FCurrFileName, UnzipClass.FCurrFile->cfilname);
                if (error_in_archive < PK_WARN)
                    error_in_archive = PK_WARN;
            }
        }
        /* Size consistency checks must come after reading in the local extra
         * field, so that any Zip64 extension local e.f. block has already
         * been processed.
         */
        if (UnzipClass.FCurrFileHeader.compression_method == STORED) {
            zusz_t csiz_decrypted = UnzipClass.FCurrFileHeader.csize;

            if (UnzipClass.FCurrFile->encrypted)
                csiz_decrypted -= 12;
            if (UnzipClass.FCurrFileHeader.ucsize != csiz_decrypted) {
                Info(0x401, WrnStorUCSizCSizDiff,
                  FnFilter1(UnzipClass.FCurrFileName),
                  fzofft(UnzipClass.FCurrFileHeader.ucsize, NULL, "u"),
                  fzofft(csiz_decrypted, NULL, "u"));
                UnzipClass.FCurrFileHeader.ucsize = csiz_decrypted;
                if (error_in_archive < PK_WARN)
                    error_in_archive = PK_WARN;
            }
        }

        if (UnzipClass.FCurrFile->encrypted) {
            error = UnzipClass.Decrypt();
            if (error != PK_COOL) {
                if (error == PK_WARN) {
                    if (!((uO.tflag && uO.qflag) || (!uO.tflag && uO.qflag)))
                        Info(0x401, SkipIncorrectPasswd,
                          FnFilter1(UnzipClass.FCurrFileName));
                    ++(*pnum_bad_pwd);
                } else {  /* (error > PK_WARN) */
                    if (error > error_in_archive)
                        error_in_archive = error;
                    Info(0x401, SkipCannotGetPasswd,
                      FnFilter1(UnzipClass.FCurrFileName));
                }
            }
            continue;   /* go on to next file */
        }

        /*
         * just about to extract file:  if extracting to disk, check if
         * already exists, and if so, take appropriate action according to
         * fflag/uflag/overwrite_all/etc. (we couldn't do this in upper
         * loop because we don't store the possibly renamed filename[] in
         * info[])
         */
        if (!uO.tflag && !uO.cflag)
        {
            renamed = FALSE;   /* user hasn't renamed output file yet */

startover:
            query = FALSE;
            skip_entry = SKIP_NO;
            /* for files from DOS FAT, check for use of backslash instead
             *  of slash as directory separator (bug in some zipper(s); so
             *  far, not a problem in HPFS, NTFS or VFAT systems)
             */
            if (UnzipClass.FCurrFile->hostnum == FS_FAT_ && !strchr(UnzipClass.FCurrFileName, '/')) {
                char *p=UnzipClass.FCurrFileName;

                if (*p) do {
                    if (*p == '\\') {
                        if (!G.reported_backslash) {
                            Info(0x21, BackslashPathSep, UnzipClass.FInputFileName.GetData());
                            G.reported_backslash = TRUE;
                            if (!error_in_archive)
                                error_in_archive = PK_WARN;
                        }
                        *p = '/';
                    }
                } while (*(++p));
            }

            if (!renamed) {
               /* remove absolute path specs */
               if (UnzipClass.FCurrFileName[0] == '/') {
                   Info(0x401, AbsolutePathWarning,
                        FnFilter1(UnzipClass.FCurrFileName));
                   if (!error_in_archive)
                       error_in_archive = PK_WARN;
                   do {
                       char *p = UnzipClass.FCurrFileName + 1;
                       do {
                           *(p-1) = *p;
                       } while (*p++ != '\0');
                   } while (UnzipClass.FCurrFileName[0] == '/');
               }
            }

            /* mapname can create dirs if not freshening or if renamed */
            error = mapname(renamed);
            if ((errcode = error & ~MPN_MASK) != PK_OK &&
                error_in_archive < errcode)
                error_in_archive = errcode;
            if ((errcode = error & MPN_MASK) > MPN_INF_TRUNC) {
                if (errcode == MPN_CREATED_DIR) {
                    direntry *d_entry;

                    error = defer_dir_attribs(&d_entry);
                    if (d_entry == (direntry *)NULL) {
                        /* There may be no dir_attribs info available, or
                         * we have encountered a mem allocation error.
                         * In case of an error, report it and set program
                         * error state to warning level.
                         */
                        if (error) {
                            Info(0x401, DirlistEntryNoMem);
                            if (!error_in_archive)
                                error_in_archive = PK_WARN;
                        }
                    } else {
                        d_entry->next = (*pdirlist);
                        (*pdirlist) = d_entry;
                        ++(*pnum_dirs);
                    }
                } else if (errcode == MPN_VOL_LABEL) {
                    Info(1, SkipVolumeLabel,
                      FnFilter1(UnzipClass.FCurrFileName), "");
                } else if (errcode > MPN_INF_SKIP &&
                           error_in_archive < PK_ERR)
                    error_in_archive = PK_ERR;
                Trace("mapname(%s) returns error code = %d\n",
                  FnFilter1(UnzipClass.FCurrFileName), error);
                continue;   /* go on to next file */
            }

            switch (UnzipClass.CheckForNewer(UnzipClass.FCurrFileName)) {
                case DOES_NOT_EXIST:
                    /* freshen (no new files): skip unless just renamed */
                    if (uO.fflag && !renamed)
                        skip_entry = SKIP_Y_NONEXIST;
                    break;
                case EXISTS_AND_OLDER:
                    {
                        if (IS_OVERWRT_NONE)
                            /* never overwrite:  skip file */
                            skip_entry = SKIP_Y_EXISTING;
                        else if (!IS_OVERWRT_ALL)
                            query = TRUE;
                    }
                    break;
                case EXISTS_AND_NEWER:             /* (or equal) */
                    if (IS_OVERWRT_NONE ||
                        (uO.uflag && !renamed)) {
                        /* skip if update/freshen & orig name */
                        skip_entry = SKIP_Y_EXISTING;
                    } else {
                        if (!IS_OVERWRT_ALL)
                            query = TRUE;
                    }
                    break;
            }
            if (query) {
                extent fnlen;
reprompt:
                Info(0x81, ReplaceQuery,
                  FnFilter1(UnzipClass.FCurrFileName));
                if (fgets(G.answerbuf, sizeof(G.answerbuf), stdin)
                    == (char *)NULL) {
                    Info(1, AssumeNone);
                    *G.answerbuf = 'N';
                    if (!error_in_archive)
                        error_in_archive = 1;  /* not extracted:  warning */
                }
                switch (*G.answerbuf) {
                    case 'r':
                    case 'R':
                        do {
                            Info(0x81, NewNameQuery);
                            fgets(UnzipClass.FCurrFileName, FILE_NAME_SIZE, stdin);
                            /* usually get \n here:  better check for it */
                            fnlen = strlen(UnzipClass.FCurrFileName);
                            if (UnzipClass.FCurrFileName[fnlen-1] == '\n')
                                UnzipClass.FCurrFileName[--fnlen] = '\0';
                        } while (fnlen == 0);
                        renamed = TRUE;
                        goto startover;   /* sorry for a goto */
                    case 'A':   /* dangerous option:  force caps */
                        G.overwrite_mode = OVERWRT_ALWAYS;
                        /* FALL THROUGH, extract */
                    case 'y':
                    case 'Y':
                        break;
                    case 'N':
                        G.overwrite_mode = OVERWRT_NEVER;
                        /* FALL THROUGH, skip */
                    case 'n':
                        /* skip file */
                        skip_entry = SKIP_Y_EXISTING;
                        break;
                    case '\n':
                    case '\r':
                        /* Improve echo of '\n' and/or '\r'
                           (sizeof(G.answerbuf) == 10 (see globals.h), so
                           there is enough space for the provided text...) */
                        strcpy(G.answerbuf, "{ENTER}");
                        /* fall through ... */
                    default:
                        /* usually get \n here:  remove it for nice display
                           (fnlen can be re-used here, we are outside the
                           "enter new filename" loop) */
                        fnlen = strlen(G.answerbuf);
                        if (G.answerbuf[fnlen-1] == '\n')
                            G.answerbuf[--fnlen] = '\0';
                        Info(1, InvalidResponse, G.answerbuf);
                        goto reprompt;   /* yet another goto? */
                } /* end switch (*answerbuf) */
            } /* end if (query) */
            if (skip_entry != SKIP_NO) {
                continue;
            }
        } /* end if (extracting to disk) */

        UnzipClass.FDiskFull = 0;

        error = UnzipClass.Extract();
        if (error != PK_COOL) {
            if (error > error_in_archive)
                error_in_archive = error;       /* ...and keep going */
            if (UnzipClass.FDiskFull > 1) {
                return error_in_archive;        /* (unless disk full) */
            }
        }
    } /* end for-loop (i:  files in current block) */

    return error_in_archive;

} /* end function extract_or_test_entrylist() */




/*************************/
/*  Function fnfilter()  */        /* here instead of in list.c for SFX */
/*************************/

char *fnfilter(const char *raw, unsigned char *space, extent size)   /* convert name to safely printable form */
{
    const unsigned char *r=(const unsigned char *)raw;
    unsigned char *s=space;
    unsigned char *slim=NULL;
    unsigned char *se=NULL;
    int have_overflow = FALSE;

    if (size > 0) {
        slim = space + size
                     - 4;
    }
    while (*r) {
        if (size > 0 && s >= slim && se == NULL) {
            se = s;
        }
        if (*r < 32) {
            /* ASCII control codes are escaped as "^{letter}". */
            if (se != NULL && (s > (space + (size-4)))) {
                have_overflow = TRUE;
                break;
            }
            *s++ = '^', *s++ = (unsigned char)(64 + *r++);
        } else {
            if (se != NULL && (s > (space + (size-3)))) {
                have_overflow = TRUE;
                break;
            }
            *s++ = *r++;
         }
    }
    if (have_overflow) {
        strcpy((char *)se, "...");
    } else {
        *s = '\0';
    }

    return (char *)space;


} /* end function fnfilter() */




/* must sort saved directories so can set perms from bottom up */

/************************/
/*  Function dircomp()  */
/************************/

static int dircomp(const void *a, const void *b)  /* used by qsort(); swiped from Zip */
{
    /* order is significant:  this sorts in reverse order (deepest first) */
    return strcmp((*(direntry **)b)->fn, (*(direntry **)a)->fn);
 /* return namecmp((*(direntry **)b)->fn, (*(direntry **)a)->fn); */
}

