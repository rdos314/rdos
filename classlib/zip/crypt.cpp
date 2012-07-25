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
#include "oldunzip.h"

#define FALSE 0

#define IZ_PWLEN  80    /* input buffer size for reading encryption key */
#define RAND_HEAD_LEN  12       /* length of encryption random header */

#define GLOBAL(g) G.g

static int testp OF((const unsigned char *h));
static int testkey OF((const unsigned char *h, const char *key));

static int keys[3];       /* keys defining the pseudo-random sequence */

#ifndef Trace
#    define Trace(x)
#endif

/***********************************************************************
 * Get the password and set up keys for current zipfile member.
 * Return PK_ class error.
 */
int decrypt(const char *passwrd)
{
    unsigned short b;
    int n, r;
    unsigned char h[RAND_HEAD_LEN];

    Trace("\n[incnt = %d]: ", UnzipClass.FInCount);

    /* get header once (turn off "encrypted" flag temporarily so we don't
     * try to decrypt the same data twice) */
    UnzipClass.FEncrypted = FALSE;
    UnzipClass.DeferInput();
    for (n = 0; n < RAND_HEAD_LEN; n++) {
        b = UnzipClass.GetNextByte();
        h[n] = (unsigned char)b;
        Trace(" (%02x)", h[n]);
    }
    UnzipClass.UndeferInput();
    UnzipClass.FEncrypted = TRUE;

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
        if (!testp(h))
            return PK_COOL;   /* existing password OK (else prompt for new) */
        else if (GLOBAL(nopwd))
            return PK_WARN;   /* user indicated no more prompting */
    } else if ((GLOBAL(key) = (char *)malloc(IZ_PWLEN+1)) == (char *)NULL)
        return PK_MEM2;

    /* try a few keys */
    n = 0;
    do {
        r = (*G.decr_passwd)((void *)&G, &n, GLOBAL(key), IZ_PWLEN+1,
                             UnzipClass.FInputFileName.GetData(), UnzipClass.FCurrFileName);
        if (r == IZ_PW_ERROR) {         /* internal error in fetch of PW */
            free (GLOBAL(key));
            GLOBAL(key) = NULL;
            return PK_MEM2;
        }
        if (r != IZ_PW_ENTERED) {       /* user replied "skip" or "skip all" */
            *GLOBAL(key) = '\0';        /*   We try the NIL password, ... */
            n = 0;                      /*   and cancel fetch for this item. */
        }
        if (!testp(h))
            return PK_COOL;
        if (r == IZ_PW_CANCELALL)       /* User replied "Skip all" */
            GLOBAL(nopwd) = TRUE;       /*   inhibit any further PW prompt! */
    } while (n > 0);

    return PK_WARN;

} /* end function decrypt() */



/***********************************************************************
 * Test the password.  Return -1 if bad, 0 if OK.
 */
static int testp(const unsigned char *h)
{
    int r;
    char *key_translated;

    /* On systems with "obscure" native character coding (e.g., EBCDIC),
     * the first test translates the password to the "main standard"
     * character coding. */

    /* first try, test password as supplied on the extractor's host */
    r = testkey(h, GLOBAL(key));

    if (r != 0) {
        /* now prepare for second (and maybe third) test with translated pwd */
        if ((key_translated = (char *)malloc(strlen(GLOBAL(key)) + 1)) == (char *)NULL)
            return -1;
        /* second try, password translated to alternate ("standard") charset */
        r = testkey(h, str2oem(key_translated, GLOBAL(key)));
        free(key_translated);
    }

    return r;

} /* end function testp() */


static int testkey(const unsigned char *h, const char *key)
{
    unsigned short b;
    int n;
    unsigned char *p;
    unsigned char hh[RAND_HEAD_LEN]; /* decrypted header */

    /* set keys and save the encrypted header */
    UnzipClass.SetupEncryption(key);
    memcpy(hh, h, RAND_HEAD_LEN);

    /* check password */
    for (n = 0; n < RAND_HEAD_LEN; n++) {
        hh[n] = UnzipClass.ZDecode(hh[n]);
        Trace(" %02x", hh[n]);
    }

    Trace("\n  lrec.crc= %08lx  crec.crc= %08lx  pInfo->ExtLocHdr= %s\n",
      UnzipClass.FCurrFile.crc32, GLOBAL(pInfo->crc),
      GLOBAL(pInfo->ExtLocHdr) ? "true":"false");
    Trace("  incnt = %d  unzip offset into zipfile = %ld\n",
      UnzipClass.FInCount,
      UnzipClass.FBufStart+(UnzipClass.FInPtr-UnzipClass.FInBuf));

    /* same test as in zipbare(): */

    b = hh[RAND_HEAD_LEN-1];
    Trace("  b = %02x  (crc >> 24) = %02x  (lrec.time >> 8) = %02x\n",
      b, (unsigned short)(UnzipClass.FCurrFile.crc32 >> 24),
      ((unsigned short)UnzipClass.FCurrFile.last_mod_dos_datetime >> 8) & 0xff);
    if (b != (GLOBAL(pInfo->ExtLocHdr) ?
        ((unsigned short)UnzipClass.FCurrFile.last_mod_dos_datetime >> 8) & 0xff :
        (unsigned short)(UnzipClass.FCurrFile.crc32 >> 24)))
        return -1;  /* bad */

    /* password OK:  decrypt current buffer contents before leaving */
    for (n = (long)UnzipClass.FInCount > UnzipClass.FDecompSize ?
             (int)UnzipClass.FDecompSize : UnzipClass.FInCount,
         p = (unsigned char *)UnzipClass.FInPtr; n--; p++)
        *p = UnzipClass.ZDecode(*p);
    return 0;       /* OK */

} /* end function testkey() */

