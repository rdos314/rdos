/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# Adapted from Info-ZIP
#
# The Info-ZIP license may be found at:  
# ftp://ftp.info-zip.org/pub/infozip/license.html
#
# zipexpl.cpp
# Explode extractor class
#
########################################################################*/

#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h> 

#include "rdos.h"
#include "zipexpl.h"
#include "unzip.h"

#define FALSE 0
#define TRUE !FALSE

/* If BMAX needs to be larger than 16, then h and x[] should be unsigned long. */
#define BMAX 16         /* maximum bit length of any code (16 for explode) */
#define N_MAX 288       /* maximum number of codes in any set */

#define INVALID_CODE 99

/* And'ing with mask_bits[n] masks the lower n bits */
static const unsigned near mask_bits[17] = {
    0x0000,
    0x0001, 0x0003, 0x0007, 0x000f, 0x001f, 0x003f, 0x007f, 0x00ff,
    0x01ff, 0x03ff, 0x07ff, 0x0fff, 0x1fff, 0x3fff, 0x7fff, 0xffff
};

/* Tables for length and distance */
static const unsigned short cplen2[] =
        {2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
        18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
        35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
        52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65};
static const unsigned short cplen3[] =
        {3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
        19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
        36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52,
        53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66};
static const unsigned char extra[] =
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        8};
static const unsigned short cpdist4[] =
        {1, 65, 129, 193, 257, 321, 385, 449, 513, 577, 641, 705,
        769, 833, 897, 961, 1025, 1089, 1153, 1217, 1281, 1345, 1409, 1473,
        1537, 1601, 1665, 1729, 1793, 1857, 1921, 1985, 2049, 2113, 2177,
        2241, 2305, 2369, 2433, 2497, 2561, 2625, 2689, 2753, 2817, 2881,
        2945, 3009, 3073, 3137, 3201, 3265, 3329, 3393, 3457, 3521, 3585,
        3649, 3713, 3777, 3841, 3905, 3969, 4033};
static const unsigned short cpdist8[] =
        {1, 129, 257, 385, 513, 641, 769, 897, 1025, 1153, 1281,
        1409, 1537, 1665, 1793, 1921, 2049, 2177, 2305, 2433, 2561, 2689,
        2817, 2945, 3073, 3201, 3329, 3457, 3585, 3713, 3841, 3969, 4097,
        4225, 4353, 4481, 4609, 4737, 4865, 4993, 5121, 5249, 5377, 5505,
        5633, 5761, 5889, 6017, 6145, 6273, 6401, 6529, 6657, 6785, 6913,
        7041, 7169, 7297, 7425, 7553, 7681, 7809, 7937, 8065};

/*##########################################################################
#
#   Name       : TUnzipExplodeExtractor::TUnzipExplodeExtractor
#
#   Purpose....: Constructor for explode extractor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipExplodeExtractor::TUnzipExplodeExtractor(int InputFileHandle, TUnzipFile *File, const char *DestFileName)
  : TUnzipExtractor(InputFileHandle, File, DestFileName)
{
}

/*##########################################################################
#
#   Name       : TUnzipExplodeExtractor::~TUnzipExplodeExtractor
#
#   Purpose....: Destructor for explode extractor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipExplodeExtractor::~TUnzipExplodeExtractor()
{
}

/*##########################################################################
#
#   Name       : TUnzipExplodeExtractor::ExplodeGetTree
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExplodeExtractor::ExplodeGetTree(unsigned *l, unsigned n)
/* Get the bit lengths for a code representation from the compressed
   stream.  If get_tree() returns 4, then there is an error in the data.
   Otherwise zero is returned. */
{
  unsigned i;           /* bytes remaining in list */
  unsigned k;           /* lengths entered */
  unsigned j;           /* number of codes */
  unsigned b;           /* bit length for those codes */


  /* get bit lengths */
  i = GetNextByte() + 1;                     /* length/count pairs to read */
  k = 0;                                /* next code */
  do {
    b = ((j = GetNextByte()) & 0xf) + 1;     /* bits in code (1..16) */
    j = ((j & 0xf0) >> 4) + 1;          /* codes with those bits (1..16) */
    if (k + j > n)
      return 4;                         /* don't overflow l[] */
    do {
      l[k++] = b;
    } while (--j);
  } while (--i);
  return k != n ? 4 : 0;                /* should have read n of them */
}

