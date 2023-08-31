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
# fatdir.h
# FAT directory class
#
########################################################################*/

#ifndef _FATDIR_H
#define _FATDIR_H

#include "dir.h"
#include "fatlfn.h"

struct TFatDirEntry
{
    char Base[8];
    char Ext[3];
    char Attr;
    char Resv1;
    char Resv2;
    short int CrTime;
    short int CrDate;
    short int AcDate;
    short int ClusterHi;
    short int WrTime;
    short int WrDate;
    short int ClusterLow;
    unsigned int FileSize;
};

class TFatDir : public TDir
{
public:
    TFatDir(TDir *ParentDir, int ParentIndex);
    virtual ~TFatDir();

    void Add(long long sector, int offset, struct TFatDirEntry *entry);

protected:
    unsigned int GetCluster(struct TFatDirEntry *entry);
    long long DecodeTime(short int Date, short int Time);
    int DecodeAttrib(char attrib);
    void Add(long long sector, int offset, const char *name, struct TFatDirEntry *fat);
    void AddStd(long long sector, int offset, struct TFatDirEntry *entry);
    void AddLfn(long long sector, int offset, struct TFatDirEntry *entry);

    struct TFatLfn *FCurrLfn;

};

#endif

