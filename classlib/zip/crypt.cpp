/*
  Copyright (c) 1990-2007 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2005-Feb-10 or later
  (the contents of which are also included in (un)zip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/*
  crypt.c (full version) by Info-ZIP.      Last revised:  [see crypt.h]

  The main encryption/decryption source code for Info-Zip software was
  originally written in Europe.  To the best of our knowledge, it can
  be freely distributed in both source and object forms from any country,
  including the USA under License Exception TSU of the U.S. Export
  Administration Regulations (section 740.13(e)) of 6 June 2002.

  NOTE on copyright history:
  Previous versions of this source package (up to version 2.8) were
  not copyrighted and put in the public domain.  If you cannot comply
  with the Info-Zip LICENSE, you may want to look for one of those
  public domain versions.
 */

/*
  This encryption code is a direct transcription of the algorithm from
  Roger Schlafly, described by Phil Katz in the file appnote.txt.  This
  file (appnote.txt) is distributed with the PKZIP program (even in the
  version without encryption capabilities).
 */

#define ZCRYPT_INTERNAL
#include "zip.h"
#include "crypt.h"
#include "ttyio.h"

# define FALSE 0

#define GLOBAL(g) G.g

local int testp OF((__GPRO__ const unsigned char *h));
local int testkey OF((__GPRO__ const unsigned char *h, const char *key));

local int keys[3];       /* keys defining the pseudo-random sequence */

#ifndef Trace
#    define Trace(x)
#endif

#include "crc32.h"

/***********************************************************************
 * Return the next byte in the pseudo-random sequence
 */
int decrypt_byte(__G)
    __GDEF
{
    unsigned temp;  /* POTENTIAL BUG:  temp*(temp^1) may overflow in an
                     * unpredictable manner on 16-bit systems; not a problem
                     * with any known compiler so far, though */

    temp = ((unsigned)GLOBAL(keys[2]) & 0xffff) | 2;
    return (int)(((temp * (temp ^ 1)) >> 8) & 0xff);
}

/***********************************************************************
 * Update the encryption keys with the next byte of plain text
 */
int update_keys(int c)
    __GDEF
{
    GLOBAL(keys[0]) = CRC32(GLOBAL(keys[0]), c, G.crc_32_tab);
    GLOBAL(keys[1]) = (GLOBAL(keys[1])
                       + (GLOBAL(keys[0]) & 0xff))
                      * 134775813L + 1;
    {
      register int keyshift = (int)(GLOBAL(keys[1]) >> 24);
      GLOBAL(keys[2]) = CRC32(GLOBAL(keys[2]), keyshift, G.crc_32_tab);
    }
    return c;
}


/***********************************************************************
 * Initialize the encryption keys and the random header according to
 * the given password.
 */
void init_keys(const char *passwd)
{
    GLOBAL(keys[0]) = 305419896L;
    GLOBAL(keys[1]) = 591751049L;
    GLOBAL(keys[2]) = 878082192L;
    while (*passwd != '\0') {
        update_keys(__G__ (int)*passwd);
        passwd++;
    }
}

/***********************************************************************
 * Get the password and set up keys for current zipfile member.
 * Return PK_ class error.
 */
