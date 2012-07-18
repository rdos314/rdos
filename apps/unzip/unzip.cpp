/*
  Copyright (c) 1990-2009 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2009-Jan-02 or later
  (the contents of which are also included in unzip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/*---------------------------------------------------------------------------

  unzip.c

  UnZip - a zipfile extraction utility.  See below for make instructions, or
  read the comments in Makefile and the various Contents files for more de-
  tailed explanations.  To report a bug, submit a *complete* description via
  //www.info-zip.org/zip-bug.html; include machine type, operating system and
  version, compiler and version, and reasonably detailed error messages or
  problem report.  To join Info-ZIP, see the instructions in README.

  UnZip 5.x is a greatly expanded and partially rewritten successor to 4.x,
  which in turn was almost a complete rewrite of version 3.x.  For a detailed
  revision history, see UnzpHist.zip at quest.jpl.nasa.gov.  For a list of
  the many (near infinite) contributors, see "CONTRIBS" in the UnZip source
  distribution.

  UnZip 6.0 adds support for archives larger than 4 GiB using the Zip64
  extensions as well as support for Unicode information embedded per the
  latest zip standard additions.

  ---------------------------------------------------------------------------

  [from original zipinfo.c]

  This program reads great gobs of totally nifty information, including the
  central directory stuff, from ZIP archives ("zipfiles" for short).  It
  started as just a testbed for fooling with zipfiles, but at this point it
  is actually a useful utility.  It also became the basis for the rewrite of
  UnZip (3.16 -> 4.0), using the central directory for processing rather than
  the individual (local) file headers.

  As of ZipInfo v2.0 and UnZip v5.1, the two programs are combined into one.
  If the executable is named "unzip" (or "unzip.exe", depending), it behaves
  like UnZip by default; if it is named "zipinfo" or "ii", it behaves like
  ZipInfo.  The ZipInfo behavior may also be triggered by use of unzip's -Z
  option; for example, "unzip -Z [zipinfo_options] archive.zip".

  Another dandy product from your buddies at Newtware!

  Author:  Greg Roelofs, newt@pobox.com, http://pobox.com/~newt/
           23 August 1990 -> April 1997

  ---------------------------------------------------------------------------

  Version:  unzip5??.{tar.Z | tar.gz | zip} for Unix, VMS, OS/2, MS-DOS, Amiga,
              Atari, Windows 3.x/95/NT/CE, Macintosh, Human68K, Acorn RISC OS,
              AtheOS, BeOS, SMS/QDOS, VM/CMS, MVS, AOS/VS, Tandem NSK, Theos
              and TOPS-20.

  Copyrights:  see accompanying file "LICENSE" in UnZip source distribution.
               (This software is free but NOT IN THE PUBLIC DOMAIN.)

  ---------------------------------------------------------------------------*/



#define __UNZIP_C       /* identifies this source module */
#define UNZIP_INTERNAL
#include "unzip.h"      /* includes, typedefs, macros, prototypes, etc. */
#include "crypt.h"
#include "unzvers.h"

/*******************/
/* Local Functions */
/*******************/

static void  help_extended      OF((__GPRO));
static void  show_version_info  OF((__GPRO));


/*************/
/* Constants */
/*************/

/* constant local variables: */

#include "consts.h"


   static const char EnvUnZip[] = ENV_UNZIP;
   static const char EnvUnZip2[] = ENV_UNZIP2;
   static const char EnvZipInfo[] = ENV_ZIPINFO;
   static const char EnvZipInfo2[] = ENV_ZIPINFO2;
  static const char NoMemEnvArguments[] =
    "envargs:  cannot get memory for arguments";
  static const char CmdLineParamTooLong[] =
    "error:  command line parameter #%d exceeds internal size limit\n";

   static const char NotExtracting[] =
     "caution:  not extracting; -d ignored\n";
   static const char MustGiveExdir[] =
     "error:  must specify directory to which to extract with -d option\n";
   static const char OnlyOneExdir[] =
     "error:  -d option used more than once (only one exdir allowed)\n";

   static const char MustGivePasswd[] =
     "error:  must give decryption password with -P option\n";

   static const char Zfirst[] =
   "error:  -Z must be first option for ZipInfo mode (check UNZIP variable?)\n";
static const char InvalidOptionsMsg[] = "error:\
  -fn or any combination of -c, -l, -p, -t, -u and -v options invalid\n";
static const char IgnoreOOptionMsg[] =
  "caution:  both -n and -o specified; ignoring -o\n";

/* usage() strings */
   static const char Example3[] = "ReadMe";
   static const char Example2[] = " \
 unzip -p foo | more  => send contents of foo.zip via pipe into program more\n";

/* local1[]:  command options */
   static const char local1[] = "";

/* local2[] and local3[]:  modifier options */
   static const char local2[] = " -M  pipe through \"more\" pager";
   static const char local3[] = "\n";

   static const char ZipInfoExample[] = "*, ?, [] (e.g., \"[a-j]*.zip\")";

static const char ZipInfoUsageLine1[] = "\
ZipInfo %d.%d%d%s of %s, by Greg Roelofs and the Info-ZIP group.\n\
\n\
List name, date/time, attribute, size, compression method, etc., about files\n\
in list (excluding those in xlist) contained in the specified .zip archive(s).\
\n\"file[.zip]\" may be a wildcard name containing %s.\n\n\
   usage:  zipinfo [-12smlvChMtTz] file[.zip] [list...] [-x xlist...]\n\
      or:  unzip %s-Z%s [-12smlvChMtTz] file[.zip] [list...] [-x xlist...]\n";