/*##########################################################################
#
#   Name       : TUnzipExplodeExtractor::BuildHuft
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExplodeExtractor::BuildHuft(const unsigned *b, unsigned n, unsigned s, const unsigned short *d, const unsigned char *e, TUnzipHuft **t, unsigned *m)
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
  register TUnzipHuft *q;      /* points to current table */
  struct TUnzipHuft r;                /* table entry for structure assignment */
  struct TUnzipHuft *u[BMAX];         /* table stack */
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
    *t = 0;
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
  u[0] = 0;                     /* just to keep compilers happy */
  q = 0;                        /* ditto */
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
        q = new struct TUnzipHuft[z + 1];
        if (q == 0)
        {
          if (h)
            FreeHuft(u[0]);
          return 3;             /* not enough memory */
        }

        *t = q + 1;             /* link to list for huft_free() */
        *(t = &(q->v.t)) = 0;
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


/*##########################################################################
#
#   Name       : TUnzipExplodeExtractor::FreeHuft
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipExplodeExtractor::FreeHuft(struct TUnzipHuft *t)
/* Free the malloc'ed tables built by huft_build(), which makes a linked
   list of the tables it made, with the links in a dummy first entry of
   each table. */
{
  register struct TUnzipHuft *p, *q;


  /* Go through linked list, freeing from the malloced (t[-1]) address. */
  p = t;
  while (p != 0)
  {
    q = (--p)->v.t;
    delete p;
    p = q;
  }
}

/*##########################################################################
#
#   Explode macros that cannot be integrated!
#
##########################################################################*/

#define GETBITS(n) {while(k<(n)){b|=((unsigned long)GetNextByte())<<k;k+=8;}}
#define ADVANCEBITS(n) {b>>=(n);k-=(n);}

#define DECODEHUFT(htab, bits, mask) {\
  GETBITS((unsigned)(bits))\
  t = (htab) + ((~(unsigned)b)&(mask));\
  while (1) {\
    ADVANCEBITS(t->b)\
    if ((e=t->e) <= 32) break;\
    if (e == INVALID_CODE) return 1;\
    e &= 31;\
    GETBITS(e)\
    t = t->v.t + ((~(unsigned)b)&mask_bits[e]);\
  }\
}

/*##########################################################################
#
#   Name       : TUnzipExplodeExtractor::ExplodeLit
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExplodeExtractor::ExplodeLit(struct TUnzipHuft *tb, struct TUnzipHuft *tl, struct TUnzipHuft *td, unsigned bb, unsigned bl, unsigned bd, unsigned bdl)
/* Decompress the imploded data using coded literals and a sliding
   window (of size 2^(6+bdl) bytes). */
{
  unsigned long s;      /* bytes to decompress */
  register unsigned e;  /* table entry flag/number of extra bits */
  unsigned n, d;        /* length and index for copy */
  unsigned w;           /* current window position */
  struct TUnzipHuft *t;       /* pointer to table entry */
  unsigned mb, ml, md;  /* masks for bb, bl, and bd bits */
  unsigned mdl;         /* mask for bdl (distance lower) bits */
  register unsigned long b;       /* bit buffer */
  register unsigned k;  /* number of bits in bit buffer */
  unsigned u;           /* true if unflushed */
  int ok;


  /* explode the coded data */
  b = k = w = 0;                /* initialize bit buffer, window */
  u = 1;                        /* buffer unflushed */
  mb = mask_bits[bb];           /* precompute masks for speed */
  ml = mask_bits[bl];
  md = mask_bits[bd];
  mdl = mask_bits[bdl];
  s = FFile->uncompr_size;
  while (s > 0)                 /* do until ucsize bytes uncompressed */
  {
    GETBITS(1)
    if (b & 1)                  /* then literal--decode it */
    {
      ADVANCEBITS(1)
      s--;
      DECODEHUFT(tb, bb, mb)    /* get coded literal */
      FOutBuf[w++] = (unsigned char)t->v.n;
      if (w == WSIZE)
      {
        ok = Flush(FOutBuf, w);
        if (!ok)
          return ok;
        w = u = 0;
      }
    }
    else                        /* else distance/length */
    {
      ADVANCEBITS(1)
      GETBITS(bdl)             /* get distance low bits */
      d = (unsigned)b & mdl;
      ADVANCEBITS(bdl)
      DECODEHUFT(td, bd, md)    /* get coded distance high bits */
      d = w - d - t->v.n;       /* construct offset */
      DECODEHUFT(tl, bl, ml)    /* get coded length */
      n = t->v.n;
      if (e)                    /* get length extra bits */
      {
        GETBITS(8)
        n += (unsigned)b & 0xff;
        ADVANCEBITS(8)
      }

      /* do the copy */
      s = (s > (unsigned long)n ? s - (unsigned long)n : 0);
      do {
          e = WSIZE - ((d &= WSIZE-1) > w ? d : w);
        if (e > n) e = n;
        n -= e;
        if (u && w <= d)
        {
          memset(FOutBuf + w, 0, e);
          w += e;
          d += e;
        }
        else
          if (w - d >= e)       /* (this test assumes unsigned comparison) */
          {
            memcpy(FOutBuf + w, FOutBuf + d, e);
            w += e;
            d += e;
          }
          else                  /* do it slow to avoid memcpy() overlap */
            do {
              FOutBuf[w++] = FOutBuf[d++];
            } while (--e);
        if (w == WSIZE)
        {
          ok = Flush(FOutBuf, w);
          if (!ok)
            return ok;
          w = u = 0;
        }
      } while (n);
    }
  }

  /* flush out redirSlide */
  ok = Flush(FOutBuf, w);
  if (!ok)
    return ok;
  if (FDecompSize + FInCount + (k >> 3))   /* should have read csize bytes, but */
  {                        /* sometimes read one too many:  k>>3 compensates */
    FUsedCSize = FFile->compr_size - FDecompSize - FInCount - (k >> 3);
    return FALSE;
  }
  return TRUE;
}

