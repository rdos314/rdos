/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# Adapted from Info-ZIP
#
# The Info-ZIP license may be found at:  
# ftp://ftp.info-zip.org/pub/infozip/license.html
#
# zipdefl.cpp
# Unzip deflate class
#
########################################################################*/

#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h> 

#include "rdos.h"
#include "zipdefl.h"
#include "zlib.h"
#include "unzip.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TUnzipDeflateExtractor::TUnzipDeflateExtractor
#
#   Purpose....: Constructor for deflate extractor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipDeflateExtractor::TUnzipDeflateExtractor(int InputFileHandle, TUnzipFile *File, const char *DestFileName)
  : TUnzipExtractor(InputFileHandle, File, DestFileName)
{
}

/*##########################################################################
#
#   Name       : TUnzipDeflateExtractor::~TUnzipDeflateExtractor
#
#   Purpose....: Destructor for deflate extractor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipDeflateExtractor::~TUnzipDeflateExtractor()
{
}

/*##########################################################################
#
#  zlib callback interface for inflate
#
###########################################################################*/
static unsigned zlib_in(void *pG, unsigned char ** pInbuf)
{
    TUnzipExtractor *extractor = (TUnzipExtractor *)pG;
    
    *pInbuf = (unsigned char *)extractor->GetInbuf();
    return extractor->FillInbuf();
}

static int zlib_out(void *pG, unsigned char *outbuf, unsigned outcnt)
{
    TUnzipExtractor *extractor = (TUnzipExtractor *)pG;
    
    if (extractor->Flush((char *)outbuf, outcnt))
        return 0;
    else
        return 1;
}


/*##########################################################################
#
#   Name       : TUnzipDeflateExtractor::Execute
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipDeflateExtractor::Execute()
/* decompress an inflated entry using the zlib routines */
{
    int err=Z_OK;
    z_stream dstrm;           /* inflate decompression stream */
    unsigned i;
    int windowBits;

    FOk = TRUE;
    
    dstrm.zalloc = (alloc_func)Z_NULL;
    dstrm.zfree = (free_func)Z_NULL;

    /* windowBits = log2(WSIZE) */
    for (i = (unsigned)WSIZE, windowBits = 0;
        !(i & 1);  i >>= 1, ++windowBits);
    if ((unsigned)windowBits > (unsigned)15)
        windowBits = 15;
    else if (windowBits < 8)
        windowBits = 8;

    err = inflateBackInit(&dstrm, windowBits, (unsigned char *)FOutBuf);

    if (err != Z_OK) {
        FOk = FALSE;
    }

    if (FOk)
    {
        dstrm.next_in = (unsigned char *)FInPtr;
        dstrm.avail_in = FInCount;

        err = inflateBack(&dstrm, zlib_in, this, zlib_out, this);
        if (err != Z_STREAM_END) {
            FOk = FALSE;
        }
        if (dstrm.next_in != NULL) {
            FInPtr = (char *)dstrm.next_in;
            FInCount = dstrm.avail_in;
        }

        err = inflateBackEnd(&dstrm);
        if (err != Z_OK) {
            FOk = FALSE;
        }
    }

    inflateEnd(&dstrm);
}
