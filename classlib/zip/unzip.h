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
# unzip.h
# unzip class
#
########################################################################*/

#ifndef _UNZIP_H
#define _UNZIP_H

#include "str.h"

/* external return codes */
#define PK_OK              0   /* no error */
#define PK_COOL            0   /* no error */
#define PK_WARN            1   /* warning error */
#define PK_ERR             2   /* error in zipfile */
#define PK_BADERR          3   /* severe error in zipfile */
#define PK_MEM             4   /* insufficient memory (during initialization) */
#define PK_MEM2            5   /* insufficient memory (password failure) */
#define PK_MEM3            6   /* insufficient memory (file decompression) */
#define PK_MEM4            7   /* insufficient memory (memory decompression) */
#define PK_MEM5            8   /* insufficient memory (not yet used) */
#define PK_NOZIP           9   /* zipfile not found */
#define PK_PARAM          10   /* bad or illegal parameters specified */
#define PK_FIND           11   /* no files found */
#define PK_SKIP           12   /* don't extract */
#define PK_DISK           50   /* disk full */
#define PK_EOF            51   /* unexpected EOF */

// these should be private!

#define DOES_NOT_EXIST    -1   /* return values for CheckForNewer() */
#define EXISTS_AND_OLDER  0
#define EXISTS_AND_NEWER  1

#define FILE_NAME_SIZE        513

#define DIR_BLKSIZ 16384   /* use more memory, to reduce long-range seeks */

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

/* The following structs are used to hold all header data of a zip entry.
   Traditionally, the structs' layouts followed the data layout of the
   corresponding zipfile header structures.  However, the zipfile header
   layouts were designed in the old ages of 16-bit CPUs, they are subject
   to structure padding and/or alignment issues on newer systems with a
   "natural word width" of more than 2 bytes.
   Please note that the structure members are now reordered by size
   (top-down), to prevent internal padding and optimize memory usage!
 */

struct TUnzipFile
{
    long offset;
    unsigned long compr_size;       /* compressed size (needed if extended header) */
    unsigned long uncompr_size;     /* uncompressed size (needed if extended header) */
    unsigned long crc;              /* crc (needed if extended header) */
    unsigned short diskstart;       /* no of volume where this entry starts */
    int encrypted;                  /* is encrypted */
    int error;
    unsigned long file_data_offset;
    unsigned char hostver;
    unsigned char hostnum;
    unsigned long rdos_msb_time;
    unsigned long rdos_lsb_time;
    unsigned char version_needed_to_extract[2];
    unsigned short compression_method;
    unsigned short internal_file_attributes;
    unsigned long external_file_attributes;
    unsigned short general_purpose_bit_flag;
    unsigned ExtLocHdr : 1;  /* use time instead of CRC for decrypt check */
    unsigned textfile : 1;   /* file is text (according to zip) */
    unsigned lcflag : 1;     /* convert filename to lowercase */
    unsigned vollabel : 1;   /* "file" is an MS-DOS volume (disk) label */
    unsigned HasUxAtt : 1;   /* crec ext_file_attr has Unix style mode bits */
    char *cfilname;          /* central header version of filename */
};

class TUnzip
{
public:
	TUnzip();
    ~TUnzip();

    void Trace(const char *format, ...);
    void Info(int code, const char *format, ...);

    void (*OnTrace)(TUnzip *unzip, const char *msg);
    void (*OnInfo)(TUnzip *unzip, int code, const char *msg);

    void SetInputFile(const char *name);
    void SetupEncryption(const char *password);
    int OpenInputFile();
    unsigned ReadBuf(char *buf, register unsigned size);
    int Seek(long abs_offset);
    void DisplayHeaderString(int lenght, int oemconvert);

    void ProcessFiles();

    struct TUnzipFile *GetFile(int index);

    int Extract(struct TUnzipFile *file);

    int CheckForNewer(struct TUnzipFile *file, const char *filename);

    void CreateTimeStr(struct TUnzipFile *file, char *str);
    void ShowVerbose(struct TUnzipFile *file);
    void ShowCompact(struct TUnzipFile *file);

// these must be global due to callback interface

    char *GetInbuf();
    int FillInbuf();
    int Flush(char *rawbuf, int size);

    TString FInputFileName;
    int FInputHandle;

    char *FInBuf;
    char *FInPtr;
    int FInCount;
    int FBufStart;

    int FExtraBytes;
    int FOldExtraBytes;

    char FCurrFileName[FILE_NAME_SIZE];
    int FDiskFull;
    
protected:

private:
    void Init();

    void DeferInput();
    void UndeferInput();
    int ReadByte();
    int GetNextByte();

    void SkipHeaderString(int length);

    int DecryptByte();
    int UpdateKeys(int c);
    int ZDecode(int c);
    int Decrypt(struct TUnzipFile *file);

    int GetFileName(int length);
    int GetDirEntry(struct TUnzipFile *file);
    int ProcessDirEntry(struct TUnzipFile *file);
    int DirEntryToFile(struct TUnzipFile *file, const char *filename);
    int SeekFile(struct TUnzipFile *file);
    int ProcessFileHeader(struct TUnzipFile *file);
    int AddFile(struct TUnzipFile *file);

    int OpenOutputFile(const char *filename);
    void CloseOutputFile();
    void CloseAndSetTime(struct TUnzipFile *file);
    int DiskError();

    int ExplodeLit(struct TUnzipFile *file, struct TUnzipHuft *tb, struct TUnzipHuft *tl, struct TUnzipHuft *td, unsigned bb, unsigned bl, unsigned bd, unsigned bdl);
    int ExplodeNolit(struct TUnzipFile *file, struct TUnzipHuft *tl, struct TUnzipHuft *td, unsigned bl, unsigned bd, unsigned bdl);

    void UnshrinkPartialClear(int lastcodeused);

    int BuildHuft(const unsigned *b, unsigned n, unsigned s, const unsigned short *d, const unsigned char *e, TUnzipHuft **t, unsigned *m);
    void FreeHuft(struct TUnzipHuft *t);

    int ExplodeGetTree(unsigned *l, unsigned n);

    int Explode(struct TUnzipFile *file);
    int Unshrink();
    int Deflate();
    int Store();

    char *FOutBuf;
    char *FOutPtr;
    int FOutCount;

    long FDecompSize;

    int *FShrinkParent;          /* pointer to (8192 * sizeof(int)) */
    unsigned char *FShrinkValue;              /* pointer to 8KB char buffer */
    unsigned char *FShrinkStack;              /* pointer to another 8KB char buffer */
    int FZipeof;
    int FBitsLeft;
    unsigned long FBitBuf;

    char FLogBuf[512];

    int FLeftoverCount;
    char *FLeftoverPtr;

    unsigned long FCurrCrcVal;
    int FUsedCSize;

    unsigned int FKeys[3]; 

    int FOutputHandle;
    char *FTmpOutBuf;
    int FCrLast;

    int FDoDecrypt;
    int FDoText;

    int FFileSize;
    int FFileCount;
    struct TUnzipFile **FFileA;

    struct TUnzipFile FFileArr[DIR_BLKSIZ];

};

#endif
