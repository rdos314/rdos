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

    int FOk;

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
