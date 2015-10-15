/*
  zipup.c - Zip 3

  Copyright (c) 1990-2008 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2007-Mar-4 or later
  (the contents of which are also included in zip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/*
 *  zipup.c by Mark Adler and Jean-loup Gailly.
 */
#define __ZIPUP_C

/* Found that for at least unix port zip.h has to be first or ctype.h will
   define off_t and when using 64-bit file environment off_t in other files
   is 8 bytes while off_t here is 4 bytes, and this makes the zlist struct
   different sizes and needless to say leads to segmentation faults.  Putting
   zip.h first seems to fix this.  8/14/04 EG */
#include "zip.h"
#include <ctype.h>
#include <errno.h>

#include "revision.h"
#include "crc32.h"
#include "crypt.h"

/* Use the raw functions for MSDOS and Unix to save on buffer space.
   They're not used for VMS since it doesn't work (raw is weird on VMS).
 */

#include "zipup.h"

/* Local functions */
local int suffixes OF((char *, char *));
local unsigned file_read OF((char *buf, unsigned size));
local unsigned mem_read OF((char *buf, unsigned size));

/* zip64 support 08/29/2003 R.Nausedat */
local zoff_t filecompress OF((struct zlist far *z_entry, int *cmpr_method));

/* Deflate "internal" global data (currently not in zip.h) */
extern ulg window_size;       /* size of said window */

unsigned (*read_buf) OF((char *buf, unsigned size)) = file_read;
  /* Current input function. Set to mem_read for in-memory compression */


/* Local data */
local ulg crc;                  /* crc on uncompressed file data */
local ftype ifile;              /* file to compress */
local char file_outbuf[1024]; /* output buffer for compression to file */

local char *in_buf;
    /* Current input buffer, in_buf is used only for in-memory compression. */
local unsigned in_offset;
    /* Current offset in input buffer. in_offset is used only for in-memory
     * compression. On 16 bit machines, the buffer is limited to 64K.
     */
local unsigned in_size;     /* size of current input buffer */

local zoff_t isize;         /* input file size. global only for debugging */
  /* If file_read detects binary it sets this flag - 12/16/04 EG */
local int file_binary = 0;        /* first buf */
local int file_binary_final = 0;  /* for bzip2 for entire file.  assume text until find binary */


/* moved check to function 3/14/05 EG */
int is_seekable(y)
  FILE *y;
{
  zoff_t pos;

  if (!fseekable(y)) {
    return 0;
  }

  pos = zftello(y);
  if (zfseeko(y, pos, SEEK_SET)) {
    return 0;
  }

  return 1;
}


int percent(n, m)
  uzoff_t n;
  uzoff_t m;                    /* n is the original size, m is the new size */
/* Return the percentage compression from n to m using only integer
   operations */
{
  zoff_t p;

/* 2004-12-01 SMS.
 * Changed to do big-n test only for small zoff_t.
 * Changed big-n arithmetic to accomodate apparently negative values
 * when a small zoff_t value exceeds 2G.
 * Increased the reduction divisor from 256 to 512 to avoid the sign bit
 * in a reduced intermediate, allowing signed arithmetic for the final
 * result (which is no longer artificially limited to non-negative
 * values).
 * Note that right shifts must be on unsigned values to avoid undesired
 * sign extension.
 */

/* Handle n = 0 case and account for int maybe being 16-bit.  12/28/2004 EG
 */

#define PC_MAX_SAFE 0x007fffffL    /* 9 clear bits at high end. */
#define PC_MAX_RND  0xffffff00L    /* 8 clear bits at low end. */

  if (sizeof(uzoff_t) < 8)          /* Don't fiddle with big zoff_t. */
  {
    if ((ulg)n > PC_MAX_SAFE)       /* Reduce large values.  (n > m) */
    {
      if ((ulg)n < PC_MAX_RND)      /* Divide n by 512 with rounding, */
        n = ((ulg)n + 0x100) >> 9;  /* if boost won't overflow. */
      else                          /* Otherwise, use max value. */
        n = PC_MAX_SAFE;

      if ((ulg)m < PC_MAX_RND)      /* Divide m by 512 with rounding, */
        m = ((ulg)m + 0x100) >> 9;  /* if boost won't overflow. */
      else                          /* Otherwise, use max value. */
        m = PC_MAX_SAFE;
    }
  }
  if (n != 0)
    p = ((200 * ((zoff_t)n - (zoff_t)m) / (zoff_t)n) + 1) / 2;
  else
    p = 0;
  return (int)p;  /* Return (rounded) % reduction. */
}


local int suffixes(a, s)
  char *a;                      /* name to check suffix of */
  char *s;                      /* list of suffixes separated by : or ; */
/* Return true if a ends in any of the suffixes in the list s. */
{
  int m;                        /* true if suffix matches so far */
  char *p;                      /* pointer into special */
  char *q;                      /* pointer into name a */

  m = 1;
  q = a + strlen(a) - 1;
  for (p = s + strlen(s) - 1; p >= s; p--)
    if (*p == ':' || *p == ';')
    {
      if (m)
        return 1;
      else
      {
        m = 1;
        q = a + strlen(a) - 1;
      }
    }
    else
    {
      m = m && q >= a && case_map(*p) == case_map(*q);
      q--;
    }
  return m;
}

/* Note: a zip "entry" includes a local header (which includes the file
   name), an encryption header if encrypting, the compressed data
   and possibly an extended local header. */

int zipup(z)
struct zlist far *z;    /* zip entry to compress */
/* Compress the file z->name into the zip entry described by *z and write
   it to the file *y. Encrypt if requested.  Return an error code in the
   ZE_ class.  Also, update tempzn by the number of bytes written. */
