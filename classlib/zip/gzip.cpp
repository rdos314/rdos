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
#  original copyright:
#
#  gz2zip.c version 1.0, 31 July 2018
#
#  Copyright (C) 2018 Mark Adler
#
#  This software is provided 'as-is', without any express or implied
#  warranty.  In no event will the authors be held liable for any damages
#  arising from the use of this software.
#
#  Permission is granted to anyone to use this software for any purpose,
#  including commercial applications, and to alter it and redistribute it
#  freely, subject to the following restrictions:
#
#  1. The origin of this software must not be misrepresented; you must not
#     claim that you wrote the original software. If you use this software
#     in a product, an acknowledgment in the product documentation would be
#     appreciated but is not required.
#  2. Altered source versions must be plainly marked as such, and must not be
#     misrepresented as being the original software.
#  3. This notice may not be removed or altered from any source distribution.
#
#  Mark Adler
#  madler@alumni.caltech.edu
#
# gzip.cpp
# gzip to pkzip converter
#
########################################################################*/



// Convert gzip (.gz) file to a single entry zip file. See the comments before
// gz2zip() for more details and caveats.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "rdos.h"
#include "file.h"

// Chunk size for reading and writing raw deflate data.
#define CHUNK 16384

// Type to track number of bytes written.
typedef struct 
{
    TFile *file;
    int off;
} tally_t;

