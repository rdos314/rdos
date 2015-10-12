/*
  ttyio.h - Zip 3

  Copyright (c) 1990-2005 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2005-Feb-10 or later
  (the contents of which are also included in zip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/*
   ttyio.h
 */

#ifndef __ttyio_h   /* don't include more than once */
#define __ttyio_h

#include "crypt.h"  /* ensure that encryption header file has been seen */

#if (CRYPT || (defined(UNZIP) && !defined(FUNZIP)))
/*
 * Non-echo keyboard/console input support is needed and enabled.
 */

/* Function prototypes */

/* The following systems supply a `non-echo' character input function "getch()"
 * (or an alias) and do not need the echoff() / echon() function pair.
 */


#ifdef NLM
#  define echoff(f)
#  define echon()
#  define HAVE_WORKING_GETCH
#endif

#ifdef DOS_H68_OS2_W32
#  define echoff(f)
#  define echon()
#  ifdef WIN32
#    ifndef getch
#      define getch() getch_win32()
#    endif
#  else /* !WIN32 */
#    ifdef __EMX__
#      ifndef getch
#        define getch() _read_kbd(0, 1, 0)
#      endif
#    else /* !__EMX__ */
#      ifdef __GO32__
#        include <pc.h>
#        define getch() getkey()
#      else /* !__GO32__ */
#        include <conio.h>
#      endif /* ?__GO32__ */
#    endif /* ?__EMX__ */
#  endif /* ?WIN32 */
#  define HAVE_WORKING_GETCH
#endif /* DOS_H68_OS2_W32 */

/* For all other systems, ttyio.c supplies the two functions Echoff() and
 * Echon() for suppressing and (re)enabling console input echo.
 */
#ifndef echoff
#  define echoff(f)  Echoff(__G__ f)
#  define echon()    Echon(__G)
   void Echoff OF((__GPRO__ int f));
   void Echon OF((__GPRO));
#endif

/* this stuff is used by MORE and also now by the ctrl-S code; fileio.c only */
#if (defined(UNZIP) && !defined(FUNZIP))
#  ifdef HAVE_WORKING_GETCH
#    define FGETCH(f)  getch()
#  endif
#  ifndef FGETCH
     /* default for all systems where no getch()-like function is available */
     int zgetch OF((__GPRO__ int f));
#    define FGETCH(f)  zgetch(__G__ f)
#  endif
#endif /* UNZIP && !FUNZIP */

#if (CRYPT && !defined(WINDLL))
   char *getp OF((__GPRO__ ZCONST char *m, char *p, int n));
#endif

#else /* !(CRYPT || (UNZIP && !FUNZIP)) */

/*
 * No need for non-echo keyboard/console input; provide dummy definitions.
 */
#define echoff(f)
#define echon()

#endif /* ?(CRYPT || (UNZIP && !FUNZIP)) */

#endif /* !__ttyio_h */