static const char ZipInfoUsageLine2[] = "\nmain\
 listing-format options:             -s  short Unix \"ls -l\" format (def.)\n\
  -1  filenames ONLY, one per line       -m  medium Unix \"ls -l\" format\n\
  -2  just filenames but allow -h/-t/-z  -l  long Unix \"ls -l\" format\n\
                                         -v  verbose, multi-page format\n";

static const char ZipInfoUsageLine3[] = "miscellaneous options:\n\
  -h  print header line       -t  print totals for listed files or for all\n\
  -z  print zipfile comment   -T  print file times in sortable decimal format\
\n  -C  be case-insensitive   %s\
  -x  exclude filenames that follow from listing\n";
   static const char ZipInfoUsageLine4[] =
     "  -M  page output through built-in \"more\"\n";

   static const char CompileOptions[] =
     "UnZip special compilation options:\n";
   static const char CompileOptFormat[] = "        %s\n";
   static const char EnvOptions[] =
     "\nUnZip and ZipInfo environment options:\n";
   static const char EnvOptFormat[] = "%16s:  %.1024s\n";
   static const char None[] = "[none]";
     static const char Copyright_Clean[] =
     "COPYRIGHT_CLEAN (PKZIP 0.9x unreducing method not supported)";
#  ifdef DEBUG
     static const char UDebug[] = "DEBUG";
#  endif
     static const char SetDirAttrib[] = "SET_DIR_ATTRIB";
     static const char Use_Unshrink[] =
     "USE_UNSHRINK (PKZIP/Zip 1.x unshrinking method supported)";
     static const char UseZlib[] =
     "USE_ZLIB (compiled with version %s; using version %s)";
     static const char Decryption[] =
       "        [decryption, version %d.%d%s of %s]\n";
     static const char CryptDate[] = CR_VERSION_DATE;

   static const char UnzipUsageLine1[] = "\
UnZip %d.%d%d%s of %s, by Info-ZIP.  Maintained by C. Spieler.  Send\n\
bug reports using http://www.info-zip.org/zip-bug.html; see README for details.\
\n\n";

# define UnzipUsageLine1v       UnzipUsageLine1

static const char UnzipUsageLine2v[] = "\
Latest sources and executables are at ftp://ftp.info-zip.org/pub/infozip/ ;\
\nsee ftp://ftp.info-zip.org/pub/infozip/UnZip.html for other sites.\
\n\n";

static const char UnzipUsageLine2[] = "\
Usage: unzip %s[-opts[modifiers]] file[.zip] [list] [-x xlist] [-d exdir]\n \
 Default action is to extract files in list, except those in xlist, to exdir;\n\
  file[.zip] may be a wildcard.  %s\n";

#  define ZIPINFO_MODE_OPTION  "[-Z] "
   static const char ZipInfoMode[] =
     "-Z => ZipInfo mode (\"unzip -Z\" for usage).";

static const char UnzipUsageLine3[] = "\n\
  -p  extract files to pipe, no messages     -l  list files (short format)\n\
  -f  freshen existing files, create none    -t  test compressed archive data\n\
  -u  update files, create if necessary      -z  display archive comment only\n\
  -v  list verbosely/show version info     %s\n\
  -x  exclude files that follow (in xlist)   -d  extract files into exdir\n";

/* There is not enough space on a standard 80x25 Windows console screen for
 * the additional line advertising the UTF-8 debugging options. This may
 * eventually also be the case for other ports. Probably, the -U option need
 * not be shown on the introductory screen at all. [Chr. Spieler, 2008-02-09]
 *
 * Likely, other advanced options should be moved to an extended help page and
 * the option to list that page put here.  [E. Gordon, 2008-3-16]
 */
static const char UnzipUsageLine4[] = "\
modifiers:\n\
  -n  never overwrite existing files         -q  quiet mode (-qq => quieter)\n\
  -o  overwrite files WITHOUT prompting      -a  auto-convert any text files\n\
  -j  junk paths (do not make directories)   -aa treat ALL files as text\n\
  -C  match filenames case-insensitively     -L  make (some) names \
lowercase\n %-42s  -V  retain VMS version numbers\n%s";

static const char UnzipUsageLine5[] = "\
See \"unzip -hh\" or unzip.txt for more help.  Examples:\n\
  unzip data1 -x joe   => extract all files except joe from zipfile data1.zip\n\
%s\
  unzip -fo foo %-6s => quietly replace existing %s if archive file newer\n";





/*****************************/
/*  main() / UzpMain() stub  */
/*****************************/

int main(int argc, char *argv[])   /* return PK-type error code (except under VMS) */
{
    int r;

    CONSTRUCTGLOBALS();
    r = unzip(__G__ argc, argv);
    return(r);
}




/*******************************/
/*  Primary UnZip entry point  */
/*******************************/