/*##########################################################################
#
#   Name       : TUnzipExplodeExtractor::ExplodeNolit
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUnzipExplodeExtractor::ExplodeNolit(struct TUnzipHuft *tl, struct TUnzipHuft *td, unsigned bl, unsigned bd, unsigned bdl)
/* Decompress the imploded data using uncoded literals and a sliding
   window (of size 2^(6+bdl) bytes). */
{
  unsigned long s;      /* bytes to decompress */
  register unsigned e;  /* table entry flag/number of extra bits */
  unsigned n, d;        /* length and index for copy */
  unsigned w;           /* current window position */
  struct TUnzipHuft *t; /* pointer to table entry */
  unsigned ml, md;      /* masks for bl and bd bits */
  unsigned mdl;         /* mask for bdl (distance lower) bits */
  register unsigned long b;       /* bit buffer */
  register unsigned k;  /* number of bits in bit buffer */
  unsigned u;           /* true if unflushed */
  int ok;


  /* explode the coded data */
  b = k = w = 0;                /* initialize bit buffer, window */
  u = 1;                        /* buffer unflushed */
  ml = mask_bits[bl];           /* precompute masks for speed */
  md = mask_bits[bd];
  mdl = mask_bits[bdl];
  s = FFile->uncompr_size;
  while (s > 0)                 /* do until ucsize bytes uncompressed */
  {
    GETBITS(1)
    if (b & 1)                  /* then literal--get eight bits */
    {
      ADVANCEBITS(1)
      s--;
      GETBITS(8)
      FOutBuf[w++] = (char)b;
      if (w == WSIZE)
      {
        ok = Flush(FOutBuf, w);
        if (!ok)
          return ok;
        w = u = 0;
      }
      ADVANCEBITS(8)
    }
    else                        /* else distance/length */
    {
      ADVANCEBITS(1)
      GETBITS(bdl)             /* get distance low bits */
      d = (unsigned)b & mdl;
      ADVANCEBITS(bdl)
      DECODEHUFT(td, bd, md)    /* get coded distance high bits */
      d = w - d - t->v.n;       /* construct offset */
      DECODEHUFT(tl, bl, ml)    /* get coded length */
      n = t->v.n;
      if (e)                    /* get length extra bits */
      {
        GETBITS(8)
        n += (unsigned)b & 0xff;
        ADVANCEBITS(8)
      }

      /* do the copy */
      s = (s > (unsigned long)n ? s - (unsigned long)n : 0);
      do {
          e = WSIZE - ((d &= WSIZE-1) > w ? d : w);
        if (e > n) e = n;
        n -= e;
        if (u && w <= d)
        {
          memset(FOutBuf + w, 0, e);
          w += e;
          d += e;
        }
        else
          if (w - d >= e)       /* (this test assumes unsigned comparison) */
          {
            memcpy(FOutBuf + w, FOutBuf + d, e);
            w += e;
            d += e;
          }
          else                  /* do it slow to avoid memcpy() overlap */
            do {
              FOutBuf[w++] = FOutBuf[d++];
            } while (--e);
        if (w == WSIZE)
        {
          ok = Flush(FOutBuf, w);
          if (!ok)
            return ok;
          w = u = 0;
        }
      } while (n);
    }
  }

  /* flush out redirSlide */
  ok = Flush(FOutBuf, w);
  if (!ok)
    return ok;
  if (FDecompSize + FInCount + (k >> 3))   /* should have read csize bytes, but */
  {                        /* sometimes read one too many:  k>>3 compensates */
    FUsedCSize = FFile->compr_size - FDecompSize - FInCount - (k >> 3);
    return FALSE;
  }
  return TRUE;
}


