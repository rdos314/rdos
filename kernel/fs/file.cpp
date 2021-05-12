/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# file.cpp
# File class
#
########################################################################*/

#include <string.h>
#include <rdos.h>
#include "file.h"

/*##########################################################################
#
#   Name       : TFile::TFile
#
#   Purpose....: Dir constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::TFile(TDir *pd, int pi)
  : Section("file")
{
    int pos;
    struct DirEntry *entry;
    char *ptr;

    Entry = 0;
    Parent = pd;
    ParentIndex = pi;

    entry = Parent->LockEntry(ParentIndex);

    pos = Add(sizeof(struct TFileInfo));
    ptr = (char *)obj;
    Info = (struct TFileInfo *)(ptr + pos);

    Info->FsSize = entry->Size;
    Info->ReqSize = entry->Size;
    Info->AccessTime = entry->AccessTime;
    Info->ModifyTime = entry->ModifyTime;
    Info->Attrib = entry->Attrib;
    Info->Flags = entry->Flags;
    Info->Uid = entry->Uid;
    Info->Gid = entry->Gid;
    Info->Handle = 0;

    Parent->UnlockEntry(entry);

    ServOpenVfsFile(obj);
}

/*##########################################################################
#
#   Name       : TFile::~TFile
#
#   Purpose....: File destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::~TFile()
{
}

/*##########################################################################
#
#   Name       : TFile::LockFile
#
#   Purpose....: Lock
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::LockFile()
{
}

/*##########################################################################
#
#   Name       : TFile::UnlockFile
#
#   Purpose....: Unlock file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::UnlockFile()
{
}

/*##########################################################################
#
#   Name       : TFile::GetAttrib
#
#   Purpose....: Get attrib
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFile::GetAttrib()
{
    return Info->Attrib;
}