int unzip(int argc, char *argv[])
{
    char *p;
    int i;
    int retcode, error=FALSE;

    /* The following (rather complex) expression determines the allocation
       size of the decompression work area.  It simulates what the
       combined "union" and "struct" declaration of the "static" work
       area reservation achieves automatically at compile time.
       Any decent compiler should evaluate this expression completely at
       compile time and provide constants to the zcalloc() call.
       (For better readability, some subexpressions are encapsulated
       in temporarly defined macros.)
     */
#   define UZ_SLIDE_CHUNK (sizeof(int)+sizeof(unsigned char)+sizeof(unsigned char))
#   define UZ_NUMOF_CHUNKS \
      (unsigned)(((WSIZE+UZ_SLIDE_CHUNK-1)/UZ_SLIDE_CHUNK > HSIZE) ? \
                 (WSIZE+UZ_SLIDE_CHUNK-1)/UZ_SLIDE_CHUNK : HSIZE)
    G.area.Slide = (unsigned char *)malloc(UZ_NUMOF_CHUNKS * UZ_SLIDE_CHUNK);
#   undef UZ_SLIDE_CHUNK
#   undef UZ_NUMOF_CHUNKS
    G.area.shrink.Parent = (int *)G.area.Slide;
    G.area.shrink.value = G.area.Slide + (sizeof(int)*(HSIZE));
    G.area.shrink.Stack = G.area.Slide +
                           (sizeof(int) + sizeof(unsigned char))*(HSIZE);

/*---------------------------------------------------------------------------
    Sanity checks.  Commentary by Otis B. Driftwood and Fiorello:

    D:  It's all right.  That's in every contract.  That's what they
        call a sanity clause.

    F:  Ha-ha-ha-ha-ha.  You can't fool me.  There ain't no Sanity
        Claus.
  ---------------------------------------------------------------------------*/

#ifdef DEBUG

    /* 2004-11-30 SMS.
       Test the NEXTBYTE macro for proper operation.
    */
    {
        int test_char;
        static unsigned char test_buf[2] = { 'a', 'b' };

        G.inptr = test_buf;
        G.incnt = 1;

        test_char = NEXTBYTE;           /* Should get 'a'. */
        if (test_char == 'a')
        {
            test_char = NEXTBYTE;       /* Should get EOF, not 'b'. */
        }
        if (test_char != EOF)
        {
            Info(slide, 0x401, ((char *)slide,
 "NEXTBYTE macro failed.  Try compiling with ALT_NEXTBYTE defined?"));

            retcode = PK_BADERR;
            goto cleanup_and_exit;
        }
    }
#endif /* DEBUG */

/*---------------------------------------------------------------------------
    First figure out if we're running in UnZip mode or ZipInfo mode, and put
    the appropriate environment-variable options into the queue.  Then rip
    through any command-line options lurking about...
  ---------------------------------------------------------------------------*/


    G.noargs = (argc == 1);   /* no options, no zipfile, no anything */

    for (p = argv[0] + strlen(argv[0]); p >= argv[0]; --p) {
        if (*p == DIR_END
            || *p == DIR_END2
           )
            break;
    }
    ++p;
    if (strnicmp(p, Zipnfo, 7) == 0 ||
        strnicmp(p, "ii", 2) == 0 ||
        (argc > 1 && strncmp(argv[1], "-Z", 2) == 0))
    {
        uO.zipinfo_mode = TRUE;
        if ((error = envargs(&argc, &argv, EnvZipInfo,
                             EnvZipInfo2)) != PK_OK)
            perror(NoMemEnvArguments);
    } else
    {
        uO.zipinfo_mode = FALSE;
        if ((error = envargs(&argc, &argv, EnvUnZip,
                             EnvUnZip2)) != PK_OK)
            perror(NoMemEnvArguments);
    }

    if (!error) {
        /* Check the length of all passed command line parameters.
         * Command arguments might get sent through the Info() message
         * system, which uses the sliding window area as string buffer.
         * As arguments may additionally get fed through one of the FnFilter
         * macros, we require all command line arguments to be shorter than
         * WSIZE/4 (and ca. 2 standard line widths for fixed message text).
         */
        for (i = 1 ; i < argc; i++) {
           if (strlen(argv[i]) > ((WSIZE>>2) - 160)) {
               Info(slide, 0x401, ((char *)slide,
                 CmdLineParamTooLong, i));
               retcode = PK_PARAM;
               goto cleanup_and_exit;
           }
        }
        if (uO.zipinfo_mode)
            error = zi_opts(__G__ &argc, &argv);
        else
            error = uz_opts(__G__ &argc, &argv);
    }

    if ((argc < 0) || error) {
        retcode = error;
        goto cleanup_and_exit;
    }

/*---------------------------------------------------------------------------
    Now get the zipfile name from the command line and then process any re-
    maining options and file specifications.
  ---------------------------------------------------------------------------*/

    /* convert MSDOS-style 'backward slash' directory separators to Unix-style
     * 'forward slashes' for user's convenience (include zipfile name itself)
     */
    /* argc does not include the zipfile specification */
    for (G.pfnames = argv, i = argc+1;  i > 0;  --i) {
        char *q = *G.pfnames;

        while (*q != '\0') {
            if (*q == '\\')
                *q = '/';
            q++;
        }
        ++G.pfnames;
    }

    G.wildzipfn = *argv++;


    G.filespecs = argc;
    G.xfilespecs = 0;

    if (argc > 0) {
        int in_files=FALSE, in_xfiles=FALSE;
        char **pp = argv-1;

        G.process_all_files = FALSE;
        G.pfnames = argv;
        while (*++pp) {
            Trace((stderr, "pp - argv = %d\n", pp-argv));
            if (!uO.exdir && strncmp(*pp, "-d", 2) == 0) {
                int firstarg = (pp == argv);

                uO.exdir = (*pp) + 2;
                if (in_files) {      /* ... zipfile ... -d exdir ... */
                    *pp = (char *)NULL;         /* terminate G.pfnames */
                    G.filespecs = pp - G.pfnames;
                    in_files = FALSE;
                } else if (in_xfiles) {
                    *pp = (char *)NULL;         /* terminate G.pxnames */
                    G.xfilespecs = pp - G.pxnames;
                    /* "... -x xlist -d exdir":  nothing left */
                }
                /* first check for "-dexdir", then for "-d exdir" */
                if (*uO.exdir == '\0') {
                    if (*++pp)
                        uO.exdir = *pp;
                    else {
                        Info(slide, 0x401, ((char *)slide,
                          MustGiveExdir));
                        /* don't extract here by accident */
                        retcode = PK_PARAM;
                        goto cleanup_and_exit;
                    }
                }
                if (firstarg) { /* ... zipfile -d exdir ... */
                    if (pp[1]) {
                        G.pfnames = pp + 1;  /* argv+2 */
                        G.filespecs = argc - (G.pfnames-argv);  /* for now... */
                    } else {
                        G.process_all_files = TRUE;
                        G.pfnames = (char **)fnames;  /* GRR: necessary? */
                        G.filespecs = 0;     /* GRR: necessary? */
                        break;
                    }
                }
            } else if (!in_xfiles) {
                if (strcmp(*pp, "-x") == 0) {
                    in_xfiles = TRUE;
                    if (pp == G.pfnames) {
                        G.pfnames = (char **)fnames;  /* defaults */
                        G.filespecs = 0;
                    } else if (in_files) {
                        *pp = 0;                   /* terminate G.pfnames */
                        G.filespecs = pp - G.pfnames;  /* adjust count */
                        in_files = FALSE;
                    }
                    G.pxnames = pp + 1; /* excluded-names ptr starts after -x */
                    G.xfilespecs = argc - (G.pxnames-argv);  /* anything left */
                } else
                    in_files = TRUE;
            }
        }
    } else
        G.process_all_files = TRUE;      /* for speed */

    if (uO.exdir != (char *)NULL && !G.extract_flag)    /* -d ignored */
        Info(slide, 0x401, ((char *)slide, NotExtracting));


/*---------------------------------------------------------------------------
    Okey dokey, we have everything we need to get started.  Let's roll.
  ---------------------------------------------------------------------------*/

    retcode = process_zipfiles(__G);

cleanup_and_exit:
    if (G.area.Slide != (unsigned char *)NULL) {
        free(G.area.Slide);
        G.area.Slide = (unsigned char *)NULL;
    }
    return(retcode);

} /* end main()/unzip() */