/* y is now global */
{
  iztimes f_utim;       /* UNIX GMT timestamps, filled by filetime() */
  ulg tim;              /* time returned by filetime() */
  ulg a = 0L;           /* attributes returned by filetime() */
  char *b;              /* malloc'ed file buffer */
  extent k = 0;         /* result of zread */
  int l = 0;            /* true if this file is a symbolic link */
  int m;                /* method for this entry */

  zoff_t o = 0, p;      /* offsets in zip file */
  zoff_t q = (zoff_t) -3; /* size returned by filetime */
  uzoff_t uq;           /* unsigned q */
  zoff_t s = 0;         /* size of compressed data */

  int r;                /* temporary variable */
  int isdir;            /* set for a directory name */
  int set_type = 0;     /* set if file type (ascii/binary) unknown */
  zoff_t last_o;        /* used to detect wrap around */

  ush tempext = 0;      /* temp copies of extra fields */
  ush tempcext = 0;
  char *tempextra = NULL;
  char *tempcextra = NULL;


  z->nam = strlen(z->iname);
  isdir = z->iname[z->nam-1] == (char)0x2f; /* ascii[(unsigned)('/')] */

  file_binary = -1;      /* not set, set after first read */
  file_binary_final = 0; /* not set, set after first read */

  tim = filetime(z->name, &a, &q, &f_utim);
  if (tim == 0 || q == (zoff_t) -3)
    return ZE_OPEN;

  /* q is set to -1 if the input file is a device, -2 for a volume label */
  if (q == (zoff_t) -2) {
     isdir = 1;
     q = 0;
  } else if (isdir != ((a & MSDOS_DIR_ATTR) != 0)) {
     /* don't overwrite a directory with a file and vice-versa */
     return ZE_MISS;
  }
  /* reset dot_count for each file */
  if (!display_globaldots)
    dot_count = -1;

  /* display uncompressed size */
  uq = ((uzoff_t) q > (uzoff_t) -3) ? 0 : (uzoff_t) q;
  if (noisy && display_usize) {
    fprintf(mesg, " (");
    DisplayNumString( mesg, uq );
    fprintf(mesg, ")");
    mesg_line_started = 1;
    fflush(mesg);
  }
  if (logall && display_usize) {
    fprintf(logfile, " (");
    DisplayNumString( logfile, uq );
    fprintf(logfile, ")");
    logfile_line_started = 1;
    fflush(logfile);
  }

  /* initial z->len so if error later have something */
  z->len = uq;

  z->att = (ush)UNKNOWN; /* will be changed later */
  z->atx = 0; /* may be changed by set_extra_field() */

  /* Free the old extra fields which are probably obsolete */
  /* Should probably read these and keep any we don't update.  12/30/04 EG */
  if (extra_fields == 2) {
    /* If keeping extra fields, make copy before clearing for set_extra_field()
       A better approach is to modify the port code, but maybe later */
    if (z->ext) {
      if ((tempextra = malloc(z->ext)) == NULL) {
        ZIPERR(ZE_MEM, "extra fields copy");
      }
      memcpy(tempextra, z->extra, z->ext);
      tempext = z->ext;
    }
    if (z->cext) {
      if ((tempcextra = malloc(z->cext)) == NULL) {
        ZIPERR(ZE_MEM, "extra fields copy");
      }
      memcpy(tempcextra, z->cextra, z->cext);
      tempcext = z->cext;
    }
  }
  if (z->ext) {
    free((zvoid *)(z->extra));
  }
  if (z->cext && z->extra != z->cextra) {
    free((zvoid *)(z->cextra));
  }
  z->extra = z->cextra = NULL;
  z->ext = z->cext = 0;

  /* Select method based on the suffix and the global method */
  m = special != NULL && suffixes(z->name, special) ? STORE : method;

  /* For now force deflate if using descriptors.  Instead zip and unzip
     could check bytes read against compressed size in each data descriptor
     found and skip over any that don't match.  This is how at least one
     other zipper does it.  To be added later.  Until then it
     probably doesn't hurt to force deflation when streaming.  12/30/04 EG
  */

  /* Open file to zip up unless it is stdin */
  if (strcmp(z->name, "-") == 0)
  {
    ifile = (ftype)zstdin;
    z->tim = tim;
  }
  else
  {
    if (extra_fields) {
      /* create extra field and change z->att and z->atx if desired */
      set_extra_field(z, &f_utim);

      /* For now allow store for testing */
    }
    l = issymlnk(a);
    if (l) {
      ifile = fbad;
      m = STORE;
    }
    else if (isdir) { /* directory */
      ifile = fbad;
      m = STORE;
      q = 0;
    }
    else {
      if ((ifile = zopen(z->name, fhow)) == fbad)
        return ZE_OPEN;
    }

    z->tim = tim;

  } /* strcmp(z->name, "-") == 0 */

  if (extra_fields == 2) {
    unsigned len;
    char *p;

    /* step through old extra fields and copy over any not already
       in new extra fields */
    p = copy_nondup_extra_fields(tempextra, tempext, z->extra, z->ext, &len);
    free(z->extra);
    z->ext = len;
    z->extra = p;
    p = copy_nondup_extra_fields(tempcextra, tempcext, z->cextra, z->cext, &len);
    free(z->cextra);
    z->cext = len;
    z->cextra = p;

    if (tempext)
      free(tempextra);
    if (tempcext)
      free(tempcextra);
  }

  if (q == 0)
    m = STORE;
  if (m == BEST)
    m = DEFLATE;

  /* Do not create STORED files with extended local headers if the
   * input size is not known, because such files could not be extracted.
   * So if the zip file is not seekable and the input file is not
   * on disk, obey the -0 option by forcing deflation with stored block.
   * Note however that using "zip -0" as filter is not very useful...
   * ??? to be done.
   */

  /* An alternative used by others is to allow storing but on reading do
   * a second check when a signature is found.  This is simply to check
   * the compressed size to the bytes read since the start of the file data.
   * If this is the right signature then the compressed size should match
   * the size of the compressed data to that point.  If not look for the
   * next signature.  We should do this.  12/31/04 EG
   *
   * For reading and testing we should do this, but should not write
   * stored streamed data unless for testing as finding the end of
   * streamed deflated data can be done by inflating.  6/26/06 EG
   */

  /* Fill in header information and write local header to zip file.
   * This header will later be re-written since compressed length and
   * crc are not yet known.
   */

  /* (Assume ext, cext, com, and zname already filled in.) */
  /* When creating OEM-coded names on Win32, the entries must always be marked
     as "created on MSDOS" (OS_CODE = 0), because UnZip needs to handle archive
     entry names just like those created by Zip's MSDOS port.
   */
  z->vem = (ush)(dosify ? 20 : 0 + Z_MAJORVER * 10 + Z_MINORVER);

  z->ver = (ush)(m == STORE ? 10 : 20); /* Need PKUNZIP 2.0 except for store */
  z->crc = 0;  /* to be updated later */
  /* Assume first that we will need an extended local header: */
  if (isdir)
    /* If dir then q = 0 and extended header not needed */
    z->flg = 0;
  else
    z->flg = 8;  /* to be updated later */
  if (!isdir && key != NULL) {
    z->flg |= 1;
    /* Since we do not yet know the crc here, we pretend that the crc
     * is the modification time:
     */
    z->crc = z->tim << 16;
    /* More than pretend.  File is encrypted using crypt header with that. */
  }
  z->lflg = z->flg;
  z->how = (ush)m;                              /* may be changed later  */
  z->siz = (zoff_t)(m == STORE && q >= 0 ? q : 0); /* will be changed later */
  z->len = (zoff_t)(q != -1L ? q : 0);          /* may be changed later  */
  if (z->att == (ush)UNKNOWN) {
      z->att = BINARY;                    /* set sensible value in header */
      set_type = 1;
  }
  /* Attributes from filetime(), flag bits from set_extra_field(): */
  z->atx = z->dosflag ? a & 0xff : a | (z->atx & 0x0000ff00);

  if ((r = putlocal(z, PUTLOCAL_WRITE)) != ZE_OK) {
    if (ifile != fbad)
      zclose(ifile);
    return r;
  }

  /* now get split information set by bfwrite() */
  z->off = current_local_offset;

  /* disk local header was written to */
  z->dsk = current_local_disk;

  tempzn += 4 + LOCHEAD + z->nam + z->ext;


  if (!isdir && key != NULL) {
    crypthead(key, z->crc);
    z->siz += RAND_HEAD_LEN;  /* to be updated later */
    tempzn += RAND_HEAD_LEN;
  }
  if (ferror(y)) {
    if (ifile != fbad)
      zclose(ifile);
    ZIPERR(ZE_WRITE, "unexpected error on zip file");
  }

  last_o = o;
  o = zftello(y); /* for debugging only, ftell can fail on pipes */
  if (ferror(y))
    clearerr(y);

  if (o != -1 && last_o > o) {
    fprintf(mesg, "last %s o %s\n", zip_fzofft(last_o, NULL, NULL),
                                    zip_fzofft(o, NULL, NULL));
    ZIPERR(ZE_BIG, "seek wrap - zip file too big to write");
  }

  /* Write stored or deflated file to zip file */
  isize = 0L;
  crc = CRCVAL_INITIAL;

  if (isdir) {
    /* nothing to write */
  }
  else if (m != STORE) {
    if (set_type) z->att = (ush)UNKNOWN;
    /* ... is finally set in file compression routine */
    {
      s = filecompress(z, &m);
    }
    if (z->att == (ush)BINARY && translate_eol && file_binary) {
      if (translate_eol == 1)
        zipwarn("has binary so -l ignored", "");
      else
        zipwarn("has binary so -ll ignored", "");
    }
    else if (z->att == (ush)BINARY && translate_eol) {
      if (translate_eol == 1)
        zipwarn("-l used on binary file - corrupted?", "");
      else
        zipwarn("-ll used on binary file - corrupted?", "");
    }
  }
  else
  {
    if ((b = malloc(SBSZ)) == NULL)
       return ZE_MEM;

    if (l) {
      k = rdsymlnk(z->name, b, SBSZ);
/*
 * compute crc first because zfwrite will alter the buffer b points to !!
 */
      crc = crc32(crc, (uch *) b, k);
      if (zfwrite(b, 1, k) != k)
      {
        free((zvoid *)b);
        return ZE_TEMP;
      }
      isize = k;

    }
    else
    {
      while ((k = file_read(b, SBSZ)) > 0 && k != (extent) EOF)
      {
        if (zfwrite(b, 1, k) != k)
        {
          if (ifile != fbad)
            zclose(ifile);
          free((zvoid *)b);
          return ZE_TEMP;
        }
        if (!display_globaldots) {
          if (dot_size > 0) {
            /* initial space */
            if (noisy && dot_count == -1) {
              putc(' ', mesg);
              fflush(mesg);
              dot_count++;
            }
            dot_count++;
            if (dot_size <= (dot_count + 1) * SBSZ) dot_count = 0;
          }
          if ((verbose || noisy) && dot_size && !dot_count) {
            putc('.', mesg);
            fflush(mesg);
            mesg_line_started = 1;
          }
        }
      }
    }
    free((zvoid *)b);
    s = isize;
  }
  if (ifile != fbad && zerr(ifile)) {
    perror("\nzip warning");
    if (logfile)
      fprintf(logfile, "\nzip warning: %s\n", strerror(errno));
    zipwarn("could not read input file: ", z->oname);
  }
  if (ifile != fbad)
    zclose(ifile);

  tempzn += s;
  p = tempzn; /* save for future fseek() */

  /* Check input size (but not in VMS -- variable record lengths mess it up)
   * and not on MSDOS -- diet in TSR mode reports an incorrect file size)
   */
  if (!translate_eol && q != -1L && isize != q)
  {
    Trace((mesg, " i=%lu, q=%lu ", isize, q));
    zipwarn(" file size changed while zipping ", z->name);
  }

  if (isdir)
  {
    /* A directory */
    z->siz = 0;
    z->len = 0;
    z->how = STORE;
    z->ver = 10;
    /* never encrypt directory so don't need extended local header */
    z->flg &= ~8;
    z->lflg &= ~8;
  }
  else
  {
    /* Try to rewrite the local header with correct information */
    z->crc = crc;
    z->siz = s;
    if (!isdir && key != NULL)
      z->siz += RAND_HEAD_LEN;
    z->len = isize;
    /* if can seek back to local header */
    if (use_descriptors || !fseekable(y) || zfseeko(y, z->off, SEEK_SET))
    {
      if (z->how != (ush) m)
         error("can't rewrite method");
      if (m == STORE && q < 0)
         ZIPERR(ZE_PARMS, "zip -0 not supported for I/O on pipes or devices");
      if ((r = putextended(z)) != ZE_OK)
        return r;
      /* if Zip64 and not seekable then Zip64 data descriptor */
      tempzn += (zip64_entry ? 24L : 16L);
      z->flg = z->lflg; /* if z->flg modified by deflate */
    } else {
      /* ftell() not as useful across splits */
      if (bytes_this_entry != (uzoff_t)(key ? s + 12 : s)) {
        fprintf(mesg, " s=%s, actual=%s ",
                zip_fzofft(s, NULL, NULL), zip_fzofft(bytes_this_entry, NULL, NULL));
        error("incorrect compressed size");
      }
       /* seek ok, ftell() should work, check compressed size */
      z->how = (ush)m;
      switch (m)
      {
      case STORE:
        z->ver = 10; break;
      /* Need PKUNZIP 2.0 for DEFLATE */
      case DEFLATE:
        z->ver = 20; break;
      }
      /*
       * The encryption header needs the crc, but we don't have it
       * for a new file.  The file time is used instead and the encryption
       * header then used to encrypt the data.  The AppNote standard only
       * can be applied to a file that the crc is known, so that means
       * either an existing entry in an archive or get the crc before
       * creating the encryption header and then encrypt the data.
       */
      if ((z->flg & 1) == 0) {
        /* not encrypting so don't need extended local header */
        z->flg &= ~8;
      }
      /* deflate may have set compression level bit markers in z->flg,
         and we can't think of any reason central and local flags should
         be different. */
      z->lflg = z->flg;

      /* If not using descriptors, back up and rewrite local header. */
      if (split_method == 1 && current_local_file != y) {
        if (zfseeko(current_local_file, z->off, SEEK_SET))
          return ZE_READ;
      }

      /* if local header in another split, putlocal will close it */
      if ((r = putlocal(z, PUTLOCAL_REWRITE)) != ZE_OK)
        return r;

      if (zfseeko(y, bytes_this_split, SEEK_SET))
        return ZE_READ;

      if ((z->flg & 1) != 0) {
        /* encrypted file, extended header still required */
        if ((r = putextended(z)) != ZE_OK)
          return r;
        if (zip64_entry)
          tempzn += 24L;
        else
          tempzn += 16L;
      }
    }
  } /* isdir */
  /* Free the local extra field which is no longer needed */
  if (z->ext) {
    if (z->extra != z->cextra) {
      free((zvoid *)(z->extra));
      z->extra = NULL;
    }
    z->ext = 0;
  }

  /* Display statistics */
  if (noisy)
  {
    if (verbose) {
      fprintf( mesg, "\t(in=%s) (out=%s)",
               zip_fzofft(isize, NULL, "u"), zip_fzofft(s, NULL, "u"));
    }
    if (m == DEFLATE)
      fprintf(mesg, " (deflated %d%%)\n", percent(isize, s));
    else
      fprintf(mesg, " (stored 0%%)\n");
    mesg_line_started = 0;
    fflush(mesg);
  }
  if (logall)
  {
    if (m == DEFLATE)
      fprintf(logfile, " (deflated %d%%)\n", percent(isize, s));
    else
      fprintf(logfile, " (stored 0%%)\n");
    logfile_line_started = 0;
    fflush(logfile);
  }

  return ZE_OK;
}




