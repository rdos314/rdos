/*
  Copyright (c) 1990-2004 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2000-Apr-09 or later
  (the contents of which are also included in zip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/*
   ttyio.h
 */

#ifndef __ttyio_h   /* don't include more than once */
#define __ttyio_h

/* Function prototypes */

/* The following systems supply a `non-echo' character input function "getch()"
 * (or an alias) and do not need the echoff() / echon() function pair.
 */

#define echoff(f)
#define echon()
#define getch() RdosReadKeyboard()
#define HAVE_WORKING_GETCH

/* this stuff is used by MORE and also now by the ctrl-S code; fileio.c only */
#define FGETCH(f)  getch()

char *getp OF((const char *m, char *p, int n));

#endif /* !__ttyio_h */
