/*
  Copyright (c) 1990-2005 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2000-Apr-09 or later
  (the contents of which are also included in unzip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/*----------------------------------------------------------------*
 | envargs - add default options from environment to command line
 |----------------------------------------------------------------
 | Author: Bill Davidsen, original 10/13/91, revised 23 Oct 1991.
 | This program is in the public domain.
 |----------------------------------------------------------------
 | Minor program notes:
 |  1. Yes, the indirection is a tad complex
 |  2. Parentheses were added where not needed in some cases
 |     to make the action of the code less obscure.
 |----------------------------------------------------------------
 | UnZip notes: 24 May 92 ("v1.4"):
 |  1. #include "unzip.h" for prototypes (24 May 92)
 |  2. changed ch to type char (24 May 92)
 |  3. added an ifdef to avoid Borland warnings (24 May 92)
 |  4. included Rich Wales' mksargs() routine (for MS-DOS, maybe
 |     OS/2? NT?) (4 Dec 93)
 |  5. added alternate-variable string envstr2 (21 Apr 94)
 |  6. added support for quoted arguments (6 Jul 96)
 *----------------------------------------------------------------*/


#define __ENVARGS_C     /* identifies this source module */
#include "unzip.h"

#  define ISspace(c) isspace((unsigned)c)

static int count_args OF((const char *));


/* envargs() returns PK-style error code */

int envargs(int *Pargc, char ***Pargv, const char *envstr, const char *envstr2)
{
    char *envptr;       /* value returned by getenv */
    char *bufptr;       /* copy of env info */
    int argc = 0;       /* internal arg count */
    register int ch;    /* spare temp value */
    char **argv;        /* internal arg vector */
    char **argvect;     /* copy of vector address */

    /* see if anything in the environment */
    if ((envptr = getenv(envstr)) != (char *)NULL)        /* usual var */
        while (ISspace(*envptr))        /* must discard leading spaces */
            envptr++;
    if (envptr == (char *)NULL || *envptr == '\0')
        if ((envptr = getenv(envstr2)) != (char *)NULL)   /* alternate var */
            while (ISspace(*envptr))
                envptr++;
    if (envptr == (char *)NULL || *envptr == '\0')
        return PK_OK;

    bufptr = (char *)malloc(1 + strlen(envptr));
    if (bufptr == (char *)NULL)
        return PK_MEM;
    strcpy(bufptr, envptr);

    /* count the args so we can allocate room for them */
    argc = count_args(bufptr);
    /* allocate a vector large enough for all args */
    argv = (char **)malloc((argc + *Pargc + 1) * sizeof(char *));
    if (argv == (char **)NULL) {
        free(bufptr);
        return PK_MEM;
    }
    argvect = argv;

    /* copy the program name first, that's always true */
    *(argv++) = *((*Pargv)++);

    /* copy the environment args next, may be changed */
    do {
        /* we do not support backslash-quoting of quotes in quoted
         * strings under DOS_FLX_NLM_OS2_W32, because backslashes are
         * directory separators and double quotes are illegal in filenames */
        if (*bufptr == '"') {
            *(argv++) = ++bufptr;
            while ((ch = *bufptr) != '\0' && ch != '\"')
                bufptr++;
            if (ch != '\0')
                *(bufptr++) = '\0';
        } else {
            *(argv++) = bufptr;
            while ((ch = *bufptr) != '\0' && !ISspace(ch))
                bufptr++;
            if (ch != '\0')
                *(bufptr++) = '\0';
        }
        while ((ch = *bufptr) != '\0' && ISspace(ch))
            bufptr++;
    } while (ch);

    /* now save old argc and copy in the old args */
    argc += *Pargc;
    while (--(*Pargc))
        *(argv++) = *((*Pargv)++);

    /* finally, add a NULL after the last arg, like Unix */
    *argv = (char *)NULL;

    /* save the values and return, indicating succes */
    *Pargv = argvect;
    *Pargc = argc;

    return PK_OK;
}



static int count_args(const char *s)
{
    int count = 0;
    char ch;

    do {
        /* count and skip args */
        ++count;
        if (*s == '\"') {
            ++s;                /* leading quote */
            while ((ch = *s) != '\0' && ch != '\"')
                s++;
            if (*s)
                ++s;        /* trailing quote */
        } else
        while ((ch = *s) != '\0' && !ISspace(ch))  /* note else-clauses above */
            s++;
        while ((ch = *s) != '\0' && ISspace(ch))
            s++;
    } while (ch);

    return count;
}

