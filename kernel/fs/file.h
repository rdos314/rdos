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
# file.h
# File class
#
########################################################################*/

#ifndef _FILE_H
#define _FILE_H

#include "section.h"
#include "rdos.h"
#include "block.h"
#include "dir.h"

struct TFileReq
{
    long long Pos;
    int Size;
    long long *SectorBuf;
    char *KernelData;
    short int PendingSel;
    short int RefCount;
};

struct TFileInfo
{
    long long FsSize;
    long long ReqSize;
    long long AccessTime;
    long long ModifyTime;
    int Attrib;
    int Flags;
    int Uid;
    int Gid;
    int KernelHandle;
    int ServHandle;
    char Disc;
    char Drive;
    char Part;
    char Pad;
    int ReqCount;
    struct TFileReq ReqArr[];
};


class TFile : public TBlock
{
public:
    TFile(TDir *ParentDir, int ParentIndex);
    virtual ~TFile();

    virtual long long AdjustStart(long long pos) = 0;
    virtual long long AdjustEnd(long long pos) = 0;
    virtual void GetSectors(long long pos, long long *SectorArr, int SectorCount) = 0;

    void Setup(int VfsHandle, int ServFileHandle);

    void LockFile();
    void UnlockFile();

    int GetServHandle();
    int GetKernelHandle();
    int GetAttrib();

protected:
    TDir *Parent;
    int ParentIndex;
    TSection Section;

    struct TFileInfo *Info;
};

#endif

