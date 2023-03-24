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
# fileio.h
# File IO class
#
########################################################################*/

#ifndef _FILE_IO_H
#define _FILE_IO_H

#include "section.h"
#include "rdos.h"

#define REQ_READ       1
#define REQ_FREE       2
#define REQ_CLOSE      3
#define REQ_COMPLETED  4
#define REQ_MAP        5

struct TFileIoEntry
{
    long long Par64;
    int Par32;
    short int File;
    short int Op;
};

class TFs;

class TFileIo
{
public:
    TFileIo();
    ~TFileIo();

    bool IsRunning();
    void Start(TFs *fs);
    void Execute();

protected:
    void HandleRead(long long pos, int size);
    void HandleCompletedReq(int index);
    void HandleMapReq(int index);
    void HandleFreeReq(int index);
    bool HandleQueue(struct TFileIoEntry *entry);

    int FHandle;
    TFs* Fs;
    bool FActive;
};

#endif

