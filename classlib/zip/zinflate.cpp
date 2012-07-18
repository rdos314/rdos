/*
  Copyright (c) 1990-2008 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2007-Mar-04 or later
  (the contents of which are also included in unzip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/* inflate.c -- by Mark Adler
   version c17e, 30 Mar 2007 */


/* Copyright history:
   - Starting with UnZip 5.41 of 16-April-2000, this source file
     is covered by the Info-Zip LICENSE cited above.
   - Prior versions of this source file, found in UnZip source packages
     up to UnZip 5.40, were put in the public domain.
     The original copyright note by Mark Adler was:
         "You can do whatever you like with this source file,
         though I would prefer that if you modify it and
         redistribute it that you include comments to that effect
         with your name and the date.  Thank you."

   History:
   vers    date          who           what
   ----  ---------  --------------  ------------------------------------
    a    ~~ Feb 92  M. Adler        used full (large, one-step) lookup table
    b1   21 Mar 92  M. Adler        first version with partial lookup tables
    b2   21 Mar 92  M. Adler        fixed bug in fixed-code blocks
    b3   22 Mar 92  M. Adler        sped up match copies, cleaned up some
    b4   25 Mar 92  M. Adler        added prototypes; removed window[] (now
                                    is the responsibility of unzip.h--also
                                    changed name to slide[]), so needs diffs
                                    for unzip.c and unzip.h (this allows
                                    compiling in the small model on MSDOS);
                                    fixed cast of q in huft_build();
    b5   26 Mar 92  M. Adler        got rid of unintended macro recursion.
    b6   27 Mar 92  M. Adler        got rid of nextbyte() routine.  fixed
                                    bug in inflate_fixed().
    c1   30 Mar 92  M. Adler        removed lbits, dbits environment variables.
                                    changed BMAX to 16 for explode.  Removed
                                    OUTB usage, and replaced it with flush()--
                                    this was a 20% speed improvement!  Added
                                    an explode.c (to replace unimplod.c) that
                                    uses the huft routines here.  Removed
                                    register union.
    c2    4 Apr 92  M. Adler        fixed bug for file sizes a multiple of 32k.
    c3   10 Apr 92  M. Adler        reduced memory of code tables made by
                                    huft_build significantly (factor of two to
                                    three).
    c4   15 Apr 92  M. Adler        added NOMEMCPY do kill use of memcpy().
                                    worked around a Turbo C optimization bug.
    c5   21 Apr 92  M. Adler        added the WSIZE #define to allow reducing
                                    the 32K window size for specialized
                                    applications.
    c6   31 May 92  M. Adler        added some typecasts to eliminate warnings
    c7   27 Jun 92  G. Roelofs      added some more typecasts (444:  MSC bug).
    c8    5 Oct 92  J-l. Gailly     added ifdef'd code to deal with PKZIP bug.
    c9    9 Oct 92  M. Adler        removed a memory error message (~line 416).
    c10  17 Oct 92  G. Roelofs      changed ULONG/UWORD/byte to unsigned long/unsigned short/unsigned char,
                                    removed old inflate, renamed inflate_entry
                                    to inflate, added Mark's fix to a comment.
   c10.5 14 Dec 92  M. Adler        fix up error messages for incomplete trees.
    c11   2 Jan 93  M. Adler        fixed bug in detection of incomplete
                                    tables, and removed assumption that EOB is
                                    the longest code (bad assumption).
    c12   3 Jan 93  M. Adler        make tables for fixed blocks only once.
    c13   5 Jan 93  M. Adler        allow all zero length codes (pkzip 2.04c
                                    outputs one zero length code for an empty
                                    distance tree).
    c14  12 Mar 93  M. Adler        made inflate.c standalone with the
                                    introduction of inflate.h.
   c14b  16 Jul 93  G. Roelofs      added (unsigned) typecast to w at 470.
   c14c  19 Jul 93  J. Bush         changed v[N_MAX], l[288], ll[28x+3x] arrays
                                    to static for Amiga.
   c14d  13 Aug 93  J-l. Gailly     de-complicatified Mark's c[*p++]++ thing.
   c14e   8 Oct 93  G. Roelofs      changed memset() to memzero().
   c14f  22 Oct 93  G. Roelofs      renamed quietflg to qflag; made Trace()
                                    conditional; added inflate_free().
   c14g  28 Oct 93  G. Roelofs      changed l/(lx+1) macro to pointer (Cray bug)
   c14h   7 Dec 93  C. Ghisler      huft_build() optimizations.
   c14i   9 Jan 94  A. Verheijen    set fixed_t{d,l} to NULL after freeing;
                    G. Roelofs      check NEXTBYTE macro for EOF.
   c14j  23 Jan 94  G. Roelofs      removed Ghisler "optimizations"; ifdef'd
                                    EOF check.
   c14k  27 Feb 94  G. Roelofs      added some typecasts to avoid warnings.
   c14l   9 Apr 94  G. Roelofs      fixed split comments on preprocessor lines
                                    to avoid bug in Encore compiler.
   c14m   7 Jul 94  P. Kienitz      modified to allow assembler version of
                                    inflate_codes() (define ASM_INFLATECODES)
   c14n  22 Jul 94  G. Roelofs      changed fprintf to macro for DLL versions
   c14o  23 Aug 94  C. Spieler      added a newline to a debug statement;
                    G. Roelofs      added another typecast to avoid MSC warning
   c14p   4 Oct 94  G. Roelofs      added (voidp *) cast to free() argument
   c14q  30 Oct 94  G. Roelofs      changed fprintf macro to MESSAGE()
   c14r   1 Nov 94  G. Roelofs      fixed possible redefinition of CHECK_EOF
   c14s   7 May 95  S. Maxwell      OS/2 DLL globals stuff incorporated;
                    P. Kienitz      "fixed" ASM_INFLATECODES macro/prototype
   c14t  18 Aug 95  G. Roelofs      added UZinflate() to use zlib functions;
                                    changed voidp to void; moved huft_build()
                                    and huft_free() to end of file
   c14u   1 Oct 95  G. Roelofs      moved G into definition of MESSAGE macro
   c14v   8 Nov 95  P. Kienitz      changed ASM_INFLATECODES to use a regular
                                    call with __G__ instead of a macro
    c15   3 Aug 96  M. Adler        fixed bomb-bug on random input data (Adobe)
   c15b  24 Aug 96  M. Adler        more fixes for random input data
   c15c  28 Mar 97  G. Roelofs      changed USE_ZLIB fatal exit code from
                                    PK_MEM2 to PK_MEM3
    c16  20 Apr 97  J. Altman       added memzero(v[]) in huft_build()
   c16b  29 Mar 98  C. Spieler      modified DLL code for slide redirection
   c16c  04 Apr 99  C. Spieler      fixed memory leaks when processing gets
                                    stopped because of input data errors
   c16d  05 Jul 99  C. Spieler      take care of FLUSH() return values and
                                    stop processing in case of errors
    c17  31 Dec 00  C. Spieler      added preliminary support for Deflate64
   c17a  04 Feb 01  C. Spieler      complete integration of Deflate64 support
   c17b  16 Feb 02  C. Spieler      changed type of "extra bits" arrays and
                                    corresponding huft_build() parameter e from
                                    unsigned short into unsigned char, to save space
   c17c   9 Mar 02  C. Spieler      fixed NEEDBITS() "read beyond EOF" problem
                                    with CHECK_EOF enabled
   c17d  23 Jul 05  C. Spieler      fixed memory leaks in inflate_dynamic()
                                    when processing invalid compressed literal/
                                    distance table data
   c17e  30 Mar 07  C. Spieler      in inflate_dynamic(), initialize tl and td
                                    to prevent freeing unallocated huft tables
                                    when processing invalid compressed data and
                                    hitting premature EOF, do not reuse td as
                                    temp work ptr during tables decoding
 */


