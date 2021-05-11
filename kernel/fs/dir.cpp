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
# dir.cpp
# Directory entry class
#
########################################################################*/

#include <string.h>
#include <rdos.h>
#include <serv.h>
#include "dir.h"

extern "C" {

extern void LockDirLinkObject(TDir *dir, int index, struct TDirLink *link);
#pragma aux LockDirLinkObject parm routine [esi] [edx] [edi]

extern void UnlockDirLinkObject(struct TDirLink *link);
#pragma aux UnlockDirLinkObject parm routine [edi]

}

/*##########################################################################
#
#   Name       : TDir::TDir
#
#   Purpose....: Dir constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir::TDir(TDir *pd, int pi)
  : Section("dir")
{
    int i;
    struct DirEntry *ParentEntry;

    Entry = 0;
    Parent = pd;
    ParentIndex = pi;

    if (Parent)
    {
        ParentEntry = Parent->LockEntry(ParentIndex);
        Inode = ParentEntry->Inode;
        Parent->UnlockEntry(ParentEntry);
    }
    else
        Inode = 0;

    EntryCount = 0;
    MaxCount = 4;
    EntryArr = new TDirLink[MaxCount];

    for (i = 0; i < MaxCount; i++)
    {
        EntryArr[i].Offset = 0;
        EntryArr[i].Link = 0;
        EntryArr[i].WaitHandle = 0;
        EntryArr[i].RefCount = 0;
        EntryArr[i].WaitCount = 0;
    }
}

/*##########################################################################
#
#   Name       : TDir::~TDir
#
#   Purpose....: Dir destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir::~TDir()
{
    delete EntryArr;
}

/*##########################################################################
#
#   Name       : TDir::LockDir
#
#   Purpose....: Lock
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDir::LockDir()
{
    if (Parent)
        Parent->LockDirLink(ParentIndex);
}

/*##########################################################################
#
#   Name       : TDir::UnlockDir
#
#   Purpose....: Unlock dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDir::UnlockDir()
{
    if (Parent)
        Parent->UnlockDirLink(ParentIndex);
}

/*##########################################################################
#
#   Name       : TDir::Grow
#
#   Purpose....: Grow link array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDir::Grow()
{
    int i;
    int Size = 2 * MaxCount;
    struct TDirLink *NewArr;

    NewArr = new TDirLink[Size];

    for (i = 0; i < MaxCount; i++)
    {
        NewArr[i].Offset = EntryArr[i].Offset;
        NewArr[i].Link = EntryArr[i].Link;
        NewArr[i].WaitHandle = EntryArr[i].WaitHandle;
        NewArr[i].RefCount = EntryArr[i].RefCount;
        NewArr[i].WaitCount = EntryArr[i].WaitCount;
    }

    for (i = MaxCount; i < Size; i++)
    {
        NewArr[i].Offset = 0;
        NewArr[i].Link = 0;
        NewArr[i].WaitHandle = 0;
        NewArr[i].RefCount = 0;
        NewArr[i].WaitCount = 0;
    }

    delete EntryArr;
    EntryArr = NewArr;
    MaxCount = Size;
}

/*##########################################################################
#
#   Name       : TDir::Add
#
#   Purpose....: Add directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct DirEntry *TDir::Add(const char *path, long long inode)
{
    int pos;
    short int len = strlen(path);
    char *ptr;
    struct DirEntry *entry;

    len = len & 0xFFFC;
    len += 4;

    if (EntryCount == MaxCount)
        Grow();

    if (obj->UsageCount > 1)
        CopyOnUsed();

    pos = TBlock::Add(len + sizeof(struct DirEntry));

    EntryArr[EntryCount].Offset = pos;
    EntryArr[EntryCount].Link = 0;
    EntryCount++;

    ptr = (char *)obj;
    ptr += pos;
    entry = (struct DirEntry *)ptr;
    entry->Inode = inode;
    entry->Size = 0;
    entry->CreateTime = 0;
    entry->AccessTime = 0;
    entry->ModifyTime = 0;
    entry->Sector = 0;
    entry->Offset = 0;
    entry->Attrib = 0;
    entry->Flags = 0;
    entry->Uid = 0;
    entry->Gid = 0;
    entry->PathNameSize = len;
    strcpy(entry->PathName, path);

    return entry;
}

/*##########################################################################
#
#   Name       : TDir::Share
#
#   Purpose....: Share directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct TShareHeader *TDir::Share()
{
    return obj;
}

/*##########################################################################
#
#   Name       : TDir::GetCount
#
#   Purpose....: Get count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDir::GetCount()
{
    return EntryCount;
}

/*##########################################################################
#
#   Name       : TDir::GetInode
#
#   Purpose....: Get inode
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TDir::GetInode()
{
    return Inode;
}

/*##########################################################################
#
#   Name       : TDir::Find
#
#   Purpose....: Find inode
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDir::Find(long long inode)
{
    int i;
    char *ptr;
    struct DirEntry *entry;

    Section.Enter();

    for (i = 0; i < EntryCount; i++)
    {
        ptr = (char *)obj;
        ptr += EntryArr[i].Offset;
        entry = (struct DirEntry *)ptr;
        if (inode == entry->Inode)
        {
            Section.Leave();
            return i;
        }
    }

    Section.Leave();

    return DIR_NOT_FOUND;
}

/*##########################################################################
#
#   Name       : TDir::Find
#
#   Purpose....: Find path
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDir::Find(const char *path)
{
    int i;
    char *ptr;
    struct DirEntry *entry;

    Section.Enter();

    for (i = 0; i < EntryCount; i++)
    {
        ptr = (char *)obj;
        ptr += EntryArr[i].Offset;
        entry = (struct DirEntry *)ptr;
        if (!strcmp(path, entry->PathName))
        {
            Section.Leave();
            return i;
        }
    }

    Section.Leave();

    return DIR_NOT_FOUND;
}

/*##########################################################################
#
#   Name       : TDir::LockEntry
#
#   Purpose....: Lock dir entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct DirEntry *TDir::LockEntry(int index)
{
    int i;
    char *ptr;
    struct DirEntry *entry;

    if (index < 0)
        return 0;

    if (index >= EntryCount)
        return 0;

    Section.Enter();

    ptr = (char *)obj;
    ptr += EntryArr[index].Offset;
    return (struct DirEntry *)ptr;
}

/*##########################################################################
#
#   Name       : TDir::LockEntry
#
#   Purpose....: Lock dir entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct DirEntry *TDir::LockEntry(struct TDirLink *link)
{
    char *ptr;
    struct DirEntry *entry;

    Section.Enter();

    ptr = (char *)obj;
    ptr += link->Offset;
    return (struct DirEntry *)ptr;
}

/*##########################################################################
#
#   Name       : TDir::UnlockEntry
#
#   Purpose....: Unlock dir entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDir::UnlockEntry(struct DirEntry *entry)
{
    if (entry)
        Section.Leave();
}

/*##########################################################################
#
#   Name       : TDir::GetParentDir
#
#   Purpose....: Get parent dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir *TDir::GetParentDir()
{
    return Parent;
}

/*##########################################################################
#
#   Name       : TDir::LockDirLink
#
#   Purpose....: Lock dir link
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir *TDir::LockDirLink(int index)
{
    TDir *dir;

    if (index < 0)
        return 0;

    if (index >= EntryCount)
        return 0;

    LockDirLinkObject(this, index, &EntryArr[index]);
    dir = (TDir *)EntryArr[index].Link;
    return dir;
}

/*##########################################################################
#
#   Name       : TDir::UnlockDirLink
#
#   Purpose....: Unlock dir link
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDir::UnlockDirLink(int index)
{
    if (index < 0)
        return;

    if (index >= EntryCount)
        return;

    UnlockDirLinkObject(&EntryArr[index]);
}

/*##########################################################################
#
#   Name       : TDir::GetDirLink
#
#   Purpose....: Get dir link
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir *TDir::GetDirLink(int index)
{
    if (index < 0)
        return 0;

    if (index >= EntryCount)
        return 0;

    return (TDir *)EntryArr[index].Link;
}

/*##########################################################################
#
#   Name       : TDir::SetDirLink
#
#   Purpose....: Set dir link
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDir::SetDirLink(int index, TDir *dir)
{
    if (index < 0)
        return;

    if (index >= EntryCount)
        return;

    EntryArr[index].Link = dir;
}