/*##########################################################################
#
#   Name       : put
#
#   Purpose....: Write len bytes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void put(tally_t *t, void const *dat, int len) 
{
    int size;

    size = t->file->Write(dat, len);
    t->off += size;
}

/*##########################################################################
#
#   Name       : put2
#
#   Purpose....: Write 16-bit integer n in little-endian order to t.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void put2(tally_t *t, unsigned n) 
{
    unsigned char dat[2];
    dat[0] = (unsigned char)n;
    dat[1] = (unsigned char)(n >> 8);
    put(t, dat, 2);
}

/*##########################################################################
#
#   Name       : put4
#
#   Purpose....: Write 32-bit integer n in little-endian order to t.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void put4(tally_t *t, unsigned long n) 
{
    put2(t, n);
    put2(t, n >> 16);
}

/*##########################################################################
#
#   Name       : putz
#
#   Purpose....: Write n zeros to t.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void putz(tally_t *t, unsigned n) 
{
    unsigned char const buf[1] = {0};
    while (n--)
        put(t, buf, 1);
}

/*##########################################################################
#
#   Name       : unixtodos
#
#   Purpose....: Convert the Unix time unix to DOS time in the four bytes at *dos. If there
#                is a conversion error for any reason, store the current time in DOS format
#                at *dos. The Unix time in seconds is rounded up to an even number of
#                seconds, since the DOS time can only represent even seconds. If the Unix
#                time is before 1980, the minimum DOS time of Jan 1, 1980 is used.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void unix2dos(unsigned char *dos, time_t unix) 
{
    unix += unix & 1;
    struct tm *s = localtime(&unix);
    if (s == NULL) 
    {
        unix = time(NULL);              // on error, use current time
        unix += unix & 1;
        s = localtime(&unix);
    }
    if (s->tm_year < 80) 
    {              // no DOS time before 1980
        dos[0] = 0;  dos[1] = 0;                // use midnight,
        dos[2] = (1 << 5) + 1;  dos[3] = 0;     // Jan 1, 1980
    }
    else 
    {
        dos[0] = (s->tm_min << 5) + (s->tm_sec >> 1);
        dos[1] = (s->tm_hour << 3) + (s->tm_min >> 3);
        dos[2] = ((s->tm_mon + 1) << 5) + s->tm_mday;
        dos[3] = ((s->tm_year - 80) << 1) + ((s->tm_mon + 1) >> 3);
    }
}

/*##########################################################################
#
#   Name       : GzipToZip
#
#   Purpose....: Read the gzip file from in and write it as a single-entry zip file to out.
#                This assumes that the gzip file has a single member, that it has no junk
#                after the gzip trailer, and that it contains less than 4GB of uncompressed
#                data. The gzip file is not decompressed or validated, other than checking
#                for the proper header format. The modification time from the gzip header is
#                used for the zip entry, unless it is not present, in which case the current
#                local time is used for the zip entry. The file name from the gzip header is
#                used for the zip entry, unless it is not present, in which case "-" is used.
#                This does not use the Zip64 format, so the offsets in the resulting zip file
#                must be less than 4GB. If name is not NULL, then the zero-terminated string
#                at name is used as the file name for the single entry. Whether the file name
#                comes from the gzip header or from name, it is truncated to 64K-1 characters
#                if necessary.
#
#                It is recommended that unzip -t be used on the resulting file to verify its
#                integrity. If the gzip files do not obey the constraints above, then the zip
#                file will not be valid.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool GzipToZip(const char *GzipFile, const char *ZipFile, const char *name) 
{
    // zip file constant headers for local, central, and end record
    unsigned char const loc[] = {'P', 'K', 3, 4, 20, 0, 8, 0, 8, 0};
    unsigned char const cen[] = {'P', 'K', 1, 2, 20, 0, 20, 0, 8, 0, 8, 0};
    unsigned char const end[] = {'P', 'K', 5, 6, 0, 0, 0, 0, 1, 0, 1, 0};

    // gzip header
    unsigned char head[10];

    // zip file modification date, CRC, and sizes -- initialize to zero for the
    // local header (the actual CRC and sizes follow the compressed data)
    unsigned char desc[16] = {0};

    // name from gzip header to use for the zip entry (the maximum size of the
    // name is 256 -- if the gzip name is longer, then it is truncated)
    unsigned name_len;
    unsigned char uch;
    char ch;
    char save[257];

    TFile InFile(GzipFile);
    TFile OutFile(ZipFile, 0);

    // read and interpret the gzip header, bailing if it is invalid or has an
    // unknown compression method or flag bits set
    int got = InFile.Read(head, sizeof(head));
    if (got < sizeof(head) || head[0] != 0x1f || head[1] != 0x8b || head[2] != 8 || (head[3] & 0xe0))
        return false;

    if (head[3] & 4) 
    {                  // extra field (ignore)
        unsigned extra = uch;
        int high = uch;

        InFile.Read(&uch, 1);
        if (InFile.Read(&uch, 1) != 1)
            return false;

        extra += (unsigned)high << 8;
        InFile.SetPos(InFile.GetPos() + extra);
    }

    if (name)
        name_len = strlen(name) + 1;
    else
        name_len = 1;

    if (name_len > 1)
        strcpy(save, name);
    else
        save[0] = '-';

    if (head[3] & 8) 
    {                  
        // file name (save)

        if (name_len > 1)
            ch = 1;
        else
        {
            while (InFile.Read(&ch, 1) && ch && name_len < 255)
            {
                save[name_len] = ch;
                name_len++;
            }
            save[name_len] = 0;
        }
        
        if (ch)
            while (InFile.Read(&ch, 1) && ch)
                ;
    }

    if (head[3] & 16) 
    {                
        // comment (ignore)
        while (InFile.Read(&ch, 1) && ch)
            ;
    }

    if (head[3] & 2) 
    {
        // header crc (ignore)
        InFile.SetPos(InFile.GetPos() + 2);
    }

    // set modification time and date in descriptor from gzip header
    time_t mod = head[4] + (head[5] << 8) + ((time_t)(head[6]) << 16) +
                 ((time_t)(head[7]) << 24);
    unix2dos(desc, mod ? mod : time(NULL));

    // initialize tally of output bytes
    tally_t zip = {&OutFile, 0};

    // write zip local header
    int locoff = zip.off;
    put(&zip, loc, sizeof(loc));
    put(&zip, desc, sizeof(desc));
    put2(&zip, name_len);
    putz(&zip, 2);
    put(&zip, save, name_len);

    // copy raw deflate stream, saving eight-byte gzip trailer
    unsigned char buf[CHUNK + 8];

    if (InFile.Read(buf, 8) != 8)
        return false;

    int comp = 0;

    got = InFile.Read(buf + 8, CHUNK);

    while (got)
    {
        put(&zip, buf, got);
        comp += got;
        memmove(buf, buf + got, 8);
        got = InFile.Read(buf + 8, CHUNK);
    }

    // write descriptor based on gzip trailer and compressed count
    memcpy(desc + 4, buf, 4);
    desc[8] = comp;
    desc[9] = comp >> 8;
    desc[10] = comp >> 16;
    desc[11] = comp >> 24;
    memcpy(desc + 12, buf + 4, 4);
    put(&zip, desc + 4, sizeof(desc) - 4);

    // write zip central directory
    int cenoff = zip.off;
    put(&zip, cen, sizeof(cen));
    put(&zip, desc, sizeof(desc));
    put2(&zip, name_len);
    putz(&zip, 12);
    put4(&zip, locoff);
    put(&zip, save, name_len);

    // write zip end-of-central-directory record
    int endoff = zip.off;
    put(&zip, end, sizeof(end));
    put4(&zip, endoff - cenoff);
    put4(&zip, cenoff);
    putz(&zip, 2);
    return true;
}