/*
   Inflate deflated (PKZIP's method 8 compressed) data.  The compression
   method searches for as much of the current string of bytes (up to a
   length of 258) in the previous 32K bytes.  If it doesn't find any
   matches (of at least length 3), it codes the next byte.  Otherwise, it
   codes the length of the matched string and its distance backwards from
   the current position.  There is a single Huffman code that codes both
   single bytes (called "literals") and match lengths.  A second Huffman
   code codes the distance information, which follows a length code.  Each
   length or distance code actually represents a base value and a number
   of "extra" (sometimes zero) bits to get to add to the base value.  At
   the end of each deflated block is a special end-of-block (EOB) literal/
   length code.  The decoding process is basically: get a literal/length
   code; if EOB then done; if a literal, emit the decoded byte; if a
   length then get the distance and emit the referred-to bytes from the
   sliding window of previously emitted data.

   There are (currently) three kinds of inflate blocks: stored, fixed, and
   dynamic.  The compressor outputs a chunk of data at a time and decides
   which method to use on a chunk-by-chunk basis.  A chunk might typically
   be 32K to 64K, uncompressed.  If the chunk is uncompressible, then the
   "stored" method is used.  In this case, the bytes are simply stored as
   is, eight bits per byte, with none of the above coding.  The bytes are
   preceded by a count, since there is no longer an EOB code.

   If the data are compressible, then either the fixed or dynamic methods
   are used.  In the dynamic method, the compressed data are preceded by
   an encoding of the literal/length and distance Huffman codes that are
   to be used to decode this block.  The representation is itself Huffman
   coded, and so is preceded by a description of that code.  These code
   descriptions take up a little space, and so for small blocks, there is
   a predefined set of codes, called the fixed codes.  The fixed method is
   used if the block ends up smaller that way (usually for quite small
   chunks); otherwise the dynamic method is used.  In the latter case, the
   codes are customized to the probabilities in the current block and so
   can code it much better than the pre-determined fixed codes can.

   The Huffman codes themselves are decoded using a multi-level table
   lookup, in order to maximize the speed of decoding plus the speed of
   building the decoding tables.  See the comments below that precede the
   lbits and dbits tuning parameters.

   GRR:  return values(?)
           0  OK
           1  incomplete table
           2  bad input
           3  not enough memory
         the following return codes are passed through from FLUSH() errors
           50 (PK_DISK)   "overflow of output space"
           80 (IZ_CTRLC)  "canceled by user's request"
 */


