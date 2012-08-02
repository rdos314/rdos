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
#include "thread.h"

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

/* The following structs are used to hold all header data of a zip entry.
   Traditionally, the structs' layouts followed the data layout of the
   corresponding zipfile header structures.  However, the zipfile header
   layouts were designed in the old ages of 16-bit CPUs, they are subject
   to structure padding and/or alignment issues on newer systems with a
   "natural word width" of more than 2 bytes.
   Please note that the structure members are now reordered by size
   (top-down), to prevent internal padding and optimize memory usage!
 */

class TUnzip;

class TUnzipFile
{
friend class TUnzip;
public:
    TUnzipFile(TUnzip *unzip);
    ~TUnzipFile();
    
    int Extract();

    int CheckForNewer(const char *filename);

    void CreateTimeStr(char *str);
    void ShowVerbose();
    void ShowCompact();

    long offset;
    unsigned long compr_size;       /* compressed size (needed if extended header) */
    unsigned long uncompr_size;     /* uncompressed size (needed if extended header) */
    unsigned long crc;              /* crc (needed if extended header) */
    unsigned short diskstart;       /* no of volume where this entry starts */
    int encrypted;                  /* is encrypted */
    int error;
    unsigned long file_data_offset;
    unsigned long abs_data_offset;
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

// must be global due to callbacks

    int Flush(char *rawbuf, int size);

protected:
    int OpenOutputFile(const char *filename);
    void CloseAndSetTime();
    int DiskError();

    int Store();

    char *FOutBuf;
    char *FOutPtr;
    int FOutCount;

    int FOutputHandle;
    char *FTmpOutBuf;
    int FCrLast;

    int FDoText;

    unsigned long FCurrCrcVal;

    TUnzip *FUnzip;
    
};

class TUnzip
{
friend class TUnzipFile;
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

    TUnzipFile *GetFile(int index);
    int GetFileCount();

// these must be global due to callback interface

    char *GetInbuf();
    int FillInbuf();

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
    int Decrypt();

    int GetFileName(int length);
    int GetDirEntry(TUnzipFile *file);
    int ProcessDirEntry(TUnzipFile *file);
    int DirEntryToFile(TUnzipFile *file, const char *filename);
    int SeekFile(TUnzipFile *file);
    int ProcessFileHeader(TUnzipFile *file);
    TUnzipFile *ProcessNextFile();

    char FLogBuf[512];

    int FLeftoverCount;
    char *FLeftoverPtr;

    int FDoDecrypt;
    long FDecompSize;

    unsigned int FKeys[3]; 

    int FFileSize;
    int FFileCount;
    TUnzipFile **FFileArr;

};

#endif
