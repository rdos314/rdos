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
# zipexpl.h
# Explode extractor class
#
########################################################################*/

#ifndef _ZIPEXPL_H
#define _ZIPEXPL_H

#include "zipextr.h"

/* Huffman code lookup table entry--this entry is four bytes for machines
   that have 16-bit pointers (e.g. PC's in the small or medium model).
   Valid extra bits are 0..16.  e == 31 is EOB (end of block), e == 32
   means that v is a literal, 32 < e < 64 means that v is a pointer to
   the next table, which codes (e & 31)  bits, and lastly e == 99 indicates
   an unused code.  If a code with e == 99 is looked up, this implies an
   error in the data. */

struct TUnzipHuft {
    unsigned char e;                /* number of extra bits or operation */
    unsigned char b;                /* number of bits in this code or subcode */
    union {
        unsigned short n;            /* literal, length base, or distance base */
        struct TUnzipHuft *t;        /* pointer to next level of table */
    } v;
};

class TUnzipExplodeExtractor : public TUnzipExtractor
{
public:
    TUnzipExplodeExtractor(int InputFileHandle, TUnzipFile *File, const char *DestFileName);
    virtual ~TUnzipExplodeExtractor();

protected:
    int ExplodeLit(struct TUnzipHuft *tb, struct TUnzipHuft *tl, struct TUnzipHuft *td, unsigned bb, unsigned bl, unsigned bd, unsigned bdl);
    int ExplodeNolit(struct TUnzipHuft *tl, struct TUnzipHuft *td, unsigned bl, unsigned bd, unsigned bdl);

    int BuildHuft(const unsigned *b, unsigned n, unsigned s, const unsigned short *d, const unsigned char *e, TUnzipHuft **t, unsigned *m);
    void FreeHuft(struct TUnzipHuft *t);

    int ExplodeGetTree(unsigned *l, unsigned n);

    virtual void Execute();

    int FUsedCSize;
};

#endif