/*
   Notes beyond the 1.93a appnote.txt:

   1. Distance pointers never point before the beginning of the output
      stream.
   2. Distance pointers can point back across blocks, up to 32k away.
   3. There is an implied maximum of 7 bits for the bit length table and
      15 bits for the actual data.
   4. If only one code exists, then it is encoded using one bit.  (Zero
      would be more efficient, but perhaps a little confusing.)  If two
      codes exist, they are coded using one bit each (0 and 1).
   5. There is no way of sending zero distance codes--a dummy must be
      sent if there are none.  (History: a pre 2.0 version of PKZIP would
      store blocks with no distance codes, but this was discovered to be
      too harsh a criterion.)  Valid only for 1.93a.  2.04c does allow
      zero distance codes, which is sent as one code of zero bits in
      length.
   6. There are up to 286 literal/length codes.  Code 256 represents the
      end-of-block.  Note however that the static length tree defines
      288 codes just to fill out the Huffman codes.  Codes 286 and 287
      cannot be used though, since there is no length base or extra bits
      defined for them.  Similarily, there are up to 30 distance codes.
      However, static trees define 32 codes (all 5 bits) to fill out the
      Huffman codes, but the last two had better not show up in the data.
   7. Unzip can check dynamic Huffman blocks for complete code sets.
      The exception is that a single code would not be complete (see #4).
   8. The five bits following the block type is really the number of
      literal codes sent minus 257.
   9. Length codes 8,16,16 are interpreted as 13 length codes of 8 bits
      (1+6+6).  Therefore, to output three times the length, you output
      three codes (1+1+1), whereas to output four times the same length,
      you only need two codes (1+3).  Hmm.
  10. In the tree reconstruction algorithm, Code = Code + Increment
      only if BitLength(i) is not zero.  (Pretty obvious.)
  11. Correction: 4 Bits: # of Bit Length codes - 4     (4 - 19)
  12. Note: length code 284 can represent 227-258, but length code 285
      really is 258.  The last length deserves its own, short code
      since it gets used a lot in very redundant files.  The length
      258 is special since 258 - 3 (the min match length) is 255.
  13. The literal/length and distance code bit lengths are read as a
      single stream of lengths.  It is possible (and advantageous) for
      a repeat code (16, 17, or 18) to go across the boundary between
      the two sets of lengths.
  14. The Deflate64 (PKZIP method 9) variant of the compression algorithm
      differs from "classic" deflate in the following 3 aspect:
      a) The size of the sliding history window is expanded to 64 kByte.
      b) The previously unused distance codes #30 and #31 code distances
         from 32769 to 49152 and 49153 to 65536.  Both codes take 14 bits
         of extra data to determine the exact position in their 16 kByte
         range.
      c) The last lit/length code #285 gets a different meaning. Instead
         of coding a fixed maximum match length of 258, it is used as a
         "generic" match length code, capable of coding any length from
         3 (min match length + 0) to 65538 (min match length + 65535).
         This means that the length code #285 takes 16 bits (!) of uncoded
         extra data, added to a fixed min length of 3.
      Changes a) and b) would have been transparent for valid deflated
      data, but change c) requires to switch decoder configurations between
      Deflate and Deflate64 modes.
 */