/**********************/
/* Function uz_opts() */
/**********************/

int uz_opts(int *pargc, char ***pargv)
{
    char **argv, *s;
    int argc, c, error=FALSE, negative=0, showhelp=0;


    argc = *pargc;
    argv = *pargv;

    while (++argv, (--argc > 0 && *argv != NULL && **argv == '-')) {
        s = *argv + 1;
        while ((c = *s++) != 0) {    /* "!= 0":  prevent Turbo C warning */
            switch (c)
            {
                case ('-'):
                    ++negative;
                    break;
                case ('a'):
                    if (negative) {
                        uO.aflag = MAX(uO.aflag-negative,0);
                        negative = 0;
                    } else
                        ++uO.aflag;
                    break;
                case ('b'):
                    if (negative) {
                        negative = 0;   /* do nothing:  "-b" is default */
                    } else {
                        uO.aflag = 0;
                    }
                    break;
                case ('c'):
                    if (negative) {
                        uO.cflag = FALSE, negative = 0;
#ifdef NATIVE
                        uO.aflag = 0;
#endif
                    } else {
                        uO.cflag = TRUE;
#ifdef NATIVE
                        uO.aflag = 2;   /* so you can read it on the screen */
#endif
                    }
                    break;
                case ('C'):    /* -C:  match filenames case-insensitively */
                    if (negative)
                        uO.C_flag = FALSE, negative = 0;
                    else
                        uO.C_flag = TRUE;
                    break;
                case ('d'):
                    if (negative) {   /* negative not allowed with -d exdir */
                        Info(slide, 0x401, ((char *)slide,
                          MustGiveExdir));
                        return(PK_PARAM);  /* don't extract here by accident */
                    }
                    if (uO.exdir != (char *)NULL) {
                        Info(slide, 0x401, ((char *)slide,
                          OnlyOneExdir));
                        return(PK_PARAM);    /* GRR:  stupid restriction? */
                    } else {
                        /* first check for "-dexdir", then for "-d exdir" */
                        uO.exdir = s;
                        if (*uO.exdir == '\0') {
                            if (argc > 1) {
                                --argc;
                                uO.exdir = *++argv;
                                if (*uO.exdir == '-') {
                                    Info(slide, 0x401, ((char *)slide,
                                      MustGiveExdir));
                                    return(PK_PARAM);
                                }
                                /* else uO.exdir points at extraction dir */
                            } else {
                                Info(slide, 0x401, ((char *)slide,
                                  MustGiveExdir));
                                return(PK_PARAM);
                            }
                        }
                        /* uO.exdir now points at extraction dir (-dexdir or
                         *  -d exdir); point s at end of exdir to avoid mis-
                         *  interpretation of exdir characters as more options
                         */
                        if (*s != 0)
                            while (*++s != 0)
                                ;
                    }
                    break;
                case ('e'):    /* just ignore -e, -x options (extract) */
                    break;
                case ('f'):    /* "freshen" (extract only newer files) */
                    if (negative)
                        uO.fflag = uO.uflag = FALSE, negative = 0;
                    else
                        uO.fflag = uO.uflag = TRUE;
                    break;
                case ('h'):    /* just print help message and quit */
                    if (showhelp == 0) {
                        if (*s == 'h')
                            showhelp = 2;
                        else
                        {
                            showhelp = 1;
                        }
                    }
                    break;
                case ('j'):    /* junk pathnames/directory structure */
                    if (negative)
                        uO.jflag = FALSE, negative = 0;
                    else
                        uO.jflag = TRUE;
                    break;
                case ('l'):
                    if (negative) {
                        uO.vflag = MAX(uO.vflag-negative,0);
                        negative = 0;
                    } else
                        ++uO.vflag;
                    break;
                case ('L'):    /* convert (some) filenames to lowercase */
                    if (negative) {
                        uO.L_flag = MAX(uO.L_flag-negative,0);
                        negative = 0;
                    } else
                        ++uO.L_flag;
                    break;
                case ('M'):    /* send all screen output through "more" fn. */
/* GRR:  eventually check for numerical argument => height */
                    if (negative)
                        G.M_flag = FALSE, negative = 0;
                    else
                        G.M_flag = TRUE;
                    break;
                case ('n'):    /* don't overwrite any files */
                    if (negative)
                        uO.overwrite_none = FALSE, negative = 0;
                    else
                        uO.overwrite_none = TRUE;
                    break;
                case ('o'):    /* OK to overwrite files without prompting */
                    if (negative) {
                        uO.overwrite_all = MAX(uO.overwrite_all-negative,0);
                        negative = 0;
                    } else
                        ++uO.overwrite_all;
                    break;
                case ('p'):    /* pipes:  extract to stdout, no messages */
                    if (negative) {
                        uO.cflag = FALSE;
                        uO.qflag = MAX(uO.qflag-999,0);
                        negative = 0;
                    } else {
                        uO.cflag = TRUE;
                        uO.qflag += 999;
                    }
                    break;
                /* GRR:  yes, this is highly insecure, but dozens of people
                 * have pestered us for this, so here we go... */
                case ('P'):
                    if (negative) {   /* negative not allowed with -P passwd */
                        Info(slide, 0x401, ((char *)slide,
                          MustGivePasswd));
                        return(PK_PARAM);  /* don't extract here by accident */
                    }
                    if (uO.pwdarg != (char *)NULL) {
/*
                        GRR:  eventually support multiple passwords?
                        Info(slide, 0x401, ((char *)slide,
                          OnlyOnePasswd));
                        return(PK_PARAM);
 */
                    } else {
                        /* first check for "-Ppasswd", then for "-P passwd" */
                        uO.pwdarg = s;
                        if (*uO.pwdarg == '\0') {
                            if (argc > 1) {
                                --argc;
                                uO.pwdarg = *++argv;
                                if (*uO.pwdarg == '-') {
                                    Info(slide, 0x401, ((char *)slide,
                                      MustGivePasswd));
                                    return(PK_PARAM);
                                }
                                /* else pwdarg points at decryption password */
                            } else {
                                Info(slide, 0x401, ((char *)slide,
                                  MustGivePasswd));
                                return(PK_PARAM);
                            }
                        }
                        /* pwdarg now points at decryption password (-Ppasswd or
                         *  -P passwd); point s at end of passwd to avoid mis-
                         *  interpretation of passwd characters as more options
                         */
                        if (*s != 0)
                            while (*++s != 0)
                                ;
                    }
                    break;
                case ('q'):    /* quiet:  fewer comments/messages */
                    if (negative) {
                        uO.qflag = MAX(uO.qflag-negative,0);
                        negative = 0;
                    } else
                        ++uO.qflag;
                    break;
                case ('t'):
                    if (negative)
                        uO.tflag = FALSE, negative = 0;
                    else
                        uO.tflag = TRUE;
                    break;
                case ('u'):    /* update (extract only new and newer files) */
                    if (negative)
                        uO.uflag = FALSE, negative = 0;
                    else
                        uO.uflag = TRUE;
                    break;
                case ('U'):    /* obsolete; to be removed in version 6.0 */
                    if (negative)
                        uO.L_flag = TRUE, negative = 0;
                    else
                        uO.L_flag = FALSE;
                    break;
                case ('v'):    /* verbose */
                    if (negative) {
                        uO.vflag = MAX(uO.vflag-negative,0);
                        negative = 0;
                    } else if (uO.vflag)
                        ++uO.vflag;
                    else
                        uO.vflag = 2;
                    break;
                case ('V'):    /* Version (retain VMS/DEC-20 file versions) */
                    if (negative)
                        uO.V_flag = FALSE, negative = 0;
                    else
                        uO.V_flag = TRUE;
                    break;
                case ('x'):    /* extract:  default */
                    break;
                case ('z'):    /* display only the archive comment */
                    if (negative) {
                        uO.zflag = MAX(uO.zflag-negative,0);
                        negative = 0;
                    } else
                        ++uO.zflag;
                    break;
                case ('Z'):    /* should have been first option (ZipInfo) */
                    Info(slide, 0x401, ((char *)slide, Zfirst));
                    error = TRUE;
                    break;
                case (':'):    /* allow "parent dir" path components */
                    if (negative) {
                        uO.ddotflag = MAX(uO.ddotflag-negative,0);
                        negative = 0;
                    } else
                        ++uO.ddotflag;
                    break;
                default:
                    error = TRUE;
                    break;

            } /* end switch */
        } /* end while (not end of argument string) */
    } /* end while (not done with switches) */

/*---------------------------------------------------------------------------
    Check for nonsensical combinations of options.
  ---------------------------------------------------------------------------*/

    if (showhelp > 0) {         /* just print help message and quit */
        *pargc = -1;
        if (showhelp == 2) {
            help_extended(__G);
            return PK_OK;
        } else
        {
            return usage(PK_OK);
        }
    }

    if ((uO.cflag && (uO.tflag || uO.uflag)) ||
        (uO.tflag && uO.uflag) || (uO.fflag && uO.overwrite_none))
    {
        Info(slide, 0x401, ((char *)slide, InvalidOptionsMsg));
        error = TRUE;
    }
    if (uO.aflag > 2)
        uO.aflag = 2;
    if (uO.overwrite_all && uO.overwrite_none) {
        Info(slide, 0x401, ((char *)slide, IgnoreOOptionMsg));
        uO.overwrite_all = FALSE;
    }
    if (G.M_flag && !isatty(1))  /* stdout redirected: "more" func. useless */
        G.M_flag = 0;

    if ((argc-- == 0) || error)
    {
        *pargc = argc;
        *pargv = argv;
        if (uO.vflag >= 2 && argc == -1) {              /* "unzip -v" */
            show_version_info(__G);
            return PK_OK;
        }
        if (!G.noargs && !error)
            error = TRUE;       /* had options (not -h or -v) but no zipfile */
        return usage(error);
    }

    if (uO.cflag || uO.tflag || uO.vflag || uO.zflag
                                                                 )
        G.extract_flag = FALSE;
    else
        G.extract_flag = TRUE;

    *pargc = argc;
    *pargv = argv;
    return PK_OK;

} /* end function uz_opts() */




