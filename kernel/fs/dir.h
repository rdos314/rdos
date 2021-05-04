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
# discserv.h
# Disc server class
#
########################################################################*/

#ifndef _DIR_H
#define _DIR_H

#include "block.h"
#include "section.h"
#include "rdos.h"

class TMetaData;

struct TDirLink
{
    int Offset;
    struct TMetaData *Link;
};

class TMetaData
{
public:
    TMetaData(long long Parent);
    virtual ~TMetaData();

    virtual bool IsDir() = 0;

    long long Parent;
};

class TDir : public TMetaData, public TBlock
{
public:
    TDir(long long Parent);
    virtual ~TDir();

    virtual bool IsDir();
    struct TShareHeader *Share();
    int GetCount();

    struct DirEntry *Add(const char *path, long long inode);

    struct TDirLink *EntryArr;

protected:
    void Grow();

    int EntryCount;
    int MaxCount;
    TSection Section;
};

#endif