local unsigned file_read(buf, size)
  char *buf;
  unsigned size;
/* Read a new buffer from the current input file, perform end-of-line
 * translation, and update the crc and input file size.
 * IN assertion: size >= 2 (for end-of-line translation)
 */
{
  unsigned len;
  char *b;
  zoff_t isize_prev;    /* Previous isize.  Used for overflow check. */

  if (translate_eol == 0) {
    len = zread(ifile, buf, size);
    if (len == (unsigned)EOF || len == 0) return len;
  } else if (translate_eol == 1) {
    /* translate_eol == 1 */
    /* Transform LF to CR LF */
    size >>= 1;
    b = buf+size;
    size = len = zread(ifile, b, size);
    if (len == (unsigned)EOF || len == 0) return len;

    /* check buf for binary - 12/16/04 */
    if (file_binary == -1) {
      /* first read */
      file_binary = is_text_buf(b, size) ? 0 : 1;
    }

    if (file_binary != 1) {
      {
         do {
            if ((*buf++ = *b++) == '\n') *(buf-1) = CR, *buf++ = LF, len++;
         } while (--size != 0);
      }
      buf -= len;
    } else { /* do not translate binary */
      memcpy(buf, b, size);
    }

  } else {
    /* translate_eol == 2 */
    /* Transform CR LF to LF and suppress final ^Z */
    b = buf;
    size = len = zread(ifile, buf, size-1);
    if (len == (unsigned)EOF || len == 0) return len;

    /* check buf for binary - 12/16/04 */
    if (file_binary == -1) {
      /* first read */
      file_binary = is_text_buf(b, size) ? 0 : 1;
    }

    if (file_binary != 1) {
      buf[len] = '\n'; /* I should check if next char is really a \n */
      {
         do {
            if (( *buf++ = *b++) == CR && *b == LF) buf--, len--;
         } while (--size != 0);
      }
      if (len == 0) {
         zread(ifile, buf, 1); len = 1; /* keep single \r if EOF */
      } else {
         buf -= len;
         if (buf[len-1] == CTRLZ) len--; /* suppress final ^Z */
      }
    }
  }
  crc = crc32(crc, (uch *) buf, len);
  /* 2005-05-23 SMS.
     Increment file size.  A small-file program reading a large file may
     cause isize to overflow, so complain (and abort) if it goes
     negative or wraps around.  Awful things happen later otherwise.
  */
  isize_prev = isize;
  isize += (ulg)len;
  if (isize < isize_prev) {
    ZIPERR(ZE_BIG, "overflow in byte count");
  }
  return len;
}


