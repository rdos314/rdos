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

#include "oldunzip.h"

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
char *getp(const char *m, char *p, int n)
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
            if ((c = (char)RdosReadKeyboard()) == '\r')
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