int decrypt(const char *passwrd)
{
    unsigned short b;
    int n, r;
    unsigned char h[RAND_HEAD_LEN];

    Trace((stdout, "\n[incnt = %d]: ", GLOBAL(incnt)));

    /* get header once (turn off "encrypted" flag temporarily so we don't
     * try to decrypt the same data twice) */
    GLOBAL(pInfo->encrypted) = FALSE;
    defer_leftover_input(__G);
    for (n = 0; n < RAND_HEAD_LEN; n++) {
        b = NEXTBYTE;
        h[n] = (unsigned char)b;
        Trace((stdout, " (%02x)", h[n]));
    }
    undefer_input(__G);
    GLOBAL(pInfo->encrypted) = TRUE;

    if (GLOBAL(newzip)) { /* this is first encrypted member in this zipfile */
        GLOBAL(newzip) = FALSE;
        if (passwrd != (char *)NULL) { /* user gave password on command line */
            if (!GLOBAL(key)) {
                if ((GLOBAL(key) = (char *)malloc(strlen(passwrd)+1)) ==
                    (char *)NULL)
                    return PK_MEM2;
                strcpy(GLOBAL(key), passwrd);
                GLOBAL(nopwd) = TRUE;  /* inhibit password prompting! */
            }
        } else if (GLOBAL(key)) { /* get rid of previous zipfile's key */
            free(GLOBAL(key));
            GLOBAL(key) = (char *)NULL;
        }
    }

    /* if have key already, test it; else allocate memory for it */
    if (GLOBAL(key)) {
        if (!testp(__G__ h))
            return PK_COOL;   /* existing password OK (else prompt for new) */
        else if (GLOBAL(nopwd))
            return PK_WARN;   /* user indicated no more prompting */
    } else if ((GLOBAL(key) = (char *)malloc(IZ_PWLEN+1)) == (char *)NULL)
        return PK_MEM2;

    /* try a few keys */
    n = 0;
    do {
        r = (*G.decr_passwd)((void *)&G, &n, GLOBAL(key), IZ_PWLEN+1,
                             GLOBAL(zipfn), GLOBAL(filename));
        if (r == IZ_PW_ERROR) {         /* internal error in fetch of PW */
            free (GLOBAL(key));
            GLOBAL(key) = NULL;
            return PK_MEM2;
        }
        if (r != IZ_PW_ENTERED) {       /* user replied "skip" or "skip all" */
            *GLOBAL(key) = '\0';        /*   We try the NIL password, ... */
            n = 0;                      /*   and cancel fetch for this item. */
        }
        if (!testp(__G__ h))
            return PK_COOL;
        if (r == IZ_PW_CANCELALL)       /* User replied "Skip all" */
            GLOBAL(nopwd) = TRUE;       /*   inhibit any further PW prompt! */
    } while (n > 0);

    return PK_WARN;

} /* end function decrypt() */



/***********************************************************************
 * Test the password.  Return -1 if bad, 0 if OK.
 */
local int testp(const unsigned char *h)
{
    int r;
    char *key_translated;

    /* On systems with "obscure" native character coding (e.g., EBCDIC),
     * the first test translates the password to the "main standard"
     * character coding. */

    /* first try, test password as supplied on the extractor's host */
    r = testkey(__G__ h, GLOBAL(key));

    if (r != 0) {
        /* now prepare for second (and maybe third) test with translated pwd */
        if ((key_translated = (char *)malloc(strlen(GLOBAL(key)) + 1)) == (char *)NULL)
            return -1;
        /* second try, password translated to alternate ("standard") charset */
        r = testkey(__G__ h, str2oem(key_translated, GLOBAL(key)));
        free(key_translated);
    }

    return r;

} /* end function testp() */


local int testkey(const unsigned char *h, const char *key)
{
    unsigned short b;
    int n;
    unsigned char *p;
    unsigned char hh[RAND_HEAD_LEN]; /* decrypted header */

    /* set keys and save the encrypted header */
    init_keys(__G__ key);
    memcpy(hh, h, RAND_HEAD_LEN);

    /* check password */
    for (n = 0; n < RAND_HEAD_LEN; n++) {
        zdecode(hh[n]);
        Trace((stdout, " %02x", hh[n]));
    }

    Trace((stdout,
      "\n  lrec.crc= %08lx  crec.crc= %08lx  pInfo->ExtLocHdr= %s\n",
      GLOBAL(lrec.crc32), GLOBAL(pInfo->crc),
      GLOBAL(pInfo->ExtLocHdr) ? "true":"false"));
    Trace((stdout, "  incnt = %d  unzip offset into zipfile = %ld\n",
      GLOBAL(incnt),
      GLOBAL(cur_zipfile_bufstart)+(GLOBAL(inptr)-GLOBAL(inbuf))));

    /* same test as in zipbare(): */

    b = hh[RAND_HEAD_LEN-1];
    Trace((stdout, "  b = %02x  (crc >> 24) = %02x  (lrec.time >> 8) = %02x\n",
      b, (unsigned short)(GLOBAL(lrec.crc32) >> 24),
      ((unsigned short)GLOBAL(lrec.last_mod_dos_datetime) >> 8) & 0xff));
    if (b != (GLOBAL(pInfo->ExtLocHdr) ?
        ((unsigned short)GLOBAL(lrec.last_mod_dos_datetime) >> 8) & 0xff :
        (unsigned short)(GLOBAL(lrec.crc32) >> 24)))
        return -1;  /* bad */

    /* password OK:  decrypt current buffer contents before leaving */
    for (n = (long)GLOBAL(incnt) > GLOBAL(csize) ?
             (int)GLOBAL(csize) : GLOBAL(incnt),
         p = GLOBAL(inptr); n--; p++)
        zdecode(*p);
    return 0;       /* OK */

} /* end function testkey() */