#ifdef USE_ZLIB

local int zl_deflate_init(pack_level)
    int pack_level;
{
    unsigned i;
    int windowBits;
    int err = Z_OK;
    int zp_err = ZE_OK;

    if (zlib_version[0] != ZLIB_VERSION[0]) {
        sprintf(errbuf, "incompatible zlib version (expected %s, found %s)",
              ZLIB_VERSION, zlib_version);
        zp_err = ZE_LOGIC;
    } else if (strcmp(zlib_version, ZLIB_VERSION) != 0) {
        fprintf(mesg,
                "\twarning:  different zlib version (expected %s, using %s)\n",
                ZLIB_VERSION, zlib_version);
    }

    /* windowBits = log2(WSIZE) */
    for (i = ((unsigned)WSIZE), windowBits = 0; i != 1; i >>= 1, ++windowBits);

    zstrm.zalloc = (alloc_func)Z_NULL;
    zstrm.zfree = (free_func)Z_NULL;

    Trace((stderr, "initializing deflate()\n"));
    err = deflateInit2(&zstrm, pack_level, Z_DEFLATED, -windowBits, 8, 0);

    if (err == Z_MEM_ERROR) {
        sprintf(errbuf, "cannot initialize zlib deflate");
        zp_err = ZE_MEM;
    } else if (err != Z_OK) {
        sprintf(errbuf, "zlib deflateInit failure (%d)", err);
        zp_err = ZE_LOGIC;
    }

    deflInit = TRUE;
    return zp_err;
}