/********************/
/* Function usage() */
/********************/

#    define QUOT ' '
#    define QUOTS ""

int usage(int error)   /* return PK-type error code */
{
    int flag = (error? 1 : 0);


/*---------------------------------------------------------------------------
    Print either ZipInfo usage or UnZip usage, depending on incantation.
    (Strings must be no longer than 512 bytes for Turbo C, apparently.)
  ---------------------------------------------------------------------------*/

    if (uO.zipinfo_mode) {

        Info(slide, flag, ((char *)slide, ZipInfoUsageLine1,
          ZI_MAJORVER, ZI_MINORVER, UZ_PATCHLEVEL, UZ_BETALEVEL,
          VersionDate,
          ZipInfoExample, QUOTS,QUOTS));
        Info(slide, flag, ((char *)slide, ZipInfoUsageLine2));
        Info(slide, flag, ((char *)slide, ZipInfoUsageLine3,
          ZipInfoUsageLine4));

    } else {   /* UnZip mode */

        Info(slide, flag, ((char *)slide, UnzipUsageLine1,
          UZ_MAJORVER, UZ_MINORVER, UZ_PATCHLEVEL, UZ_BETALEVEL,
          VersionDate));

        Info(slide, flag, ((char *)slide, UnzipUsageLine2,
          ZIPINFO_MODE_OPTION, ZipInfoMode));

        Info(slide, flag, ((char *)slide, UnzipUsageLine3,
          local1));

        Info(slide, flag, ((char *)slide, UnzipUsageLine4,
          local2, local3));

        Info(slide, flag, ((char *)slide, UnzipUsageLine5,
          Example2, Example3,
          Example3));

    } /* end if (uO.zipinfo_mode) */

    if (error)
        return PK_PARAM;
    else
        return PK_COOL;     /* just wanted usage screen: no error */

} /* end function usage() */



