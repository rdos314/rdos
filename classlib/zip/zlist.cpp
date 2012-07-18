/*
  Copyright (c) 1990-2009 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2009-Jan-02 or later
  (the contents of which are also included in unzip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/*---------------------------------------------------------------------------

  list.c

  This file contains the non-ZipInfo-specific listing routines for UnZip.

  Contains:  list_files()
             get_time_stamp()   [optional feature]
             ratio()
             fnprint()

  ---------------------------------------------------------------------------*/


#include "unzip.h"

   static const char CompFactorStr[] = "%c%d%%";
   static const char CompFactor100[] = "100%%";

   static const char HeadersS[]  =
     "  Length      Date    Time    Name";
   static const char HeadersS1[] =
     "---------  ---------- -----   ----";

   static const char HeadersL[]  =
     " Length   Method    Size  Cmpr    Date    Time   CRC-32   Name";
   static const char HeadersL1[] =
     "--------  ------  ------- ---- ---------- ----- --------  ----";
   static const char *Headers[][2] =
     { {HeadersS, HeadersS1}, {HeadersL, HeadersL1} };

   static const char CaseConversion[] =
     "%s (\"^\" ==> case\n%s   conversion)\n";
   static const char LongHdrStats[] =
     "%s  %-7s%s %4s %02u%c%02u%c%02u %02u:%02u %08lx %c";
   static const char LongFileTrailer[] =
     "--------          -------  ---                       \
     -------\n%s         %s %4s                            %lu file%s\n";
   static const char ShortHdrStats[] =
     "%s  %02u%c%02u%c%02u %02u:%02u  %c";
   static const char ShortFileTrailer[] =
     "---------                     -------\n%s\
                     %lu file%s\n";





/*************************/
/* Function list_files() */
/*************************/