void zl_deflate_free()
{
    int err;

    if (f_obuf != NULL) {
        free(f_obuf);
        f_obuf = NULL;
    }
    if (f_ibuf != NULL) {
        free(f_ibuf);
        f_ibuf = NULL;
    }
    if (deflInit) {
        err = deflateEnd(&zstrm);
        if (err != Z_OK && err !=Z_DATA_ERROR) {
            ziperr(ZE_LOGIC, "zlib deflateEnd failed");
        }
        deflInit = FALSE;
    }
}

#else /* !USE_ZLIB */

# ifdef ZP_NEED_MEMCOMPR
/* ===========================================================================
 * In-memory read function. As opposed to file_read(), this function
 * does not perform end-of-line translation, and does not update the
 * crc and input size.
 *    Note that the size of the entire input buffer is an unsigned long,
 * but the size used in mem_read() is only an unsigned int. This makes a
 * difference on 16 bit machines. mem_read() may be called several
 * times for an in-memory compression.
 */
local unsigned mem_read(b, bsize)
     char *b;
     unsigned bsize;
{
    if (in_offset < in_size) {
        ulg block_size = in_size - in_offset;
        if (block_size > (ulg)bsize) block_size = (ulg)bsize;
        memcpy(b, in_buf + in_offset, (unsigned)block_size);
        in_offset += (unsigned)block_size;
        return (unsigned)block_size;
    } else {
        return 0; /* end of input */
    }
}
# endif /* ZP_NEED_MEMCOMPR */


/* ===========================================================================
 * Flush the current output buffer.
 */
void flush_outbuf(o_buf, o_idx)
    char *o_buf;
    unsigned *o_idx;
{
    if (y == NULL) {
        error("output buffer too small for in-memory compression");
    }
    /* Encrypt and write the output buffer: */
    if (*o_idx != 0) {
        zfwrite(o_buf, 1, (extent)*o_idx);
        if (ferror(y)) ziperr(ZE_WRITE, "write error on zip file");
    }
    *o_idx = 0;
}

/* ===========================================================================
 * Return true if the zip file can be seeked. This is used to check if
 * the local header can be re-rewritten. This function always returns
 * true for in-memory compression.
 * IN assertion: the local header has already been written (ftell() > 0).
 */
int seekable()
{
    return fseekable(y);
}
#endif /* ?USE_ZLIB */


/* ===========================================================================
 * Compression to archive file.
 */
