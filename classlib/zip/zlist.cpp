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


#include "oldunzip.h"

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

void fnprint()    /* print filename (after filtering) and newline */
{
    char *name = fnfilter(UnzipClass.FCurrFileName, slide, (extent)(WSIZE>>1));

    Info(0, name);
    Info(0, "\n");

} /* end function fnprint() */
