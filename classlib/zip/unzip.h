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

struct TUnzipHeader
{
    unsigned long size_central_directory;
    unsigned long offset_start_central_directory;
    unsigned int num_entries_centrl_dir_ths_disk;
    unsigned int total_entries_central_dir;
    unsigned short number_this_disk;
    unsigned short num_disk_start_cdir;
    unsigned short zipfile_comment_length;
};


class TUnzip;

class TUnzipFile
{
friend class TUnzip;
friend class TUnzipExtractor;
friend class TUnzipExplodeExtractor;
public:
    TUnzipFile(TUnzip *unzip);
    ~TUnzipFile();

    void Skip();

    int IsOk();
    int IsSkipped();
    
    int Extract(const char *filename);
    int NeedUpdate(const char *filename);

    int CheckForNewer(const char *filename);

    void ShowVerbose();
    void ShowCompact();

    const char *GetFileName();

protected:
    void CreateTimeStr(char *str);

    int ProcessDirEntry();
    int ProcessFileHeader();

    char *cfilname;          /* central header version of filename */

    int FOk;
    int FSkipped;

    TUnzip *FUnzip;
    
    long offset;
    unsigned long compr_size;       /* compressed size (needed if extended header) */
    unsigned long uncompr_size;     /* uncompressed size (needed if extended header) */
    unsigned long crc;              /* crc (needed if extended header) */
    unsigned short diskstart;       /* no of volume where this entry starts */
    int encrypted;                  /* is encrypted */
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
};

class TUnzip
{
friend class TUnzipFile;
public:
    TUnzip(const char *name);
    TUnzip();
    ~TUnzip();

    int Open(const char *name);
    int OpenNoHeader(const char *name);
    void Close();

    TUnzipFile *GetFile(int index);
    int GetFileCount();

    void Trace(const char *format, ...);
    void Info(int code, const char *format, ...);

    void (*OnTrace)(TUnzip *unzip, const char *msg);
    void (*OnInfo)(TUnzip *unzip, int code, const char *msg);
    
protected:

private:
    void Init();

    int GetCentralHeader(const char *filename, long searchlen, int verbose);

    unsigned ReadBuf(char *buf, register unsigned size);
    int Seek(long abs_offset);

    void SkipHeaderString(int length);
    void DisplayHeaderString(int lenght, int oemconvert);

    int GetFileName(char *buf, int length);
    int SeekFile(TUnzipFile *file);
    TUnzipFile *ProcessNextFile();
    int FindRec(long searchlen, char* signature, int rec_size);

    int ProcessFiles(const char *filename, int verbose);

    char FLogBuf[512];

    int FFileSize;
    int FFileCount;
    TUnzipFile **FFileArr;

    int FInputHandle;

    char *FInBuf;
    char *FInPtr;
    int FInCount;
    int FBufStart;

    int FExtraBytes;
    int FOldExtraBytes;

    long FZipLen;
    unsigned long FRealHeaderOffset;
    unsigned long FExpectHeaderOffset;
    char *FSearchHold;
    TUnzipHeader FHeader;
};

#endif