local zoff_t filecompress(z_entry, cmpr_method)
    struct zlist far *z_entry;
    int *cmpr_method;
{
#ifdef USE_ZLIB
    int err = Z_OK;
    unsigned mrk_cnt = 1;
    int maybe_stored = FALSE;
    ulg cmpr_size;
#if defined(MMAP) || defined(BIG_MEM)
    unsigned ibuf_sz = (unsigned)SBSZ;
#else
#   define ibuf_sz ((unsigned)SBSZ)
#endif
#ifndef OBUF_SZ
#  define OBUF_SZ ZBSZ
#endif
    unsigned u;

#if defined(MMAP) || defined(BIG_MEM)
    if (remain == (ulg)-1L && f_ibuf == NULL)
#else /* !(MMAP || BIG_MEM */
    if (f_ibuf == NULL)
#endif /* MMAP || BIG_MEM */
        f_ibuf = (char *)malloc(SBSZ);
    if (f_obuf == NULL)
        f_obuf = (char *)malloc(OBUF_SZ);
#if defined(MMAP) || defined(BIG_MEM)
    if ((remain == (ulg)-1L && f_ibuf == NULL) || f_obuf == NULL)
#else /* !(MMAP || BIG_MEM */
    if (f_ibuf == NULL || f_obuf == NULL)
#endif /* MMAP || BIG_MEM */
        ziperr(ZE_MEM, "allocating zlib file-I/O buffers");

    if (!deflInit) {
        err = zl_deflate_init(level);
        if (err != ZE_OK)
            ziperr(err, errbuf);
    }

    if (level <= 2) {
        z_entry->flg |= 4;
    } else if (level >= 8) {
        z_entry->flg |= 2;
    }
#if defined(MMAP) || defined(BIG_MEM)
    if (remain != (ulg)-1L) {
        zstrm.next_in = (Bytef *)window;
        ibuf_sz = (unsigned)WSIZE;
    } else
#endif /* MMAP || BIG_MEM */
    {
        zstrm.next_in = (Bytef *)f_ibuf;
    }
    zstrm.avail_in = file_read(zstrm.next_in, ibuf_sz);
    if (zstrm.avail_in < ibuf_sz) {
        unsigned more = file_read(zstrm.next_in + zstrm.avail_in,
                                  (ibuf_sz - zstrm.avail_in));
        if (more == EOF || more == 0) {
            maybe_stored = TRUE;
        } else {
            zstrm.avail_in += more;
        }
    }
    zstrm.next_out = (Bytef *)f_obuf;
    zstrm.avail_out = OBUF_SZ;

    if (!maybe_stored) while (zstrm.avail_in != 0 && zstrm.avail_in != EOF) {
        err = deflate(&zstrm, Z_NO_FLUSH);
        if (err != Z_OK && err != Z_STREAM_END) {
            sprintf(errbuf, "unexpected zlib deflate error %d", err);
            ziperr(ZE_LOGIC, errbuf);
        }
        if (zstrm.avail_out == 0) {
            if (zfwrite(f_obuf, 1, OBUF_SZ) != OBUF_SZ) {
                ziperr(ZE_TEMP, "error writing to zipfile");
            }
            zstrm.next_out = (Bytef *)f_obuf;
            zstrm.avail_out = OBUF_SZ;
        }
        if (zstrm.avail_in == 0) {
            if (verbose || noisy)
                while((unsigned)(zstrm.total_in / (uLong)WSIZE) > mrk_cnt) {
                    mrk_cnt++;
                    if (!display_globaldots) {
                      if (dot_size > 0) {
                        /* initial space */
                        if (noisy && dot_count == -1) {
#ifndef WINDLL
                          putc(' ', mesg);
                          fflush(mesg);
#else
                          fprintf(stdout,"%c",' ');
#endif
                          dot_count++;
                        }
                        dot_count++;
                        if (dot_size <= (dot_count + 1) * WSIZE) dot_count = 0;
                      }
                      if (noisy && dot_size && !dot_count) {
#ifndef WINDLL
                        putc('.', mesg);
                        fflush(mesg);
#else
                        fprintf(stdout,"%c",'.');
#endif
                        mesg_line_started = 1;
                      }
                    }
                }
#if defined(MMAP) || defined(BIG_MEM)
            if (remain == (ulg)-1L)
                zstrm.next_in = (Bytef *)f_ibuf;
#else
            zstrm.next_in = (Bytef *)f_ibuf;
#endif
            zstrm.avail_in = file_read(zstrm.next_in, ibuf_sz);
        }
    }

    do {
        err = deflate(&zstrm, Z_FINISH);
        if (maybe_stored) {
            if (err == Z_STREAM_END && zstrm.total_out >= zstrm.total_in &&
                fseekable(zipfile)) {
                /* deflation does not reduce size, switch to STORE method */
                unsigned len_out = (unsigned)zstrm.total_in;
                if (zfwrite(f_ibuf, 1, len_out) != len_out) {
                    ziperr(ZE_TEMP, "error writing to zipfile");
                }
                zstrm.total_out = (uLong)len_out;
                *cmpr_method = STORE;
                break;
            } else {
                maybe_stored = FALSE;
            }
        }
        if (zstrm.avail_out < OBUF_SZ) {
            unsigned len_out = OBUF_SZ - zstrm.avail_out;
            if (zfwrite(f_obuf, 1, len_out) != len_out) {
                ziperr(ZE_TEMP, "error writing to zipfile");
            }
            zstrm.next_out = (Bytef *)f_obuf;
            zstrm.avail_out = OBUF_SZ;
        }
    } while (err == Z_OK);

    if (err != Z_STREAM_END) {
        sprintf(errbuf, "unexpected zlib deflate error %d", err);
        ziperr(ZE_LOGIC, errbuf);
    }

    if (z_entry->att == (ush)UNKNOWN)
        z_entry->att = (ush)(zstrm.data_type == Z_ASCII ? ASCII : BINARY);
    cmpr_size = (ulg)zstrm.total_out;

    if ((err = deflateReset(&zstrm)) != Z_OK)
        ziperr(ZE_LOGIC, "zlib deflateReset failed");
    return cmpr_size;
#else /* !USE_ZLIB */

    /* Set the defaults for file compression. */
    read_buf = file_read;

    /* Initialize deflate's internals and execute file compression. */
    bi_init(file_outbuf, sizeof(file_outbuf), TRUE);
    ct_init(&z_entry->att, cmpr_method);
    lm_init(level, &z_entry->flg);
    return deflate();
#endif /* ?USE_ZLIB */
}

#ifdef ZP_NEED_MEMCOMPR
/* ===========================================================================
 * In-memory compression. This version can be used only if the entire input
 * fits in one memory buffer. The compression is then done in a single
 * call of memcompress(). (An extension to allow repeated calls would be
 * possible but is not needed here.)
 * The first two bytes of the compressed output are set to a short with the
 * method used (DEFLATE or STORE). The following four bytes contain the CRC.
 * The values are stored in little-endian order on all machines.
 * This function returns the byte size of the compressed output, including
 * the first six bytes (method and crc).
 */

