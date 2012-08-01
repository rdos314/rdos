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
                unsigned long *pfilnum, unsigned long *pnum_bad_pwd, 
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
    unsigned long filnum=0L, blknum=0L;
    int reached_end;
    int no_endsig_found;
    int error, error_in_archive=PK_COOL;
    int *fn_matched=NULL, *xn_matched=NULL;
    zucn_t members_processed;
    unsigned long num_skipped=0L, num_bad_pwd=0L;
    unsigned num_dirs=0;
    direntry *dirlist=(direntry *)NULL;
    direntry **sorted_dirlist=(direntry **)NULL;
    struct TUnzipFile *file;
    int renamed, query;
    int skip_entry;
    int errcode;

/* possible values for local skip_entry flag: */
#define SKIP_NO         0       /* do not skip this entry */
#define SKIP_Y_EXISTING 1       /* skip this entry, do not overwrite file */
#define SKIP_Y_NONEXIST 2       /* skip this entry, do not create new file */
    /*
     * First, two general initializations are applied. These have been moved
     * here from process_zipfiles() because they are only needed for accessing
     * and/or extracting the data content of the zip archive.
     */

    /* b) check out if specified extraction root directory exists */
    if (uO.exdir != (char *)NULL && G.extract_flag) {
        G.create_dirs = !uO.fflag;
        if ((error = checkdir(file, uO.exdir, ROOT)) > MPN_INF_SKIP) {
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

    UnzipClass.ProcessFiles();
    
    members_processed = 0;
    no_endsig_found = FALSE;
    reached_end = FALSE;

    for (i = 0; i < UnzipClass.GetFileCount(); i++)
    {
        file = UnzipClass.GetFile(i);

        if (file == 0)
            break;

        if (file->error != PK_COOL)
            continue;

        if (!G.process_all_files) {
            int   do_this_file;

            if (G.filespecs == 0)
                do_this_file = TRUE;
            else {  /* check if this entry matches an `include' argument */
                do_this_file = FALSE;
                for (j = 0; j < G.filespecs; j++)
                    if (match(file->cfilname, G.pfnames[j], uO.C_flag)) {
                        do_this_file = TRUE;  /* ^-- ignore case or not? */
                        if (fn_matched)
                            fn_matched[j] = TRUE;
                        break;       /* found match, so stop looping */
                    }
            }
            if (do_this_file) {  /* check if this is an excluded file */
                for (j = 0; j < G.xfilespecs; j++)
                    if (match(file->cfilname, G.pxnames[j], uO.C_flag)) {
                        do_this_file = FALSE; /* ^-- ignore case or not? */
                        if (xn_matched)
                            xn_matched[j] = TRUE;
                        break;
                    }
            }
            if (!do_this_file) 
                file->error = PK_SKIP;
        } /* end if (process_all_files) */
    }

    /*-----------------------------------------------------------------------
        Second loop:  process files in current block, extracting or testing
        each one.
      -----------------------------------------------------------------------*/

    for (i = 0; i < UnzipClass.GetFileCount(); i++)
    {
        file = UnzipClass.GetFile(i);

        if (file == 0)
            break;

        if (file->error == PK_EOF)
            break;

        if (file->error != PK_COOL)
            continue;

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
            if (file->hostnum == FS_FAT_ && !strchr(file->cfilname, '/')) {
                char *p=file->cfilname;

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
               if (file->cfilname[0] == '/') {
                   Info(0x401, AbsolutePathWarning,
                        FnFilter1(file->cfilname));
                   if (!error_in_archive)
                       error_in_archive = PK_WARN;
                   do {
                       char *p = file->cfilname + 1;
                       do {
                           *(p-1) = *p;
                       } while (*p++ != '\0');
                   } while (file->cfilname[0] == '/');
               }
            }

            /* mapname can create dirs if not freshening or if renamed */
            error = mapname(file, renamed);
            if ((errcode = error & ~MPN_MASK) != PK_OK &&
                error_in_archive < errcode)
                error_in_archive = errcode;

            switch (UnzipClass.CheckForNewer(file, file->cfilname)) {
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
                  FnFilter1(file->cfilname));
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
                            fgets(file->cfilname, FILE_NAME_SIZE, stdin);
                            /* usually get \n here:  better check for it */
                            fnlen = strlen(file->cfilname);
                            if (file->cfilname[fnlen-1] == '\n')
                                file->cfilname[--fnlen] = '\0';
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

        error = UnzipClass.Extract(file);
        if (error != PK_COOL) {
            if (error > error_in_archive)
                error_in_archive = error;       /* ...and keep going */
            if (UnzipClass.FDiskFull > 1) {
                return error_in_archive;        /* (unless disk full) */
            }
        }
    } /* end for-loop (i:  files in current block) */

    return PK_OK;

} /* end function extract_or_test_files() */




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

