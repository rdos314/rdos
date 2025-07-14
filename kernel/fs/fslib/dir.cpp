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

extern void UnlockDirLinkObject(TDir *dir, int index, struct TDirLink *link);
#pragma aux UnlockDirLinkObject parm routine [esi] [edx] [edi]

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
    struct RdosDirEntry *ParentEntry;

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
#   Name       : TDir::FindFree
#
#   Purpose....: Find free entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDir::FindFree()
{
    int i;

    for (i = 0; i < MaxCount; i++)
        if (!EntryArr[i].Offset)
            return i;

    i = MaxCount;
    Grow();

    return i;
}

/*##########################################################################
#
#   Name       : TDir::Add
#
#   Purpose....: Add directory entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct RdosDirEntry *TDir::Add(const char *path, long long inode)
{
    int pos;
    short int len = (short int)strlen(path);
    char *ptr;
    int index;
    struct RdosDirEntry *entry;

    len = len & 0xFFFC;
    len += 4;

    Section.Enter();

    index = FindFree();

    if (obj->UsageCount > 1)
        CopyOnUsed();

    pos = TBlock::Add(len + sizeof(struct RdosDirEntry));

    EntryArr[index].Offset = pos;
    EntryArr[index].Link = 0;

    EntryCount++;

    ptr = (char *)obj;
    ptr += pos;
    entry = (struct RdosDirEntry *)ptr;
    entry->Inode = inode;
    entry->Size = 0;
    entry->CreateTime = 0;
    entry->AccessTime = 0;
    entry->ModifyTime = 0;
    entry->Pos = 0;
    entry->Attrib = 0;
    entry->Flags = 0;
    entry->Uid = 0;
    entry->Gid = 0;
    entry->PathNameSize = len;
    strcpy(entry->PathName, path);

    Section.Leave();

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
    struct RdosDirEntry *entry;

    Section.Enter();

    for (i = 0; i < MaxCount; i++)
    {
        if (EntryArr[i].Offset)
        {
            ptr = (char *)obj;
            ptr += EntryArr[i].Offset;
            entry = (struct RdosDirEntry *)ptr;
            if (inode == entry->Inode)
            {
                Section.Leave();
                return i;
            }
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
    struct RdosDirEntry *entry;

    Section.Enter();

    for (i = 0; i < MaxCount; i++)
    {
        if (EntryArr[i].Offset)
        {
            ptr = (char *)obj;
            ptr += EntryArr[i].Offset;
            entry = (struct RdosDirEntry *)ptr;
            if (!strcmp(path, entry->PathName))
            {
                Section.Leave();
                return i;
            }
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
struct RdosDirEntry *TDir::LockEntry(int index)
{
    char *ptr;

    if (index < 0)
        return 0;

    if (index >= MaxCount)
        return 0;

    if (!EntryArr[index].Offset)
        return 0;

    Section.Enter();

    ptr = (char *)obj;
    ptr += EntryArr[index].Offset;
    return (struct RdosDirEntry *)ptr;
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
struct RdosDirEntry *TDir::LockEntry(struct TDirLink *link)
{
    char *ptr;

    Section.Enter();

    ptr = (char *)obj;
    ptr += link->Offset;
    return (struct RdosDirEntry *)ptr;
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
void TDir::UnlockEntry(struct RdosDirEntry *entry)
{
    if (entry)
        Section.Leave();
}

/*##########################################################################
#
#   Name       : TDir::DeleteEntry
#
#   Purpose....: Delete dir entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TDir::DeleteEntry(int index)
{
    char *ptr;
    char *src;
    char *dst;
    int pos;
    int size;
    int count;
    int i;
    struct RdosDirEntry *entry;

    if (index < 0)
        return false;

    if (index >= MaxCount)
        return false;

    if (!EntryArr[index].Offset)
        return false;

    if (EntryArr[index].Link)
        return false;

    if (EntryArr[index].WaitHandle)
        return false;

    pos = EntryArr[index].Offset;
    EntryArr[index].Offset = 0;
    EntryArr[index].RefCount = 0;

    ptr = (char *)obj;
    ptr += pos;

    entry = (struct RdosDirEntry *)ptr;

    if (!DeleteEntry(entry))
        return false;

    Section.Enter();

    size = entry->PathNameSize + sizeof(struct RdosDirEntry);

    if (obj->UsageCount > 1)
        CopyOnUsed();

    count = 0;

    for (i = 0; i < MaxCount; i++)
    {
        if (EntryArr[i].Offset > pos)
        {
            EntryArr[i].Offset -= size;
            count++;
        }
    }

    TBlock::Sub(size);
    EntryCount--;

    dst = ptr;
    src = ptr + size;

    for (i = 0; i < count; i++)
    {
        ptr += size;
        entry = (struct RdosDirEntry *)ptr;
        size = entry->PathNameSize + sizeof(struct RdosDirEntry);
        memcpy(dst, src, size);
        src += size;
        dst += size;
    }

    Section.Leave();

    return true;
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

    if (index >= MaxCount)
        return 0;

    if (!EntryArr[index].Offset)
        return 0;

    LockDirLinkObject(this, index, &EntryArr[index]);
    dir = (TDir *)EntryArr[index].Link;
    return dir;
}

/*##########################################################################
#
#   Name       : TDir::LockFileLink
#
#   Purpose....: Lock file link
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TDir::LockFileLink(int index)
{
    TFile *file;

    if (index < 0)
        return 0;

    if (index >= MaxCount)
        return 0;

    if (!EntryArr[index].Offset)
        return 0;

    LockDirLinkObject(this, index, &EntryArr[index]);
    file = (TFile *)EntryArr[index].Link;
    return file;
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

    if (index >= MaxCount)
        return;

    if (!EntryArr[index].Offset)
        return;

    UnlockDirLinkObject(this, index, &EntryArr[index]);
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

    if (index >= MaxCount)
        return 0;

    if (!EntryArr[index].Offset)
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

    if (index >= MaxCount)
        return;

    if (!EntryArr[index].Offset)
        return;

    EntryArr[index].Link = dir;
}

/*##########################################################################
#
#   Name       : TDir::GetFileLink
#
#   Purpose....: Get file link
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TDir::GetFileLink(int index)
{
    if (index < 0)
        return 0;

    if (index >= MaxCount)
        return 0;

    if (!EntryArr[index].Offset)
        return 0;

    return (TFile *)EntryArr[index].Link;
}

/*##########################################################################
#
#   Name       : TDir::SetFileLink
#
#   Purpose....: Set file link
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDir::SetFileLink(int index, TFile *file)
{
    if (index < 0)
        return;

    if (index >= MaxCount)
        return;

    if (!EntryArr[index].Offset)
        return;

    EntryArr[index].Link = file;
}

/*##########################################################################
#
#   Name       : TDir::ClearFileLink
#
#   Purpose....: Clear file link
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDir::ClearFileLink(int index)
{
    if (index < 0)
        return;

    if (index >= MaxCount)
        return;

    if (!EntryArr[index].Offset)
        return;

    EntryArr[index].Link = 0;
}