ulg memcompress(tgt, tgtsize, src, srcsize)
    char *tgt, *src;       /* target and source buffers */
    ulg tgtsize, srcsize;  /* target and source sizes */
{
    ulg crc;
    unsigned out_total;
    int method   = DEFLATE;
#ifdef USE_ZLIB
    int err      = Z_OK;
#else
    ush att      = (ush)UNKNOWN;
    ush flags    = 0;
#endif

    if (tgtsize <= (ulg)6L) error("target buffer too small");
    out_total = 2 + 4;

#ifdef USE_ZLIB
    if (!deflInit) {
        err = zl_deflate_init(level);
        if (err != ZE_OK)
            ziperr(err, errbuf);
    }

    zstrm.next_in = (Bytef *)src;
    zstrm.avail_in = (uInt)srcsize;
    zstrm.next_out = (Bytef *)(tgt + out_total);
    zstrm.avail_out = (uInt)tgtsize - (uInt)out_total;

    err = deflate(&zstrm, Z_FINISH);
    if (err != Z_STREAM_END)
        error("output buffer too small for in-memory compression");
    out_total += (unsigned)zstrm.total_out;

    if ((err = deflateReset(&zstrm)) != Z_OK)
        error("zlib deflateReset failed");
#else /* !USE_ZLIB */
    read_buf  = mem_read;
    in_buf    = src;
    in_size   = (unsigned)srcsize;
    in_offset = 0;
    window_size = 0L;

    bi_init(tgt + (2 + 4), (unsigned)(tgtsize - (2 + 4)), FALSE);
    ct_init(&att, &method);
    lm_init((level != 0 ? level : 1), &flags);
    out_total += (unsigned)deflate();
    window_size = 0L; /* was updated by lm_init() */
#endif /* ?USE_ZLIB */

    crc = CRCVAL_INITIAL;
    crc = crc32(crc, (uch *)src, (extent)srcsize);

    /* For portability, force little-endian order on all machines: */
    tgt[0] = (char)(method & 0xff);
    tgt[1] = (char)((method >> 8) & 0xff);
    tgt[2] = (char)(crc & 0xff);
    tgt[3] = (char)((crc >> 8) & 0xff);
    tgt[4] = (char)((crc >> 16) & 0xff);
    tgt[5] = (char)((crc >> 24) & 0xff);

    return (ulg)out_total;
}
#endif /* ZP_NEED_MEMCOMPR */

#ifdef BZIP2_SUPPORT

local int bz_compress_init(pack_level)
int pack_level;
{
    int err = BZ_OK;
    int zp_err = ZE_OK;
    const char *bzlibVer;

    bzlibVer = BZ2_bzlibVersion();

    /* $TODO - Check BZIP2 LIB version? */

    bstrm.bzalloc = NULL;
    bstrm.bzfree = NULL;
    bstrm.opaque = NULL;

    Trace((stderr, "initializing bzlib compress()\n"));
    err = BZ2_bzCompressInit(&bstrm, pack_level, 0, 30);

    if (err == BZ_MEM_ERROR) {
        sprintf(errbuf, "cannot initialize bzlib compress");
        zp_err = ZE_MEM;
    } else if (err != BZ_OK) {
        sprintf(errbuf, "bzlib bzCompressInit failure (%d)", err);
        zp_err = ZE_LOGIC;
    }

    bzipInit = TRUE;
    return zp_err;
}

void bz_compress_free()
{
    int err;

    if (f_obuf != NULL) {
        free(f_obuf);
        f_obuf = NULL;
    }
    if (f_ibuf != NULL) {
        free(f_ibuf);
        f_ibuf = NULL;
    }
    if (bzipInit) {
        err = BZ2_bzCompressEnd(&bstrm);
        if (err != BZ_OK && err != BZ_DATA_ERROR) {
            ziperr(ZE_LOGIC, "bzlib bzCompressEnd failed");
        }
        bzipInit = FALSE;
    }
}

/* ===========================================================================
 * BZIP2 Compression to archive file.
 */