#define PKZIP_BUG_WORKAROUND    /* PKZIP 1.93a problem--live with it */

/*
    inflate.h must supply the unsigned char slide[WSIZE] array, the void typedef
    (void if (void *) is accepted, else char) and the NEXTBYTE,
    FLUSH() and memzero macros.  If the window size is not 32K, it
    should also define WSIZE.  If INFMOD is defined, it can include
    compiled functions to support the NEXTBYTE and/or FLUSH() macros.
    There are defaults for NEXTBYTE and FLUSH() below for use as
    examples of what those functions need to do.  Normally, you would
    also want FLUSH() to compute a crc on the data.  inflate.h also
    needs to provide these typedefs:

        typedef unsigned char unsigned char;
        typedef unsigned short unsigned short;
        typedef unsigned long unsigned long;

    This module uses the external functions malloc() and free() (and
    probably memset() or bzero() in the memzero() macro).  Their
    prototypes are normally found in <string.h> and <stdlib.h>.
 */

#define __INFLATE_C     /* identifies this source module */

/* #define DEBUG */
#define INFMOD          /* tell inflate.h to include code to be compiled */
#include "inflate.h"


/* marker for "unused" huft code, and corresponding check macro */
#define INVALID_CODE 99
#define IS_INVALID_CODE(c)  ((c) == INVALID_CODE)

#ifndef NEXTBYTE        /* default is to simply get a byte from stdin */
#  define NEXTBYTE getchar()
#endif

#ifndef MESSAGE   /* only used twice, for fixed strings--NOT general-purpose */
#  define MESSAGE(str,len,flag)  fprintf(stderr,(char *)(str))
#endif

/* Warning: the fwrite above might not work on 16-bit compilers, since
   0x8000 might be interpreted as -32,768 by the library function.  When
   support for Deflate64 is enabled, the window size is 64K and the
   simple fwrite statement is definitely broken for 16-bit compilers. */

#ifndef Trace
#  ifdef DEBUG
#    define Trace(x) fprintf x
#  else
#    define Trace(x)
#  endif
#endif


/*---------------------------------------------------------------------------*/

/* Beginning with zlib version 1.2.0, a new inflate callback interface is
   provided that allows tighter integration of the zlib inflate service
   into unzip's extraction framework.
   The advantages are:
   - uses the windows buffer supplied by the unzip code; this saves one
     copy process between zlib's internal decompression buffer and unzip's
     post-decompression output buffer and improves performance.
   - does not pull in unused checksum code (adler32).
   The preprocessor flag NO_ZLIBCALLBCK can be set to force usage of the
   old zlib 1.1.x interface, for testing purpose.
 */