/* Print extended help to stdout. */
static void help_extended(__G)
    __GDEF
{
    extent i;             /* counter for help array */

    /* help array */
    static const char *text[] = {
  "",
  "Extended Help for UnZip",
  "",
  "See the UnZip Manual for more detailed help",
  "",
  "",
  "UnZip lists and extracts files in zip archives.  The default action is to",
  "extract zipfile entries to the current directory, creating directories as",
  "needed.  With appropriate options, UnZip lists the contents of archives",
  "instead.",
  "",
  "Basic unzip command line:",
  "  unzip [-Z] options archive[.zip] [file ...] [-x xfile ...] [-d exdir]",
  "",
  "Some examples:",
  "  unzip -l foo.zip        - list files in short format in archive foo.zip",
  "",
  "  unzip -t foo            - test the files in archive foo",
  "",
  "  unzip -Z foo            - list files using more detailed zipinfo format",
  "",
  "  unzip foo               - unzip the contents of foo in current dir",
  "",
  "  unzip -a foo            - unzip foo and convert text files to local OS",
  "",
  "If unzip is run in zipinfo mode, a more detailed list of archive contents",
  "is provided.  The -Z option sets zipinfo mode and changes the available",
  "options.",
  "",
  "Basic zipinfo command line:",
  "  zipinfo options archive[.zip] [file ...] [-x xfile ...]",
  "  unzip -Z options archive[.zip] [file ...] [-x xfile ...]",
  "",
  "Below, Mac OS refers to Mac OS before Mac OS X.  Mac OS X is a Unix based",
  "port and is referred to as Unix Apple.",
  "",
  "",
  "unzip options:",
  "  -Z   Switch to zipinfo mode.  Must be first option.",
  "  -hh  Display extended help.",
  "  -A   [OS/2, Unix DLL] Print extended help for DLL.",
  "  -c   Extract files to stdout/screen.  As -p but include names.  Also,",
  "         -a allowed and EBCDIC conversions done if needed.",
  "  -f   Freshen by extracting only if older file on disk.",
  "  -l   List files using short form.",
  "  -p   Extract files to pipe (stdout).  Only file data is output and all",
  "         files extracted in binary mode (as stored).",
  "  -t   Test archive files.",
  "  -T   Set timestamp on archive(s) to that of newest file.  Similar to",
  "       zip -o but faster.",
  "  -u   Update existing older files on disk as -f and extract new files.",
  "  -v   Use verbose list format.  If given alone as unzip -v show version",
  "         information.  Also can be added to other list commands for more",
  "         verbose output.",
  "  -z   Display only archive comment.",
  "",
  "unzip modifiers:",
  "  -a   Convert text files to local OS format.  Convert line ends, EOF",
  "         marker, and from or to EBCDIC character set as needed.",
  "  -b   Treat all files as binary.  [Tandem] Force filecode 180 ('C').",
  "         [VMS] Autoconvert binary files.  -bb forces convert of all files.",
  "  -B   [UNIXBACKUP compile option enabled] Save a backup copy of each",
  "         overwritten file in foo~ or foo~99999 format.",
  "  -C   Use case-insensitive matching.",
  "  -D   Skip restoration of timestamps for extracted directories.  On VMS this",
  "         is on by default and -D essentially becames -DD.",
  "  -DD  Skip restoration of timestamps for all entries.",
  "  -E   [MacOS (not Unix Apple)]  Display contents of MacOS extra field during",
  "         restore.",
  "  -F   [Acorn] Suppress removal of NFS filetype extension.  [Non-Acorn if",
  "         ACORN_FTYPE_NFS] Translate filetype and append to name.",
  "  -i   [MacOS] Ignore filenames in MacOS extra field.  Instead, use name in",
  "         standard header.",
  "  -j   Junk paths and deposit all files in extraction directory.",
  "  -J   [BeOS] Junk file attributes.  [MacOS] Ignore MacOS specific info.",
  "  -K   [AtheOS, BeOS, Unix] Restore SUID/SGID/Tacky file attributes.",
  "  -L   Convert to lowercase any names from uppercase only file system.",
  "  -LL  Convert all files to lowercase.",
  "  -M   Pipe all output through internal pager similar to Unix more(1).",
  "  -n   Never overwrite existing files.  Skip extracting that file, no prompt.",
  "  -N   [Amiga] Extract file comments as Amiga filenotes.",
  "  -o   Overwrite existing files without prompting.  Useful with -f.  Use with",
  "         care.",
  "  -P p Use password p to decrypt files.  THIS IS INSECURE!  Some OS show",
  "         command line to other users.",
  "  -q   Perform operations quietly.  The more q (as in -qq) the quieter.",
  "  -s   [OS/2, NT, MS-DOS] Convert spaces in filenames to underscores.",
  "  -S   [VMS] Convert text files (-a, -aa) into Stream_LF format.",
  "  -U   [UNICODE enabled] Show non-local characters as #Uxxxx or #Lxxxxxx ASCII",
  "         text escapes where x is hex digit.  [Old] -U used to leave names",
  "         uppercase if created on MS-DOS, VMS, etc.  See -L.",
  "  -UU  [UNICODE enabled] Disable use of stored UTF-8 paths.  Note that UTF-8",
  "         paths stored as native local paths are still processed as Unicode.",
  "  -V   Retain VMS file version numbers.",
  "  -W   [Only if WILD_STOP_AT_DIR] Modify pattern matching so ? and * do not",
  "         match directory separator /, but ** does.  Allows matching at specific",
  "         directory levels.",
  "  -X   [VMS, Unix, OS/2, NT, Tandem] Restore UICs and ACL entries under VMS,",
  "         or UIDs/GIDs under Unix, or ACLs under certain network-enabled",
  "         versions of OS/2, or security ACLs under Windows NT.  Can require",
  "         user privileges.",
  "  -XX  [NT] Extract NT security ACLs after trying to enable additional",
  "         system privileges.",
  "  -Y   [VMS] Treat archived name endings of .nnn as VMS version numbers.",
  "  -$   [MS-DOS, OS/2, NT] Restore volume label if extraction medium is",
  "         removable.  -$$ allows fixed media (hard drives) to be labeled.",
  "  -/ e [Acorn] Use e as extension list.",
  "  -:   [All but Acorn, VM/CMS, MVS, Tandem] Allow extract archive members into",
  "         locations outside of current extraction root folder.  This allows",
  "         paths such as ../foo to be extracted above the current extraction",
  "         directory, which can be a security problem.",
  "  -^   [Unix] Allow control characters in names of extracted entries.  Usually",
  "         this is not a good thing and should be avoided.",
  "  -2   [VMS] Force unconditional conversion of names to ODS-compatible names.",
  "         Default is to exploit destination file system, preserving cases and",
  "         extended name characters on ODS5 and applying ODS2 filtering on ODS2.",
  "",
  "",
  "Wildcards:",
  "  Internally unzip supports the following wildcards:",
  "    ?       (or %% or #, depending on OS) matches any single character",
  "    *       matches any number of characters, including zero",
  "    [list]  matches char in list (regex), can do range [ac-f], all but [!bf]",
  "  If port supports [], must escape [ as [[]",
  "  For shells that expand wildcards, escape (\\* or \"*\") so unzip can recurse.",
  "",
  "Include and Exclude:",
  "  -i pattern pattern ...   include files that match a pattern",
  "  -x pattern pattern ...   exclude files that match a pattern",
  "  Patterns are paths with optional wildcards and match paths as stored in",
  "  archive.  Exclude and include lists end at next option or end of line.",
  "    unzip archive -x pattern pattern ...",
  "",
  "Multi-part (split) archives (archives created as a set of split files):",
  "  Currently split archives are not readable by unzip.  A workaround is",
  "  to use zip to convert the split archive to a single-file archive and",
  "  use unzip on that.  See the manual page for Zip 3.0 or later.",
  "",
  "Streaming (piping into unzip):",
  "  Currently unzip does not support streaming.  The funzip utility can be",
  "  used to process the first entry in a stream.",
  "    cat archive | funzip",
  "",
  "Testing archives:",
  "  -t        test contents of archive",
  "  This can be modified using -q for quieter operation, and -qq for even",
  "  quieter operation.",
  "",
  "Unicode:",
  "  If compiled with Unicode support, unzip automatically handles archives",
  "  with Unicode entries.  Currently Unicode on Win32 systems is limited.",
  "  Characters not in the current character set are shown as ASCII escapes",
  "  in the form #Uxxxx where the Unicode character number fits in 16 bits,",
  "  or #Lxxxxxx where it doesn't, where x is the ASCII character for a hex",
  "  digit.",
  "",
  "",
  "zipinfo options (these are used in zipinfo mode (unzip -Z ...)):",
  "  -1  List names only, one per line.  No headers/trailers.  Good for scripts.",
  "  -2  List names only as -1, but include headers, trailers, and comments.",
  "  -s  List archive entries in short Unix ls -l format.  Default list format.",
  "  -m  List in long Unix ls -l format.  As -s, but includes compression %.",
  "  -l  List in long Unix ls -l format.  As -m, but compression in bytes.",
  "  -v  List zipfile information in verbose, multi-page format.",
  "  -h  List header line.  Includes archive name, actual size, total files.",
  "  -M  Pipe all output through internal pager similar to Unix more(1) command.",
  "  -t  List totals for files listed or for all files.  Includes uncompressed",
  "        and compressed sizes, and compression factors.",
  "  -T  Print file dates and times in a sortable decimal format (yymmdd.hhmmss)",
  "        Default date and time format is a more human-readable version.",
  "  -U  [UNICODE] If entry has a UTF-8 Unicode path, display any characters",
  "        not in current character set as text #Uxxxx and #Lxxxxxx escapes",
  "        representing the Unicode character number of the character in hex.",
  "  -UU [UNICODE]  Disable use of any UTF-8 path information.",
  "  -z  Include archive comment if any in listing.",
  "",
  "",
  "funzip stream extractor:",
  "  funzip extracts the first member in an archive to stdout.  Typically",
  "  used to unzip the first member of a stream or pipe.  If a file argument",
  "  is given, read from that file instead of stdin.",
  "",
  "funzip command line:",
  "  funzip [-password] [input[.zip|.gz]]",
  "",
  "",
  "unzipsfx self extractor:",
  "  Self-extracting archives made with unzipsfx are no more (or less)",
  "  portable across different operating systems than unzip executables.",
  "  In general, a self-extracting archive made on a particular Unix system,",
  "  for example, will only self-extract under the same flavor of Unix.",
  "  Regular unzip may still be used to extract embedded archive however.",
  "",
  "unzipsfx command line:",
  "  <unzipsfx+archive_filename>  [-options] [file(s) ... [-x xfile(s) ...]]",
  "",
  "unzipsfx options:",
  "  -c, -p - Output to pipe.  (See above for unzip.)",
  "  -f, -u - Freshen and Update, as for unzip.",
  "  -t     - Test embedded archive.  (Can be used to list contents.)",
  "  -z     - Print archive comment.  (See unzip above.)",
  "",
  "unzipsfx modifiers:",
  "  Most unzip modifiers are supported.  These include",
  "  -a     - Convert text files.",
  "  -n     - Never overwrite.",
  "  -o     - Overwrite without prompting.",
  "  -q     - Quiet operation.",
  "  -C     - Match names case-insensitively.",
  "  -j     - Junk paths.",
  "  -V     - Keep version numbers.",
  "  -s     - Convert spaces to underscores.",
  "  -$     - Restore volume label.",
  "",
  "If unzipsfx compiled with SFX_EXDIR defined, -d option also available:",
  "  -d exd - Extract to directory exd.",
  "By default, all files extracted to current directory.  This option",
  "forces extraction to specified directory.",
  "",
  "See unzipsfx manual page for more information.",
  ""
    };

    for (i = 0; i < sizeof(text)/sizeof(char *); i++)
    {
        Info(slide, 0, ((char *)slide, "%s\n", text[i]));
    }
} /* end function help_extended() */