int list_files(__G)    /* return PK-type error code */
    __GDEF
{
    int do_this_file=FALSE, cfactor, error, error_in_archive=PK_COOL;
    char sgn, cfactorstr[10];
    int longhdr=(uO.vflag>1);
    int date_format;
    char dt_sepchar;
    unsigned long members=0L;
    zusz_t j;
    unsigned methnum;
    unsigned yr, mo, dy, hh, mm;
    zusz_t csiz, tot_csize=0L, tot_ucsize=0L;
    min_info info;
    char methbuf[8];
    static const char dtype[]="NXFS";  /* see zi_short() */
    static const char method[NUM_METHODS+1][8] =
        {"Stored", "Shrunk", "Reduce1", "Reduce2", "Reduce3", "Reduce4",
         "Implode", "Token", "Defl:#", "Def64#", "ImplDCL", "BZip2",
         "LZMA", "Terse", "IBMLZ77", "WavPack", "PPMd", "Unk:###"};



/*---------------------------------------------------------------------------
    Unlike extract_or_test_files(), this routine confines itself to the cen-
    tral directory.  Thus its structure is somewhat simpler, since we can do
    just a single loop through the entire directory, listing files as we go.

    So to start off, print the heading line and then begin main loop through
    the central directory.  The results will look vaguely like the following:

 Length   Method    Size  Ratio   Date   Time   CRC-32    Name ("^" ==> case
--------  ------  ------- -----   ----   ----   ------    ----   conversion)
   44004  Implode   13041  71%  11-02-89 19:34  8b4207f7  Makefile.UNIX
    3438  Shrunk     2209  36%  09-15-90 14:07  a2394fd8 ^dos-file.ext
   16717  Defl:X     5252  69%  11-03-97 06:40  1ce0f189  WHERE
--------          -------  ---                            -------
   64159            20502  68%                            3 files
  ---------------------------------------------------------------------------*/

    G.pInfo = &info;
    date_format = DATE_FORMAT;
    dt_sepchar = DATE_SEPCHAR;

    if (uO.qflag < 2) {
        if (uO.L_flag)
            Info(slide, 0, ((char *)slide, CaseConversion,
              Headers[longhdr][0],
              Headers[longhdr][1]));
        else
            Info(slide, 0, ((char *)slide, "%s\n%s\n",
               Headers[longhdr][0],
               Headers[longhdr][1]));
    }

    for (j = 1L;;j++) {

        if (readbuf(__G__ G.sig, 4) == 0)
            return PK_EOF;
        if (memcmp(G.sig, central_hdr_sig, 4)) {  /* is it a CentDir entry? */
            /* no new central directory entry
             * -> is the number of processed entries compatible with the
             *    number of entries as stored in the end_central record?
             */
            if (((j - 1) &
                 (unsigned long)(G.ecrec.have_ecr64 ? MASK_ZUCN64 : MASK_ZUCN16))
                == (unsigned long)G.ecrec.total_entries_central_dir)
            {
                /* "j modulus 4T/64k" matches the reported 64/16-bit-unsigned
                 * number of directory entries -> probably, the regular
                 * end of the central directory has been reached
                 */
                break;
            } else {
                Info(slide, 0x401,
                     ((char *)slide, CentSigMsg, j));
                Info(slide, 0x401,
                     ((char *)slide, ReportMsg));
                return PK_BADERR;   /* sig not found */
            }
        }
        /* process_cdir_file_hdr() sets pInfo->hostnum, pInfo->lcflag, ...: */
        if ((error = process_cdir_file_hdr(__G)) != PK_COOL)
            return error;       /* only PK_EOF defined */

        /*
         * We could DISPLAY the filename instead of storing (and possibly trun-
         * cating, in the case of a very long name) and printing it, but that
         * has the disadvantage of not allowing case conversion--and it's nice
         * to be able to see in the listing precisely how you have to type each
         * filename in order for unzip to consider it a match.  Speaking of
         * which, if member names were specified on the command line, check in
         * with match() to see if the current file is one of them, and make a
         * note of it if it is.
         */

        if ((error = do_string(__G__ G.crec.filename_length, DS_FN)) !=
             PK_COOL)   /*  ^--(uses pInfo->lcflag) */
        {
            error_in_archive = error;
            if (error > PK_WARN)   /* fatal:  can't continue */
                return error;
        }
        if (G.extra_field != (unsigned char *)NULL) {
            free(G.extra_field);
            G.extra_field = (unsigned char *)NULL;
        }
        if ((error = do_string(__G__ G.crec.extra_field_length, EXTRA_FIELD))
            != 0)
        {
            error_in_archive = error;
            if (error > PK_WARN)      /* fatal */
                return error;
        }
        if (!G.process_all_files) {   /* check if specified on command line */
            unsigned i;

            if (G.filespecs == 0)
                do_this_file = TRUE;
            else {  /* check if this entry matches an `include' argument */
                do_this_file = FALSE;
                for (i = 0; i < G.filespecs; i++)
                    if (match(G.filename, G.pfnames[i], uO.C_flag)) {
                        do_this_file = TRUE;
                        break;       /* found match, so stop looping */
                    }
            }
            if (do_this_file) {  /* check if this is an excluded file */
                for (i = 0; i < G.xfilespecs; i++)
                    if (match(G.filename, G.pxnames[i], uO.C_flag)) {
                        do_this_file = FALSE;  /* ^-- ignore case in match */
                        break;
                    }
            }
        }
        /*
         * If current file was specified on command line, or if no names were
         * specified, do the listing for this file.  Otherwise, get rid of the
         * file comment and go back for the next file.
         */

        if (G.process_all_files || do_this_file) {

            {
                yr = ((((unsigned)(G.crec.last_mod_dos_datetime >> 25) & 0x7f)
                       + 1980));
                mo = ((unsigned)(G.crec.last_mod_dos_datetime >> 21) & 0x0f);
                dy = ((unsigned)(G.crec.last_mod_dos_datetime >> 16) & 0x1f);
                hh = (((unsigned)G.crec.last_mod_dos_datetime >> 11) & 0x1f);
                mm = (((unsigned)G.crec.last_mod_dos_datetime >> 5) & 0x3f);
            }
            /* permute date so it displays according to nat'l convention
             * ('methnum' is not yet set, it is used as temporary buffer) */
            switch (date_format) {
                case DF_YMD:
                    methnum = mo;
                    mo = yr; yr = dy; dy = methnum;
                    break;
                case DF_DMY:
                    methnum = mo;
                    mo = dy; dy = methnum;
            }

            csiz = G.crec.csize;
            if (G.crec.general_purpose_bit_flag & 1)
                csiz -= 12;   /* if encrypted, don't count encryption header */
            if ((cfactor = ratio(G.crec.ucsize, csiz)) < 0) {
                sgn = '-';
                cfactor = (-cfactor + 5) / 10;
            } else {
                sgn = ' ';
                cfactor = (cfactor + 5) / 10;
            }

            methnum = find_compr_idx(G.crec.compression_method);
            strcpy(methbuf, method[methnum]);
            if (G.crec.compression_method == DEFLATED ||
                G.crec.compression_method == ENHDEFLATED) {
                methbuf[5] = dtype[(G.crec.general_purpose_bit_flag>>1) & 3];
            } else if (methnum >= NUM_METHODS) {
                sprintf(&methbuf[4], "%03u", G.crec.compression_method);
            }

            if (cfactor == 100)
                sprintf(cfactorstr, CompFactor100);
            else
                sprintf(cfactorstr, CompFactorStr, sgn, cfactor);
            if (longhdr)
                Info(slide, 0, ((char *)slide, LongHdrStats,
                  FmZofft(G.crec.ucsize, "8", "u"), methbuf,
                  FmZofft(csiz, "8", "u"), cfactorstr,
                  mo, dt_sepchar, dy, dt_sepchar, yr, hh, mm,
                  G.crec.crc32, (G.pInfo->lcflag? '^':' ')));
            else
                Info(slide, 0, ((char *)slide, ShortHdrStats,
                  FmZofft(G.crec.ucsize, "9", "u"),
                  mo, dt_sepchar, dy, dt_sepchar, yr, hh, mm,
                  (G.pInfo->lcflag? '^':' ')));
            fnprint(__G);

            if ((error = do_string(__G__ G.crec.file_comment_length,
                                   (!uO.qflag) ? DISPL_8 : SKIP)) != 0)
            {
                error_in_archive = error;  /* might be just warning */
                if (error > PK_WARN)       /* fatal */
                    return error;
            }
            tot_ucsize += G.crec.ucsize;
            tot_csize += csiz;
            ++members;
        } else {        /* not listing this file */
            SKIP_(G.crec.file_comment_length)
        }
    } /* end for-loop (j: files in central directory) */

/*---------------------------------------------------------------------------
    Print footer line and totals (compressed size, uncompressed size, number
    of members in zipfile).
  ---------------------------------------------------------------------------*/

    if (uO.qflag < 2
                                            ) {
        if ((cfactor = ratio(tot_ucsize, tot_csize)) < 0) {
            sgn = '-';
            cfactor = (-cfactor + 5) / 10;
        } else {
            sgn = ' ';
            cfactor = (cfactor + 5) / 10;
        }
        if (cfactor == 100)
            sprintf(cfactorstr, CompFactor100);
        else
            sprintf(cfactorstr, CompFactorStr, sgn, cfactor);
        if (longhdr) {
            Info(slide, 0, ((char *)slide, LongFileTrailer,
              FmZofft(tot_ucsize, "8", "u"), FmZofft(tot_csize, "8", "u"),
              cfactorstr, members, members==1? "":"s"));
        } else
            Info(slide, 0, ((char *)slide, ShortFileTrailer,
              FmZofft(tot_ucsize, "9", "u"),
              members, members == 1 ? "" : "s"));
    }

    /* Skip the following checks in case of a premature listing break. */
    if (error_in_archive <= PK_WARN) {

/*---------------------------------------------------------------------------
    Double check that we're back at the end-of-central-directory record.
  ---------------------------------------------------------------------------*/

        if ( (memcmp(G.sig,
                     (G.ecrec.have_ecr64 ?
                      end_central64_sig : end_central_sig),
                     4) != 0)
            && (!G.ecrec.is_zip64_archive)
            && (memcmp(G.sig, end_central_sig, 4) != 0)
           ) {          /* just to make sure again */
            Info(slide, 0x401, ((char *)slide, EndSigMsg));
            error_in_archive = PK_WARN;   /* didn't find sig */
        }

        /* Set specific return code when no files have been found. */
        if (members == 0L && error_in_archive <= PK_WARN)
            error_in_archive = PK_FIND;

    }

    return error_in_archive;

} /* end function list_files() */