static unsigned zlib_inCB OF((void FAR *pG, unsigned char FAR * FAR * pInbuf));
static int zlib_outCB OF((void FAR *pG, unsigned char FAR *outbuf,
                          unsigned outcnt));

static unsigned zlib_inCB(void *pG, unsigned char ** pInbuf)
{
    *pInbuf = G.inbuf;
    return fillinbuf(__G);
}

static int zlib_outCB(void *pG, unsigned char *outbuf, unsigned outcnt)
{
    return ((G.mem_mode) ? memflush(__G__ outbuf, (unsigned long)(outcnt))
                         : flush(__G__ outbuf, (unsigned long)(outcnt), 0));
}


/*
   GRR:  return values for both original inflate() and UZinflate()
           0  OK
           1  incomplete table(?)
           2  bad input
           3  not enough memory
 */

/**************************/
/*  Function UZinflate()  */
/**************************/

int UZinflate(int is_defl64)
/* decompress an inflated entry using the zlib routines */
{
    int retval = 0;     /* return code: 0 = "no error" */
    int err=Z_OK;

    if (!G.inflInit) {
        /* local buffer for efficiency */
        const char *zlib_RtVersion = zlibVersion();

        /* only need to test this stuff once */
        if ((zlib_RtVersion[0] != ZLIB_VERSION[0]) ||
            (zlib_RtVersion[2] != ZLIB_VERSION[2])) {
            Info(slide, 0x21, ((char *)slide,
              "error:  incompatible zlib version (expected %s, found %s)\n",
              ZLIB_VERSION, zlib_RtVersion));
            return 3;
        } else if (strcmp(zlib_RtVersion, ZLIB_VERSION) != 0)
            Info(slide, 0x21, ((char *)slide,
              "warning:  different zlib version (expected %s, using %s)\n",
              ZLIB_VERSION, zlib_RtVersion));

        G.dstrm.zalloc = (alloc_func)Z_NULL;
        G.dstrm.zfree = (free_func)Z_NULL;

        G.inflInit = 1;
    }

    {
        /* For the callback interface, inflate initialization has to
           be called before each decompression call.
         */
        {
            unsigned i;
            int windowBits;
            /* windowBits = log2(WSIZE) */
            for (i = (unsigned)WSIZE, windowBits = 0;
                 !(i & 1);  i >>= 1, ++windowBits);
            if ((unsigned)windowBits > (unsigned)15)
                windowBits = 15;
            else if (windowBits < 8)
                windowBits = 8;

            Trace((stderr, "initializing inflate()\n"));
            err = inflateBackInit(&G.dstrm, windowBits, redirSlide);

            if (err == Z_MEM_ERROR)
                return 3;
            else if (err != Z_OK) {
                Trace((stderr, "oops!  (inflateBackInit() err = %d)\n", err));
                return 2;
            }
        }

        G.dstrm.next_in = G.inptr;
        G.dstrm.avail_in = G.incnt;

        err = inflateBack(&G.dstrm, zlib_inCB, &G, zlib_outCB, &G);
        if (err != Z_STREAM_END) {
            if (err == Z_DATA_ERROR || err == Z_STREAM_ERROR) {
                Trace((stderr, "oops!  (inflateBack() err = %d)\n", err));
                retval = 2;
            } else if (err == Z_MEM_ERROR) {
                retval = 3;
            } else if (err == Z_BUF_ERROR) {
                Trace((stderr, "oops!  (inflateBack() err = %d)\n", err));
                if (G.dstrm.next_in == Z_NULL) {
                    /* input failure */
                    Trace((stderr, "  inflateBack() input failure\n"));
                    retval = 2;
                } else {
                    /* output write failure */
                    retval = (G.disk_full != 0 ? PK_DISK : IZ_CTRLC);
                }
            } else {
                Trace((stderr, "oops!  (inflateBack() err = %d)\n", err));
                retval = 2;
            }
        }
        if (G.dstrm.next_in != NULL) {
            G.inptr = (unsigned char *)G.dstrm.next_in;
            G.incnt = G.dstrm.avail_in;
        }

        err = inflateBackEnd(&G.dstrm);
        if (err != Z_OK) {
            Trace((stderr, "oops!  (inflateBackEnd() err = %d)\n", err));
            if (retval == 0)
                retval = 2;
        }
    }

    return retval;
}



