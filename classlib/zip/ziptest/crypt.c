/*
  Copyright (c) 1990-2008 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2007-Mar-4 or later
  (the contents of which are also included in zip.h) for terms of use.
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

   /* For the encoding task used in Zip (and ZipCloak), we want to initialize
      the crypt algorithm with some reasonably unpredictable bytes, see
      the crypthead() function. The standard rand() library function is
      used to supply these `random' bytes, which in turn is initialized by
      a srand() call. The srand() function takes an "unsigned" (at least 16bit)
      seed value as argument to determine the starting point of the rand()
      pseudo-random number generator.
      This seed number is constructed as "Seed = Seed1 .XOR. Seed2" with
      Seed1 supplied by the current time (= "(unsigned)time()") and Seed2
      as some (hopefully) nondeterministic bitmask. On many (most) systems,
      we use some "process specific" number, as the PID or something similar,
      but when nothing unpredictable is available, a fixed number may be
      sufficient.
      NOTE:
      1.) This implementation requires the availability of the following
          standard UNIX C runtime library functions: time(), rand(), srand().
          On systems where some of them are missing, the environment that
          incorporates the crypt routines must supply suitable replacement
          functions.
      2.) It is a very bad idea to use a second call to time() to set the
          "Seed2" number! In this case, both "Seed1" and "Seed2" would be
          (almost) identical, resulting in a (mostly) "zero" constant seed
          number passed to srand().

      The implementation environment defined in the "zip.h" header should
      supply a reasonable definition for ZCR_SEED2 (an unsigned number; for
      most implementations of rand() and srand(), only the lower 16 bits are
      significant!). An example that works on many systems would be
           "#define ZCR_SEED2  (unsigned)getpid()".
      The default definition for ZCR_SEED2 supplied below should be regarded
      as a fallback to allow successful compilation in "beta state"
      environments.
    */
#include <time.h>     /* time() function supplies first part of crypt seed */

   /* "last resort" source for second part of crypt seed pattern */
#define ZCR_SEED2 (unsigned)3141592654L     /* use PI as default pattern */
#define GLOBAL(g) g

local z_uint4 keys[3];       /* keys defining the pseudo-random sequence */

#define Trace(x)

#include "crc32.h"

#define CRY_CRC_TAB  CRC_32_TAB

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
int update_keys(__G__ c)
    __GDEF
    int c;                      /* byte of plain text */
{
    GLOBAL(keys[0]) = CRC32(GLOBAL(keys[0]), c, CRY_CRC_TAB);
    GLOBAL(keys[1]) = (GLOBAL(keys[1])
                       + (GLOBAL(keys[0]) & 0xff))
                      * 134775813L + 1;
    {
      register int keyshift = (int)(GLOBAL(keys[1]) >> 24);
      GLOBAL(keys[2]) = CRC32(GLOBAL(keys[2]), keyshift, CRY_CRC_TAB);
    }
    return c;
}


/***********************************************************************
 * Initialize the encryption keys and the random header according to
 * the given password.
 */
void init_keys(__G__ passwd)
    __GDEF
    ZCONST char *passwd;        /* password string with which to modify keys */
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
 * Write encryption header to file zfile using the password passwd
 * and the cyclic redundancy check crc.
 */
void crypthead(passwd, crc)
    ZCONST char *passwd;         /* password string */
    ulg crc;                     /* crc of file being encrypted */
{
    int n;                       /* index in random header */
    int t;                       /* temporary */
    int c;                       /* random byte */
    uch header[RAND_HEAD_LEN];   /* random header */
    static unsigned calls = 0;   /* ensure different random header each time */

    /* First generate RAND_HEAD_LEN-2 random bytes. We encrypt the
     * output of rand() to get less predictability, since rand() is
     * often poorly implemented.
     */
    if (++calls == 1) {
        srand((unsigned)time(NULL) ^ ZCR_SEED2);
    }
    init_keys(passwd);
    for (n = 0; n < RAND_HEAD_LEN-2; n++) {
        c = (rand() >> 7) & 0xff;
        header[n] = (uch)zencode(c, t);
    }
    /* Encrypt random header (last two bytes is high word of crc) */
    init_keys(passwd);
    for (n = 0; n < RAND_HEAD_LEN-2; n++) {
        header[n] = (uch)zencode(header[n], t);
    }
    header[RAND_HEAD_LEN-2] = (uch)zencode((int)(crc >> 16) & 0xff, t);
    header[RAND_HEAD_LEN-1] = (uch)zencode((int)(crc >> 24) & 0xff, t);
    bfwrite(header, 1, RAND_HEAD_LEN, BFWRITE_DATA);
}


/***********************************************************************
 * If requested, encrypt the data in buf, and in any case call fwrite()
 * with the arguments to zfwrite().  Return what fwrite() returns.
 *
 * now write to global y
 *
 * A bug has been found when encrypting large files that don't
 * compress.  See trees.c for the details and the fix.
 */
unsigned zfwrite(buf, item_size, nb)
    zvoid *buf;                 /* data buffer */
    extent item_size;           /* size of each item in bytes */
    extent nb;                  /* number of items */
{
    int t;                      /* temporary */

    if (key != (char *)NULL) {  /* key is the global password pointer */
        ulg size;               /* buffer size */
        char *p = (char *)buf;  /* steps through buffer */

        /* Encrypt data in buffer */
        for (size = item_size*(ulg)nb; size != 0; p++, size--) {
            *p = (char)zencode(*p, t);
        }
    }
    /* Write the buffer out */
    return bfwrite(buf, item_size, nb, BFWRITE_DATA);
}

