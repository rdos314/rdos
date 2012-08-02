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
# unzip.cpp
# Unzip class
#
########################################################################*/

#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h> 

#include "rdos.h"
#include "zipunshr.h"
#include "unzip.h"

#define MAX_BITS    13                 /* used in unshrink() */
#define HSIZE       (1 << MAX_BITS)    /* size of global work area */

/* HSIZE is defined as 2^13 (8192) in unzip.h (resp. unzpriv.h */
#define BOGUSCODE  256
#define CODE_MASK  (HSIZE - 1)   /* 0x1fff (lower bits are parent's index) */
#define FREE_CODE  HSIZE         /* 0x2000 (code is unused or was cleared) */
#define HAS_CHILD  (HSIZE << 1)  /* 0x4000 (code has a child--do not clear) */

/* And'ing with mask_bits[n] masks the lower n bits */
static const unsigned near mask_bits[17] = {
    0x0000,
    0x0001, 0x0003, 0x0007, 0x000f, 0x001f, 0x003f, 0x007f, 0x00ff,
    0x01ff, 0x03ff, 0x07ff, 0x0fff, 0x1fff, 0x3fff, 0x7fff, 0xffff
};

/*##########################################################################
#
#   Name       : TUnzipUnshrinkExtractor::TUnzipUnshrinkExtractor
#
#   Purpose....: Constructor for unshrink extractor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipUnshrinkExtractor::TUnzipUnshrinkExtractor(int InputFileHandle, TUnzipFile *File, const char *DestFileName)
  : TUnzipExtractor(InputFileHandle, File, DestFileName)
{
}

/*##########################################################################
#
#   Name       : TUnzipUnshrinkExtractor::~TUnzipUnshrinkExtractor
#
#   Purpose....: Destructor for unshrink extractor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipUnshrinkExtractor::~TUnzipUnshrinkExtractor()
{
}

/*##########################################################################
#
#   Unshrink macros that cannot be integrated!
#
##########################################################################*/

#define READBITS(nbits,zdest) {if(nbits>FBitsLeft) {int temp; FZipeof=1;\
  while (FBitsLeft<=8*(int)(sizeof(FBitBuf)-1) && (temp=GetNextByte())!=EOF) {\
  FBitBuf|=(unsigned long)temp<<FBitsLeft; FBitsLeft+=8; FZipeof=0;}}\
  zdest=(int)((unsigned)FBitBuf&mask_bits[nbits]);FBitBuf>>=nbits;\
  FBitsLeft-=nbits;}

/*##########################################################################
#
#   Name       : TUnzipUnshrinkExtractor::PartialClear
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipUnshrinkExtractor::PartialClear(int lastcodeused)
{
    register int code;

    /* clear all nodes which have no children (i.e., leaf nodes only) */

    /* first loop:  mark each parent as such */
    for (code = BOGUSCODE+1;  code <= lastcodeused;  ++code) {
        register int cparent = (int)(FShrinkParent[code] & CODE_MASK);

        if (cparent > BOGUSCODE)
            FShrinkParent[cparent] |= HAS_CHILD;   /* set parent's child-bit */
    }

    /* second loop:  clear all nodes *not* marked as parents; reset flag bits */
    for (code = BOGUSCODE+1;  code <= lastcodeused;  ++code) {
        if (FShrinkParent[code] & HAS_CHILD)    /* just clear child-bit */
            FShrinkParent[code] &= ~HAS_CHILD;
        else {                              /* leaf:  lose it */
            FShrinkParent[code] = FREE_CODE;
        }
    }
}

/*##########################################################################
#
#   Name       : TUnzipUnshrinkExtractor::Execute
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipUnshrinkExtractor::Execute()
{
    unsigned char *stacktop;
    register unsigned char *newstr;
    unsigned char finalval;
    int codesize=9, len, error;
    int code, oldcode, curcode;
    int lastfreecode;
    unsigned char *p;

    FZipeof = 0;
    FBitsLeft = 0;
    FBitBuf = 0;

/*---------------------------------------------------------------------------
    Initialize various variables.
  ---------------------------------------------------------------------------*/

    lastfreecode = BOGUSCODE;