/*##########################################################################
#
#   Name       : TUnzipExplodeExtractor::Execute
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipExplodeExtractor::Execute()
/* Explode an imploded compressed stream.  Based on the general purpose
   bit flag, decide on coded or uncoded literals, and an 8K or 4K sliding
   window.  Construct the literal (if any), length, and distance codes and
   the tables needed to decode them (using huft_build() from inflate.c),
   and call the appropriate routine for the type of data in the remainder
   of the stream.  The four routines are nearly identical, differing only
   in whether the literal is decoded or simply read in, and in how many
   bits are read in, uncoded, for the low distance bits. */
{
  unsigned r;           /* return codes */
  struct TUnzipHuft *tb;      /* literal code table */
  struct TUnzipHuft *tl;      /* length code table */
  struct TUnzipHuft *td;      /* distance code table */
  unsigned bb;          /* bits for tb */
  unsigned bl;          /* bits for tl */
  unsigned bd;          /* bits for td */
  unsigned bdl;         /* number of uncoded lower distance bits */
  unsigned l[256];      /* bit lengths for codes */

  /* Tune base table sizes.  Note: I thought that to truly optimize speed,
     I would have to select different bl, bd, and bb values for different
     compressed file sizes.  I was surprised to find out that the values of
     7, 7, and 9 worked best over a very wide range of sizes, except that
     bd = 8 worked marginally better for large compressed sizes. */
  bl = 7;
  bd = (FDecompSize + FInCount) > 200000L ? 8 : 7;

  if (FFile->general_purpose_bit_flag & 4)
  /* With literal tree--minimum match length is 3 */
  {
    bb = 9;                     /* base table size for literals */
    if ((r = ExplodeGetTree(l, 256)) != 0) {
       FOk = FALSE;
       return;
    }
    if ((r = BuildHuft(l, 256, 256, NULL, NULL, &tb, &bb)) != 0)
    {
      if (r == 1)
        FreeHuft(tb);
      FOk = FALSE;
      return;
    }
    if ((r = ExplodeGetTree(l, 64)) != 0) {
      FreeHuft(tb);
      FOk = FALSE;
      return;
    }
    if ((r = BuildHuft(l, 64, 0, cplen3, extra, &tl, &bl)) != 0)
    {
      if (r == 1)
        FreeHuft(tl);
      FreeHuft(tb);
      FOk = FALSE;
      return;
    }
  }
  else
  /* No literal tree--minimum match length is 2 */
  {
    tb = 0;
    if ((r = ExplodeGetTree(l, 64)) != 0) {
      FOk = FALSE;
      return;
    }
    if ((r = BuildHuft(l, 64, 0, cplen2, extra, &tl, &bl)) != 0)
    {
      if (r == 1)
        FreeHuft(tl);
      FOk = FALSE;
      return;
    }
  }

  if ((r = ExplodeGetTree(l, 64)) != 0) {
    FreeHuft(tl);
    if (tb != 0) FreeHuft(tb);
    FOk = FALSE;
    return;
  }
  if (FFile->general_purpose_bit_flag & 2)      /* true if 8K */
  {
    bdl = 7;
    r = BuildHuft(l, 64, 0, cpdist8, extra, &td, &bd);
  }
  else                                          /* else 4K */
  {
    bdl = 6;
    r = BuildHuft(l, 64, 0, cpdist4, extra, &td, &bd);
  }
  if (r != 0)
  {
    if (r == 1)
      FreeHuft(td);
    FreeHuft(tl);
    if (tb != 0) FreeHuft(tb);
    FOk = FALSE;
    return;
  }

  if (tb != NULL) {
    FOk = ExplodeLit(tb, tl, td, bb, bl, bd, bdl);
    FreeHuft(tb);
  } else {
    FOk = ExplodeNolit(tl, td, bl, bd, bdl);
  }

  FreeHuft(td);
  FreeHuft(tl);
}
