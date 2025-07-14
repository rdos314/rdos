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
# fat.h
# Fat functions
#
########################################################################*/

#ifndef _FAT_H
#define _FAT_H

struct TFatDirEntry
{
    char Base[8];
    char Ext[3];
    char Attr;
    char Resv1;
    unsigned char CrMs;
    short int CrTime;
    short int CrDate;
    short int AcDate;
    unsigned short int ClusterHi;
    short int WrTime;
    short int WrDate;
    unsigned short int ClusterLow;
    unsigned int FileSize;
};

unsigned int GetCluster(struct TFatDirEntry *entry);
long long DecodeTime(short int Date, short int Time, unsigned char Ms);
void EncodeTime(long long RdosTime, short int *Date, short int *Time, unsigned char *Ms);
int DecodeAttrib(char attrib);
char EncodeAttrib(int attrib);
void GetEntryName(struct TFatDirEntry *entry, char *name);
void SetEntryName(struct TFatDirEntry *entry, const char *name);
bool SetCreateTime(struct TFatDirEntry *entry, long long td);
bool SetAccessTime(struct TFatDirEntry *entry, long long td);
bool SetWriteTime(struct TFatDirEntry *entry, long long td);
char GetChkSum(struct TFatDirEntry *entry);

bool IsValidShortChar(char ch);
bool IsValidShortName(const char *buf);
void GenerateShortName(const char *name, int index, char *buf);


#endif