/********************************/
/* Function show_version_info() */
/********************************/

static void show_version_info(__G)
    __GDEF
{
    if (uO.qflag > 3)                           /* "unzip -vqqqq" */
        Info(slide, 0, ((char *)slide, "%d\n",
          (UZ_MAJORVER*100 + UZ_MINORVER*10 + UZ_PATCHLEVEL)));
    else {
        char *envptr;
        int numopts = 0;

        Info(slide, 0, ((char *)slide, UnzipUsageLine1v,
          UZ_MAJORVER, UZ_MINORVER, UZ_PATCHLEVEL, UZ_BETALEVEL,
          VersionDate));
        Info(slide, 0, ((char *)slide,
          UnzipUsageLine2v));
        version(__G);
        Info(slide, 0, ((char *)slide, CompileOptions));
        Info(slide, 0, ((char *)slide, CompileOptFormat,
          Copyright_Clean));
        ++numopts;
#ifdef DEBUG
        Info(slide, 0, ((char *)slide, CompileOptFormat,
          UDebug));
        ++numopts;
#endif
        Info(slide, 0, ((char *)slide, CompileOptFormat,
          SetDirAttrib));
        ++numopts;
        Info(slide, 0, ((char *)slide, CompileOptFormat,
          Use_Unshrink));
        ++numopts;
        sprintf((char *)(slide+256), UseZlib,
          ZLIB_VERSION, zlibVersion());
        Info(slide, 0, ((char *)slide, CompileOptFormat,
          (char *)(slide+256)));
        ++numopts;
        Info(slide, 0, ((char *)slide, Decryption,
          CR_MAJORVER, CR_MINORVER, CR_BETA_VER,
          CryptDate));
        ++numopts;
        if (numopts == 0)
            Info(slide, 0, ((char *)slide,
              CompileOptFormat,
              None));

        Info(slide, 0, ((char *)slide, EnvOptions));
        envptr = getenv(EnvUnZip);
        Info(slide, 0, ((char *)slide, EnvOptFormat,
          EnvUnZip,
          (envptr == (char *)NULL || *envptr == 0)?
          None : envptr));
        envptr = getenv(EnvUnZip2);
        Info(slide, 0, ((char *)slide, EnvOptFormat,
          EnvUnZip2,
          (envptr == (char *)NULL || *envptr == 0)?
          None : envptr));
        envptr = getenv(EnvZipInfo);
        Info(slide, 0, ((char *)slide, EnvOptFormat,
          EnvZipInfo,
          (envptr == (char *)NULL || *envptr == 0)?
          None : envptr));
        envptr = getenv(EnvZipInfo2);
        Info(slide, 0, ((char *)slide, EnvOptFormat,
          EnvZipInfo2,
          (envptr == (char *)NULL || *envptr == 0)?
          None : envptr));
    }
} /* end function show_version() */
