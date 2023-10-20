/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-20019, Leif Ekblad
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

