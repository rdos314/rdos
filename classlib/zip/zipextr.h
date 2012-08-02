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
# zipextr
# Extractor base class
#
########################################################################*/

#ifndef _ZIPEXTR_H
#define _ZIPEXTR_H

#include "thread.h"

#define WSIZE   0x8000  /* window size--must be a power of two, and */

#define STORED            0    /* compression methods */
#define SHRUNK            1
#define REDUCED1          2
#define REDUCED2          3
#define REDUCED3          4
#define REDUCED4          5
#define IMPLODED          6
#define TOKENIZED         7
#define DEFLATED          8
#define ENHDEFLATED       9
#define DCLIMPLODED      10
#define BZIPPED          12
#define LZMAED           14
#define IBMTERSED        18
#define IBMLZ77ED        19
#define WAVPACKED        97
#define PPMDED           98
#define NUM_METHODS      17     /* number of known method IDs */

class TUnzipFile;

class TUnzipExtractor : public TThread
{
public: 
    TUnzipExtractor(int InputFileHandle, TUnzipFile *File, const char *DestFileName);
    virtual ~TUnzipExtractor();

    int IsFileOpen();
    void SetupEncryption(const char *password);

    int Extract();

    int error;

    unsigned long FCurrCrcVal;

// these must be global due to callback interface

    char *GetInbuf();
    int FillInbuf();
    int Flush(char *rawbuf, int size);

protected:
    int Seek(long abs_offset);

    int DecryptByte();
    int UpdateKeys(int c);
    int ZDecode(int c);
    int Decrypt();

    int ReadByte();
    int GetNextByte();
    void DeferInput();
    void UndeferInput();

    TUnzipFile *FFile;

    int FInputHandle;
    int FOutputHandle;

    char *FInBuf;
    char *FInPtr;
    int FInCount;

    int FLeftoverCount;
    char *FLeftoverPtr;

    int FDoDecrypt;
    long FDecompSize;

    unsigned int FKeys[3]; 

    char *FTmpOutBuf;
    char *FOutBuf;
    char *FOutPtr;
    int FOutCount;

    int FCrLast;
    int FDoText;
};

#endif