local zoff_t bzfilecompress(z_entry, cmpr_method)
struct zlist far *z_entry;
int *cmpr_method;
{
    FILE *zipfile = y;

    int err = BZ_OK;
    unsigned mrk_cnt = 1;
    int maybe_stored = FALSE;
    zoff_t cmpr_size;
#if defined(MMAP) || defined(BIG_MEM)
    unsigned ibuf_sz = (unsigned)SBSZ;
#else
#   define ibuf_sz ((unsigned)SBSZ)
#endif
#ifndef OBUF_SZ
#  define OBUF_SZ ZBSZ
#endif

#if defined(MMAP) || defined(BIG_MEM)
    if (remain == (ulg)-1L && f_ibuf == NULL)
#else /* !(MMAP || BIG_MEM */
    if (f_ibuf == NULL)
#endif /* MMAP || BIG_MEM */
        f_ibuf = (char *)malloc(SBSZ);
    if (f_obuf == NULL)
        f_obuf = (char *)malloc(OBUF_SZ);
#if defined(MMAP) || defined(BIG_MEM)
    if ((remain == (ulg)-1L && f_ibuf == NULL) || f_obuf == NULL)
#else /* !(MMAP || BIG_MEM */
    if (f_ibuf == NULL || f_obuf == NULL)
#endif /* MMAP || BIG_MEM */
        ziperr(ZE_MEM, "allocating zlib/bzlib file-I/O buffers");

    if (!bzipInit) {
        err = bz_compress_init(level);
        if (err != ZE_OK)
            ziperr(err, errbuf);
    }

#if defined(MMAP) || defined(BIG_MEM)
    if (remain != (ulg)-1L) {
        bstrm.next_in = (Bytef *)window;
        ibuf_sz = (unsigned)WSIZE;
    } else
#endif /* MMAP || BIG_MEM */
    {
        bstrm.next_in = (char *)f_ibuf;
    }
    bstrm.avail_in = file_read(bstrm.next_in, ibuf_sz);
    if (file_binary_final == 0) {
      /* check for binary as library does not */
      if (!is_text_buf(bstrm.next_in, ibuf_sz))
        file_binary_final = 1;
    }
    if (bstrm.avail_in < ibuf_sz) {
        unsigned more = file_read(bstrm.next_in + bstrm.avail_in,
                                  (ibuf_sz - bstrm.avail_in));
        if (more == (unsigned) EOF || more == 0) {
            maybe_stored = TRUE;
        } else {
            bstrm.avail_in += more;
        }
    }
    bstrm.next_out = (char *)f_obuf;
    bstrm.avail_out = OBUF_SZ;

    if (!maybe_stored) {
      while (bstrm.avail_in != 0 && bstrm.avail_in != (unsigned) EOF) {
        err = BZ2_bzCompress(&bstrm, BZ_RUN);
        if (err != BZ_RUN_OK && err != BZ_STREAM_END) {
            sprintf(errbuf, "unexpected bzlib compress error %d", err);
            ziperr(ZE_LOGIC, errbuf);
        }
        if (bstrm.avail_out == 0) {
            if (zfwrite(f_obuf, 1, OBUF_SZ) != OBUF_SZ) {
                ziperr(ZE_TEMP, "error writing to zipfile");
            }
            bstrm.next_out = (char *)f_obuf;
            bstrm.avail_out = OBUF_SZ;
        }
        /* $TODO what about high 32-bits of total-in??? */
        if (bstrm.avail_in == 0) {
            if (verbose || noisy)
#ifdef LARGE_FILE_SUPPORT
                while((unsigned)((bstrm.total_in_lo32
                                  + (((zoff_t)bstrm.total_in_hi32) << 32))
                                 / (zoff_t)(ulg)WSIZE) > mrk_cnt) {
#else
                while((unsigned)(bstrm.total_in_lo32 / (ulg)WSIZE) > mrk_cnt) {
#endif
                    mrk_cnt++;
                    if (!display_globaldots) {
                      if (dot_size > 0) {
                        /* initial space */
                        if (noisy && dot_count == -1) {
#ifndef WINDLL
                          putc(' ', mesg);
                          fflush(mesg);
#else
                          fprintf(stdout,"%c",' ');
#endif
                          dot_count++;
                        }
                        dot_count++;
                        if (dot_size <= (dot_count + 1) * WSIZE) dot_count = 0;
                      }
                      if (noisy && dot_size && !dot_count) {
#ifndef WINDLL
                        putc('.', mesg);
                        fflush(mesg);
#else
                        fprintf(stdout,"%c",'.');
#endif
                        mesg_line_started = 1;
                      }
                    }
                }
#if defined(MMAP) || defined(BIG_MEM)
            if (remain == (ulg)-1L)
                bstrm.next_in = (char *)f_ibuf;
#else
            bstrm.next_in = (char *)f_ibuf;
#endif
            bstrm.avail_in = file_read(bstrm.next_in, ibuf_sz);
            if (file_binary_final == 0) {
              /* check for binary as library does not */
              if (!is_text_buf(bstrm.next_in, ibuf_sz))
                file_binary_final = 1;
            }
        }
      }
    }

    /* binary or text */
    if (file_binary_final)
      /* found binary in file */
      z_entry->att = (ush)BINARY;
    else
      /* text file */
      z_entry->att = (ush)ASCII;

    do {
        err = BZ2_bzCompress(&bstrm, BZ_FINISH);
        if (maybe_stored) {
            /* This code is only executed when the complete data stream fits
               into the input buffer (see above where maybe_stored gets set).
               So, it is safe to assume that total_in_hi32 (and total_out_hi32)
               are 0, because the input buffer size is well below the 32-bit
               limit.
             */
            if (err == BZ_STREAM_END
                && bstrm.total_out_lo32 >= bstrm.total_in_lo32
                && fseekable(zipfile)) {
                /* BZIP2 compress does not reduce size,
                   switch to STORE method */
                unsigned len_out = (unsigned)bstrm.total_in_lo32;
                if (zfwrite(f_ibuf, 1, len_out) != len_out) {
                    ziperr(ZE_TEMP, "error writing to zipfile");
                }
                bstrm.total_out_lo32 = (ulg)len_out;
                *cmpr_method = STORE;
                break;
            } else {
                maybe_stored = FALSE;
            }
        }
        if (bstrm.avail_out < OBUF_SZ) {
            unsigned len_out = OBUF_SZ - bstrm.avail_out;
            if (zfwrite(f_obuf, 1, len_out) != len_out) {
                ziperr(ZE_TEMP, "error writing to zipfile");
            }
            bstrm.next_out = (char *)f_obuf;
            bstrm.avail_out = OBUF_SZ;
        }
    } while (err == BZ_FINISH_OK);

    if (err < BZ_OK) {
        sprintf(errbuf, "unexpected bzlib compress error %d", err);
        ziperr(ZE_LOGIC, errbuf);
    }

    if (z_entry->att == (ush)UNKNOWN)
        z_entry->att = (ush)BINARY;
#ifdef LARGE_FILE_SUPPORT
    cmpr_size = (zoff_t)bstrm.total_out_lo32
               + (((zoff_t)bstrm.total_out_hi32) << 32);
#else
    cmpr_size = (zoff_t)bstrm.total_out_lo32;
#endif

    if ((err = BZ2_bzCompressEnd(&bstrm)) != BZ_OK)
        ziperr(ZE_LOGIC, "zlib deflateReset failed");
    bzipInit = FALSE;
    return cmpr_size;
}

#endif /* BZIP2_SUPPORT */
