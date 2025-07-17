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

