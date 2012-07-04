/*
  Copyright (c) 1990-2008 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2000-Apr-09 or later
  (the contents of which are also included in zip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/*---------------------------------------------------------------------------

  ttyio.c

  This file contains routines for doing console input/output, including code
  for non-echoing input.  It is used by the encryption/decryption code but
  does not contain any restricted code itself.  This file is shared between
  Info-ZIP's Zip and UnZip.

  Contains:  echo()         (VMS only)
             Echon()        (Unix only)
             Echoff()       (Unix only)
             screensize()   (Unix only)
             zgetch()       (Unix, VMS, and non-Unix/VMS versions)
             getp()         ("PC," Unix/Atari/Be, VMS/VMCMS/MVS)

  ---------------------------------------------------------------------------*/

#define __TTYIO_C       /* identifies this source module */

#include "zip.h"
#include "crypt.h"

#if (CRYPT || (defined(UNZIP) && !defined(FUNZIP)))
/* Non-echo console/keyboard input is needed for (en/de)cryption's password
 * entry, and for UnZip(SFX)'s MORE and Pause features.
 * (The corresponding #endif is found at the end of this module.)
 */

#include "ttyio.h"

#ifdef ZIP
#  ifdef GLOBAL          /* used in Amiga system headers, maybe others too */
#    undef GLOBAL
#  endif
#  define GLOBAL(g) g
#else
#  define GLOBAL(g) G.g
#endif

#ifdef UNZIP            /* Zip handles this with the unix/configure script */
#  ifndef _POSIX_VERSION
#    if (defined(SYSV) || defined(CRAY)) &&  !defined(__MINT__)
#      ifndef USE_SYSV_TERMIO
#        define USE_SYSV_TERMIO
#      endif
#      ifdef COHERENT
#        ifndef HAVE_TERMIO_H
#          define HAVE_TERMIO_H
#        endif
#        ifdef HAVE_SYS_TERMIO_H
#          undef HAVE_SYS_TERMIO_H
#        endif
#      else /* !COHERENT */
#        ifdef HAVE_TERMIO_H
#          undef HAVE_TERMIO_H
#        endif
#        ifndef HAVE_SYS_TERMIO_H
#           define HAVE_SYS_TERMIO_H
#        endif
#      endif /* ?COHERENT */
#    endif /* (SYSV || CRAY) && !__MINT__ */
#  endif /* !_POSIX_VERSION */
#  if !(defined(BSD4_4) || defined(SYSV) || defined(__convexc__))
#    ifndef NO_FCNTL_H
#      define NO_FCNTL_H
#    endif
#  endif /* !(BSD4_4 || SYSV || __convexc__) */
#endif /* UNZIP */

#ifdef HAVE_TERMIOS_H
#  ifndef USE_POSIX_TERMIOS
#    define USE_POSIX_TERMIOS
#  endif
#endif

#if (defined(HAVE_TERMIO_H) || defined(HAVE_SYS_TERMIO_H))
#  ifndef USE_SYSV_TERMIO
#    define USE_SYSV_TERMIO
#  endif
#endif

#if (defined(UNZIP) && !defined(FUNZIP) && defined(UNIX) && defined(MORE))
#  include <sys/ioctl.h>
#  define GOT_IOCTL_H
   /* int ioctl OF((int, int, zvoid *));   GRR: may need for some systems */
#endif


#if CRYPT                       /* getp() is only used with full encryption */

/*
 * Simple compile-time check for source compatibility between
 * zcrypt and ttyio:
 */
#if (!defined(CR_MAJORVER) || (CR_MAJORVER < 2) || (CR_MINORVER < 7))
   error:  This Info-ZIP tool requires zcrypt 2.7 or later.
#endif

/*
 * Get a password of length n-1 or less into *p using the prompt *m.
 * The entered password is not echoed.
 */

/*
 * For the AMIGA, getch() is defined as Agetch(), which is in
 * amiga/filedate.c; SAS/C 6.x provides a getch(), but since Agetch()
 * uses the infrastructure that is already in place in filedate.c, it is
 * smaller.  With this function, echoff() and echon() are not needed.
 *
 * For the MAC, a non-echo macgetch() function is defined in the MacOS
 * specific sources which uses the event handling mechanism of the
 * desktop window manager to get a character from the keyboard.
 *
 * For the other systems in this section, a non-echo getch() function
 * is either contained the C runtime library (conio package), or getch()
 * is defined as an alias for a similar system specific RTL function.
 */

/* This is the getp() function for all systems (with TTY type user interface)
 * that supply a working `non-echo' getch() function for "raw" console input.
 */
char *getp(ZCONST char *m, char *p, int n)
{
    char c;                     /* one-byte buffer for read() to use */
    int i;                      /* number of characters input */
    char *w;                    /* warning on retry */

    /* get password */
    w = "";
    do {
        RdosWriteString(w);
        RdosWriteString(m);
        i = 0;
        do {                    /* read line, keeping first n characters */
            if ((c = (char)getch()) == '\r')
                c = '\n';       /* until user hits CR */
            if (c == 8 || c == 127) {
                if (i > 0) i--; /* the `backspace' and `del' keys works */
            }
            else if (i < n)
                p[i++] = c;     /* truncate past n */
        } while (c != '\n');
        RdosWriteString("\r\n");
        w = "(line too long--try again)\r\n";
    } while (p[i-1] != '\n');
    p[i-1] = 0;                 /* terminate at newline */

    return p;                   /* return pointer to password */

} /* end function getp() */

#endif /* CRYPT */
#endif /* CRYPT || (UNZIP && !FUNZIP) */
