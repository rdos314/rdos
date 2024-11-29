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
# zipstor.cpp
# Stored extractor class
#
########################################################################*/

#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h> 

#include "rdos.h"
#include "unzip.h"
#include "zipstor.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TUnzipStoreExtractor::TUnzipStoreExtractor
#
#   Purpose....: Constructor for store extractor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipStoreExtractor::TUnzipStoreExtractor(int InputFileHandle, TUnzipFile *File, const char *DestFileName)
  : TUnzipExtractor(InputFileHandle, File, DestFileName)
{
}

/*##########################################################################
#
#   Name       : TUnzipStoreExtractor::~TUnzipStoreExtractor
#
#   Purpose....: Destructor for store extractor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUnzipStoreExtractor::~TUnzipStoreExtractor()
{
}

/*##########################################################################
#
#   Name       : TUnzipStoreExtractor::Execute
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUnzipStoreExtractor::Execute()
{
    int b;
    
    FOutPtr = FOutBuf;
    FOutCount = 0;

    while ((b = GetNextByte()) != EOF) {
        *FOutPtr++ = b;
        if (++FOutCount == WSIZE) {
            FOk = Flush(FOutBuf, FOutCount);
            FOutPtr = FOutBuf;
            FOutCount = 0;
            if (!FOk) break;
        }
    }

    if (FOk && FOutCount) {        /* flush final (partial) buffer */
        FOk = Flush(FOutBuf, FOutCount);
    }
}