/*
 * GRR:  moved huft_build() and huft_free() down here; used by explode()
 *       and fUnZip regardless of whether USE_ZLIB defined or not
 */


/* If BMAX needs to be larger than 16, then h and x[] should be unsigned long. */
#define BMAX 16         /* maximum bit length of any code (16 for explode) */
#define N_MAX 288       /* maximum number of codes in any set */


int huft_build(const unsigned *b, unsigned n, unsigned s, const unsigned short *d, const unsigned char *e, struct huft **t, unsigned *m)
/* Given a list of code lengths and a maximum table size, make a set of
   tables to decode that set of codes.  Return zero on success, one if
   the given code set is incomplete (the tables are still built in this
   case), two if the input is invalid (all zero length codes or an
   oversubscribed set of lengths), and three if not enough memory.
   The code with value 256 is special, and the tables are constructed
   so that no bits beyond that code are fetched when that code is
   decoded. */
{
  unsigned a;                   /* counter for codes of length k */
  unsigned c[BMAX+1];           /* bit length count table */
  unsigned el;                  /* length of EOB code (value 256) */
  unsigned f;                   /* i repeats in table every f entries */
  int g;                        /* maximum code length */
  int h;                        /* table level */
  register unsigned i;          /* counter, current code */
  register unsigned j;          /* counter */
  register int k;               /* number of bits in current code */
  int lx[BMAX+1];               /* memory for l[-1..BMAX-1] */
  int *l = lx+1;                /* stack of bits per table */
  register unsigned *p;         /* pointer into c[], b[], or v[] */
  register struct huft *q;      /* points to current table */
  struct huft r;                /* table entry for structure assignment */
  struct huft *u[BMAX];         /* table stack */
  unsigned v[N_MAX];            /* values in order of bit length */
  register int w;               /* bits before this table == (l * h) */
  unsigned x[BMAX+1];           /* bit offsets, then code stack */
  unsigned *xp;                 /* pointer into x */
  int y;                        /* number of dummy codes added */
  unsigned z;                   /* number of entries in current table */


  /* Generate counts for each bit length */
  el = n > 256 ? b[256] : BMAX; /* set length of EOB code, if any */
  memset((char *)c, 0, sizeof(c));
  p = (unsigned *)b;  i = n;
  do {
    c[*p]++; p++;               /* assume all entries <= BMAX */
  } while (--i);
  if (c[0] == n)                /* null input--all zero length codes */
  {
    *t = (struct huft *)NULL;
    *m = 0;
    return 0;
  }


  /* Find minimum and maximum length, bound *m by those */
  for (j = 1; j <= BMAX; j++)
    if (c[j])
      break;
  k = j;                        /* minimum code length */
  if (*m < j)
    *m = j;
  for (i = BMAX; i; i--)
    if (c[i])
      break;
  g = i;                        /* maximum code length */
  if (*m > i)
    *m = i;


  /* Adjust last length count to fill out codes, if needed */
  for (y = 1 << j; j < i; j++, y <<= 1)
    if ((y -= c[j]) < 0)
      return 2;                 /* bad input: more codes than bits */
  if ((y -= c[i]) < 0)
    return 2;
  c[i] += y;


  /* Generate starting offsets into the value table for each length */
  x[1] = j = 0;
  p = c + 1;  xp = x + 2;
  while (--i) {                 /* note that i == g from above */
    *xp++ = (j += *p++);
  }


  /* Make a table of values in order of bit lengths */
  memset((char *)v, 0, sizeof(v));
  p = (unsigned *)b;  i = 0;
  do {
    if ((j = *p++) != 0)
      v[x[j]++] = i;
  } while (++i < n);
  n = x[g];                     /* set n to length of v */


  /* Generate the Huffman codes and for each, make the table entries */
  x[0] = i = 0;                 /* first Huffman code is zero */
  p = v;                        /* grab values in bit order */
  h = -1;                       /* no tables yet--level -1 */
  w = l[-1] = 0;                /* no bits decoded yet */
  u[0] = (struct huft *)NULL;   /* just to keep compilers happy */
  q = (struct huft *)NULL;      /* ditto */
  z = 0;                        /* ditto */

  /* go through the bit lengths (k already is bits in shortest code) */
  for (; k <= g; k++)
  {
    a = c[k];
    while (a--)
    {
      /* here i is the Huffman code of length k bits for value *p */
      /* make tables up to required level */
      while (k > w + l[h])
      {
        w += l[h++];            /* add bits already decoded */

        /* compute minimum size table less than or equal to *m bits */
        z = (z = g - w) > *m ? *m : z;                  /* upper limit */
        if ((f = 1 << (j = k - w)) > a + 1)     /* try a k-w bit table */
        {                       /* too few codes for k-w bit table */
          f -= a + 1;           /* deduct codes from patterns left */
          xp = c + k;
          while (++j < z)       /* try smaller tables up to z bits */
          {
            if ((f <<= 1) <= *++xp)
              break;            /* enough codes to use up j bits */
            f -= *xp;           /* else deduct codes from patterns */
          }
        }
        if ((unsigned)w + j > el && (unsigned)w < el)
          j = el - w;           /* make EOB code end at table */
        z = 1 << j;             /* table entries for j-bit table */
        l[h] = j;               /* set table size in stack */

        /* allocate and link in new table */
        if ((q = (struct huft *)malloc((z + 1)*sizeof(struct huft))) ==
            (struct huft *)NULL)
        {
          if (h)
            huft_free(u[0]);
          return 3;             /* not enough memory */
        }
#ifdef DEBUG
        G.hufts += z + 1;         /* track memory usage */
#endif
        *t = q + 1;             /* link to list for huft_free() */
        *(t = &(q->v.t)) = (struct huft *)NULL;
        u[h] = ++q;             /* table starts after link */

        /* connect to last table, if there is one */
        if (h)
        {
          x[h] = i;             /* save pattern for backing up */
          r.b = (unsigned char)l[h-1];    /* bits to dump before this table */
          r.e = (unsigned char)(32 + j);  /* bits in this table */
          r.v.t = q;            /* pointer to this table */
          j = (i & ((1 << w) - 1)) >> (w - l[h-1]);
          u[h-1][j] = r;        /* connect to last table */
        }
      }

      /* set up table entry in r */
      r.b = (unsigned char)(k - w);
      if (p >= v + n)
        r.e = INVALID_CODE;     /* out of values--invalid code */
      else if (*p < s)
      {
        r.e = (unsigned char)(*p < 256 ? 32 : 31);  /* 256 is end-of-block code */
        r.v.n = (unsigned short)*p++;                /* simple code is just the value */
      }
      else
      {
        r.e = e[*p - s];        /* non-simple--look up in lists */
        r.v.n = d[*p++ - s];
      }

      /* fill code-like entries with r */
      f = 1 << (k - w);
      for (j = i >> w; j < z; j += f)
        q[j] = r;

      /* backwards increment the k-bit code i */
      for (j = 1 << (k - 1); i & j; j >>= 1)
        i ^= j;
      i ^= j;

      /* backup over finished tables */
      while ((i & ((1 << w) - 1)) != x[h])
        w -= l[--h];            /* don't need to update q */
    }
  }


  /* return actual size of base table */
  *m = l[0];


  /* Return true (1) if we were given an incomplete table */
  return y != 0 && g != 1;
}



int huft_free(struct huft *t)
/* Free the malloc'ed tables built by huft_build(), which makes a linked
   list of the tables it made, with the links in a dummy first entry of
   each table. */
{
  register struct huft *p, *q;


  /* Go through linked list, freeing from the malloced (t[-1]) address. */
  p = t;
  while (p != (struct huft *)NULL)
  {
    q = (--p)->v.t;
    free((void *)p);
    p = q;
  }
  return 0;
}