/*---------------------------------------------------------------------------
    Get and output first code, then loop over remaining ones.
  ---------------------------------------------------------------------------*/

    error = PK_OK;
    
    READBITS(codesize, oldcode)
    if (FZipeof)
        return;
    
    FShrinkParent = new int[HSIZE];
    FShrinkValue = new unsigned char[HSIZE];
    FShrinkStack = new unsigned char[HSIZE];

    stacktop = FShrinkStack + (HSIZE - 1);
    
    for (code = 0;  code < BOGUSCODE;  ++code) {
        FShrinkValue[code] = (unsigned char)code;
        FShrinkParent[code] = BOGUSCODE;
    }
    for (code = BOGUSCODE+1;  code < HSIZE;  ++code)
        FShrinkParent[code] = FREE_CODE;

    FOutPtr = FOutBuf;
    FOutCount = 0;

    finalval = (unsigned char)oldcode;
    *FOutPtr++ = finalval;
    ++FOutCount;

    while (error == PK_OK) {
        READBITS(codesize, code)
        if (FZipeof)
            break;
        if (code == BOGUSCODE) {   /* possible to have consecutive escapes? */
            READBITS(codesize, code)
            if (FZipeof)
                break;
            if (code == 1) {
                ++codesize;
                if (codesize > MAX_BITS)
                {
                    error = PK_ERR;
                    break;
                }
            } else if (code == 2) {
                /* clear leafs (nodes with no children) */
                PartialClear(lastfreecode);
                lastfreecode = BOGUSCODE; /* reset start of free-node search */
            }
            continue;
        }

    /*-----------------------------------------------------------------------
        Translate code:  traverse tree from leaf back to root.
      -----------------------------------------------------------------------*/

        newstr = stacktop;
        curcode = code;

        if (FShrinkParent[code] == FREE_CODE) {
            /* or (FLAG_BITS[code] & FREE_CODE)? */
            *newstr-- = finalval;
            code = oldcode;
        }

        while (code != BOGUSCODE) {
            if (newstr < FShrinkStack) {
                /* Bogus compression stream caused buffer underflow! */
                error = PK_ERR;
                break;
            }
            if (FShrinkParent[code] == FREE_CODE) {
                /* or (FLAG_BITS[code] & FREE_CODE)? */
                *newstr-- = finalval;
                code = oldcode;
            } else {
                *newstr-- = FShrinkValue[code];
                code = (int)(FShrinkParent[code] & CODE_MASK);
            }
        }

        len = (int)(stacktop - newstr++);
        finalval = *newstr;

    /*-----------------------------------------------------------------------
        Write expanded string in reverse order to output buffer.
      -----------------------------------------------------------------------*/

        for (p = newstr;  p < newstr+len;  ++p) {
            *FOutPtr++ = *p;
            if (++FOutCount == WSIZE) {
                if ((error = Flush(FOutBuf, FOutCount)) != 0) {
                    break;
                }
                FOutPtr = FOutBuf;
                FOutCount = 0;
            }
        }

    /*-----------------------------------------------------------------------
        Add new leaf (first character of newstr) to tree as child of oldcode.
      -----------------------------------------------------------------------*/

        /* search for freecode */
        code = (int)(lastfreecode + 1);
        /* add if-test before loop for speed? */
        while ((code < HSIZE) && (FShrinkParent[code] != FREE_CODE))
            ++code;
        lastfreecode = code;
        if (code >= HSIZE) {
            /* invalid compressed data caused max-code overflow! */
            error = PK_ERR;
            break;
        }

        FShrinkValue[code] = finalval;
        FShrinkParent[code] = oldcode;
        oldcode = curcode;

    }

/*---------------------------------------------------------------------------
    Flush any remaining data and return to sender...
  ---------------------------------------------------------------------------*/

    if (FOutCount > 0) {
        if (error == PK_OK)
            error = Flush(FOutBuf, FOutCount) != 0;
        else
            Flush(FOutBuf, FOutCount);
    }

    delete FShrinkParent;
    delete FShrinkValue;
    delete FShrinkStack;
} /* end function unshrink() */