/********************/
/* Function ratio() */    /* also used by ZipInfo routines */
/********************/

int ratio(zusz_t uc, zusz_t c)
{
    zusz_t denom;

    if (uc == 0)
        return 0;
    if (uc > 2000000L) {    /* risk signed overflow if multiply numerator */
        denom = uc / 1000L;
        return ((uc >= c) ?
            (int) ((uc-c + (denom>>1)) / denom) :
          -((int) ((c-uc + (denom>>1)) / denom)));
    } else {             /* ^^^^^^^^ rounding */
        denom = uc;
        return ((uc >= c) ?
            (int) ((1000L*(uc-c) + (denom>>1)) / denom) :
          -((int) ((1000L*(c-uc) + (denom>>1)) / denom)));
    }                            /* ^^^^^^^^ rounding */
}





/************************/
/*  Function fnprint()  */    /* also used by ZipInfo routines */
/************************/

void fnprint(__G)    /* print filename (after filtering) and newline */
    __GDEF
{
    char *name = fnfilter(G.filename, slide, (extent)(WSIZE>>1));

    (*G.message)((void *)&G, (unsigned char *)name, (unsigned long)strlen(name), 0);
    (*G.message)((void *)&G, (unsigned char *)"\n", 1L, 0);

} /* end function fnprint() */
